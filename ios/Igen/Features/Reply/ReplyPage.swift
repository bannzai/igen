import SwiftUI

/// 返書画面。星座線アバター演出・図解カード・対訳ブロックの本実装は #8 で行う (現状は表示のプレースホルダ)
struct ReplyPage: View {
  var letter: Letter

  var body: some View {
    ZStack {
      StarfieldBackground()

      ScrollView {
        VStack(spacing: 24) {
          // ja: あなたへの返書
          Text("A Letter for You")
            .font(.system(size: 16, weight: .semibold, design: .serif))
            .tracking(4)
            .foregroundStyle(Color(red: 245 / 255, green: 223 / 255, blue: 164 / 255))

          if let person = letter.person {
            VStack(spacing: 4) {
              Text(person.name.localized(letter.language))
                .font(.system(size: 20, weight: .semibold, design: .serif))
                .foregroundStyle(Color(red: 236 / 255, green: 231 / 255, blue: 244 / 255))
              Text(person.title.localized(letter.language))
                .font(.system(size: 11))
                .foregroundStyle(Color(red: 236 / 255, green: 231 / 255, blue: 244 / 255).opacity(0.6))
            }
          }

          Text(letter.oneliner)
            .font(.system(size: 14))
            .lineSpacing(8)
            .foregroundStyle(Color(red: 236 / 255, green: 231 / 255, blue: 244 / 255))

          Text(letter.quote.text.localized(letter.language))
            .font(.system(size: 24, weight: .semibold, design: .serif))
            .multilineTextAlignment(.center)
            .lineSpacing(10)
            .foregroundStyle(Color(red: 245 / 255, green: 223 / 255, blue: 164 / 255))

          // 原文は出典の信頼性の要件として、訳文との一致にかかわらず常に併記する (localization-guidelines.md)
          VStack(spacing: 6) {
            // ja: 原文
            Text("Original")
              .font(.system(size: 10, weight: .semibold))
              .tracking(3)
              .foregroundStyle(Color(red: 232 / 255, green: 201 / 255, blue: 122 / 255))
            Text(letter.quote.original)
              .font(.system(size: 15, design: .serif))
              .italic()
              .multilineTextAlignment(.center)
              .foregroundStyle(Color(red: 236 / 255, green: 231 / 255, blue: 244 / 255))
          }

          if let diagram = letter.diagram {
            VStack(alignment: .leading, spacing: 8) {
              Text(diagram.metaphor)
              Text(diagram.meaning)
              Text(diagram.usage)
            }
            .font(.system(size: 13))
            .foregroundStyle(Color(red: 236 / 255, green: 231 / 255, blue: 244 / 255))
          }

          Text(letter.meaning)
            .font(.system(size: 14))
            .lineSpacing(8)
            .foregroundStyle(Color(red: 236 / 255, green: 231 / 255, blue: 244 / 255))

          Text(letter.closing)
            .font(.system(size: 15, design: .serif))
            .lineSpacing(8)
            .foregroundStyle(Color(red: 236 / 255, green: 231 / 255, blue: 244 / 255))

          VStack(spacing: 4) {
            // ja: 出典
            Text("Source")
              .font(.system(size: 10, weight: .semibold))
              .tracking(3)
              .foregroundStyle(Color(red: 232 / 255, green: 201 / 255, blue: 122 / 255))
            Text(letter.quote.source.work.localized(letter.language))
              .font(.system(size: 13))
              .foregroundStyle(Color(red: 236 / 255, green: 231 / 255, blue: 244 / 255))
            if let detail = letter.quote.source.detail {
              Text(detail.localized(letter.language))
                .font(.system(size: 11))
                .foregroundStyle(Color(red: 236 / 255, green: 231 / 255, blue: 244 / 255).opacity(0.6))
            }
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 12)
          .overlay(
            RoundedRectangle(cornerRadius: 12)
              .stroke(Color(red: 232 / 255, green: 201 / 255, blue: 122 / 255).opacity(0.35), lineWidth: 1)
          )
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 24)
      }
    }
  }
}

struct ReplyPage_Previews: PreviewProvider {
  static var previews: some View {
    ReplyPage(
      letter: Letter(
        id: "preview",
        concern: "新しい仕事に挑戦するのが怖い",
        language: "ja",
        quoteId: "seneca-non-quia-difficilia",
        quote: LetterQuote(
          kind: "quote",
          text: LocalizedText(ja: "難しいから挑めないのではない。挑まないから難しくなるのだ。", en: "It is not because things are difficult that we do not dare; it is because we do not dare that they are difficult."),
          original: "Non quia difficilia sunt non audemus, sed quia non audemus difficilia sunt.",
          originalLanguage: "la",
          source: LetterQuoteSource(
            work: LocalizedText(ja: "倫理書簡集 (ルキリウスへの手紙)", en: "Moral Letters to Lucilius"),
            detail: LocalizedText(ja: "第104書簡 26節", en: "Letter 104, section 26"),
            origTitle: "Epistulae morales ad Lucilium",
            year: "65年頃"
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
    )
  }
}
