import FirebaseAnalytics
import Photos
import SwiftUI

/// 共有カードのプレビューとシェア導線。返書画面・振り返り詳細から開く
struct SharePage: View {
  var letter: Letter
  @Environment(\.displayScale) var displayScale
  @Environment(\.dismiss) var dismiss
  @State var cardImage: UIImage?
  @State var shareActivitySheetIsPresented = false
  @State var saveDoneAlertIsPresented = false
  @State var saveErrorAlertIsPresented = false

  var body: some View {
    ZStack {
      Color.igenSheet.opacity(0.97)
        .ignoresSafeArea()

      // 小さい画面 (iPhone SE 等) でも共有・保存ボタンまで到達できるようスクロール可能にする
      ScrollView {
        VStack(spacing: 16) {
          // デザイン指定の共有画面ヘッダー (もどる / タイトル)
          HStack {
            Button {
              Analytics.logEvent("share_back_button_pressed", parameters: nil)
              dismiss()
            } label: {
              // ja: もどる
              Text("Back")
                .font(.system(size: 12))
                .foregroundStyle(Color.igenText.opacity(0.8))
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(Capsule().fill(Color.igenCard.opacity(0.55)))
                .overlay(Capsule().stroke(Color.igenText.opacity(0.22), lineWidth: 1))
                // 見た目のカプセルは保ちつつ、最小タップターゲット 44pt を確保する
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            Spacer()
            // ja: 共有カード
            Text("Share Card")
              .font(.igenSerif(size: 15, weight: .semibold))
              .tracking(3)
              .foregroundStyle(Color.igenGoldBright)
            Spacer()
            // 左のもどるピルと釣り合いを取り、タイトルを中央に保つための余白
            Color.clear.frame(width: 58, height: 1)
          }
          .padding(.horizontal, 18)

          // プレビューと書き出し画像を同じ装飾で揃えるため、グロー付きの View を共有する
          ShareCardWithGlow(letter: letter)

          // ja: 悩みの本文はカードに含まれません
          Text("Your worry is not included in the card")
            .font(.system(size: 11))
            .foregroundStyle(Color.igenText.opacity(0.6))

          if let cardImage {
            Button {
              Analytics.logEvent("share_button_pressed", parameters: ["quote_id": letter.quoteId])
              shareActivitySheetIsPresented = true
            } label: {
              // ja: シェア
              Text("Share")
                .font(.igenSerif(size: 16, weight: .semibold))
                .tracking(3)
                .foregroundStyle(Color.igenButtonText)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                  LinearGradient(colors: [Color.igenGold, Color.igenGoldDark], startPoint: .top, endPoint: .bottom)
                )
                .clipShape(Capsule())
            }
            .padding(.horizontal, 32)

            // デザイン指定の独立した保存導線 (共有シートを経由せずフォトライブラリへ保存できる)
            Button {
              Analytics.logEvent("share_save_button_pressed", parameters: ["quote_id": letter.quoteId])
              Task {
                if await save(cardImage: cardImage) {
                  Analytics.logEvent("share_card_saved", parameters: ["quote_id": letter.quoteId])
                  saveDoneAlertIsPresented = true
                } else {
                  saveErrorAlertIsPresented = true
                }
              }
            } label: {
              // ja: 画像を保存
              Text("Save image")
                .font(.igenSerif(size: 15, weight: .semibold))
                .tracking(2)
                .foregroundStyle(Color.igenTextGold)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .overlay(
                  Capsule().stroke(Color.igenGold.opacity(0.6), lineWidth: 1)
                )
            }
            .padding(.horizontal, 32)
            .sheet(isPresented: $shareActivitySheetIsPresented) {
              // 共有先での完了・キャンセルを計測するため、completion を取得できる UIActivityViewController を使う
              // (ShareLink は完了結果を取得できない)
              ShareActivitySheet(cardImage: cardImage) { completed, activityType in
                if completed {
                  // 保存・コピーは SNS 共有ではないため別イベントで数え、共有完了率を過大にしない
                  if activityType == .saveToCameraRoll || activityType == .copyToPasteboard {
                    Analytics.logEvent("share_card_saved", parameters: ["quote_id": letter.quoteId])
                  } else {
                    Analytics.logEvent("share_completed", parameters: ["quote_id": letter.quoteId])
                  }
                }
              }
              .presentationDetents([.medium, .large])
            }
          } else {
            ProgressView()
              .tint(Color.igenGold)
          }
        }
        .padding(.vertical, 24)
      }
    }
    // ja: 共有カードを写真に保存しました
    .alert("The share card has been saved to your photos.", isPresented: $saveDoneAlertIsPresented) {}
    // ja: 保存できませんでした 設定アプリで写真への追加を許可してください
    .alert(
      "The card could not be saved. Please allow adding to Photos in the Settings app.",
      isPresented: $saveErrorAlertIsPresented
    ) {}
    .onAppear {
      // 相談本文は Analytics に送らない (.claude/rules/coding-rules-analytics.md)
      Analytics.logEvent("share_card_shown", parameters: ["quote_id": letter.quoteId])
      // 影を描くための余白ごとレンダリングして、共有・保存する画像にもグローを残す
      let renderer = ImageRenderer(content: ShareCardWithGlow(letter: letter).padding(24))
      renderer.scale = displayScale
      cardImage = renderer.uiImage
    }
  }

  /// カード画像をフォトライブラリへ保存し、成功したかを返す。
  /// Analytics・アラートなどの副作用は呼び出し元で処理する (.claude/rules/coding-rules-analytics.md)
  private func save(cardImage: UIImage) async -> Bool {
    if !(await PHPhotoLibrary.requestAuthorization(for: .addOnly)).allowsAddingAssets {
      return false
    }

    return await PhotoLibraryImageSaver().save(cardImage)
  }
}

struct SharePage_Previews: PreviewProvider {
  static var previews: some View {
    SharePage(letter: ReplyPage_Previews.senecaLetter)
  }
}
