#if DEBUG
  import SwiftUI

  /// 5 枚目: 振り返り。日付ごとの返書一覧を、取得済みデータを渡した本番の ArchivePage で見せる
  /// (letters を渡すと Firestore からの取得は走らない)
  struct AppStoreScreenshot5Page: View {
    var body: some View {
      AppStoreScreenshotFrameLayout(
        title: "Revisit the letters to\nyour past self anytime",
        subtitle: "Look back on the words you received day by day"
      ) {
        AppStoreScreenshotMockScreen {
          ArchivePage(letters: AppStoreScreenshotMockData.letters(language: appLanguage()))
        }
      }
    }
  }

  struct AppStoreScreenshot5Page_Previews: PreviewProvider {
    static var previews: some View {
      AppStoreScreenshot5Page()
        .environment(\.colorScheme, .dark)
    }
  }
#endif
