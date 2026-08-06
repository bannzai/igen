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

  /// API のベース URL。GoogleService-Info.plist が無い間は Functions エミュレータに向ける
  /// (FirebaseSetup の Emulator フォールバックと同じ判定。実プロジェクト作成後に本番 URL を設定する)
  static var baseURL: URL {
    if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
      return URL(string: "https://asia-northeast1-igen-prod.cloudfunctions.net/api")!
    }
    return URL(string: "http://127.0.0.1:5201/demo-igen/asia-northeast1/api")!
  }

  /// 相談本文を送り、返書または safety を受け取る。
  /// 401 (Keychain に残った無効なセッション等) は匿名ユーザーを作り直して 1 回だけリトライする
  static func requestLetter(text: String, language: String, timeZone: String) async throws -> LetterResult {
    let firstResponse = try await postLetter(text: text, language: language, timeZone: timeZone)
    if firstResponse.statusCode != 401 {
      return try parseLetterResponse(firstResponse)
    }
    _ = try await FirebaseSetup.resetAnonymousUser()
    return try parseLetterResponse(try await postLetter(text: text, language: language, timeZone: timeZone))
  }

  private static func postLetter(text: String, language: String, timeZone: String) async throws -> (statusCode: Int, data: Data) {
    guard let user = Auth.auth().currentUser else {
      throw APIError.unauthenticated
    }
    var request = URLRequest(url: baseURL.appending(path: "letters"))
    request.httpMethod = "POST"
    request.setValue("Bearer \(try await user.getIDToken())", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONEncoder().encode(["text": text, "language": language, "timeZone": timeZone])

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
