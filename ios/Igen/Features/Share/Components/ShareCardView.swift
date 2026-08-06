import SwiftUI

/// 共有カード本体。星空 + 星座線アバター + 格言 + 出典の縦型カード。
/// **悩みの本文は含めない** (格言と偉人だけをシェアできる。documents/PROJECT.md「Shipaton 2026 戦略」Most Viral)。
/// ImageRenderer で画像化するため、アニメーションを含めない静的な描画にする
struct ShareCardView: View {
  var letter: Letter

  var body: some View {
    VStack(spacing: 12) {
      // ja: 偉言
      Text("IGEN")
        .font(.igenSerif(size: 12, weight: .bold))
        .tracking(6)
        .foregroundStyle(Color.igenGoldBright)

      ConstellationAvatar(constellation: ConstellationData.constellation(for: letter.personId))
        .frame(width: 100, height: 100)

      if let person = letter.person {
        Text(person.name.localized(letter.language))
          .font(.igenSerif(size: 13, weight: .semibold))
          .tracking(2)
          .foregroundStyle(Color.igenText)
      }

      Text(letter.quote.text.localized(letter.language))
        .font(.igenSerif(size: 15, weight: .semibold))
        .multilineTextAlignment(.center)
        .lineSpacing(7)
        .foregroundStyle(Color.igenGoldBright)

      if letter.quote.originalLanguage != letter.language {
        Text(letter.quote.original)
          .font(.igenOriginalText(size: 10))
          .multilineTextAlignment(.center)
          .foregroundStyle(Color.igenText.opacity(0.8))
      }

      VStack(spacing: 6) {
        Rectangle()
          .fill(Color.igenGold.opacity(0.25))
          .frame(height: 1)
        Text(verbatim: sourceLine)
          .font(.system(size: 9))
          .multilineTextAlignment(.center)
          .foregroundStyle(Color.igenText.opacity(0.6))
      }

      // ja: IGEN — 偉人からの返書
      Text("IGEN — Letters from the Greats")
        .font(.system(size: 8))
        .tracking(2)
        .foregroundStyle(Color.igenTextGold.opacity(0.8))
    }
    .padding(.vertical, 18)
    .padding(.horizontal, 16)
    .frame(width: 236)
    .background(cardBackground)
    .clipShape(RoundedRectangle(cornerRadius: 18))
    .overlay(
      RoundedRectangle(cornerRadius: 18)
        .stroke(Color.igenGold.opacity(0.5), lineWidth: 1)
    )
  }

  /// 出典行 (文献名 — 箇所 ・ 成立年)
  private var sourceLine: String {
    var line = letter.quote.source.work.localized(letter.language)
    if let detail = letter.quote.source.detail {
      line += " — \(detail.localized(letter.language))"
    }
    if let year = letter.quote.source.year {
      line += " ・ \(year)"
    }
    return line
  }

  private var cardBackground: some View {
    ZStack {
      LinearGradient(
        stops: [
          .init(color: Color(red: 7 / 255, green: 10 / 255, blue: 28 / 255), location: 0),
          .init(color: Color(red: 25 / 255, green: 18 / 255, blue: 67 / 255), location: 0.7),
          .init(color: Color(red: 35 / 255, green: 22 / 255, blue: 80 / 255), location: 1),
        ],
        startPoint: .top,
        endPoint: .bottom
      )
      // 静的な星屑 (座標はシード固定。ImageRenderer で描けるようアニメーションなし)
      Canvas { context, size in
        var seed: UInt64 = 0x51A4_CA4D
        func next() -> Double {
          seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
          return Double(seed >> 33) / Double(UInt64(1) << 31)
        }
        for _ in 0..<40 {
          let rect = CGRect(x: next() * size.width, y: next() * size.height, width: 1.2 + next() * 1.6, height: 1.2 + next() * 1.6)
          context.fill(
            Path(ellipseIn: rect),
            with: .color(Color.igenGoldBright.opacity(0.25 + next() * 0.5))
          )
        }
      }
    }
  }
}

struct ShareCardView_Previews: PreviewProvider {
  static var previews: some View {
    ShareCardView(letter: ReplyPage_Previews.senecaLetter)
      .padding()
      .background(Color.igenSheet)
  }
}
