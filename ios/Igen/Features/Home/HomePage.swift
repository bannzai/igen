import FirebaseAnalytics
import OSLog
import SwiftUI

struct HomePage: View {
  @State var draft = ""
  @State var letter: Letter?
  @State var sending = false
  @State var listening = false
  @State var listeningTask: Task<Void, Never>?
  @State var speechRecognizer = SpeechRecognizer()
  @State var sendErrorAlertIsPresented = false
  @State var paywallSheetIsPresented = false
  @State var speechPermissionAlertIsPresented = false
  @State var speechUnavailableAlertIsPresented = false
  @State var safetyNoticeIsPresented = false
  @State var archiveIsPresented = false
  @State var atlasIsPresented = false
  #if DEBUG
    @State var debugMenuIsPresented = false
  #endif
  // 初回起動のオンボーディングを表示済みか。既定の false は未インストール状態 (= 未表示) を表す
  @AppStorage("onboardingCompleted") var onboardingCompleted = false
  // キーボードは待機オーバーレイより上のウィンドウに表示されるため、送信開始時に明示的に閉じる
  @FocusState var draftIsFocused: Bool

  var body: some View {
    NavigationStack {
      ZStack {
        StarfieldBackground()

        VStack(spacing: 16) {
          HStack {
            // ja: 偉言
            Text("IGEN")
              .font(.igenSerif(size: 20, weight: .bold))
              .tracking(8)
              .foregroundStyle(Color(red: 245 / 255, green: 223 / 255, blue: 164 / 255))
              .shadow(color: Color(red: 232 / 255, green: 201 / 255, blue: 122 / 255).opacity(0.45), radius: 16)

            Spacer()

            #if DEBUG
              // 開発者メニューへの入口。DEBUG ビルド限定のためデザイン (余計なナビなし) の例外にする
              Button {
                debugMenuIsPresented = true
              } label: {
                Text(verbatim: "Dev")
                  .font(.system(size: 11))
                  .foregroundStyle(Color.igenTextGold)
                  .padding(.vertical, 7)
                  .padding(.horizontal, 13)
                  .background(Capsule().fill(Color.igenCard.opacity(0.55)))
                  .overlay(Capsule().stroke(Color.igenGold.opacity(0.32), lineWidth: 1))
                  .frame(minHeight: 44)
                  .contentShape(Rectangle())
              }
              .accessibilityIdentifier("debug_menu_button")
            #endif

            Button {
              Analytics.logEvent("home_atlas_button_pressed", parameters: nil)
              // 音声入力中・開始処理の suspend 中に遷移しても背後で録音が続かないよう、先に停止する
              listeningTask?.cancel()
              listeningTask = nil
              speechRecognizer.stop()
              listening = false
              atlasIsPresented = true
            } label: {
              // ja: 星図
              Text("Star Atlas")
                .font(.system(size: 11))
                .foregroundStyle(Color.igenTextGold)
                .padding(.vertical, 7)
                .padding(.horizontal, 13)
                .background(Capsule().fill(Color.igenCard.opacity(0.55)))
                .overlay(Capsule().stroke(Color.igenGold.opacity(0.32), lineWidth: 1))
                // 見た目のカプセルは保ちつつ、最小タップターゲット 44pt を確保する (design_handoff_igen/README.md)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }

            Button {
              Analytics.logEvent("home_archive_button_pressed", parameters: nil)
              // 音声入力中・開始処理の suspend 中に遷移しても背後で録音が続かないよう、先に停止する
              listeningTask?.cancel()
              listeningTask = nil
              speechRecognizer.stop()
              listening = false
              archiveIsPresented = true
            } label: {
              // ja: 記録
              Text("Archive")
                .font(.system(size: 11))
                .foregroundStyle(Color.igenTextGold)
                .padding(.vertical, 7)
                .padding(.horizontal, 13)
                .background(Capsule().fill(Color.igenCard.opacity(0.55)))
                .overlay(Capsule().stroke(Color.igenGold.opacity(0.32), lineWidth: 1))
                // 見た目のカプセルは保ちつつ、最小タップターゲット 44pt を確保する (design_handoff_igen/README.md)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
          }
          .padding(.vertical, 8)

          // キーボード表示時に入力カード・マイクが隠れないよう、中央ブロックはスクロール可能にする。
          // 通常時はデザイン指定どおり中央寄せになるよう、内容の最小高をビューポート高に合わせる
          GeometryReader { geometry in
            ScrollView {
              VStack(spacing: 16) {
                // ja: きょうのできごと・お悩みを どうぞ
                Text("Tell me about your day, or what's on your mind")
                  .font(.igenSerif(size: 22, weight: .semibold))
                  .multilineTextAlignment(.center)
                  .lineSpacing(8)
                  .foregroundStyle(Color(red: 236 / 255, green: 231 / 255, blue: 244 / 255))

                // ja: 書き終えたら、ふさわしい偉人が出典つきの返書を届けます
                Text("Write it down, and a fitting great figure will send you a letter of reply with its source")
                  .font(.system(size: 12))
                  .multilineTextAlignment(.center)
                  .foregroundStyle(Color(red: 236 / 255, green: 231 / 255, blue: 244 / 255).opacity(0.6))

                HomeInputCard(
                  draft: $draft,
                  listening: $listening,
                  draftIsFocused: $draftIsFocused,
                  onMicButtonPressed: {
                    toggleListening()
                  }
                )

                // 文字数はバックエンド (text.length = UTF-16 コード単位) と同じ単位で判定する
                if draft.utf16.count > IgenAPI.maxConcernChars {
                  // ja: 2,000字以内でお願いします（いま %lld 字）
                  Text("Please keep it within 2,000 characters (now \(draft.utf16.count))")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(red: 240 / 255, green: 160 / 255, blue: 160 / 255))
                }

                HomeAskButton(draft: draft, sending: sending) {
                  Analytics.logEvent("home_ask_button_pressed", parameters: ["text_length": draft.count])
                  // 音声入力の開始処理が suspend 中でも送信後に録音が始まらないよう、開始 Task ごとキャンセルする
                  listeningTask?.cancel()
                  listeningTask = nil
                  speechRecognizer.stop()
                  listening = false
                  // キーボードが待機オーバーレイに重なって残らないよう閉じる (issue #36)
                  draftIsFocused = false
                  sending = true
                  Task {
                    await send()
                    sending = false
                  }
                }

                Button {
                  Analytics.logEvent("home_paywall_link_pressed", parameters: nil)
                  paywallSheetIsPresented = true
                } label: {
                  // ja: 聞き放題プランをみる
                  Text("See the unlimited plan")
                    .font(.system(size: 11))
                    .underline()
                    .foregroundStyle(Color.igenText.opacity(0.6))
                }
              }
              .padding(.vertical, 24)
              .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }
            .scrollIndicators(.hidden)
          }
          // 待機文言と入力中の本文が重なって読めなくなるため、生成待ちの間は中央ブロックを隠す。
          // デザイン指定の待機画面 (スクリム + 待機文言を星空の上に重ねる) の再現でもある (design_handoff_igen/README.md「回答演出」)
          .opacity(sending ? 0 : 1)
        }
        .padding(.horizontal, 24)

        if sending {
          HomeWaitingOverlay()
        }
      }
      .navigationDestination(item: $letter) { letter in
        ReplyPage(letter: letter)
      }
      .navigationDestination(isPresented: $archiveIsPresented) {
        ArchivePage()
      }
      .navigationDestination(isPresented: $atlasIsPresented) {
        AtlasPage()
      }
      #if DEBUG
        .navigationDestination(isPresented: $debugMenuIsPresented) {
          DebugMenuPage()
        }
      #endif
      // 未表示の間だけ表示し、閉じられた (完了・スキップ) 時点で表示済みとして永続化する
      .fullScreenCover(
        isPresented: Binding(
          get: { !onboardingCompleted },
          set: { presented in
            if !presented {
              onboardingCompleted = true
            }
          }
        )
      ) {
        OnboardingPage()
      }
      // ja: 返書をお届けできませんでした しばらくしてからもう一度お試しください
      .alert("The letter could not be delivered. Please try again later.", isPresented: $sendErrorAlertIsPresented) {}
      .sheet(isPresented: $paywallSheetIsPresented) {
        PaywallPage()
      }
      // ja: マイクまたは音声認識が許可されていません 設定アプリから許可してください
      .alert("Microphone or speech recognition is not allowed. Please allow them in the Settings app.", isPresented: $speechPermissionAlertIsPresented) {}
      // ja: いま音声入力を開始できませんでした キーボードでの入力をお試しください
      .alert("Voice input could not be started. Please try typing instead.", isPresented: $speechUnavailableAlertIsPresented) {}
      .fullScreenCover(isPresented: $safetyNoticeIsPresented) {
        SafetyPage()
      }
    }
  }

  private func toggleListening() {
    if listening {
      // 権限確認などで開始処理が suspend している間の停止にも効くよう、開始 Task ごとキャンセルする
      listeningTask?.cancel()
      listeningTask = nil
      speechRecognizer.stop()
      listening = false
      return
    }
    listening = true
    // 部分認識結果は全文置き換えで届くため、開始時点の下書きを保持して認識結果を末尾に追記する。
    // 既存本文が空白・改行で終わっていなければ区切りを入れ、単語や文が結合しないようにする
    let baseDraft = draft
    let separator = baseDraft.last.map { $0.isWhitespace || $0.isNewline } == true ? "" : " "
    listeningTask = Task {
      do {
        let transcripts = try await speechRecognizer.start()
        if Task.isCancelled {
          // 開始処理の途中で停止された場合、開始してしまった録音を巻き戻す
          speechRecognizer.stop()
        } else {
          // 押下 (home_mic_button_pressed) と分けて、認識開始の成功を記録する (権限拒否・開始失敗の離脱率を出すため)
          Analytics.logEvent("home_mic_started", parameters: nil)
          for try await transcript in transcripts {
            draft = baseDraft.isEmpty ? transcript : baseDraft + separator + transcript
          }
        }
      } catch is CancellationError {
        // 停止操作によるキャンセルはエラーではない
      } catch SpeechRecognizer.SpeechError.notAuthorized {
        speechPermissionAlertIsPresented = true
      } catch {
        // シミュレータの音声認識アセット欠如など、許可以外の理由でも失敗しうる
        Logger(subsystem: "com.bannzai.Igen", category: "speech").error("speech input failed: \(error)")
        speechUnavailableAlertIsPresented = true
      }
      listening = false
    }
  }

  private func send() async {
    // 生成中 (数分かかりうる) にユーザーが編集した下書きを消さないよう、送信時点の本文を控える
    let sentText = draft
    do {
      let result = try await IgenAPI.requestLetter(
        text: sentText,
        language: appLanguage(),
        timeZone: TimeZone.autoupdatingCurrent.identifier
      )
      switch result {
      case .letter(let letter):
        Analytics.logEvent("reply_generated", parameters: ["quote_id": letter.quoteId])
        draft = Self.draftAfterSuccessfulRequest(currentDraft: draft, sentDraft: sentText)
        self.letter = letter
      case .safety:
        draft = Self.draftAfterSuccessfulRequest(currentDraft: draft, sentDraft: sentText)
        // 案内画面の表示イベントは SafetyPage 側で送る (相談本文は送らない)
        safetyNoticeIsPresented = true
      }
    } catch IgenAPI.APIError.freeQuotaExceeded {
      // 無料枠超過はペイウォールへ誘導する (チケット購入 or サブスク訴求)
      paywallSheetIsPresented = true
    } catch IgenAPI.APIError.rateLimited {
      // レート制限は時間経過でしか解除されないため、購入導線には流さず再試行を促す汎用エラー表示にする
      sendErrorAlertIsPresented = true
    } catch {
      // 実機での障害切り分け (通信断・HTTP エラー・デコード失敗の区別) をログでできるようにする。
      // エラーには相談本文が含まれないため public で記録する (既定の private では実機ログで読めない)
      Logger(subsystem: "com.bannzai.Igen", category: "api").error(
        "letter request failed: \(error, privacy: .public)"
      )
      sendErrorAlertIsPresented = true
    }
  }

  // 送信中に編集された下書きは残し、送信したままの本文だけをクリアする
  static func draftAfterSuccessfulRequest(currentDraft: String, sentDraft: String) -> String {
    currentDraft == sentDraft ? "" : currentDraft
  }
}

struct HomePage_Previews: PreviewProvider {
  static var previews: some View {
    HomePage()
  }
}
