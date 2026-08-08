import Foundation
import Testing

@testable import Igen

struct FirebaseSetupTests {
  // Debug ビルド (IGEN_USE_PROD なし) では Emulator 用の demo-igen で初期化されることを検証する
  @Test
  func configuredWithDemoProjectInDebugBuild() {
    FirebaseSetup.configure()
    #expect(FirebaseSetup.usesEmulator)
    #expect(FirebaseSetup.configuredProjectID == "demo-igen")
  }
}
