import OSLog
import SwiftUI

@main
struct IgenApp: App {
  init() {
    FirebaseSetup.configure()
  }

  var body: some Scene {
    WindowGroup {
      HomePage()
        .task {
          do {
            let uid = try await FirebaseSetup.ensureAnonymousUser()
            Logger(subsystem: "com.bannzai.Igen", category: "auth").info("anonymous sign-in ok: uid=\(uid)")
          } catch {
            // サインイン失敗 (Auth エミュレータ未起動など) でアプリを止めない。次回起動時に再試行される
            Logger(subsystem: "com.bannzai.Igen", category: "auth").error("anonymous sign-in failed: \(error)")
          }
        }
        // デザインはダークテーマ固定 (design_handoff_igen/README.md)。端末のライトモードでもステータスバーを暗色前提の表示に保つ
        .preferredColorScheme(.dark)
    }
  }
}
