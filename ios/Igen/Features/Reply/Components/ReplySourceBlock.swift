import SwiftUI

/// 出典ブロック。装飾ではなく「信頼の根拠」としての情報ブロック
/// (出典 / 原題 / 原文言語 / 成立の 2 カラム grid。design_handoff_igen/README.md「返書」9)
struct ReplySourceBlock: View {
  var quote: LetterQuote
  var language: String

  var body: some View {
    VStack(spacing: 0) {
      // ja: 出典
      Text("Source")
        .font(.system(size: 11, weight: .semibold))
        .tracking(3)
        .foregroundStyle(Color.igenGold)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.igenGold.opacity(0.12))

      Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
        GridRow {
          // ja: 出典
          Text("Work")
            .gridColumnAlignment(.leading)
            .font(.system(size: 11))
            .foregroundStyle(Color.igenText.opacity(0.5))
          Text(sourceWorkText)
            .font(.system(size: 13))
            .foregroundStyle(Color.igenText)
        }
        if let origTitle = quote.source.origTitle {
          GridRow {
            // ja: 原題
            Text("Original title")
              .font(.system(size: 11))
              .foregroundStyle(Color.igenText.opacity(0.5))
            Text(origTitle)
              .font(.igenOriginalText(size: 13, originalLanguage: quote.originalLanguage))
              .foregroundStyle(Color.igenText)
          }
        }
        GridRow {
          // ja: 原文言語
          Text("Language")
            .font(.system(size: 11))
            .foregroundStyle(Color.igenText.opacity(0.5))
          ReplyLanguageNameText(code: quote.originalLanguage)
            .font(.system(size: 13))
            .foregroundStyle(Color.igenText)
        }
        if let year = quote.source.year {
          GridRow {
            // ja: 成立
            Text("Written")
              .font(.system(size: 11))
              .foregroundStyle(Color.igenText.opacity(0.5))
            Text(year.localized(language))
              .font(.system(size: 13))
              .foregroundStyle(Color.igenText)
          }
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
  }

  /// 出典表記 (文献名 + 箇所)
  private var sourceWorkText: String {
    if let detail = quote.source.detail {
      return "\(quote.source.work.localized(language)) — \(detail.localized(language))"
    }
    return quote.source.work.localized(language)
  }
}

struct ReplySourceBlock_Previews: PreviewProvider {
  static var previews: some View {
    ReplySourceBlock(quote: ReplyPage_Previews.senecaLetter.quote, language: "ja")
      .padding()
      .background(Color.igenSheet)
  }
}
