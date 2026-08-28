#if DEBUG
  import SwiftUI

  /// 6 枚目: 共有カード。格言だけを載せた縦型カード (本番の ShareCardWithGlow) を拡大して見せる
  struct AppStoreScreenshot6Page: View {
    var body: some View {
      AppStoreScreenshotFrameLayout(
        title: "Share the quote\nas a card",
        subtitle: "Your worry is not included in the card"
      ) {
        AppStoreScreenshotMockScreen {
          VStack(spacing: 20) {
            Text("Share Card")
              .font(.igenSerif(size: 15, weight: .semibold))
              .tracking(3)
              .foregroundStyle(Color.igenGoldBright)
              .padding(.vertical, 8)

            Text("Your worry is not included in the card")
              .font(.system(size: 11))
              .foregroundStyle(Color.igenText.opacity(0.6))

            // カードは画面幅に合わせて拡大する (ShareCardView は共有画像と同じ固定幅のため)
            ShareCardWithGlow(letter: AppStoreScreenshotMockData.senecaLetter(language: appLanguage()))
              .scaleEffect(1.45, anchor: .top)

            Spacer()
          }
          .padding(.top, 8)
        }
      }
    }
  }

  struct AppStoreScreenshot6Page_Previews: PreviewProvider {
    static var previews: some View {
      AppStoreScreenshot6Page()
        .environment(\.colorScheme, .dark)
    }
  }
#endif
