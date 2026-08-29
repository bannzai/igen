import StoreKit
import StoreKitTest
import XCTest

/// StoreKit Configuration file (Igen.storekit) の検証。
/// SKTestSession がテストバンドル内の .storekit を読み込むため、App Store Connect にも
/// ネットワークにも触れず、CLI (xcodebuild test) だけで
/// 「商品解決 → 購入 → entitlement 付与」まで確認できる。
/// simctl launch には StoreKit Configuration を渡す手段が無いため、CLI からの課金検証はこの経路を使う。
/// プロジェクトの既定は MainActor 分離だが、XCTestCase の初期化子は nonisolated なため
/// 継承した初期化子と分離が食い違う。テストケースは nonisolated で宣言する。
/// IgenTests は Swift Testing を使う規約だが、SKTestSession の検証は XCTest 前提の
/// 参照実装 (ios-storekit-testing skill の雛形) を踏襲するため XCTest で書いている
nonisolated final class StoreKitConfigurationTests: XCTestCase {
  private static let configurationFileName = "Igen"
  private static let ticketProductID = "igen_ticket1_160yen"
  private static let monthlyProductID = "igen_unlimited_monthly_480yen"
  private static let annualProductID = "igen_unlimited_annual_3800yen"

  /// iOS 26.5 の simulator では xcodebuild test 経由の StoreKit Testing が機能しない既知の問題があるため skip する。
  /// SKTestSession の init は成功するのに設定が適用されず、商品解決が実ストア (sandbox) に落ち、
  /// buyProduct は StoreKitError.notEntitled を投げる (iOS 26.5 で実測。iOS 26.2 では全項目 pass。
  /// Apple Developer Forums でも iOS 26.5 simulator の CI 利用で同様の報告あり)
  private func skipOnBrokenSimulatorRuntime() throws {
    let version = ProcessInfo.processInfo.operatingSystemVersion
    try XCTSkipIf(
      version.majorVersion == 26 && version.minorVersion == 5,
      "iOS 26.5 simulator では StoreKit Testing が StoreKitError.notEntitled で機能しない (iOS 26.2 以下の runtime で実行する)"
    )
  }

  private func makeSession() throws -> SKTestSession {
    let session = try SKTestSession(configurationFileNamed: Self.configurationFileName)
    session.resetToDefaultState()
    session.clearTransactions()
    session.disableDialogs = true
    return session
  }

  /// 相談チケットと聞き放題サブスクが .storekit の定義どおりの価格・期間で解決されること
  func testProductsResolveWithConfirmedPrices() async throws {
    try skipOnBrokenSimulatorRuntime()
    let session = try makeSession()
    // session が生存している間だけ .storekit の設定が効くため、テスト終了まで破棄させない
    defer { session.clearTransactions() }

    let products = try await Product.products(for: [
      Self.ticketProductID,
      Self.monthlyProductID,
      Self.annualProductID,
    ])
    let productsByID = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })

    XCTAssertEqual(productsByID.count, 3)
    XCTAssertEqual(productsByID[Self.ticketProductID]?.price, 160)
    XCTAssertEqual(productsByID[Self.monthlyProductID]?.price, 480)
    XCTAssertEqual(productsByID[Self.annualProductID]?.price, 3800)

    XCTAssertEqual(productsByID[Self.monthlyProductID]?.subscription?.subscriptionPeriod.unit, .month)
    XCTAssertEqual(productsByID[Self.annualProductID]?.subscription?.subscriptionPeriod.unit, .year)
    // 相談チケットは消耗型のため購読情報を持たない
    XCTAssertNil(productsByID[Self.ticketProductID]?.subscription)

    // 無料トライアルは設けていない (ASC / RevenueCat の登録内容と一致させている)
    XCTAssertNil(productsByID[Self.monthlyProductID]?.subscription?.introductoryOffer)
    XCTAssertNil(productsByID[Self.annualProductID]?.subscription?.introductoryOffer)
  }

  /// 聞き放題サブスク (月額) の購入で entitlement が付与されること
  func testBuyMonthlySubscriptionGrantsEntitlement() async throws {
    try skipOnBrokenSimulatorRuntime()
    let session = try makeSession()
    defer { session.clearTransactions() }

    _ = try await session.buyProduct(identifier: Self.monthlyProductID)

    var entitledProductIDs: Set<String> = []
    for await result in Transaction.currentEntitlements {
      if case .verified(let transaction) = result {
        entitledProductIDs.insert(transaction.productID)
      }
    }
    XCTAssertTrue(entitledProductIDs.contains(Self.monthlyProductID))
  }

  /// 相談チケット (消耗型) の購入がトランザクションとして成立すること。
  /// 消耗型は Transaction.currentEntitlements に現れないため、購入済みトランザクションの一覧で確認する
  func testBuyTicketRecordsConsumableTransaction() async throws {
    try skipOnBrokenSimulatorRuntime()
    let session = try makeSession()
    defer { session.clearTransactions() }

    _ = try await session.buyProduct(identifier: Self.ticketProductID)

    var purchasedProductIDs: Set<String> = []
    for await result in Transaction.all {
      if case .verified(let transaction) = result {
        purchasedProductIDs.insert(transaction.productID)
      }
    }
    XCTAssertTrue(purchasedProductIDs.contains(Self.ticketProductID))

    let ticketTransactions = session.allTransactions().filter {
      $0.productIdentifier == Self.ticketProductID
    }
    XCTAssertEqual(ticketTransactions.count, 1)
  }
}
