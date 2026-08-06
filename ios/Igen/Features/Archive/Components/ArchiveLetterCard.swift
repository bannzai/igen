import SwiftUI

/// 振り返り一覧の 1 件ぶんのカード。日付・相談文・話者ピル・格言スニペットを表示する
struct ArchiveLetterCard: View {
  var letter: Letter

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text((letter.createdAt ?? .now).formatted(date: .long, time: .omitted))
        .font(.system(size: 10))
        .foregroundStyle(Color.igenText.opacity(0.5))

      Text(letter.concern)
        .font(.system(size: 13))
        .lineLimit(2)
        .multilineTextAlignment(.leading)
        .foregroundStyle(Color.igenText)

      HStack(spacing: 8) {
        HStack(spacing: 4) {
          Text(verbatim: "✦")
          if let person = letter.person {
            Text(person.name.localized(letter.language))
          } else {
            // ja: ことわざ・図解
            Text("Proverb & diagram")
          }
        }
        .font(.system(size: 11))
        .foregroundStyle(Color.igenTextGold)
        .padding(.vertical, 4)
        .padding(.horizontal, 10)
        .overlay(
          Capsule().stroke(Color.igenGold.opacity(0.4), lineWidth: 1)
        )

        Text(letter.quote.text.localized(letter.language))
          .font(.system(size: 12, design: .serif))
          .lineLimit(1)
          .foregroundStyle(Color.igenText.opacity(0.8))
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.vertical, 14)
    .padding(.horizontal, 16)
    .background(
      RoundedRectangle(cornerRadius: 14)
        .fill(Color.igenCard.opacity(0.6))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 14)
        .stroke(Color.igenGold.opacity(0.2), lineWidth: 1)
    )
  }
}

struct ArchiveLetterCard_Previews: PreviewProvider {
  static var previews: some View {
    ArchiveLetterCard(letter: ReplyPage_Previews.senecaLetter)
      .padding()
      .background(Color.igenSheet)
  }
}
