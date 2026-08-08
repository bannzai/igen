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
      } else {
        // 人物のいない格言でも話者位置を空けない (デザイン指定の代替ラベル)
        // ja: ことわざ
        Text("Proverb")
          .font(.igenSerif(size: 13, weight: .semibold))
          .tracking(2)
          .foregroundStyle(Color.igenText)
      }

      Text(letter.quote.text.localized(letter.language))
        .font(.igenSerif(size: 15, weight: .semibold))
        .multilineTextAlignment(.center)
        .lineSpacing(7)
        .foregroundStyle(Color.igenGoldBright)

      // 原文は出典の信頼性の要件として、訳文との一致にかかわらず常に併記する (localization-guidelines.md)
      Text(letter.quote.original)
        .font(.igenOriginalText(size: 10, originalLanguage: letter.quote.originalLanguage))
        .multilineTextAlignment(.center)
        .foregroundStyle(Color.igenText.opacity(0.8))

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
    .background(ShareCardBackground())
    .clipShape(RoundedRectangle(cornerRadius: 18))
    .overlay(
      RoundedRectangle(cornerRadius: 18)
        .stroke(Color.igenGold.opacity(0.5), lineWidth: 1)
    )
    // カード内の UI 文言 (ロゴ・フッター) も返書の言語に固定し、端末ロケールと混在しないようにする。
    // ImageRenderer での画像化もこの View を描くため同じロケールが適用される
    .environment(\.locale, Locale(identifier: letter.language == "ja" ? "ja" : "en"))
  }

  /// 出典行 (文献名 — 箇所 ・ 成立年)
  private var sourceLine: String {
    var line = letter.quote.source.work.localized(letter.language)
    if let detail = letter.quote.source.detail {
      line += " — \(detail.localized(letter.language))"
    }
    if let year = letter.quote.source.year {
      line += " ・ \(year.localized(letter.language))"
    }
    return line
  }

}

struct ShareCardView_Previews: PreviewProvider {
  static var previews: some View {
    ShareCardView(letter: ReplyPage_Previews.senecaLetter)
      .padding()
      .background(Color.igenSheet)
  }
}
