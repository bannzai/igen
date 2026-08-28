import SwiftUI

/// オンボーディングの進捗ドット。現在の画面を金、それ以外を淡い点で示す
struct OnboardingProgressDots: View {
  var steps: [OnboardingStep]
  var selectedStep: OnboardingStep

  var body: some View {
    HStack(spacing: 8) {
      ForEach(steps, id: \.self) { step in
        Circle()
          .fill(step == selectedStep ? Color.igenGold : Color.igenText.opacity(0.25))
          .frame(width: 6, height: 6)
          .shadow(color: Color.igenGold.opacity(step == selectedStep ? 0.8 : 0), radius: 4)
      }
    }
  }
}

struct OnboardingProgressDots_Previews: PreviewProvider {
  static var previews: some View {
    OnboardingProgressDots(steps: OnboardingStep.steps(language: "en"), selectedStep: .howItWorks)
      .padding()
      .background(Color.igenSheet)
  }
}
