import FirebaseAnalytics
import LicenseList
import SwiftUI

/// アプリが利用している OSS のライセンス一覧。
/// 一覧は LicenseList (cybozu/LicenseList) のビルドツールプラグインが
/// SwiftPM の解決結果から生成するため、依存関係の増減にそのまま追従する
struct LicensesPage: View {
  @Environment(\.dismiss) var dismiss

  var body: some View {
    NavigationStack {
      LicenseListView()
        .licenseViewStyle(.withRepositoryAnchorLink)
        // ja: オープンソースライセンス
        .navigationTitle("Open Source Licenses")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .topBarTrailing) {
            Button {
              Analytics.logEvent("licenses_close_button_pressed", parameters: nil)
              dismiss()
            } label: {
              // ja: 閉じる
              Text("Close")
            }
          }
        }
    }
  }
}

struct LicensesPage_Previews: PreviewProvider {
  static var previews: some View {
    LicensesPage()
  }
}
