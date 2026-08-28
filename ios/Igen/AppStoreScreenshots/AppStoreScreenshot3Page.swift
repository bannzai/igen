#if DEBUG
  import SwiftUI

  /// 3 枚目: 格言・原文・出典。返書の信頼の根拠となる部品 (対訳ブロック・出典ブロック) を拡大して見せる
  struct AppStoreScreenshot3Page: View {
    var body: some View {
      let letter = AppStoreScreenshotMockData.senecaLetter(language: appLanguage())
      AppStoreScreenshotFrameLayout(
        title: "Real sources\nfor every quote",
        subtitle: "Original text and source with every quote"
      ) {
        AppStoreScreenshotMockScreen {
          VStack(spacing: 24) {
            VStack(spacing: 8) {
              ConstellationAvatar(constellation: ConstellationData.constellation(for: letter.personId))
                .frame(width: 110, height: 110)
              if let person = letter.person {
                Text(person.name.localized(letter.language))
                  .font(.igenSerif(size: 20, weight: .semibold))
                  .tracking(3)
                  .foregroundStyle(Color.igenText)
              }
            }

            VStack(spacing: 12) {
              ReplyGoldHairline()
              Text(letter.quote.text.localized(letter.language))
                .font(.igenSerif(size: 24, weight: .semibold))
                .multilineTextAlignment(.center)
                .lineSpacing(12)
                .foregroundStyle(Color.igenGoldBright)
                .shadow(color: Color.igenGold.opacity(0.35), radius: 12)
              ReplyGoldHairline()
            }

            ReplyOriginalTextBlock(quote: letter.quote, language: letter.language)

            ReplySourceBlock(quote: letter.quote, language: letter.language)

            Spacer()
          }
          .padding(.horizontal, 24)
          .padding(.top, 16)
        }
      }
    }
  }

  struct AppStoreScreenshot3Page_Previews: PreviewProvider {
    static var previews: some View {
      AppStoreScreenshot3Page()
        .environment(\.colorScheme, .dark)
    }
  }
#endif
