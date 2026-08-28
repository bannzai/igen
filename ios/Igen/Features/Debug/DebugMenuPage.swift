#if DEBUG
  import SwiftUI

  /// DEBUG ビルド限定の開発者メニュー。シミュレータでの動作確認・E2E テストで到達しにくい状態
  /// (オンボーディングの再表示など) をタップ操作だけで作る (~/.claude/rules/debug-menu-first-for-hard-to-reach-states.md)。
  /// 開発者だけが見る画面のため、文言はローカライズしない
  struct DebugMenuPage: View {
    @Environment(\.dismiss) var dismiss
    // false (未表示) にリセットするだけなので既定値は使われないが、@AppStorage の宣言上必要
    @AppStorage("onboardingCompleted") var onboardingCompleted = false

    var body: some View {
      List {
        Section {
          Button {
            onboardingCompleted = false
            // ホームに戻ると fullScreenCover の条件 (未表示) が成立してオンボーディングが再表示される
            dismiss()
          } label: {
            Text(verbatim: "Reset onboarding")
          }
          .accessibilityIdentifier("debug_reset_onboarding")
        } header: {
          Text(verbatim: "State reset")
            .textCase(nil)
        }
      }
      .navigationTitle(Text(verbatim: "Developer menu"))
      .navigationBarTitleDisplayMode(.inline)
    }
  }

  struct DebugMenuPage_Previews: PreviewProvider {
    static var previews: some View {
      NavigationStack {
        DebugMenuPage()
      }
    }
  }
#endif
