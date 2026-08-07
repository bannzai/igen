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

  /// ローカル開発で Emulator (demo-igen) を使うかどうか。
  /// GoogleService-Info.plist は常時バンドルされるため、plist の有無ではなく明示的に切り替える。
  /// Debug ビルドは既定で Emulator に向け、誤って実プロジェクトへ開発データを書いたり
  /// 実 LLM の費用を発生させたりしない。実プロジェクトで確認したいときは
  /// 環境変数 IGEN_USE_PROD=1 (simctl では SIMCTL_CHILD_IGEN_USE_PROD=1) を付けて起動する。
  /// Release ビルドは常に実プロジェクト
  static var usesEmulator: Bool {
    #if DEBUG
      return ProcessInfo.processInfo.environment["IGEN_USE_PROD"] != "1"
    #else
      return false
    #endif
  }

  /// Firebase を初期化する。既に初期化済みなら何もしない (冪等)
  static func configure() {
    if FirebaseApp.app() != nil {
      return
    }
    if usesEmulator {
      // Emulator (demo-igen) 向けのダミーオプションで初期化する
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
    } else {
      FirebaseApp.configure()
    }
  }

  /// 匿名 UID を確保する。既にサインイン済みならその UID を返す (冪等)
  static func ensureAnonymousUser() async throws -> String {
    if let user = Auth.auth().currentUser {
      return user.uid
    }
    let result = try await Auth.auth().signInAnonymously()
    return result.user.uid
  }

  /// サインアウトして新しい匿名ユーザーでサインインし直す。
  /// サーバーに認証を拒否された (無効なセッションが Keychain に残っている) 場合の回復に使う
  static func resetAnonymousUser() async throws -> String {
    try Auth.auth().signOut()
    return try await Auth.auth().signInAnonymously().user.uid
  }
}
