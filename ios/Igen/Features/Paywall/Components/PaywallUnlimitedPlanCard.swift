import RevenueCat
import SwiftUI

/// 聞き放題サブスク「星読み」のプランカード (featured。金枠 + グロー + いちばん人気バッジ)。
/// 価格は StoreKit のローカライズ済み価格を表示し、offering 未取得 (SDK 未設定) の間は仮価格を表示する
struct PaywallUnlimitedPlanCard: View {
  /// 購入対象の月額パッケージ。取得済みならローカライズ済み価格の表示にも使う
  var package: Package?
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

      if let priceString = package?.storeProduct.localizedPriceString {
        // ja: %@ / 月
        Text("\(priceString) / month")
          .font(.igenSerif(size: 22, weight: .semibold))
          .foregroundStyle(Color.igenGoldBright)
      } else {
        // SDK 未設定の間の仮価格 (#16 でストア価格を設定したら package 側の表示になる)
        Text(verbatim: "¥480 / 月")
          .font(.igenSerif(size: 22, weight: .semibold))
          .foregroundStyle(Color.igenGoldBright)
      }

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
    PaywallUnlimitedPlanCard(package: nil, purchasing: false, onPressed: {})
      .padding()
      .background(Color.igenSheet)
  }
}
