import XCTest

final class ShareSaveImageUITests: XCTestCase {
  @MainActor
  func testSaveImageRequestsAddOnlyAuthorizationAndKeepsAppRunning() {
    let app = XCUIApplication()
    app.launchArguments += ["--isSnapshotUITest", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]

    addUIInterruptionMonitor(withDescription: "Photos add-only authorization") { alert in
      if alert.buttons["Allow"].exists {
        alert.buttons["Allow"].tap()
        return true
      }
      return false
    }

    app.launch()
    app.buttons["AppStoreScreenshot1Page_Previews_0"].tap()

    let shareButton = app.buttons["Share"]
    XCTAssertTrue(shareButton.waitForExistence(timeout: 5))
    shareButton.tap()

    let saveImageButton = app.buttons["Save image"]
    XCTAssertTrue(saveImageButton.waitForExistence(timeout: 5))
    saveImageButton.tap()
    app.tap()

    XCTAssertTrue(
      app.alerts["The share card has been saved to your photos."].waitForExistence(timeout: 5)
    )
    XCTAssertEqual(app.state, .runningForeground)
  }
}
