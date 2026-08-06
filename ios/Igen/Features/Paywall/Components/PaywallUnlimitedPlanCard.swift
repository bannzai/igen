import SwiftUI

/// 聞き放題サブスク「星読み」のプランカード (featured。金枠 + グロー + いちばん人気バッジ)。
/// 価格はストア反映後に StoreKit の値へ差し替える (#16)。それまでは仮価格を表示する
struct PaywallUnlimitedPlanCard: View {
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
        .font(.system(size: 17, weight: .semibold, design: .serif))
        .foregroundStyle(Color.igenText)

      Text(verbatim: "¥480 / 月")
        .font(.system(size: 22, weight: .semibold, design: .serif))
        .foregroundStyle(Color.igenGoldBright)
      // ja: 年払いは ¥3,800 (約34%お得)
      Text("Yearly: ¥3,800 (save about 34%)")
        .font(.system(size: 11))
        .foregroundStyle(Color.igenText.opacity(0.6))

      VStack(alignment: .leading, spacing: 6) {
        // ja: 返書無制限
        Label("Unlimited letters", systemImage: "envelope.open")
        // ja: 星図・記録の無制限保存 出会った偉人はあなたの夜空に残りつづけます
        Label("Unlimited star atlas & archive — every great figure you meet stays in your sky", systemImage: "sparkles")
        // ja: 新偉人の先行解放
        Label("Early access to new great figures", systemImage: "person.crop.circle.badge.plus")
      }
      .font(.system(size: 12))
      .foregroundStyle(Color.igenText.opacity(0.85))

      Button {
        onPressed()
      } label: {
        // ja: 星読みをはじめる
        Text("Start Hoshiyomi")
          .font(.system(size: 16, weight: .semibold, design: .serif))
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
    PaywallUnlimitedPlanCard(purchasing: false, onPressed: {})
      .padding()
      .background(Color.igenSheet)
  }
}
