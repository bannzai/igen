import XCTest

/// App Store スクリーンショットの撮影手順。6 本の SnapshotUITest が共通で使う
extension XCTestCase {
  /// 全言語でアプリを起動し、previewType の各 Preview を開いて撮影する。
  /// 撮影の方法は環境変数 SNAPSHOT_INNER_SYNC_DIR の有無で変わる
  /// (スクリプト側で TEST_RUNNER_SNAPSHOT_INNER_SYNC_DIR を export すると、xcodebuild がテストランナーに渡す):
  /// - 無し: XCTAttachment で撮る。名前 `{クラス名}---{関数名}---{言語}---{index}` は scripts/generate_screenshots/organize_appstore_screenshots.sh が解析する
  /// - 有り: iPhone Duo の内側ディスプレイ用。XCTest の API では内側ディスプレイを仕様の寸法で撮れないため、
  ///   同ディレクトリに `{同じ名前}.ready` を書き、ホスト (scripts/generate_screenshots/generate_duo_screenshots.sh) が
  ///   `xcrun simctl io` で撮り終えて `.done` を書くのを待つ。撮影は行わない
  ///
  /// functionName の既定値は呼び出し元のテスト関数名 (スクリプトが `-only-testing` に渡すテストパスの末尾と揃える)
  @MainActor
  func captureAppStoreScreenshots(previewType: String, previewCount: Int, functionName: String = #function) throws {
    XCUIDevice.shared.appearance = .dark
    let className = String(describing: type(of: self))
    let functionName = functionName.replacingOccurrences(of: "()", with: "")

    for (language, _) in filteredLanguages() {
      let app = XCUIApplication.instantiateForSnapshot()
      app.launchArguments += ["-AppleLanguages", "(\(language))"]
      app.launch()

      for index in 0..<previewCount {
        app.buttons["\(previewType)_\(index)"].firstMatch.tap()
        // 星空・グローのアニメーションと画面遷移が落ち着いてから撮る
        sleep(2)

        let name = "\(className)---\(functionName)---\(language)---\(index)"
        if let syncDirectory = ProcessInfo.processInfo.environment["SNAPSHOT_INNER_SYNC_DIR"], !syncDirectory.isEmpty {
          try waitForHostCapture(syncDirectory: URL(fileURLWithPath: syncDirectory), name: name)
        } else {
          let attachment = XCTAttachment(screenshot: app.screenshot())
          attachment.name = name
          attachment.lifetime = .keepAlways
          add(attachment)
        }
      }
    }
  }

  /// ホストに撮影を依頼し (`{name}.ready` を書く)、撮り終わりの印 (`{name}.done`) を待つ
  private func waitForHostCapture(syncDirectory: URL, name: String) throws {
    try Data().write(to: syncDirectory.appendingPathComponent("\(name).ready"))
    let doneURL = syncDirectory.appendingPathComponent("\(name).done")
    // ホストの撮影 (simctl io と alpha の除去) は数秒で終わる。Mac の負荷が高い時に備えて余裕を持たせる
    let deadline = Date.now.addingTimeInterval(120)
    while !FileManager.default.fileExists(atPath: doneURL.path) {
      if Date.now > deadline {
        XCTFail("ホストの撮影完了 (\(doneURL.path)) を待ちましたが届きませんでした")
        return
      }
      sleep(1)
    }
  }
}
