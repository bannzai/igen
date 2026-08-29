import SwiftUI

/// オンボーディング最終画面。相談するたびに星図へ偉人が増えていく体験で、毎日の内省の継続を訴求する。
/// 出会い済みの星座 3 体と未出会いの暗い星のクラスタを縮小した星図で見せる (8BP #4, #7)
struct OnboardingAtlasStep: View {
  /// 縮小星図上の配置 (0–1)。星図画面 (AtlasPage) の雰囲気を 1 枚に圧縮した見本
  private static let metSlots: [(personId: String, x: Double, y: Double, scale: Double)] = [
    ("seneca", 0.2, 0.42, 1.0),
    ("confucius", 0.55, 0.22, 0.85),
    ("nietzsche", 0.82, 0.58, 0.9),
  ]
  private static let unmetSlots: [CGPoint] = [CGPoint(x: 0.42, y: 0.8), CGPoint(x: 0.7, y: 0.88)]

  var body: some View {
    VStack(spacing: 24) {
      // ja: 相談するたび夜空に偉人が増える
      Text("With every letter your night sky grows")
        .font(.igenSerif(size: 22, weight: .semibold))
        .multilineTextAlignment(.center)
        .lineSpacing(8)
        .foregroundStyle(Color.igenText)
        .padding(.vertical, 16)

      // 図版のため高さを固定する (文章ではないので折り返しの制約はかからない)
      GeometryReader { geometry in
        ForEach(Self.metSlots, id: \.personId) { slot in
          ConstellationAvatar(constellation: ConstellationData.constellation(for: slot.personId))
            .frame(width: 74 * slot.scale, height: 74 * slot.scale)
            .position(x: slot.x * geometry.size.width, y: slot.y * geometry.size.height)
        }
        ForEach(Self.unmetSlots, id: \.x) { slot in
          AtlasUnmetCluster()
            .position(x: slot.x * geometry.size.width, y: slot.y * geometry.size.height)
        }
      }
      .frame(height: 200)

      // ja: 1 日 1 通は無料。毎晩の小さな内省が、あなたの星図になっていきます
      Text("One free letter a day. Leave a small reflection each night, and watch your star atlas fill.")
        .font(.system(size: 14))
        .multilineTextAlignment(.center)
        .lineSpacing(9)
        .foregroundStyle(Color.igenText.opacity(0.7))
    }
    .padding(.vertical, 16)
  }
}

struct OnboardingAtlasStep_Previews: PreviewProvider {
  static var previews: some View {
    ZStack {
      StarfieldBackground()
      OnboardingAtlasStep()
        .padding(.horizontal, 24)
    }
  }
}
