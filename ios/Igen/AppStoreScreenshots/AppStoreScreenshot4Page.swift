#if DEBUG
  import SwiftUI

  /// 4 枚目: 星図。出会った偉人が星座として灯る収集要素を、本番の星図本体 (AtlasPageBody) で見せる
  struct AppStoreScreenshot4Page: View {
    var body: some View {
      AppStoreScreenshotFrameLayout(
        title: "Great minds you meet\nbecome constellations",
        subtitle: "Your night sky grows with every letter"
      ) {
        AppStoreScreenshotMockScreen {
          VStack(spacing: 12) {
            Text("Your Star Atlas")
              .font(.igenSerif(size: 16, weight: .semibold))
              .tracking(4)
              .foregroundStyle(Color.igenGoldBright)
              .padding(.vertical, 8)

            Text("Great figures you've met through your letters light up as constellations in your night sky")
              .font(.system(size: 12))
              .multilineTextAlignment(.center)
              .foregroundStyle(Color.igenText.opacity(0.6))
              .padding(.horizontal, 24)

            AtlasPageBody(
              encounters: AppStoreScreenshotMockData.encounters,
              newlyMetPersonIds: [],
              onRevealFinished: { _ in }
            )
          }
        }
      }
    }
  }

  struct AppStoreScreenshot4Page_Previews: PreviewProvider {
    static var previews: some View {
      AppStoreScreenshot4Page()
        .environment(\.colorScheme, .dark)
    }
  }
#endif
