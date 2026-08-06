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

  static var isConfigured: Bool {
    apiKey != ""
  }

  /// SDK を初期化する。API キー未設定なら何もしない (冪等)
  static func configure(appUserID: String) {
    if !isConfigured || Purchases.isConfigured {
      return
    }
    Purchases.configure(with: Configuration.Builder(withAPIKey: apiKey).with(appUserID: appUserID).build())
  }
}
