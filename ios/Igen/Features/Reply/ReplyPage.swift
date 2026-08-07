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
  @Environment(\.dismiss) var dismiss

  var body: some View {
    ZStack {
      StarfieldBackground()

      if ritualFinished || !showsRitual {
        letterContent
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

  private var letterContent: some View {
    ScrollView {
      VStack(spacing: 24) {
        // ja: あなたへの返書
        Text("A Letter for You")
          .font(.system(size: 16, weight: .semibold, design: .serif))
          .tracking(4)
          .foregroundStyle(Color.igenGoldBright)
          .igenReveal(0)

        Text(letter.dateText())
          .font(.system(size: 11))
          .foregroundStyle(Color.igenText.opacity(0.5))
          .igenReveal(0)

        if let person = letter.person {
          VStack(spacing: 8) {
            ConstellationAvatar(constellation: ConstellationData.constellation(for: person.id))
              .frame(width: 130, height: 130)
            Text(person.name.localized(letter.language))
              .font(.system(size: 20, weight: .semibold, design: .serif))
              .tracking(3)
              .foregroundStyle(Color.igenText)
            HStack(spacing: 4) {
              Text(person.title.localized(letter.language))
              Text(verbatim: "—")
              Text(verbatim: eraText(person))
            }
            .font(.system(size: 11))
            .foregroundStyle(Color.igenText.opacity(0.6))
          }
          .igenReveal(1)
        } else if let diagram = letter.diagram {
          ReplyDiagramCard(diagram: diagram)
            .igenReveal(1)
        }

        Text(letter.oneliner)
          .font(.system(size: 14))
          .lineSpacing(9)
          .foregroundStyle(Color.igenText)
          .igenReveal(2)

        VStack(spacing: 12) {
          goldHairline
          Text(letter.quote.text.localized(letter.language))
            .font(.system(size: 24, weight: .semibold, design: .serif))
            .multilineTextAlignment(.center)
            .lineSpacing(12)
            .foregroundStyle(Color.igenGoldBright)
            .shadow(color: Color.igenGold.opacity(0.35), radius: 12)
          goldHairline
        }
        .igenReveal(3)

        // 原文はどのロケールでも改変せず併記する (localization-guidelines.md)。
        // 同一言語でも古文原文などが異なる場合があるため、言語コードではなく表示文との差異で判定する
        if letter.quote.original != letter.quote.text.localized(letter.language) {
          ReplyOriginalTextBlock(quote: letter.quote, language: letter.language)
            .igenReveal(4)
        }

        VStack(spacing: 8) {
          // ja: 意味と文脈
          Text("Meaning & Context")
            .font(.system(size: 10, weight: .semibold))
            .tracking(3)
            .foregroundStyle(Color.igenGold)
          Text(letter.meaning)
            .font(.system(size: 14))
            .lineSpacing(9)
            .foregroundStyle(Color.igenText)
        }
        .igenReveal(5)

        VStack(spacing: 10) {
          Text(letter.closing)
            .font(.system(size: 15, design: .serif))
            .lineSpacing(10)
            .foregroundStyle(Color.igenText)
          if let person = letter.person {
            // ja: — %@ より
            Text("— from \(person.name.localized(letter.language))")
              .font(.system(size: 13, design: .serif))
              .foregroundStyle(Color.igenText.opacity(0.7))
              .frame(maxWidth: .infinity, alignment: .trailing)
          } else {
            // ja: — 偉言 より
            Text("— from IGEN")
              .font(.system(size: 13, design: .serif))
              .foregroundStyle(Color.igenText.opacity(0.7))
              .frame(maxWidth: .infinity, alignment: .trailing)
          }
        }
        .igenReveal(6)

        ReplySourceBlock(quote: letter.quote, language: letter.language)
          .igenReveal(7)

        Button {
          dismiss()
        } label: {
          // ja: とじる
          Text("Close")
            .font(.system(size: 15))
            .foregroundStyle(Color.igenText.opacity(0.8))
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .overlay(
              Capsule().stroke(Color.igenText.opacity(0.25), lineWidth: 1)
            )
        }
        .igenReveal(8)
      }
      .padding(.horizontal, 24)
      .padding(.vertical, 24)
    }
  }

  private var goldHairline: some View {
    Rectangle()
      .fill(Color.igenGold.opacity(0.25))
      .frame(height: 1)
  }

  /// 生没年の表示 (紀元前は負数で保持している)
  private func eraText(_ person: LetterPerson) -> String {
    let died = formatYear(person.died)
    if let born = person.born {
      return "\(formatYear(born))–\(died)"
    }
    return "?–\(died)"
  }

  private func formatYear(_ year: Int) -> String {
    if year < 0 {
      // ja 表示は「前551」のような形式、en は BC 表記
      return letter.language == "ja" ? "前\(-year)" : "\(-year) BC"
    }
    return "\(year)"
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
