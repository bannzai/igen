import Testing

@testable import Igen

/// オンボーディングの画面構成が表示言語ごとの方針 (日本語は短尺・英語は出典の画面を足した長尺) に
/// 一致することを検証する
struct OnboardingStepTests {
  @Test
  func japaneseIsShortWithoutSources() {
    #expect(OnboardingStep.steps(language: "ja") == [.welcome, .howItWorks, .atlas])
  }

  @Test
  func englishAddsSourcesStep() {
    #expect(OnboardingStep.steps(language: "en") == [.welcome, .howItWorks, .sources, .atlas])
  }

  // 対応言語は ja / en の 2 つのため、それ以外の言語は英語と同じ構成に倒れることを検証する
  @Test
  func unsupportedLanguageFallsBackToEnglish() {
    #expect(OnboardingStep.steps(language: "fr") == OnboardingStep.steps(language: "en"))
  }

  // どの言語でも、価値の宣言で始まり「最初の 1 通を書く」導線のある星図の画面で終わることを検証する
  @Test
  func everyLanguageStartsWithWelcomeAndEndsWithAtlas() {
    for language in ["ja", "en"] {
      #expect(OnboardingStep.steps(language: language).first == .welcome)
      #expect(OnboardingStep.steps(language: language).last == .atlas)
    }
  }

  // Analytics のパラメータ値としてそのまま送るため、rawValue が snake_case であることを検証する
  @Test
  func rawValuesAreSnakeCase() {
    for step in OnboardingStep.allCases {
      #expect(step.rawValue == step.rawValue.lowercased())
      #expect(!step.rawValue.contains(" "))
    }
  }
}
