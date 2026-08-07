import FirebaseAnalytics
import FirebaseFirestore
import SwiftUI

/// 振り返り画面。日付ごとの相談一覧から「あの日の自分への返書」を再訪できる
struct ArchivePage: View {
  @State var letters: [Letter]?
  @State var nextCursor: DocumentSnapshot?
  @State var loadFailed = false
  @Environment(\.dismiss) var dismiss

  var body: some View {
    ZStack {
      StarfieldBackground()

      VStack(spacing: 0) {
        // スクロールしても消えない固定ヘッダー (design_handoff_igen プロトタイプの「返書の記録」画面)
        HStack {
          Button {
            Analytics.logEvent("archive_home_button_pressed", parameters: nil)
            dismiss()
          } label: {
            // ja: ホーム
            Text("Home")
              .font(.system(size: 12))
              .foregroundStyle(Color.igenText.opacity(0.8))
              .padding(.vertical, 6)
              .padding(.horizontal, 12)
              .background(Capsule().fill(Color.igenCard.opacity(0.55)))
              .overlay(Capsule().stroke(Color.igenText.opacity(0.22), lineWidth: 1))
              // 見た目のカプセルは保ちつつ、最小タップターゲット 44pt を確保する (design_handoff_igen/README.md)
              .frame(minHeight: 44)
              .contentShape(Rectangle())
          }
          Spacer()
          // ja: 返書の記録
          Text("Your Letters")
            .font(.igenSerif(size: 13, weight: .semibold))
            .tracking(4)
            .foregroundStyle(Color.igenGoldBright)
          Spacer()
          // 左のホームピルと釣り合いを取り、タイトルを中央に保つための余白
          Color.clear.frame(width: 58, height: 1)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 18)

        if loadFailed {
          // ja: 記録を読み込めませんでした しばらくしてからもう一度お試しください
          Text("Your letters could not be loaded. Please try again later.")
            .font(.system(size: 13))
            .foregroundStyle(Color.igenText.opacity(0.7))
            .padding(.vertical, 32)
          Spacer()
        } else if let letters {
          ArchivePageBody(letters: letters, hasMore: nextCursor != nil) {
            await loadMore()
          }
        } else {
          ProgressView()
            .tint(Color.igenGold)
            .padding(.vertical, 32)
          Spacer()
        }
      }
    }
    .toolbar(.hidden, for: .navigationBar)
    .task {
      do {
        let page = try await LettersStore.fetchLetters(cursor: nil)
        letters = page.letters
        nextCursor = page.cursor
        Analytics.logEvent("archive_loaded", parameters: ["letters_count": page.letters.count])
      } catch {
        loadFailed = true
      }
    }
  }

  private func loadMore() async {
    if nextCursor == nil {
      return
    }
    do {
      let page = try await LettersStore.fetchLetters(cursor: nextCursor)
      letters = (letters ?? []) + page.letters
      nextCursor = page.cursor
    } catch {
      // 追加取得の失敗で画面全体をエラーにしない (既に表示済みの一覧を保つ)。
      // 一時的な失敗に備えて少し待ってから 1 回だけ再試行する (スピナーが出たまま止まらないように)
      try? await Task.sleep(for: .seconds(2))
      if let page = try? await LettersStore.fetchLetters(cursor: nextCursor) {
        letters = (letters ?? []) + page.letters
        nextCursor = page.cursor
      }
    }
  }
}

/// 取得済みの返書一覧の表示 (空状態・カード一覧・追加読み込み・フッター文言)
private struct ArchivePageBody: View {
  var letters: [Letter]
  var hasMore: Bool
  // 追加取得は Firestore アクセスを持つ ArchivePage の責務のため、末尾到達の通知だけを返す
  var onReachEnd: () async -> Void

  @State var selected: Letter?

  var body: some View {
    ScrollView {
      // LazyVStack で末尾のスピナーが「実際に表示された」ときだけ構築されるようにし、
      // スクロールしていないのに全ページを連続取得しないようにする
      LazyVStack(spacing: 12) {
        if letters.isEmpty {
          // ja: まだ返書がありません 今夜、最初のお便りをどうぞ
          Text("No letters yet. Write your first tonight.")
            .font(.system(size: 13))
            .foregroundStyle(Color.igenText.opacity(0.7))
            .padding(.vertical, 32)
        } else {
          ForEach(letters) { letter in
            Button {
              Analytics.logEvent("archive_letter_button_pressed", parameters: nil)
              selected = letter
            } label: {
              ArchiveLetterCard(letter: letter)
            }
          }
          if hasMore {
            ProgressView()
              .tint(Color.igenGold)
              .padding(.vertical, 16)
              // 表示中にページが積まれた場合も letters.count の変化で task を再起動し、
              // スピナーが見えている限り次ページを取り続ける
              .task(id: letters.count) {
                await onReachEnd()
              }
          } else {
            // ja: あの日の自分への返書を、いつでも読み返せます
            Text("You can revisit the letters to your past self anytime")
              .font(.system(size: 11))
              .foregroundStyle(Color.igenText.opacity(0.5))
              .padding(.vertical, 16)
          }
        }
      }
      .padding(.horizontal, 24)
      .padding(.vertical, 12)
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
