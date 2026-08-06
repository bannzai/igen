import FirebaseAnalytics
import SwiftUI

/// 共有カードのプレビューとシェア導線。返書画面・振り返り詳細から開く
struct SharePage: View {
  var letter: Letter
  @Environment(\.displayScale) var displayScale
  @State var cardImage: Image?

  var body: some View {
    ZStack {
      Color.igenSheet.opacity(0.97)
        .ignoresSafeArea()

      VStack(spacing: 16) {
        // ja: 共有カード
        Text("Share Card")
          .font(.system(size: 15, weight: .semibold, design: .serif))
          .tracking(3)
          .foregroundStyle(Color.igenGoldBright)
          .padding(.vertical, 8)

        ShareCardView(letter: letter)
          .shadow(color: Color.igenGold.opacity(0.35), radius: 24)

        // ja: 悩みの本文はカードに含まれません
        Text("Your worry is not included in the card")
          .font(.system(size: 11))
          .foregroundStyle(Color.igenText.opacity(0.6))

        if let cardImage {
          ShareLink(
            item: cardImage,
            preview: SharePreview("IGEN", image: cardImage)
          ) {
            // ja: シェア
            Text("Share")
              .font(.system(size: 16, weight: .semibold, design: .serif))
              .tracking(3)
              .foregroundStyle(Color.igenButtonText)
              .frame(maxWidth: .infinity)
              .frame(height: 50)
              .background(
                LinearGradient(colors: [Color.igenGold, Color.igenGoldDark], startPoint: .top, endPoint: .bottom)
              )
              .clipShape(Capsule())
          }
          .padding(.horizontal, 32)
        } else {
          ProgressView()
            .tint(Color.igenGold)
        }
      }
      .padding(.vertical, 24)
    }
    .onAppear {
      // 相談本文は Analytics に送らない (.claude/rules/coding-rules-analytics.md)
      Analytics.logEvent("share_card_shown", parameters: ["quote_id": letter.quoteId])
      let renderer = ImageRenderer(content: ShareCardView(letter: letter))
      renderer.scale = displayScale
      if let uiImage = renderer.uiImage {
        cardImage = Image(uiImage: uiImage)
      }
    }
  }
}

struct SharePage_Previews: PreviewProvider {
  static var previews: some View {
    SharePage(letter: ReplyPage_Previews.senecaLetter)
  }
}
