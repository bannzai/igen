import Foundation
import RevenueCat

/// RevenueCat SDK の初期化。appUserID には Firebase 匿名認証の UID を使い、
/// 購入状態とサーバー側の相談履歴を同一 ID で紐付ける (ADR 0001)
enum PurchasesSetup {
  /// RevenueCat の Public API キー。RevenueCat プロジェクト作成 (#16 公開前チェックリスト) 後に設定する。
  /// 未設定の間、課金 UI は仮価格の表示のみで購入ボタンは準備中の案内を出す
  static let apiKey = ""

  /// 聞き放題サブスクの entitlement 識別子。backend/functions/src/entitlement.ts と揃える
  static let unlimitedEntitlementID = "unlimited"

  /// 相談チケット (consumable) のストア商品 id。backend/functions/src/entitlement.ts の TICKET_PRODUCT_ID と揃える
  static let ticketProductID = "igen_ticket_1"

  static var isConfigured: Bool {
    apiKey != ""
  }

  /// 課金 UI が SDK を使ってよい状態か (API キー設定済みかつ configure 完了)。
  /// キーがあっても匿名サインイン前は configure が終わっておらず、Purchases.shared が未初期化エラーになるため両方を見る
  static var isAvailable: Bool {
    isConfigured && Purchases.isConfigured
  }

  /// SDK を初期化する。API キー未設定なら何もしない (冪等)
  static func configure(appUserID: String) {
    if !isConfigured || Purchases.isConfigured {
      return
    }
    Purchases.configure(with: Configuration.Builder(withAPIKey: apiKey).with(appUserID: appUserID).build())
  }

  /// 匿名ユーザーの作り直しなどで Firebase UID が変わったとき、RevenueCat 側のユーザーも同じ UID へ切り替える。
  /// 切り替えないと購入が旧 UID に紐づき、サーバーの entitlement 照会 (新 UID) と食い違う
  static func logIn(appUserID: String) async {
    if !isAvailable || Purchases.shared.appUserID == appUserID {
      return
    }
    // 失敗しても購入フロー自体は SDK の次回同期で回復するため、throw はしない
    _ = try? await Purchases.shared.logIn(appUserID)
  }
}
