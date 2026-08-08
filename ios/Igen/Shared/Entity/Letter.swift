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
  /// 没後 70 年経過 (パブリックドメイン) の確認結果 (persons スナップショットの権利確認情報)
  var publicDomain: LetterPersonPublicDomain?

  /// 生没年の表示。紀元前は負数で保持しているため、言語に応じて「前551–前479」「551 BC–479 BC」の形にする。
  /// 紀元をまたぐ場合 (紀元前生まれ・西暦没) は、英語では没年側にも AD を付けて紀元を明示する
  func eraText(language: String) -> String {
    if let born {
      let diedText =
        born < 0 && died > 0 && language != "ja"
        ? "\(died) AD"
        : Self.yearText(year: died, language: language)
      return "\(Self.yearText(year: born, language: language))–\(diedText)"
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

/// 収録人物のパブリックドメイン確認結果
struct LetterPersonPublicDomain: Codable, Hashable {
  var confirmed: Bool
  var note: String?
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
  /// 相談時の端末タイムゾーン。履歴の日付表示を相談時のまま固定するために使う
  var timeZone: String?
  /// POST /letters の冪等化に使ったクライアント生成 ID
  var requestId: String?
  var quoteId: String
  var quote: LetterQuote
  var personId: String?
  var person: LetterPerson?
  var oneliner: String
  var meaning: String
  var closing: String
  var diagram: LetterDiagram?
  /// 相談の受信時刻。履歴の日付表示の基準にする (createdAt は生成完了時のため深夜送信で翌日にずれる)
  var consultedAt: Date?
  /// Firestore から読む場合のみ入る (レスポンスには含まれない)
  var createdAt: Date?
  /// Firestore から読む場合のみ入る (レスポンスには含まれない)
  var updatedAt: Date?

  /// 相談日の表示。相談時のタイムゾーンで固定し (別のタイムゾーンで開いても日付が変わらない)、
  /// 返書の言語のロケールでフォーマットする (端末が第三言語でも表示言語が混在しない)。
  /// 日付の基準は相談受信時刻 consultedAt (生成完了時の createdAt では深夜送信で翌日にずれるため)
  func dateText() -> String {
    var style = Date.FormatStyle(date: .long, time: .omitted)
      .locale(Locale(identifier: language == "ja" ? "ja_JP" : "en_US"))
    if let timeZone = timeZone.flatMap(TimeZone.init(identifier:)) {
      style.timeZone = timeZone
    }
    return (consultedAt ?? createdAt ?? .now).formatted(style)
  }
}
