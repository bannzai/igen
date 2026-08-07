import FirebaseAnalytics
import SwiftUI

/// 共有カードのプレビューとシェア導線。返書画面・振り返り詳細から開く
struct SharePage: View {
  var letter: Letter
  @Environment(\.displayScale) var displayScale
  @State var cardImage: UIImage?
  @State var shareActivitySheetIsPresented = false

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
          Button {
            Analytics.logEvent("share_button_pressed", parameters: ["quote_id": letter.quoteId])
            shareActivitySheetIsPresented = true
          } label: {
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
          .sheet(isPresented: $shareActivitySheetIsPresented) {
            // 共有先での完了・キャンセルを計測するため、completion を取得できる UIActivityViewController を使う
            // (ShareLink は完了結果を取得できない)
            ShareActivitySheet(cardImage: cardImage) { completed, activityType in
              if completed {
                // 保存・コピーは SNS 共有ではないため別イベントで数え、共有完了率を過大にしない
                if activityType == .saveToCameraRoll || activityType == .copyToPasteboard {
                  Analytics.logEvent("share_card_saved", parameters: ["quote_id": letter.quoteId])
                } else {
                  Analytics.logEvent("share_completed", parameters: ["quote_id": letter.quoteId])
                }
              }
            }
            .presentationDetents([.medium, .large])
          }
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
      cardImage = renderer.uiImage
    }
  }
}

struct SharePage_Previews: PreviewProvider {
  static var previews: some View {
    SharePage(letter: ReplyPage_Previews.senecaLetter)
  }
}
