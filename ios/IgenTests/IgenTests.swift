import Foundation
import Testing

struct IgenTests {
  // テストホスト (Igen.app) 上でテストが実行されていることを検証する
  @Test
  func testHostIsIgenApp() {
    #expect(Bundle.main.bundleIdentifier == "com.bannzai.Igen")
  }
}
