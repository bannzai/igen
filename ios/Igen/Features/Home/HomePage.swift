import FirebaseAnalytics
import OSLog
import SwiftUI

struct HomePage: View {
  @State var draft = ""
  @State var letter: Letter?
  @State var sending = false
  @State var listening = false
  @State var speechRecognizer = SpeechRecognizer()
  @State var sendErrorAlertIsPresented = false
  @State var paywallSheetIsPresented = false
  @State var speechPermissionAlertIsPresented = false
  @State var speechUnavailableAlertIsPresented = false
  @State var safetyNoticeIsPresented = false
  @State var archiveIsPresented = false
  @State var atlasIsPresented = false

  var body: some View {
    NavigationStack {
      ZStack {
        StarfieldBackground()

        VStack(spacing: 16) {
          HStack {
            // ja: 偉言
            Text("IGEN")
              .font(.system(size: 20, weight: .bold, design: .serif))
              .tracking(8)
              .foregroundStyle(Color(red: 245 / 255, green: 223 / 255, blue: 164 / 255))
              .shadow(color: Color(red: 232 / 255, green: 201 / 255, blue: 122 / 255).opacity(0.45), radius: 16)

            Spacer()

            Button {
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
            }

            Button {
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
            }
          }
          .padding(.vertical, 8)

          Spacer()

          // ja: きょうのできごと・お悩みを どうぞ
          Text("Tell me about your day, or what's on your mind")
            .font(.system(size: 22, weight: .semibold, design: .serif))
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
            onMicButtonPressed: {
              toggleListening()
            }
          )

          askButton

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

          Spacer()
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
        SafetyPage(language: Locale.autoupdatingCurrent.language.languageCode?.identifier == "ja" ? "ja" : "en")
      }
    }
  }

  private var askButton: some View {
    Button {
      Analytics.logEvent("home_ask_button_pressed", parameters: ["text_length": draft.count])
      speechRecognizer.stop()
      listening = false
      sending = true
      Task {
        await send()
        sending = false
      }
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
    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || sending)
    .opacity(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
  }

  private func toggleListening() {
    if listening {
      speechRecognizer.stop()
      listening = false
      return
    }
    listening = true
    Task {
      do {
        for try await transcript in try await speechRecognizer.start() {
          draft = transcript
        }
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
    do {
      let result = try await IgenAPI.requestLetter(
        text: draft,
        language: Locale.autoupdatingCurrent.language.languageCode?.identifier == "ja" ? "ja" : "en",
        timeZone: TimeZone.autoupdatingCurrent.identifier
      )
      switch result {
      case .letter(let letter):
        Analytics.logEvent("reply_generated", parameters: ["quote_id": letter.quoteId])
        draft = ""
        self.letter = letter
      case .safety:
        // 案内画面の表示イベントは SafetyPage 側で送る (相談本文は送らない)
        safetyNoticeIsPresented = true
      }
    } catch IgenAPI.APIError.freeQuotaExceeded {
      // 無料枠超過はペイウォールへ誘導する (チケット購入 or サブスク訴求)
      paywallSheetIsPresented = true
    } catch {
      sendErrorAlertIsPresented = true
    }
  }
}

struct HomePage_Previews: PreviewProvider {
  static var previews: some View {
    HomePage()
  }
}
