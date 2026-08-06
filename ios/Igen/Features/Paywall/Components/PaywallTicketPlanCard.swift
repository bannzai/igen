import SwiftUI

/// 相談チケット「ひとしずく」(consumable) のプランカード。
/// 価格はストア反映後に StoreKit の値へ差し替える (#16)。それまでは仮価格を表示する
struct PaywallTicketPlanCard: View {
  var purchasing: Bool
  var onPressed: () -> Void

  var body: some View {
    VStack(spacing: 8) {
      // ja: 相談チケット「ひとしずく」
      Text("Ticket — 'Hitoshizuku'")
        .font(.system(size: 15, weight: .semibold, design: .serif))
        .foregroundStyle(Color.igenText)

      Text(verbatim: "¥160 / 1通")
        .font(.system(size: 18, weight: .semibold, design: .serif))
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
          .font(.system(size: 15, weight: .semibold, design: .serif))
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
    PaywallTicketPlanCard(purchasing: false, onPressed: {})
      .padding()
      .background(Color.igenSheet)
  }
}
