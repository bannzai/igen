import XCTest

extension XCUIApplication {
  /// App Store スクリーンショット撮影用にアプリを生成する。
  /// --isSnapshotUITest を付けると IgenApp が HomePage の代わりに AppStoreScreenshotsRootPage を表示する
  static func instantiateForSnapshot() -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments += ["--isSnapshotUITest"]
    return app
  }
}
