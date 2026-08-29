import FirebaseAuth
import Foundation
import OSLog

/// 返書 API (backend/functions) のクライアント。
enum IgenAPI {
  /// 返書 API のエラー
  enum APIError: Error {
    /// 無料枠 (1 日 1 通) を使い切った (HTTP 429, code: free_quota_exceeded)
    case freeQuotaExceeded
    /// IP 単位のレート制限に達した (HTTP 429, code: rate_limited)。
    /// 購入では解除されないためペイウォールへは誘導しない
    case rateLimited
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
    // 通信断・タイムアウトで POST の結果が不明な場合、POST は再送せず読み取り専用の冪等照会 (GET) で
    // 保存済みの結果 (返書または safety) を回収する。再 POST はサーバー側で生成が進行中だと
    // 生成の重複実行・チケットの二重消費を起こしうるため、自動再試行では行わない
    let firstResponse: (statusCode: Int, data: Data)
    do {
      firstResponse = try await postLetter(
        text: text,
        language: language,
        timeZone: timeZone,
        requestId: requestId,
        forcesTokenRefresh: false
      )
    } catch let error as URLError {
      // 障害の発生点を実機ログで特定できるようにする (エラーコードのみで相談本文は含めない)
      Logger(subsystem: "com.bannzai.Igen", category: "api").error(
        "letter post failed (URLError \(error.code.rawValue, privacy: .public)), recovering via replay"
      )
      if let replayed = await replayLetter(requestId: requestId) {
        firstResponse = replayed
      } else {
        // 回収できなければ POST 時点の原因をエラー表示・ログに使う
        throw error
      }
    }
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

  /// POST の応答を受信できなかったとき、保存済みの結果 (返書または safety) を冪等照会 (GET /letters) で回収する。
  /// 実機 (モバイル回線) では応答の受信に失敗した直後はまだ回線が回復しておらず、
  /// サーバー側の生成も完了していないことがある (issue #36: サーバーは 200 を返したが
  /// クライアントにエラーが表示された) ため、待機を挟んで照会を繰り返す。
  /// 送信直後に切断された場合の生成完了も取りこぼさないよう、デッドラインはサーバーの
  /// 生成期限 (Functions の timeoutSeconds 300 秒) を包含する 300 秒にする。
  /// ネットワーク完全断でも失敗表示までは約 300 秒で、本修正前の実装の最悪値 (330 秒 × 2 回) より短い。
  /// 回収できなければ nil (呼び出し元が POST 時点のエラーを表示に使う)
  private static func replayLetter(requestId: String) async -> (statusCode: Int, data: Data)? {
    let clock = ContinuousClock()
    let replayDeadline = clock.now.advanced(by: .seconds(300))
    // 回線の瞬断は数秒で回復する想定でまず短い間隔で照会し、
    // 生成待ちが長引く場合はサーバー負荷を抑えるため間隔を 15 秒まで広げる
    var pollDelay: Duration = .seconds(2)
    while clock.now < replayDeadline {
      try? await Task.sleep(for: pollDelay)
      pollDelay = min(pollDelay * 2, .seconds(15))
      do {
        let response = try await getLetter(requestId: requestId)
        if response.statusCode == 200 {
          return response
        }
        // 404 (未保存) は生成が完了していない可能性があるため次の照会へ。その他のステータスも同様に扱う
        Logger(subsystem: "com.bannzai.Igen", category: "api").error(
          "letter replay poll returned status \(response.statusCode, privacy: .public)"
        )
      } catch {
        // 照会中の通信エラーは回線の回復を待って次の照会へ
        Logger(subsystem: "com.bannzai.Igen", category: "api").error(
          "letter replay poll failed: \(error, privacy: .public)"
        )
      }
    }
    return nil
  }

  /// requestId で保存済みの返書を照会する (GET /letters)。読み取り専用で利用枠を消費しない
  private static func getLetter(requestId: String) async throws -> (statusCode: Int, data: Data) {
    _ = try await FirebaseSetup.ensureAnonymousUser()
    guard let user = Auth.auth().currentUser else {
      throw APIError.unauthenticated
    }
    var components = URLComponents(
      url: baseURL.appending(path: "letters"),
      resolvingAgainstBaseURL: false
    )!
    components.queryItems = [URLQueryItem(name: "requestId", value: requestId)]
    var request = URLRequest(url: components.url!)
    // 照会は読み取りのみで即応するため、POST (330 秒) より大幅に短くする。
    // 照会全体の打ち切りは replayLetter のデッドライン (300 秒) が受け持つ
    request.timeoutInterval = 15
    request.setValue(
      "Bearer \(try await user.getIDToken())",
      forHTTPHeaderField: "Authorization"
    )
    if let appCheckToken = await FirebaseSetup.appCheckToken() {
      request.setValue(appCheckToken, forHTTPHeaderField: "X-Firebase-AppCheck")
    }
    let (data, response) = try await URLSession.shared.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse else {
      throw APIError.invalidResponse
    }
    return (httpResponse.statusCode, data)
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
    // ensureAnonymousUser が無効ユーザーを作り直した場合も RevenueCat を同じ UID へ揃える (UID 一致なら no-op)
    await PurchasesSetup.logIn(appUserID: uid)
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
    if let appCheckToken = await FirebaseSetup.appCheckToken() {
      request.setValue(appCheckToken, forHTTPHeaderField: "X-Firebase-AppCheck")
    }
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

  // private でないのは、レスポンス契約 (バックエンドの JSON 形状と Letter の Codable の整合) を
  // IgenTests から検証するため
  static func parseLetterResponse(_ response: (statusCode: Int, data: Data)) throws -> LetterResult {
    if response.statusCode == 429 {
      // 429 は無料枠切れとレート制限の 2 種類があり、ペイウォールへ誘導してよいのは前者だけ。
      // エラーコードを返さない古いサーバー応答でも従来どおりペイウォールへ誘導するよう、
      // デコードできない場合は freeQuotaExceeded に倒す
      if (try? JSONDecoder().decode(ErrorEnvelope.self, from: response.data))?.error.code
        == "rate_limited"
      {
        throw APIError.rateLimited
      }
      throw APIError.freeQuotaExceeded
    }
    if response.statusCode != 200 {
      throw APIError.http(statusCode: response.statusCode)
    }
    let decoder = JSONDecoder()
    // レスポンスの日時 (consultedAt) はミリ秒 epoch で届く (backend/functions/src/store.ts)
    decoder.dateDecodingStrategy = .millisecondsSince1970
    let envelope = try decoder.decode(LetterEnvelope.self, from: response.data)
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

/// エラー時のレスポンス形状 (backend/functions/src/app.ts の sendError)
private struct ErrorEnvelope: Codable {
  /// エラーの内容
  var error: ErrorBody

  /// エラーの種類と説明
  struct ErrorBody: Codable {
    /// エラーの種類を示すコード (free_quota_exceeded / rate_limited など)
    var code: String
    /// 開発者向けの説明。UI には表示しない
    var message: String
  }
}
