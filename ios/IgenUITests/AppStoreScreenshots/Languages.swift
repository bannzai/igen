import Foundation

/// 撮影対象の言語。左が起動引数 -AppleLanguages に渡すコード、右が代表的なリージョン付きのコード
let languageCodeAndLanguageWithRegion = [
  ("ja", "ja-JP"),
  ("en", "en-US"),
]

/// 環境変数 SNAPSHOT_LANGUAGES (カンマ区切り) で撮影言語を絞る。
/// スクリプト側で TEST_RUNNER_SNAPSHOT_LANGUAGES を export すると、xcodebuild がテストランナーに SNAPSHOT_LANGUAGES として渡す。
/// 未設定なら全言語
func filteredLanguages() -> [(String, String)] {
  if let languagesEnv = ProcessInfo.processInfo.environment["SNAPSHOT_LANGUAGES"], !languagesEnv.isEmpty {
    let targetLanguages = languagesEnv.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
    return languageCodeAndLanguageWithRegion.filter { targetLanguages.contains($0.0) }
  }
  return languageCodeAndLanguageWithRegion
}
