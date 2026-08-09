import FirebaseAnalytics
import SwiftUI

/// ホーム画面の入力カード。テキスト入力・音声入力ボタン・文字数カウンタを持つ
struct HomeInputCard: View {
  @Binding var draft: String
  @Binding var listening: Bool
  // 送信開始時に HomePage 側からキーボードを閉じられるようにする (待機オーバーレイより上に残るため)
  var draftIsFocused: FocusState<Bool>.Binding
  var onMicButtonPressed: () -> Void

  var body: some View {
    VStack(spacing: 8) {
      ZStack(alignment: .topLeading) {
        TextEditor(text: $draft)
          .focused(draftIsFocused)
          // 音声認識中の手入力は次の部分認識結果で失われるため、認識中は無効化する
          .disabled(listening)
          .scrollContentBackground(.hidden)
          .font(.system(size: 15))
          .lineSpacing(8)
          .foregroundStyle(Color(red: 236 / 255, green: 231 / 255, blue: 244 / 255))
          .frame(height: 140)
        if draft.isEmpty {
          // ja: 例: 最近、眠る前に考えごとが止まらない…
          Text("e.g. Lately, I can't stop thinking before I fall asleep…")
            .font(.system(size: 15))
            .foregroundStyle(Color(red: 236 / 255, green: 231 / 255, blue: 244 / 255).opacity(0.4))
            .padding(.vertical, 8)
            .padding(.horizontal, 5)
            .allowsHitTesting(false)
        }
      }

      HStack {
        Button {
          Analytics.logEvent("home_mic_button_pressed", parameters: nil)
          onMicButtonPressed()
        } label: {
          Image(systemName: listening ? "mic.fill" : "mic")
            .font(.system(size: 18))
            .foregroundStyle(Color(red: 232 / 255, green: 217 / 255, blue: 176 / 255))
            .frame(width: 44, height: 44)
            .background(Circle().stroke(Color(red: 232 / 255, green: 201 / 255, blue: 122 / 255).opacity(listening ? 0.9 : 0.32), lineWidth: 1))
        }
        if listening {
          // ja: 聞いています…
          Text("Listening…")
            .font(.system(size: 12))
            .foregroundStyle(Color(red: 232 / 255, green: 201 / 255, blue: 122 / 255))
        }
        Spacer()
        // 上限判定 (バックエンドの text.length) と同じ UTF-16 コード単位で表示する
        Text("\(draft.utf16.count)")
          .font(.system(size: 12))
          .foregroundStyle(Color(red: 236 / 255, green: 231 / 255, blue: 244 / 255).opacity(0.5))
      }
    }
    .padding(.vertical, 14)
    .padding(.horizontal, 16)
    .background(
      RoundedRectangle(cornerRadius: 18)
        .fill(Color(red: 16 / 255, green: 15 / 255, blue: 48 / 255).opacity(0.72))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 18)
        .stroke(Color(red: 232 / 255, green: 201 / 255, blue: 122 / 255).opacity(0.26), lineWidth: 1)
    )
  }
}

struct HomeInputCard_Previews: PreviewProvider {
  static var previews: some View {
    HomeInputCard(
      draft: .constant(""),
      listening: .constant(false),
      draftIsFocused: FocusState<Bool>().projectedValue,
      onMicButtonPressed: {}
    )
    .background(Color.black)
  }
}
