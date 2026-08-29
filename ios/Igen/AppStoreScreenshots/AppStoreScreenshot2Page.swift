#if DEBUG
  import SwiftUI

  /// 2 枚目: ホーム。相談文を書き込んだ状態の入力カードで「書くだけ」の使い方を見せる
  struct AppStoreScreenshot2Page: View {
    var body: some View {
      AppStoreScreenshotFrameLayout(
        title: "Write about your day\nor what troubles you",
        subtitle: "A fitting great figure is chosen for what you wrote"
      ) {
        AppStoreScreenshotMockScreen {
          AppStoreScreenshotHomeScreen()
        }
      }
    }
  }

  /// ホーム画面の再現。本番の HomePage は Firebase と音声認識に依存するため、
  /// その部品 (HomeInputCard・HomeAskButton) と同じ文言・装飾で組む
  private struct AppStoreScreenshotHomeScreen: View {
    @FocusState var draftIsFocused: Bool

    var body: some View {
      let draft = AppStoreScreenshotMockData.homeDraft(language: appLanguage())
      VStack(spacing: 16) {
        HStack {
          Text("IGEN")
            .font(.igenSerif(size: 20, weight: .bold))
            .tracking(8)
            .foregroundStyle(Color.igenGoldBright)
            .shadow(color: Color.igenGold.opacity(0.45), radius: 16)
          Spacer()
          AppStoreScreenshotNavigationPill(label: "Star Atlas")
          AppStoreScreenshotNavigationPill(label: "Archive")
        }
        .padding(.vertical, 8)

        VStack(spacing: 16) {
          Text("Tell me about your day, or what's on your mind")
            .font(.igenSerif(size: 22, weight: .semibold))
            .multilineTextAlignment(.center)
            .lineSpacing(8)
            .foregroundStyle(Color.igenText)

          Text("Write it down, and a fitting great figure will send you a letter of reply with its source")
            .font(.system(size: 12))
            .multilineTextAlignment(.center)
            .foregroundStyle(Color.igenText.opacity(0.6))

          HomeInputCard(
            draft: .constant(draft),
            listening: .constant(false),
            draftIsFocused: $draftIsFocused,
            onMicButtonPressed: {}
          )

          HomeAskButton(draft: draft, sending: false) {}
        }
        .padding(.vertical, 24)

        Spacer()
      }
      .padding(.horizontal, 24)
    }
  }

  /// ホーム上部の「星図」「記録」ピル (HomePage と同じ装飾)
  private struct AppStoreScreenshotNavigationPill: View {
    var label: LocalizedStringResource

    var body: some View {
      Text(label)
        .font(.system(size: 11))
        .foregroundStyle(Color.igenTextGold)
        .padding(.vertical, 7)
        .padding(.horizontal, 13)
        .background(Capsule().fill(Color.igenCard.opacity(0.55)))
        .overlay(Capsule().stroke(Color.igenGold.opacity(0.32), lineWidth: 1))
    }
  }

  struct AppStoreScreenshot2Page_Previews: PreviewProvider {
    static var previews: some View {
      AppStoreScreenshot2Page()
        .environment(\.colorScheme, .dark)
    }
  }
#endif
