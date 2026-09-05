import XCTest

/// ペイウォールがストア価格を表示することを、実 RevenueCat (offerings) 経由で検証する。
/// offerings の取得には RevenueCat の public API key (ios/Config.local.xcconfig) と、
/// 実 Firebase プロジェクトでの匿名認証 (IGEN_USE_PROD=1) が必要。
/// 価格は StoreKit のローカライズ済み価格をそのまま出すため、通貨・金額は実行環境のストアフロントで
/// 変わる (CI の macOS Runner は US ストアフロント)。金額を固定で期待せず、表示の形だけを見る。
/// スキームには StoreKit Configuration (Igen.storekit) を設定しているが、iOS 26.5 の simulator では
/// StoreKit Testing が機能しない既知の問題があり (IgenTests/Purchases/StoreKitConfigurationTests.swift
/// が同じ理由で skip している)、CI では実ストアの価格が出る
final class PaywallPriceUITests: XCTestCase {
  /// Debug ビルドの既定は Firebase Emulator 向きのため、匿名認証と RevenueCat の初期化が通る実プロジェクトに向ける
  @MainActor
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
  @MainActor
  private func attachScreenshot(app: XCUIApplication, name: String) {
    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }

  /// 新規インストール直後はオンボーディングが全画面で出るため、ホームに到達するまで閉じる。
  /// 表示済み (onboardingCompleted) の端末では出ないので、出た時だけスキップする
  @MainActor
  private func dismissOnboardingIfNeeded(app: XCUIApplication) {
    let skip = app.buttons["Skip"]
    if skip.waitForExistence(timeout: 10) {
      skip.tap()
    }
  }

  @MainActor
  func testPaywallShowsStorePrices() throws {
    let app = launchApp()
    dismissOnboardingIfNeeded(app: app)

    let paywallLink = app.buttons["See the unlimited plan"]
    XCTAssertTrue(paywallLink.waitForExistence(timeout: 30))
    paywallLink.tap()

    // 匿名認証 → RevenueCat 初期化 → offerings 取得 → StoreKit の商品解決までを待つ。
    // 取得できない時は "Price unavailable" になるため、この形が出れば実価格を表示できている
    let monthlyPrice = app.staticTexts.matching(NSPredicate(format: "label ENDSWITH %@", " / month")).firstMatch
    XCTAssertTrue(monthlyPrice.waitForExistence(timeout: 60), "月額の価格がストア価格として表示されない")

    // 削除した仮価格が復活していないこと (#59)。ストアフロントに依らず、この文言は実価格になりえない
    XCTAssertFalse(app.staticTexts["¥480 / 月"].exists, "サブスクの仮価格が表示されている")
    XCTAssertFalse(app.staticTexts["¥160 / 1通"].exists, "チケットの仮価格が表示されている")

    // チケットの package は CI では解決できず "Price unavailable" と再試行導線が出るため
    // (#59 のうち未解決で残っている部分)、その 2 つの不在はアサーションにしない
    attachScreenshot(app: app, name: "paywall-store-prices")
  }
}
