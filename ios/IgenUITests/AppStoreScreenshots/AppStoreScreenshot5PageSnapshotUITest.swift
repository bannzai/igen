import XCTest

/// App Store スクリーンショット 5 枚目 (AppStoreScreenshot5Page) を全言語で撮影する。
/// 撮影の手順と Attachment の命名は XCTestCase+AppStoreScreenshots.swift
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
    try captureAppStoreScreenshots(previewType: previewType, previewCount: previewCount)
  }
}
