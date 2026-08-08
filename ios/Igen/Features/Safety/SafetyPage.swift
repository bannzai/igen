import FirebaseAnalytics
import SwiftUI

/// 深刻な相談 (危機ワード検知) のときに、返書の代わりに表示する相談窓口の案内画面。
/// トーンは静かで誠実に。世界観は保ちつつ演出は抑える (design_handoff_igen/README.md「セーフティ」)
struct SafetyPage: View {
  @Environment(\.dismiss) var dismiss

  var body: some View {
    ZStack {
      StarfieldBackground()
      // きらめきを抑える濃いスクリム
      Color(red: 4 / 255, green: 5 / 255, blue: 14 / 255).opacity(0.78)
        .ignoresSafeArea()

      ScrollView {
        VStack(spacing: 20) {
          // 静かな一つ星
          Circle()
            .fill(Color.igenGoldBright)
            .frame(width: 6, height: 6)
            .shadow(color: Color.igenGold.opacity(0.9), radius: 8)
            .padding(.vertical, 24)

          // ja: たいせつなお話を、ありがとうございます。
          Text("Thank you for telling me something so important.")
            .font(.system(size: 18, weight: .semibold, design: .serif))
            .multilineTextAlignment(.center)
            .lineSpacing(8)
            .foregroundStyle(Color.igenText)

          // ja: 偉言は励ましのアプリで、専門の支援をお届けすることはできません 下記の窓口が、あなたの話を聞いてくれます
          Text("IGEN is an app of encouragement and cannot provide professional support. The services below are there to listen to you.")
            .font(.system(size: 13))
            .multilineTextAlignment(.center)
            .lineSpacing(9)
            .foregroundStyle(Color.igenText.opacity(0.85))

          // 窓口は表示言語ではなく端末の地域で選ぶ (危機時に利用できない国の窓口へ誘導しないため)
          ForEach(SafetyResource.resources(regionCode: Locale.autoupdatingCurrent.region?.identifier)) {
            resource in
            SafetyResourceCard(resource: resource)
          }

          // ja: このご相談への返書はお送りしていません。
          Text("No letter has been sent for this consultation.")
            .font(.system(size: 11))
            .foregroundStyle(Color.igenText.opacity(0.5))
            .padding(.vertical, 8)

          Button {
            Analytics.logEvent("safety_back_button_pressed", parameters: nil)
            dismiss()
          } label: {
            // ja: ホームにもどる
            Text("Back to Home")
              .font(.system(size: 15))
              .foregroundStyle(Color.igenText.opacity(0.85))
              .frame(maxWidth: .infinity)
              .frame(height: 48)
              .overlay(
                Capsule().stroke(Color.igenText.opacity(0.3), lineWidth: 1)
              )
          }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 24)
      }
    }
    .onAppear {
      // 相談本文は Analytics に送らない (.claude/rules/coding-rules-analytics.md)
      Analytics.logEvent("safety_guide_shown", parameters: nil)
    }
  }
}

/// 相談窓口 1 件。電話番号・URL は表示用のデータとしてそのまま扱う。
/// 名称・注記は Localizable.xcstrings のカタログから表示言語で解決する (窓口の選択は地域、文言は言語)。
/// **掲載内容 (電話番号・受付時間) はリリース前に必ず最新情報を確認する** (#16 公開前チェックリスト)
struct SafetyResource: Identifiable {
  var id: String
  var name: String
  var phoneNumber: String?
  var note: String?
  var url: URL?

  /// 端末の地域ごとの窓口一覧。表示言語ではなく地域で選ぶ (利用できない国の窓口へ誘導しないため)。
  /// 日本・米国以外の地域は、国別の窓口を探せる国際サービスに誘導する
  static func resources(regionCode: String?) -> [SafetyResource] {
    switch regionCode {
    case "JP":
      return [
        SafetyResource(
          id: "inochi",
          // ja: いのちの電話
          name: String(localized: "Inochi no Denwa (Japan Lifeline)"),
          phoneNumber: "0570-783-556",
          note: nil,
          url: nil
        ),
        SafetyResource(
          id: "yorisoi",
          // ja: よりそいホットライン
          name: String(localized: "Yorisoi Hotline"),
          phoneNumber: "0120-279-338",
          // ja: 24時間・通話無料
          note: String(localized: "24 hours, toll-free"),
          url: nil
        ),
        SafetyResource(
          id: "mamorouyo",
          // ja: まもろうよ こころ（厚生労働省）
          name: String(localized: "Mamorou yo Kokoro (MHLW)"),
          phoneNumber: nil,
          note: nil,
          url: URL(string: "https://www.mhlw.go.jp/mamorouyokokoro/")
        ),
      ]
    case "US":
      return [
        SafetyResource(
          id: "lifeline-988",
          // ja: 988 Suicide & Crisis Lifeline
          name: String(localized: "988 Suicide & Crisis Lifeline"),
          phoneNumber: "988",
          // ja: 24時間・無料・秘密厳守（米国）
          note: String(localized: "24/7, free and confidential (US)"),
          url: nil
        )
      ]
    default:
      return [
        SafetyResource(
          id: "find-a-helpline",
          // ja: Find a Helpline
          name: String(localized: "Find a Helpline"),
          phoneNumber: nil,
          // ja: お住まいの国の相談窓口を探せます
          note: String(localized: "Find support services in your country"),
          url: URL(string: "https://findahelpline.com/")
        )
      ]
    }
  }
}

struct SafetyPage_Previews: PreviewProvider {
  static var previews: some View {
    SafetyPage()
  }
}
