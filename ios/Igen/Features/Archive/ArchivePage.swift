import SwiftUI

/// 振り返り画面。日付ごとの相談一覧から「あの日の自分への返書」を再訪できる
struct ArchivePage: View {
  @State var letters: [Letter]?
  @State var loadFailed = false
  @State var selected: Letter?

  var body: some View {
    ZStack {
      StarfieldBackground()

      ScrollView {
        VStack(spacing: 12) {
          // ja: 返書の記録
          Text("Your Letters")
            .font(.system(size: 16, weight: .semibold, design: .serif))
            .tracking(4)
            .foregroundStyle(Color.igenGoldBright)
            .padding(.vertical, 8)

          if loadFailed {
            // ja: 記録を読み込めませんでした しばらくしてからもう一度お試しください
            Text("Your letters could not be loaded. Please try again later.")
              .font(.system(size: 13))
              .foregroundStyle(Color.igenText.opacity(0.7))
              .padding(.vertical, 32)
          } else if let letters {
            if letters.isEmpty {
              // ja: まだ返書がありません 今夜、最初のお便りをどうぞ
              Text("No letters yet. Write your first tonight.")
                .font(.system(size: 13))
                .foregroundStyle(Color.igenText.opacity(0.7))
                .padding(.vertical, 32)
            } else {
              ForEach(letters) { letter in
                Button {
                  selected = letter
                } label: {
                  ArchiveLetterCard(letter: letter)
                }
              }
              // ja: あの日の自分への返書を、いつでも読み返せます
              Text("You can revisit the letters to your past self anytime")
                .font(.system(size: 11))
                .foregroundStyle(Color.igenText.opacity(0.5))
                .padding(.vertical, 16)
            }
          } else {
            ProgressView()
              .tint(Color.igenGold)
              .padding(.vertical, 32)
          }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
      }
    }
    .task {
      do {
        letters = try await LettersStore.fetchLetters()
      } catch {
        loadFailed = true
      }
    }
    .navigationDestination(item: $selected) { letter in
      // 再訪では登場演出をスキップして返書をすぐ表示する
      ReplyPage(letter: letter, showsRitual: false)
    }
  }
}

struct ArchivePage_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ArchivePage(letters: [ReplyPage_Previews.senecaLetter])
    }
  }
}
