import XCTest

/// App Store スクリーンショット 5 枚目 (AppStoreScreenshot5Page) を全言語で撮影する。
/// Attachment 名 `{クラス名}---{関数名}---{言語}---{index}` は scripts/generate_screenshots/organize_appstore_screenshots.sh が解析する
final class AppStoreScreenshot5PageSnapshotUITest: XCTestCase {
  override class var runsForEachTargetApplicationUIConfiguration: Bool {
    // 有効にするとテスト側で Locale が取れず全言語 en になるため無効にする
    false
  }

  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  // Preview の型名と個数は _allPreviews から取れない (protocol conformance descriptor が解決できない) ため固定で書く
  let previewType = "AppStoreScreenshot5Page_Previews"
  let previewCount = 1

  @MainActor
  func testSnapshot() throws {
    XCUIDevice.shared.appearance = .dark
    let fileName = URL(fileURLWithPath: #file).deletingPathExtension().lastPathComponent
    let functionName = #function.replacingOccurrences(of: "()", with: "")

    for (language, _) in filteredLanguages() {
      let app = XCUIApplication.instantiateForSnapshot()
      app.launchArguments += ["-AppleLanguages", "(\(language))"]
      app.launch()

      for index in 0..<previewCount {
        app.buttons["\(previewType)_\(index)"].firstMatch.tap()
        // 星空・グローのアニメーションと画面遷移が落ち着いてから撮る
        sleep(2)

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "\(fileName)---\(functionName)---\(language)---\(index)"
        attachment.lifetime = .keepAlways
        add(attachment)
      }
    }
  }
}
