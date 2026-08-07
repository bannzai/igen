import Foundation

/// ロケールごとのテキスト。名言 DB・返書のフィールドで使う (documents/design/db-schema.md)
struct LocalizedText: Codable, Hashable {
  var ja: String
  var en: String

  /// 返書の言語 ("ja" / "en") に応じた訳文を返す
  func localized(_ language: String) -> String {
    language == "ja" ? ja : en
  }
}

/// 返書に埋め込まれる格言のスナップショット。本文・原文・出典の出どころは常に名言 DB (ADR 0002)
struct LetterQuote: Codable, Hashable {
  var kind: String
  var text: LocalizedText
  var original: String
  var originalLanguage: String
  var source: LetterQuoteSource
}

/// 格言の出典 (文献名・箇所・原題・成立年)。信頼の根拠として返書に必ず表示する
struct LetterQuoteSource: Codable, Hashable {
  var work: LocalizedText
  var detail: LocalizedText?
  var origTitle: String?
  /// 成立年の表記。表示ロケールに応じて切り替える (クライアントでは翻訳しない)
  var year: LocalizedText?
}

/// 返書の話者 (persons のスナップショット)。ことわざ等で人物がいない場合は Letter.person が nil
struct LetterPerson: Codable, Hashable {
  var id: String
  var name: LocalizedText
  var born: Int?
  var died: Int
  var title: LocalizedText
  var bio: LocalizedText

  /// 生没年の表示。紀元前は負数で保持しているため、言語に応じて「前551–前479」「551 BC–479 BC」の形にする
  func eraText(language: String) -> String {
    if let born {
      return "\(Self.yearText(year: born, language: language))–\(Self.yearText(year: died, language: language))"
    }
    return "?–\(Self.yearText(year: died, language: language))"
  }

  private static func yearText(year: Int, language: String) -> String {
    if year < 0 {
      return language == "ja" ? "前\(-year)" : "\(-year) BC"
    }
    return "\(year)"
  }
}

/// 話者が特定できない格言を説明する図解カード (例え → 意味 → 使いどころ)
struct LetterDiagram: Codable, Hashable {
  var metaphor: String
  var meaning: String
  var usage: String
}

/// 返書 1 通。POST /letters のレスポンスと users/{uid}/letters ドキュメントのデコード先
struct Letter: Codable, Hashable, Identifiable {
  var id: String
  var concern: String
  var language: String
  var quoteId: String
  var quote: LetterQuote
  var personId: String?
  var person: LetterPerson?
  var oneliner: String
  var meaning: String
  var closing: String
  var diagram: LetterDiagram?
  /// Firestore から読む場合のみ入る (レスポンスには含まれない)
  var createdAt: Date?
}
