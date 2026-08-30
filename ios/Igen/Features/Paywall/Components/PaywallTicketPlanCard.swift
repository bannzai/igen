import RevenueCat
import SwiftUI

/// 相談チケット「ひとしずく」(consumable) のプランカード。
/// 価格は StoreKit のローカライズ済み価格をそのまま表示する。ストアが正を持つ値のため、
/// 取得できない時に代わりの金額を表示することはしない (#59。呼び出し側がカードごと出さない)
struct PaywallTicketPlanCard: View {
  /// 購入対象のチケットパッケージ。ローカライズ済み価格の表示にも使う
  var package: Package
  var purchasing: Bool
  var onPressed: () -> Void

  var body: some View {
    VStack(spacing: 8) {
      // ja: 相談チケット「ひとしずく」
      Text("Ticket — 'Hitoshizuku'")
        .font(.igenSerif(size: 15, weight: .semibold))
        .foregroundStyle(Color.igenText)

      // ja: %@ / 1通
      Text("\(package.storeProduct.localizedPriceString) / 1 letter")
        .font(.igenSerif(size: 18, weight: .semibold))
        .foregroundStyle(Color.igenGoldBright)

      // ja: 今夜だけ、もう一通。
      Text("Just one more letter, for tonight.")
        .font(.system(size: 12))
        .foregroundStyle(Color.igenText.opacity(0.7))

      Button {
        onPressed()
      } label: {
        // ja: チケットを買う
        Text("Buy a ticket")
          .font(.igenSerif(size: 15, weight: .semibold))
          .tracking(2)
          .foregroundStyle(Color.igenTextGold)
          .frame(maxWidth: .infinity)
          .frame(height: 44)
          .overlay(
            Capsule().stroke(Color.igenGold.opacity(0.6), lineWidth: 1)
          )
      }
      .disabled(purchasing)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 14)
    .padding(.horizontal, 16)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color.igenCard.opacity(0.55))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .stroke(Color.igenGold.opacity(0.25), lineWidth: 1)
    )
  }
}

struct PaywallTicketPlanCard_Previews: PreviewProvider {
  static var previews: some View {
    PaywallTicketPlanCard(
      // 実行時はストアが解決した Package を渡す。プレビューは描画の確認だけが目的のため、
      // RevenueCat がプレビュー・テスト用に用意している TestStoreProduct で組み立てる
      package: Package(
        identifier: "ticket_1",
        packageType: .custom,
        storeProduct: TestStoreProduct(
          localizedTitle: "Ticket",
          price: 160,
          currencyCode: "JPY",
          localizedPriceString: "¥160",
          productIdentifier: "igen_ticket1_160yen",
          productType: .consumable,
          localizedDescription: "",
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
