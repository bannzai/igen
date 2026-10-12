import FirebaseAnalytics
import SwiftUI

/// 星図で偉人をタップしたときのプロフィール画面 (シート表示)。
/// その偉人からもらった返書を personId 指定で取得し、取得できたら本文表示 (AtlasProfilePageBody) へ渡す
struct AtlasProfilePage: View {
  var encounter: Encounter
  /// この偉人からもらった返書 (新しい順)。表示時に personId 指定で取得する (nil は取得中)
  @State var letters: [Letter]?
  /// プロフィール本文 (閉じるボタンから「返書を読む」まで) の高さ。シートの高さを本文に合わせるために測る (nil は取得中・計測前)
  @State var profileContentHeight: CGFloat?

  var body: some View {
    NavigationStack {
      ZStack {
        Color.igenSheet.opacity(0.94)
          .ignoresSafeArea()

        if let letters {
          AtlasProfilePageBody(encounter: encounter, letters: letters, contentHeight: $profileContentHeight)
        } else {
          ProgressView()
            .tint(Color.igenGold)
        }
      }
      .task {
        // 取得失敗はもらった言葉ブロックの非表示に留める (プロフィール自体は encounter だけで表示できる)
        do {
          letters = try await LettersStore.fetchLetters(personId: encounter.personId)
          // 押下 (atlas_person_button_pressed) と分けて、プロフィールが正常に読み込めた数を記録する
          Analytics.logEvent("atlas_profile_loaded", parameters: nil)
        } catch {
          letters = []
        }
      }
    }
    // デザイン指定の下部プロフィールシートとして星図とのつながりを保ちつつ、本文が収まる高さで開く。
    // .medium は画面の高さの約半分のため、iPhone Duo の外側ディスプレイのように画面の低い端末では「返書を読む」が見切れる
    .presentationDetents(
      {
        // .height はシート下端の safe area を含まない高さとして扱われる (iPhone Duo の Simulator で実測) ため、本文の高さをそのまま渡す
        if let profileContentHeight {
          return [.height(profileContentHeight), .large]
        }
        return [.medium, .large]
      }()
    )
  }
}

/// プロフィールの本文表示 (人物・生没年・略歴・もらった言葉・返書への導線)
private struct AtlasProfilePageBody: View {
  var encounter: Encounter
  /// この偉人からもらった返書 (新しい順)
  var letters: [Letter]
  /// 本文の高さの計測結果の書き込み先 (シートの高さを決める AtlasProfilePage が持つ)
  @Binding var contentHeight: CGFloat?

  @Environment(\.dismiss) var dismiss
  @State var selectedLetter: Letter?

  var body: some View {
    ScrollView {
      VStack(spacing: 16) {
        HStack {
          Spacer()
          Button {
            Analytics.logEvent("atlas_profile_close_button_pressed", parameters: nil)
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
            .font(.igenSerif(size: 20, weight: .semibold))
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
                // 格言はデザインの共通タイポグラフィ指定 (Shippori Mincho 500–700) に合わせて Medium 以上にする
                .font(.igenSerif(size: 13, weight: .medium))
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
            Analytics.logEvent("atlas_read_letter_button_pressed", parameters: nil)
            selectedLetter = letters.first
          } label: {
            // ja: 返書を読む
            Text("Read the letter")
              .font(.igenSerif(size: 15, weight: .semibold))
              .foregroundStyle(Color.igenButtonText)
              .frame(maxWidth: .infinity)
              .frame(height: 48)
              .background(
                LinearGradient(
                  colors: [Color.igenGold, Color.igenGoldDark],
                  startPoint: .top,
                  endPoint: .bottom
                )
              )
              .clipShape(Capsule())
          }
        }
      }
      .padding(.horizontal, 24)
      .padding(.bottom, 24)
      .onGeometryChange(for: CGFloat.self) { proxy in
        proxy.size.height
      } action: { height in
        contentHeight = height
      }
    }
    .navigationDestination(item: $selectedLetter) { letter in
      ReplyPage(letter: letter, showsRitual: false)
    }
  }

  /// シートの表示言語 (アプリに適用中のローカライズ。アプリ単位の言語切り替えに追随する)
  private var deviceLanguage: String {
    Bundle.main.preferredLocalizations.first == "ja" ? "ja" : "en"
  }
}

struct AtlasProfilePage_Previews: PreviewProvider {
  static var previews: some View {
    AtlasProfilePage(
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
