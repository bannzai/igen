import SwiftUI

/// オンボーディング 3 画面目 (英語モードのみ)。「出典つき・捏造なし」を信頼の根拠として提示する。
/// 返書の出典ブロックと同じ様式で、セネカの書簡を例に作品名・原文言語・成立年代を見せる
struct OnboardingSourcesStep: View {
  var body: some View {
    VStack(spacing: 24) {
      // ja: すべてのことばに出典がある
      Text("Every word has a source")
        .font(.igenSerif(size: 22, weight: .semibold))
        .multilineTextAlignment(.center)
        .lineSpacing(8)
        .foregroundStyle(Color.igenText)
        .padding(.vertical, 16)

      // ja: つくられた名言はありません。返書には作品名・原文の言語・成立年代を添えます
      Text(
        "No invented quotes. Each letter tells you the work, the original language, and the era it comes from."
      )
      .font(.system(size: 14))
      .multilineTextAlignment(.center)
      .lineSpacing(9)
      .foregroundStyle(Color.igenText.opacity(0.7))

      VStack(spacing: 0) {
        // ja: 出典
        Text("Source")
          .font(.system(size: 11, weight: .semibold))
          .tracking(3)
          .foregroundStyle(Color.igenGold)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 8)
          .background(Color.igenGold.opacity(0.12))

        // 例示の出典 (セネカ『ルキリウスへの手紙』) は名言 DB と同じくデータとして扱い、ローカライズしない
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
          GridRow {
            // ja: 出典
            Text("Work")
              .gridColumnAlignment(.leading)
              .font(.system(size: 11))
              .foregroundStyle(Color.igenText.opacity(0.5))
            Text(verbatim: "Epistulae Morales ad Lucilium")
              .font(.igenOriginalText(size: 13, originalLanguage: "la"))
              .foregroundStyle(Color.igenText)
          }
          GridRow {
            // ja: 原文言語
            Text("Language")
              .font(.system(size: 11))
              .foregroundStyle(Color.igenText.opacity(0.5))
            ReplyLanguageNameText(code: "la")
              .font(.system(size: 13))
              .foregroundStyle(Color.igenText)
          }
          GridRow {
            // ja: 成立
            Text("Written")
              .font(.system(size: 11))
              .foregroundStyle(Color.igenText.opacity(0.5))
            Text(verbatim: "c. 65 AD")
              .font(.system(size: 13))
              .foregroundStyle(Color.igenText)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
      }
      .clipShape(RoundedRectangle(cornerRadius: 12))
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(Color.igenGold.opacity(0.35), lineWidth: 1)
      )

      // ja: 例: セネカからの返書の出典
      Text("Example: the source of a letter from Seneca")
        .font(.system(size: 11))
        .foregroundStyle(Color.igenText.opacity(0.45))
    }
    .padding(.vertical, 16)
  }
}

struct OnboardingSourcesStep_Previews: PreviewProvider {
  static var previews: some View {
    ZStack {
      StarfieldBackground()
      OnboardingSourcesStep()
        .padding(.horizontal, 24)
    }
  }
}
