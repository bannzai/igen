#if DEBUG
  import SwiftUI

  /// App Store スクリーンショット撮影の入口。起動引数 `--isSnapshotUITest` のときに HomePage の代わりに表示し、
  /// 各スクショ画面の PreviewProvider を UITest がタップできるボタンとして並べる
  /// (撮影の流れは scripts/generate_screenshots/README.md)
  struct AppStoreScreenshotsRootPage: View {
    var body: some View {
      NavigationStack {
        ScrollView {
          VStack(alignment: .leading) {
            SnapshotUITest<AppStoreScreenshot1Page_Previews>()
            SnapshotUITest<AppStoreScreenshot2Page_Previews>()
            SnapshotUITest<AppStoreScreenshot3Page_Previews>()
            SnapshotUITest<AppStoreScreenshot4Page_Previews>()
            SnapshotUITest<AppStoreScreenshot5Page_Previews>()
            SnapshotUITest<AppStoreScreenshot6Page_Previews>()
          }
        }
      }
    }
  }

  /// PreviewProvider の各 Preview を `{PreviewType}_{index}` という accessibility label のボタンにし、
  /// UITest がタップすると NavigationLink でその Preview を全画面表示する
  struct SnapshotUITest<T: PreviewProvider>: View {
    var body: some View {
      VStack(alignment: .leading, spacing: 16) {
        Text(verbatim: "\(T.self)")
          .font(.title3)

        VStack(alignment: .leading) {
          ForEach(T._allPreviews.indices, id: \.self) { index in
            NavigationLink {
              T._allPreviews[index].content
                .navigationBarBackButtonHidden()
                .toolbar(.hidden, for: .navigationBar)
                .statusBarHidden()
            } label: {
              Text(verbatim: "\(T.self)_\(index)")
                .accessibilityLabel(Text(verbatim: "\(T.self)_\(index)"))
                .font(.body)
                .foregroundStyle(Color.accentColor)
            }
            .buttonStyle(.plain)
          }
          Divider()
        }
        .frame(maxWidth: .infinity)
      }
      .padding()
    }
  }
#endif
