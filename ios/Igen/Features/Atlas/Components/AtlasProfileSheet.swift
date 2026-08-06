import SwiftUI

/// 星図で偉人をタップしたときのプロフィールシート。
/// 人物・生没年・略歴と、過去にその偉人からもらった言葉の一覧、返書への導線を表示する
struct AtlasProfileSheet: View {
  var encounter: Encounter
  /// この偉人からもらった返書 (新しい順)
  var letters: [Letter]
  @Environment(\.dismiss) var dismiss
  @State var selectedLetter: Letter?

  var body: some View {
    NavigationStack {
      ZStack {
        Color.igenSheet.opacity(0.94)
          .ignoresSafeArea()

        ScrollView {
          VStack(spacing: 16) {
            HStack {
              Spacer()
              Button {
                dismiss()
              } label: {
                Image(systemName: "xmark")
                  .font(.system(size: 14))
                  .foregroundStyle(Color.igenText.opacity(0.6))
                  .frame(width: 44, height: 44)
              }
            }

            ConstellationAvatar(constellation: ConstellationData.constellation(for: encounter.personId))
              .frame(width: 64, height: 64)

            VStack(spacing: 4) {
              Text(encounter.person.name.localized(deviceLanguage))
                .font(.system(size: 20, weight: .semibold, design: .serif))
                .tracking(3)
                .foregroundStyle(Color.igenText)
              HStack(spacing: 4) {
                Text(encounter.person.title.localized(deviceLanguage))
                Text(verbatim: "—")
                Text(verbatim: encounter.person.eraText(language: deviceLanguage))
              }
              .font(.system(size: 11))
              .foregroundStyle(Color.igenText.opacity(0.6))
            }

            Text(encounter.person.bio.localized(deviceLanguage))
              .font(.system(size: 12))
              .lineSpacing(7)
              .foregroundStyle(Color.igenText.opacity(0.85))

            if !letters.isEmpty {
              VStack(alignment: .leading, spacing: 8) {
                // ja: もらった言葉
                Text("Words you received")
                  .font(.system(size: 10, weight: .semibold))
                  .tracking(3)
                  .foregroundStyle(Color.igenGold)
                ForEach(letters) { letter in
                  Text(letter.quote.text.localized(letter.language))
                    .font(.system(size: 13, design: .serif))
                    .lineSpacing(6)
                    .foregroundStyle(Color.igenText)
                }
              }
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.vertical, 12)
              .padding(.horizontal, 14)
              .background(
                RoundedRectangle(cornerRadius: 12)
                  .fill(Color.igenGold.opacity(0.08))
              )

              Button {
                selectedLetter = letters.first
              } label: {
                // ja: 返書を読む
                Text("Read the letter")
                  .font(.system(size: 15, weight: .semibold, design: .serif))
                  .foregroundStyle(Color.igenButtonText)
                  .frame(maxWidth: .infinity)
                  .frame(height: 48)
                  .background(
                    LinearGradient(colors: [Color.igenGold, Color.igenGoldDark], startPoint: .top, endPoint: .bottom)
                  )
                  .clipShape(Capsule())
              }
            }
          }
          .padding(.horizontal, 24)
          .padding(.bottom, 24)
        }
      }
      .navigationDestination(item: $selectedLetter) { letter in
        ReplyPage(letter: letter, showsRitual: false)
      }
    }
  }

  /// シートの表示言語 (端末ロケール)
  private var deviceLanguage: String {
    Locale.autoupdatingCurrent.language.languageCode?.identifier == "ja" ? "ja" : "en"
  }
}

struct AtlasProfileSheet_Previews: PreviewProvider {
  static var previews: some View {
    AtlasProfileSheet(
      encounter: Encounter(
        personId: "seneca",
        person: ReplyPage_Previews.senecaLetter.person!,
        lastQuoteId: nil,
        createdAt: nil,
        updatedAt: nil
      ),
      letters: [ReplyPage_Previews.senecaLetter]
    )
  }
}
