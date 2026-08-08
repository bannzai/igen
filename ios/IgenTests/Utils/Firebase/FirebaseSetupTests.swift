import Foundation
import Testing

@testable import Igen

struct FirebaseSetupTests {
  // GoogleService-Info.plist が無いビルドでは Emulator 用の demo-igen で初期化されることを検証する
  @Test
  func configuredWithDemoProjectWhenPlistIsAbsent() {
    FirebaseSetup.configure()
    #expect(FirebaseSetup.configuredProjectID == "demo-igen")
  }
}
