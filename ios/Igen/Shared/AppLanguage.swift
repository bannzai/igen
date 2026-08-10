import Foundation

/// アプリが現在どちらの対応言語で表示されているか ("ja" / "en")。
/// 返書 API のリクエストや法務ドキュメントのリンク先など、UI 以外で言語の分岐が必要な箇所で使う。
/// Locale ではなく Bundle を使うのは、端末の言語リストとアプリ対応言語のマッチング結果
/// (実際に表示されている言語) と判定を一致させるため
func appLanguage() -> String {
  Bundle.main.preferredLocalizations.first == "ja" ? "ja" : "en"
}
