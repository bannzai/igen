import Foundation

/// 初回起動オンボーディングの 1 画面。表示文言・図版は View 側 (OnboardingPage) で switch する。
/// rawValue は Analytics のパラメータ値としてそのまま送る
enum OnboardingStep: String, CaseIterable {
  /// 世界観と価値の宣言 (偉人の登場演出)
  case welcome
  /// 書く → 偉人が現れる → 出典つきの返書、の 3 ステップ
  case howItWorks = "how_it_works"
  /// 出典つき・捏造なしという信頼の根拠 (英語モードのみ)
  case sources
  /// 相談するたび星図に偉人が増える (習慣化) と、最初の 1 通への誘導
  case atlas

  /// 表示言語ごとの画面構成。第一市場の日本語は短尺 (3 画面)、
  /// 英語は信頼の根拠を 1 画面足した長尺 (4 画面) にする (onboarding-design skill の US 長尺 / JP 短尺の方針)
  static func steps(language: String) -> [OnboardingStep] {
    if language == "ja" {
      return [.welcome, .howItWorks, .atlas]
    }
    return [.welcome, .howItWorks, .sources, .atlas]
  }
}
