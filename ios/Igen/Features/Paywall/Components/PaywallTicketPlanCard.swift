import RevenueCat
import SwiftUI

/// 相談チケット「ひとしずく」(consumable) のプランカード。
/// 価格は StoreKit のローカライズ済み価格だけを表示する。package を取得できない間は
/// 実際の請求額と異なる金額を見せないよう、価格の代わりに取得失敗を示して購入ボタンを無効にする
struct PaywallTicketPlanCard: View {
  /// 購入対象のチケットパッケージ。取得済みならローカライズ済み価格の表示にも使う
  var package: Package?
  /// package の取得中か。取得中は価格の代わりに読み込みを示し、取得失敗の表示を出さない
  var loading: Bool
  var purchasing: Bool
  var onPressed: () -> Void

  var body: some View {
    VStack(spacing: 8) {
      // ja: 相談チケット「ひとしずく」
      Text("Ticket — 'Hitoshizuku'")
        .font(.igenSerif(size: 15, weight: .semibold))
        .foregroundStyle(Color.igenText)

      if let priceString = package?.storeProduct.localizedPriceString {
        // ja: %@ / 1通
        Text("\(priceString) / 1 letter")
          .font(.igenSerif(size: 18, weight: .semibold))
          .foregroundStyle(Color.igenGoldBright)
      } else if loading {
        ProgressView()
          .controlSize(.small)
          .tint(Color.igenGoldBright)
      } else {
        // ja: 価格を取得できませんでした
        Text("Price unavailable")
          .font(.system(size: 13))
          .foregroundStyle(Color.igenText.opacity(0.6))
      }

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
          .opacity(package == nil ? 0.5 : 1)
      }
      .disabled(purchasing || package == nil)
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
    PaywallTicketPlanCard(package: nil, loading: false, purchasing: false, onPressed: {})
      .padding()
      .background(Color.igenSheet)
  }
}
