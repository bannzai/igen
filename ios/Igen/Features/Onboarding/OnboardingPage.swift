import FirebaseAnalytics
import SwiftUI

/// 初回起動時のオンボーディング。「書く → 偉人が現れる → 星図に増えていく」という体験の価値を
/// 最初の相談に入る前に短く伝え、最後は「最初の 1 通を書く」でホームの入力へ着地させる。
/// 表示済みフラグ (onboardingCompleted) の保存は、表示を司る HomePage 側の fullScreenCover の binding が行う
struct OnboardingPage: View {
  @Environment(\.dismiss) var dismiss
  @State var selectedStep: OnboardingStep = .welcome

  var body: some View {
    let steps = OnboardingStep.steps(language: appLanguage())
    ZStack {
      StarfieldBackground()

      VStack(spacing: 0) {
        HStack {
          Spacer()
          Button {
            Analytics.logEvent("onboarding_skip_button_pressed", parameters: ["step": selectedStep.rawValue])
            Analytics.logEvent("onboarding_completed", parameters: ["skipped": true])
            dismiss()
          } label: {
            // ja: スキップ
            Text("Skip")
              .font(.system(size: 13))
              .foregroundStyle(Color.igenText.opacity(0.6))
              .padding(.horizontal, 16)
              // 見た目はゴーストのまま、最小タップターゲット 44pt を確保する (design_handoff_igen/README.md)
              .frame(minHeight: 44)
              .contentShape(Rectangle())
          }
        }

        TabView(selection: $selectedStep) {
          ForEach(steps, id: \.self) { step in
            // 英語で文字量が増えても固定高さで切れないよう、各画面はスクロール可能にする。
            // 通常時は内容を上下中央に置くため、内容の最小高をビューポート高に合わせる (HomePage と同じ)
            GeometryReader { geometry in
              ScrollView {
                VStack {
                  switch step {
                  case .welcome:
                    OnboardingWelcomeStep()
                  case .howItWorks:
                    OnboardingHowItWorksStep()
                  case .sources:
                    OnboardingSourcesStep()
                  case .atlas:
                    OnboardingAtlasStep()
                  }
                }
                .frame(maxWidth: .infinity, minHeight: geometry.size.height)
              }
              .scrollIndicators(.hidden)
            }
            .tag(step)
          }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))

        OnboardingProgressDots(steps: steps, selectedStep: selectedStep)
          .padding(.vertical, 16)

        if selectedStep == steps.last {
          Button {
            Analytics.logEvent("onboarding_start_button_pressed", parameters: nil)
            Analytics.logEvent("onboarding_completed", parameters: ["skipped": false])
            dismiss()
          } label: {
            // ja: 最初の 1 通を書く
            Text("Write your first letter")
              .font(.igenSerif(size: 17, weight: .bold))
              .tracking(4)
              .foregroundStyle(Color.igenButtonText)
              .frame(maxWidth: .infinity)
              .frame(height: 52)
              .background(
                LinearGradient(
                  colors: [Color.igenGold, Color.igenGoldDark],
                  startPoint: .top,
                  endPoint: .bottom
                )
              )
              .clipShape(Capsule())
              .shadow(color: Color.igenGold.opacity(0.4), radius: 18)
          }
        } else {
          Button {
            Analytics.logEvent("onboarding_next_button_pressed", parameters: ["step": selectedStep.rawValue])
            if let index = steps.firstIndex(of: selectedStep), index + 1 < steps.count {
              withAnimation {
                selectedStep = steps[index + 1]
              }
            }
          } label: {
            // ja: つぎへ
            Text("Next")
              .font(.igenSerif(size: 17, weight: .bold))
              .tracking(4)
              .foregroundStyle(Color.igenButtonText)
              .frame(maxWidth: .infinity)
              .frame(height: 52)
              .background(
                LinearGradient(
                  colors: [Color.igenGold, Color.igenGoldDark],
                  startPoint: .top,
                  endPoint: .bottom
                )
              )
              .clipShape(Capsule())
          }
        }
      }
      .padding(.horizontal, 24)
      .padding(.bottom, 16)
    }
    .onAppear {
      Analytics.logEvent("onboarding_shown", parameters: nil)
    }
    // スワイプ・ボタンのどちらで進んでも、各画面の表示 (到達) を記録する
    .onChange(of: selectedStep, initial: true) { _, step in
      Analytics.logEvent(
        "onboarding_step_shown",
        parameters: ["step": step.rawValue, "index": steps.firstIndex(of: step) ?? 0]
      )
    }
  }
}

struct OnboardingPage_Previews: PreviewProvider {
  static var previews: some View {
    OnboardingPage()
  }
}
