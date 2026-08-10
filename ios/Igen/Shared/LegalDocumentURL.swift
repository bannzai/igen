import Foundation

/// 法務ドキュメント (docs/ 配下) の公開ページ URL。
/// GitHub Pages が docs/ の Markdown を「<ベース名>-<言語>.html」として公開する構成を前提とする
/// (Pages の有効化は issue #16。有効化されるまでリンク先は 404 になる)。
/// - Parameters:
///   - fileBaseName: docs/ 配下のファイル名から言語サフィックスを除いた部分 (例: "Terms")
///   - language: appLanguage() が返す表示言語。提供言語が ja / en の 2 つのため "ja" 以外は英語版に倒す
func legalDocumentURL(fileBaseName: String, language: String) -> URL {
  URL(string: "https://bannzai.github.io/igen/\(fileBaseName)-\(language == "ja" ? "ja" : "en").html")!
}
