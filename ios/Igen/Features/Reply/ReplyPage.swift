import SwiftUI

/// 返書画面。登場演出 (星座線アバター) → 各ブロックの stagger 出現で返書を表示する。
/// 構成順は固定: 日付 → 話者 (または図解カード) → ひとこと → 格言 → 対訳 → 意味と文脈 → 結び → 出典
struct ReplyPage: View {
  var letter: Letter
  /// 振り返りからの再訪では false にして、登場演出をスキップする
  var showsRitual = true
  /// 演出の実行回数。初回はリッチ、2 回目以降は短縮する (テンポを守る)
  @AppStorage("ritualCount") var ritualCount = 0
  @State var ritualFinished = false

  var body: some View {
    ZStack {
      StarfieldBackground()

      if ritualFinished || !showsRitual {
        // 再訪 (showsRitual == false) ではブロックの stagger 出現も無効化して即時表示する
        ReplyLetterContent(letter: letter, revealsBlocks: showsRitual)
      } else {
        ReplyRitualOverlay(letter: letter, short: ritualCount > 0) {
          ritualCount += 1
          withAnimation {
            ritualFinished = true
          }
        }
      }
    }
    .toolbar(.hidden, for: .navigationBar)
  }

}

struct ReplyPage_Previews: PreviewProvider {
  static let senecaLetter = Letter(
    id: "preview",
    concern: "新しい仕事に挑戦するのが怖い",
    language: "ja",
    quoteId: "seneca-non-quia-difficilia",
    quote: LetterQuote(
      kind: "quote",
      text: LocalizedText(
        ja: "難しいから挑めないのではない。挑まないから難しくなるのだ。",
        en: "It is not because things are difficult that we do not dare; it is because we do not dare that they are difficult."
      ),
      original: "Non quia difficilia sunt non audemus, sed quia non audemus difficilia sunt.",
      originalLanguage: "la",
      source: LetterQuoteSource(
        work: LocalizedText(ja: "倫理書簡集 (ルキリウスへの手紙)", en: "Moral Letters to Lucilius"),
        detail: LocalizedText(ja: "第104書簡 26節", en: "Letter 104, section 26"),
        origTitle: "Epistulae morales ad Lucilium",
        year: LocalizedText(ja: "65年頃", en: "c. 65 AD")
      )
    ),
    personId: "seneca",
    person: LetterPerson(
      id: "seneca",
      name: LocalizedText(ja: "セネカ", en: "Seneca"),
      born: -4,
      died: 65,
      title: LocalizedText(ja: "ストア派の哲学者・政治家", en: "Stoic philosopher and statesman"),
      bio: LocalizedText(ja: "古代ローマの哲学者。", en: "Roman Stoic philosopher.")
    ),
    oneliner: "その一歩をためらう夜もあるでしょう。",
    meaning: "この言葉は、困難の多くが踏み出さないことから生まれると説いています。",
    closing: "あなたの挑戦を、星々とともに見守っています。",
    diagram: nil,
    createdAt: nil
  )

  static var previews: some View {
    NavigationStack {
      ReplyPage(letter: senecaLetter)
    }
  }
}
