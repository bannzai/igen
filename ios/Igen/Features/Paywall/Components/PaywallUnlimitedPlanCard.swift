import RevenueCat
import SwiftUI

/// 聞き放題サブスク「星読み」のプランカード (featured。金枠 + グロー + いちばん人気バッジ)。
/// 価格は StoreKit のローカライズ済み価格をそのまま表示する。ストアが正を持つ値のため、
/// 取得できない時に代わりの金額を表示することはしない (#59。呼び出し側がカードごと出さない)
struct PaywallUnlimitedPlanCard: View {
  /// 購入対象の月額パッケージ。ローカライズ済み価格の表示にも使う
  var package: Package
  var purchasing: Bool
  var onPressed: () -> Void

  var body: some View {
    VStack(spacing: 10) {
      // ja: いちばん人気
      Text("Most popular")
        .font(.system(size: 10, weight: .semibold))
        .tracking(2)
        .foregroundStyle(Color.igenButtonText)
        .padding(.vertical, 4)
        .padding(.horizontal, 12)
        .background(Capsule().fill(Color.igenGold))

      // ja: 聞き放題「星読み」
      Text("Unlimited — 'Hoshiyomi'")
        .font(.igenSerif(size: 17, weight: .semibold))
        .foregroundStyle(Color.igenText)

      // ja: %@ / 月
      Text("\(package.storeProduct.localizedPriceString) / month")
        .font(.igenSerif(size: 22, weight: .semibold))
        .foregroundStyle(Color.igenGoldBright)

      VStack(alignment: .leading, spacing: 6) {
        // ja: 返書無制限
        Label("Unlimited letters", systemImage: "envelope.open")
        // ja: 1日1通の枠を気にせず、話したい夜に話せます
        Label("Talk on any night you need, without the once-a-day limit", systemImage: "sparkles")
      }
      .font(.system(size: 12))
      .foregroundStyle(Color.igenText.opacity(0.85))

      Button {
        onPressed()
      } label: {
        // ja: 星読みをはじめる
        Text("Start Hoshiyomi")
          .font(.igenSerif(size: 16, weight: .semibold))
          .tracking(2)
          .foregroundStyle(Color.igenButtonText)
          .frame(maxWidth: .infinity)
          .frame(height: 48)
          .background(
            LinearGradient(colors: [Color.igenGold, Color.igenGoldDark], startPoint: .top, endPoint: .bottom)
          )
          .clipShape(Capsule())
      }
      .disabled(purchasing)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 16)
    .padding(.horizontal, 16)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color.igenCard.opacity(0.7))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .stroke(Color.igenGold.opacity(0.6), lineWidth: 1.2)
    )
    .shadow(color: Color.igenGold.opacity(0.25), radius: 18)
  }
}

struct PaywallUnlimitedPlanCard_Previews: PreviewProvider {
  static var previews: some View {
    PaywallUnlimitedPlanCard(
      // 実行時はストアが解決した Package を渡す。プレビューは描画の確認だけが目的のため、
      // RevenueCat がプレビュー・テスト用に用意している TestStoreProduct で組み立てる
      package: Package(
        identifier: "$rc_monthly",
        packageType: .monthly,
        storeProduct: TestStoreProduct(
          localizedTitle: "Unlimited",
          price: 480,
          currencyCode: "JPY",
          localizedPriceString: "¥480",
          productIdentifier: "igen_unlimited_monthly_480yen",
          productType: .autoRenewableSubscription,
          localizedDescription: "",
          subscriptionPeriod: SubscriptionPeriod(value: 1, unit: .month),
          locale: Locale(identifier: "ja_JP")
        ).toStoreProduct(),
        offeringIdentifier: "default",
        webCheckoutUrl: nil
      ),
      purchasing: false,
      onPressed: {}
    )
    .padding()
    .background(Color.igenSheet)
  }
}
