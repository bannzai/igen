import Foundation
import Testing

@testable import Igen

/// 法務ドキュメントの公開 URL が docs/ の公開構成 (GitHub Pages の「<ベース名>-<言語>.html」) と
/// 言語別に整合することを検証する
struct LegalDocumentURLTests {
  @Test
  func japaneseURL() {
    #expect(
      legalDocumentURL(fileBaseName: "Terms", language: "ja").absoluteString
        == "https://bannzai.github.io/igen/Terms-ja.html"
    )
  }

  @Test
  func englishURL() {
    #expect(
      legalDocumentURL(fileBaseName: "PrivacyPolicy", language: "en").absoluteString
        == "https://bannzai.github.io/igen/PrivacyPolicy-en.html"
    )
  }

  // 提供言語は ja / en の 2 つのため、それ以外の言語では英語版へ倒れることを検証する
  @Test
  func unsupportedLanguageFallsBackToEnglish() {
    #expect(
      legalDocumentURL(fileBaseName: "SpecifiedCommercialTransactionAct", language: "fr")
        .absoluteString
        == "https://bannzai.github.io/igen/SpecifiedCommercialTransactionAct-en.html"
    )
  }
}
