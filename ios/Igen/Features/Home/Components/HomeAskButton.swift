import SwiftUI

/// 相談を送信する「偉人に聞く」ボタン。入力が空・文字数超過・送信中は押せない。
/// 常時アニメーション (グロー明滅) を含むため、パフォーマンスの例外規定 (.claude/rules/coding-rules.md) に該当する
struct HomeAskButton: View {
  var draft: String
  var sending: Bool
  // 送信フロー (Analytics・音声停止・API 呼び出し) は状態を持つ HomePage 側で完結させるため、押下だけを伝える
  var onPressed: () -> Void

  @State var glowPulsing = false
  @Environment(\.accessibilityReduceMotion) var reduceMotion

  var body: some View {
    let trimmedDraft = draft.trimmingCharacters(in: .whitespacesAndNewlines)
    Button {
      onPressed()
    } label: {
      // ja: 偉人に聞く
      Text("Ask the Greats")
        .font(.igenSerif(size: 17, weight: .bold))
        .tracking(4)
        .foregroundStyle(Color(red: 36 / 255, green: 22 / 255, blue: 80 / 255))
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(
          LinearGradient(
            colors: [
              Color(red: 232 / 255, green: 201 / 255, blue: 122 / 255),
              Color(red: 201 / 255, green: 162 / 255, blue: 77 / 255),
            ],
            startPoint: .top,
            endPoint: .bottom
          )
        )
        .clipShape(Capsule())
        // グロー明滅 (デザイン指定: box-shadow 18→34px, 4s ease-in-out infinite)
        .shadow(
          color: Color(red: 232 / 255, green: 201 / 255, blue: 122 / 255).opacity(0.4),
          radius: glowPulsing ? 34 : 18
        )
    }
    // 文字数はバックエンド (text.length = UTF-16 コード単位) と同じ単位で判定する
    .disabled(trimmedDraft.isEmpty || draft.utf16.count > IgenAPI.maxConcernChars || sending)
    .opacity(trimmedDraft.isEmpty || draft.utf16.count > IgenAPI.maxConcernChars ? 0.45 : 1)
    .onAppear {
      updateGlow()
    }
    // 表示中に「視差効果を減らす」設定が変わった場合も明滅の有無を追随させる
    .onChange(of: reduceMotion) { _, _ in
      updateGlow()
    }
  }

  /// グロー明滅の開始・停止。「視差効果を減らす」設定では静止させる
  private func updateGlow() {
    if reduceMotion {
      // 実行中の repeatForever を止め、固定の半径に戻す
      withAnimation(.linear(duration: 0)) {
        glowPulsing = false
      }
      return
    }
    // autoreverses は往路・復路それぞれに duration を使うため、往復 4 秒周期にするには片道 2 秒にする。
    // withAnimation でこの状態変化だけにアニメーションを閉じ、初回レイアウトを巻き込まない
    withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
      glowPulsing = true
    }
  }
}
