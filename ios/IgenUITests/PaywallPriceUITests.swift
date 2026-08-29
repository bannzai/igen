import XCTest

/// ペイウォールがストア価格を表示することを、実 RevenueCat (offerings) + StoreKit Configuration (Igen.storekit) で検証する。
/// Igen スキームの StoreKit Configuration により、商品は App Store ではなく Igen.storekit から解決される
/// (xcodebuild test / Xcode の Run にだけ反映される。simctl launch には渡せない)。
/// offerings の取得には RevenueCat の public API key (ios/Config.local.xcconfig) と、
/// 実 Firebase プロジェクトでの匿名認証 (IGEN_USE_PROD=1) が必要
final class PaywallPriceUITests: XCTestCase {
  /// Debug ビルドの既定は Firebase Emulator 向きのため、匿名認証と RevenueCat の初期化が通る実プロジェクトに向ける
  private func launchApp() -> XCUIApplication {
    let app = XCUIApplication()
    app.launchEnvironment["IGEN_USE_PROD"] = "1"
    // simulator の言語設定に依らず英語 UI の文言で要素を探す
    app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
    app.launch()
    return app
  }

  /// 画面を xcresult の添付として残す (PR の動作確認の軌跡用。
  /// `xcrun xcresulttool export attachments --path <xcresult> --output-path <dir>` で取り出せる)
  private func attachScreenshot(app: XCUIApplication, name: String) {
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }

  @MainActor
  func testPaywallShowsStorePrices() throws {
    let app = launchApp()

    let paywallLink = app.buttons["See the unlimited plan"]
    XCTAssertTrue(paywallLink.waitForExistence(timeout: 30))
    paywallLink.tap()

    // 価格は "<localizedPriceString> / month" の形で表示される。offering 未取得の間の仮価格 (verbatim "¥480 / 月") とは区別できる。
    // 匿名認証 → RevenueCat 初期化 → offerings 取得 → StoreKit の商品解決までを待つ
    let monthlyPrice = app.staticTexts["¥480 / month"]
    XCTAssertTrue(monthlyPrice.waitForExistence(timeout: 60), "月額の価格が StoreKit Configuration の定義どおりに表示されない")
    XCTAssertTrue(app.staticTexts["¥160 / 1 letter"].exists, "チケットの価格が StoreKit Configuration の定義どおりに表示されない")
    XCTAssertFalse(app.buttons["Prices could not be loaded. Tap to retry."].exists, "価格の取得に失敗している")

    attachScreenshot(app: app, name: "paywall-store-prices")
  }
}
