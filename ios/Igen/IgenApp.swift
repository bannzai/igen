import SwiftUI

@main
struct IgenApp: App {
  var body: some Scene {
    WindowGroup {
      HomePage()
        // デザインはダークテーマ固定 (design_handoff_igen/README.md)。端末のライトモードでもステータスバーを暗色前提の表示に保つ
        .preferredColorScheme(.dark)
    }
  }
}
