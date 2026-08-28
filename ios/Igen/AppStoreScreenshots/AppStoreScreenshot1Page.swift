#if DEBUG
  import SwiftUI

  /// 1 枚目: 返書 (セネカ)。「悩みを書くと偉人から返書が届く」という中核のベネフィットを、本番の返書本文でそのまま見せる
  struct AppStoreScreenshot1Page: View {
    var body: some View {
      AppStoreScreenshotFrameLayout(
        title: "Write a worry and\na great mind replies",
        subtitle: "Not a chat but one letter addressed to you"
      ) {
        AppStoreScreenshotMockScreen {
          ReplyLetterContent(
            letter: AppStoreScreenshotMockData.senecaLetter(language: appLanguage()),
            revealsBlocks: false
          )
        }
      }
    }
  }

  struct AppStoreScreenshot1Page_Previews: PreviewProvider {
    static var previews: some View {
      AppStoreScreenshot1Page()
        .environment(\.colorScheme, .dark)
    }
  }
#endif
