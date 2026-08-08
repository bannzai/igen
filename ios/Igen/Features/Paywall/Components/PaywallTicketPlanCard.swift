import RevenueCat
import SwiftUI

/// 相談チケット「ひとしずく」(consumable) のプランカード。
/// 価格は StoreKit のローカライズ済み価格を表示し、offering 未取得 (SDK 未設定) の間は仮価格を表示する
struct PaywallTicketPlanCard: View {
  /// 購入対象のチケットパッケージ。取得済みならローカライズ済み価格の表示にも使う
  var package: Package?
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
      } else {
        // SDK 未設定の間の仮価格 (#16 でストア価格を設定したら package 側の表示になる)
        Text(verbatim: "¥160 / 1通")
          .font(.igenSerif(size: 18, weight: .semibold))
          .foregroundStyle(Color.igenGoldBright)
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
    PaywallTicketPlanCard(package: nil, purchasing: false, onPressed: {})
      .padding()
      .background(Color.igenSheet)
  }
}
