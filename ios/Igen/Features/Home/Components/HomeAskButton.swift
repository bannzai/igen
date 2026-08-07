import SwiftUI

/// 相談を送信する「偉人に聞く」ボタン。入力が空・文字数超過・送信中は押せない
struct HomeAskButton: View {
  var draft: String
  var sending: Bool
  // 送信フロー (Analytics・音声停止・API 呼び出し) は状態を持つ HomePage 側で完結させるため、押下だけを伝える
  var onPressed: () -> Void

  var body: some View {
    let trimmedDraft = draft.trimmingCharacters(in: .whitespacesAndNewlines)
    Button {
      onPressed()
    } label: {
      // ja: 偉人に聞く
      Text("Ask the Greats")
        .font(.system(size: 17, weight: .bold, design: .serif))
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
        .shadow(color: Color(red: 232 / 255, green: 201 / 255, blue: 122 / 255).opacity(0.4), radius: 18)
    }
    .disabled(trimmedDraft.isEmpty || draft.count > IgenAPI.maxConcernChars || sending)
    .opacity(trimmedDraft.isEmpty || draft.count > IgenAPI.maxConcernChars ? 0.45 : 1)
  }
}
