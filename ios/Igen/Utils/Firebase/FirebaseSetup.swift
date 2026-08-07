import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import Foundation

/// Firebase の初期化と匿名認証を担う。
/// 実プロジェクトの GoogleService-Info.plist がバンドルされていればそれで初期化し、
/// 無ければ Emulator (demo-igen) 向けのオプションで初期化して Auth エミュレータに接続する。
enum FirebaseSetup {
  /// Auth エミュレータのポート。backend/firebase.json の emulators.auth.port と揃える
  static let authEmulatorPort = 9299

  /// Firestore エミュレータのポート。backend/firebase.json の emulators.firestore.port と揃える
  static let firestoreEmulatorPort = 8282

  /// テストから Firebase の初期化結果 (どのプロジェクトで初期化されたか) を観測するためのプロパティ
  static var configuredProjectID: String? {
    FirebaseApp.app()?.options.projectID
  }

  /// Firebase を初期化する。既に初期化済みなら何もしない (冪等)
  static func configure() {
    if FirebaseApp.app() != nil {
      return
    }
    if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
      FirebaseApp.configure()
    } else {
      // Firebase 実プロジェクトの作成はオーナー承認が必要なため、承認までは
      // Emulator (demo-igen) 向けのダミーオプションで初期化する (issue #4)
      let options = FirebaseOptions(
        googleAppID: "1:000000000000:ios:0000000000000000",
        gcmSenderID: "000000000000"
      )
      options.projectID = "demo-igen"
      // FirebaseInstallations が API キーの形式 (39 文字・A 始まり) を起動時に検証するため、
      // 形式だけ満たすダミー値にする (Emulator は値を検証しない)
      options.apiKey = "AIzaSyDemoKey00000000000000000000000000"
      FirebaseApp.configure(options: options)
      Auth.auth().useEmulator(withHost: "127.0.0.1", port: authEmulatorPort)
      // useEmulator だけでは SSL が無効にならず接続に失敗するため、settings で明示的に無効化する
      let settings = Firestore.firestore().settings
      settings.host = "127.0.0.1:\(firestoreEmulatorPort)"
      settings.isSSLEnabled = false
      Firestore.firestore().settings = settings
    }
  }

  /// 保存済みユーザーがサーバー側に存在しない・無効化されたことを示す Auth エラーコード
  private static let invalidUserErrorCodes: Set<AuthErrorCode> = [
    .userNotFound, .invalidUserToken, .userTokenExpired, .userDisabled,
  ]

  /// 進行中の匿名サインイン。起動時 (.task) と送信時の同時呼び出しが別々の UID を作らないよう直列化する
  @MainActor private static var signInTask: Task<String, Error>?

  /// 匿名 UID を確保する。既にサインイン済みならトークンを強制更新して有効性を検証したうえで返す (冪等)
  @MainActor
  static func ensureAnonymousUser() async throws -> String {
    if let signInTask {
      return try await signInTask.value
    }
    if let user = Auth.auth().currentUser {
      do {
        // Auth エミュレータの再起動やユーザー削除でサーバー側から消えた保存済みユーザーを検出する
        _ = try await user.getIDToken(forcingRefresh: true)
        return user.uid
      } catch let error as NSError
        where invalidUserErrorCodes.contains(AuthErrorCode(rawValue: error.code) ?? .internalError)
      {
        // サーバーに存在しないユーザーはサインアウトし、下の signInAnonymously で作り直す
        try Auth.auth().signOut()
      } catch {
        // ネットワーク断などユーザー無効以外の失敗では、新規 UID を発行して履歴を失わないよう既存 UID を維持する
        return user.uid
      }
    }
    let task = Task {
      try await Auth.auth().signInAnonymously().user.uid
    }
    signInTask = task
    defer { signInTask = nil }
    return try await task.value
  }

  /// サインアウトして新しい匿名ユーザーでサインインし直す。
  /// サーバーに認証を拒否された (無効なセッションが Keychain に残っている) 場合の回復に使う
  static func resetAnonymousUser() async throws -> String {
    try Auth.auth().signOut()
    return try await Auth.auth().signInAnonymously().user.uid
  }
}
