import XCTest

final class IgenUITests: XCTestCase {
  // アプリがクラッシュせず起動することを検証する
  @MainActor
  func testLaunch() throws {
    let app = XCUIApplication()
    app.launch()
    XCTAssertEqual(app.state, .runningForeground)
  }
}
