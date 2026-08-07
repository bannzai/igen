import SwiftUI

/// 返書の本文表示。固定ヘッダー (とじる / タイトル) + スクロール本文。
/// 構成順は固定: 日付 → 話者 (または図解カード) → ひとこと → 格言 → 対訳 → 意味と文脈 → 結び → 出典
struct ReplyLetterContent: View {
  var letter: Letter

  @Environment(\.dismiss) var dismiss

  var body: some View {
    VStack(spacing: 0) {
      // スクロールしても消えない固定ヘッダー (design_handoff_igen/README.md「返書」)。
      // 長い返書でも末尾までスクロールせずに戻れるようにする
      HStack {
        Button {
          dismiss()
        } label: {
          // ja: とじる
          Text("Close")
            .font(.system(size: 12))
            .foregroundStyle(Color.igenText.opacity(0.8))
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(Capsule().fill(Color.igenCard.opacity(0.55)))
            .overlay(Capsule().stroke(Color.igenText.opacity(0.22), lineWidth: 1))
            // 見た目のカプセルは保ちつつ、最小タップターゲット 44pt を確保する (design_handoff_igen/README.md)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        Spacer()
        // ja: あなたへの返書
        Text("A Letter for You")
          .font(.system(size: 13, weight: .semibold, design: .serif))
          .tracking(4)
          .foregroundStyle(Color.igenGoldBright)
        Spacer()
        // 左のとじるピルと釣り合いを取り、タイトルを中央に保つための余白
        Color.clear.frame(width: 58, height: 1)
      }
      .padding(.vertical, 12)
      .padding(.horizontal, 18)

      ScrollView {
        VStack(spacing: 24) {
          Text((letter.createdAt ?? .now).formatted(date: .long, time: .omitted))
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
                Text(verbatim: person.eraText(language: letter.language))
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
            ReplyGoldHairline()
            Text(letter.quote.text.localized(letter.language))
              .font(.system(size: 24, weight: .semibold, design: .serif))
              .multilineTextAlignment(.center)
              .lineSpacing(12)
              .foregroundStyle(Color.igenGoldBright)
              .shadow(color: Color.igenGold.opacity(0.35), radius: 12)
            ReplyGoldHairline()
          }
          .igenReveal(3)

          // 原文は出典の信頼性の要件として、訳文との一致にかかわらず常に併記する (localization-guidelines.md)
          ReplyOriginalTextBlock(quote: letter.quote, language: letter.language)
            .igenReveal(4)

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
  }
}

struct ReplyLetterContent_Previews: PreviewProvider {
  static var previews: some View {
    ZStack {
      StarfieldBackground()
      ReplyLetterContent(letter: ReplyPage_Previews.senecaLetter)
    }
  }
}
