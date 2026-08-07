import SwiftUI

/// 原文と訳文の対訳ブロック。外国語由来の格言のみ表示する (原文は改変せず併記。PROJECT.md UI 要望 6)
struct ReplyOriginalTextBlock: View {
  var quote: LetterQuote
  var language: String

  var body: some View {
    VStack(spacing: 10) {
      VStack(spacing: 6) {
        HStack(spacing: 4) {
          // ja: 原文
          Text("Original")
          Text(verbatim: "(")
          ReplyLanguageNameText(code: quote.originalLanguage)
          Text(verbatim: ")")
        }
        .font(.system(size: 10, weight: .semibold))
        .tracking(2)
        .foregroundStyle(Color.igenGold)
        Text(quote.original)
          .font(.igenOriginalText(size: 15, originalLanguage: quote.originalLanguage))
          .multilineTextAlignment(.center)
          .lineSpacing(6)
          .foregroundStyle(Color.igenText)
      }

      Rectangle()
        .fill(Color.igenText.opacity(0.16))
        .frame(height: 1)

      VStack(spacing: 6) {
        // ja: 日本語訳
        Text("Translation")
          .font(.system(size: 10, weight: .semibold))
          .tracking(2)
          .foregroundStyle(Color.igenGold)
        Text(quote.text.localized(language))
          .font(.system(size: 13))
          .multilineTextAlignment(.center)
          .lineSpacing(6)
          .foregroundStyle(Color.igenText.opacity(0.9))
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 14)
    .padding(.horizontal, 16)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color.igenBilingual.opacity(0.65))
    )
  }

}

struct ReplyOriginalTextBlock_Previews: PreviewProvider {
  static var previews: some View {
    ReplyOriginalTextBlock(quote: ReplyPage_Previews.senecaLetter.quote, language: "ja")
      .padding()
      .background(Color.igenSheet)
  }
}
