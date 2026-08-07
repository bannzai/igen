import FirebaseAuth
import Foundation

/// 返書 API (backend/functions) のクライアント。
enum IgenAPI {
  /// 返書 API のエラー
  enum APIError: Error {
    /// 無料枠 (1 日 1 通) を使い切った (HTTP 429)
    case freeQuotaExceeded
    /// 匿名認証がまだ完了していない
    case unauthenticated
    /// その他の HTTP エラー
    case http(statusCode: Int)
    /// レスポンスの形が想定と異なる
    case invalidResponse
  }

  /// POST /letters の結果。危機ワード検知時は返書ではなく safety が返る
  enum LetterResult {
    case letter(Letter)
    case safety
  }

  /// 相談本文の送信上限。バックエンド (backend/functions/src/openai.ts の MAX_CONCERN_CHARS) と同じ値
  static let maxConcernChars = 2000

  /// Emulator 開発かどうか。判定は FirebaseSetup.usesEmulator と共有する
  /// (Debug は既定で Functions エミュレータ、IGEN_USE_PROD=1 または Release で実プロジェクト)
  private static var usesEmulator: Bool {
    FirebaseSetup.usesEmulator
  }

  /// API のベース URL。Emulator 開発では Functions エミュレータ、それ以外は実プロジェクト igen-prod に向ける
  static var baseURL: URL {
    if usesEmulator {
      return URL(string: "http://127.0.0.1:5201/demo-igen/asia-northeast1/api")!
    }
    return URL(string: "https://asia-northeast1-igen-prod.cloudfunctions.net/api")!
  }

  /// 相談本文を送り、返書または safety を受け取る。
  /// 401 はまずトークンを強制更新して 1 回リトライする。それでも 401 の場合、Emulator 開発時に限り
  /// 匿名ユーザーを作り直してもう 1 回だけリトライする (Auth エミュレータ再起動で残った無効セッションの回復)。
  /// 本番では認証系の一時的な失敗で UID を作り直すと保存済み返書 (users/{uid}/letters) へ
  /// 恒久的にアクセスできなくなるため、ユーザーの作り直しはしない
  static func requestLetter(text: String, language: String, timeZone: String) async throws -> LetterResult {
    // 再送 (トークン更新・ユーザー作り直し後を含む) で同じ ID を使い、応答喪失時にサーバーが
    // 保存済みの返書を再生成せずに返せるようにする (POST の冪等化)
    let requestId = UUID().uuidString
    let firstResponse = try await postLetter(
      text: text,
      language: language,
      timeZone: timeZone,
      requestId: requestId,
      forcesTokenRefresh: false
    )
    if firstResponse.statusCode != 401 {
      return try parseLetterResponse(firstResponse)
    }
    if usesEmulator == false {
      return try parseLetterResponse(
        try await postLetter(
          text: text,
          language: language,
          timeZone: timeZone,
          requestId: requestId,
          forcesTokenRefresh: true
        )
      )
    }
    // Emulator では、強制更新が 401 を返すケースに加えて、無効なリフレッシュトークンで
    // getIDToken 自体が throw するケース (Auth エミュレータ再起動後) もリセット経路へつなぐ。
    // 取得できたレスポンスの解析エラーを認証リセットの対象にしないよう、catch は取得までに限定する
    var refreshedResponse: (statusCode: Int, data: Data)?
    do {
      refreshedResponse = try await postLetter(
        text: text,
        language: language,
        timeZone: timeZone,
        requestId: requestId,
        forcesTokenRefresh: true
      )
    } catch {
      // リセットで回復を試みるため、ここでは投げ直さない
      refreshedResponse = nil
    }
    if let refreshedResponse, refreshedResponse.statusCode != 401 {
      return try parseLetterResponse(refreshedResponse)
    }
    let resetUid = try await FirebaseSetup.resetAnonymousUser()
    // 購入とサーバーの entitlement 照会が同じ UID を見るよう、RevenueCat 側も新しい UID へ切り替える
    await PurchasesSetup.logIn(appUserID: resetUid)
    return try parseLetterResponse(
      try await postLetter(
        text: text,
        language: language,
        timeZone: timeZone,
        requestId: requestId,
        forcesTokenRefresh: false
      )
    )
  }

  private static func postLetter(
    text: String,
    language: String,
    timeZone: String,
    requestId: String,
    forcesTokenRefresh: Bool
  ) async throws -> (statusCode: Int, data: Data) {
    // 起動時の匿名サインインが未完了・失敗していても、送信時に再確保して自己回復する。
    // その経路でも購入機能が使えるよう、RevenueCat の初期化も再試行する (どちらも冪等)
    let uid = try await FirebaseSetup.ensureAnonymousUser()
    PurchasesSetup.configure(appUserID: uid)
    guard let user = Auth.auth().currentUser else {
      throw APIError.unauthenticated
    }
    var request = URLRequest(url: baseURL.appending(path: "letters"))
    // Functions は LLM 呼び出しのため timeoutSeconds 300 で動く。クライアント既定 (60 秒) のままだと
    // 生成完了前に打ち切り、サーバー側だけ返書が保存され無料枠も消費される。
    // クライアント側の計測には接続・転送時間も含まれるため、サーバー期限 + 30 秒の余裕を持たせる
    request.timeoutInterval = 330
    request.httpMethod = "POST"
    request.setValue(
      "Bearer \(try await user.getIDToken(forcingRefresh: forcesTokenRefresh))",
      forHTTPHeaderField: "Authorization"
    )
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONEncoder().encode([
      "text": text, "language": language, "timeZone": timeZone, "requestId": requestId,
    ])

    let (data, response) = try await URLSession.shared.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse else {
      throw APIError.invalidResponse
    }
    return (httpResponse.statusCode, data)
  }

  private static func parseLetterResponse(_ response: (statusCode: Int, data: Data)) throws -> LetterResult {
    if response.statusCode == 429 {
      throw APIError.freeQuotaExceeded
    }
    if response.statusCode != 200 {
      throw APIError.http(statusCode: response.statusCode)
    }
    let envelope = try JSONDecoder().decode(LetterEnvelope.self, from: response.data)
    switch envelope.type {
    case "letter":
      if let letter = envelope.letter {
        return .letter(letter)
      }
      throw APIError.invalidResponse
    case "safety":
      return .safety
    default:
      throw APIError.invalidResponse
    }
  }
}

/// POST /letters のレスポンス形状
private struct LetterEnvelope: Codable {
  var type: String
  var letter: Letter?
}
