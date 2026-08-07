import SwiftUI

/// 窓口カード。電話番号があればタップで発信、URL があればブラウザで開く
struct SafetyResourceCard: View {
  var resource: SafetyResource

  var body: some View {
    if let phoneNumber = resource.phoneNumber,
      let telURL = URL(string: "tel:\(phoneNumber.replacingOccurrences(of: "-", with: ""))")
    {
      Link(destination: telURL) {
        SafetyResourceCardContent(resource: resource)
      }
    } else if let url = resource.url {
      Link(destination: url) {
        SafetyResourceCardContent(resource: resource)
      }
    } else {
      SafetyResourceCardContent(resource: resource)
    }
  }
}

/// 窓口カードの表示部分 (名称・電話番号・注記)。名称・注記は文字列カタログで解決済みの文字列を受け取る
struct SafetyResourceCardContent: View {
  var resource: SafetyResource

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(verbatim: resource.name)
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(Color.igenText)
      if let phoneNumber = resource.phoneNumber {
        Text(verbatim: phoneNumber)
          .font(.system(size: 17, weight: .semibold, design: .serif))
          .foregroundStyle(Color.igenGoldBright)
      }
      if let note = resource.note {
        Text(verbatim: note)
          .font(.system(size: 11))
          .foregroundStyle(Color.igenText.opacity(0.6))
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    // 電話番号・注記のないカードでも最小タップターゲット 44pt を確保する (design_handoff_igen/README.md)
    .frame(minHeight: 44)
    .padding(.vertical, 12)
    .padding(.horizontal, 16)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color.igenCard.opacity(0.7))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(Color.igenText.opacity(0.2), lineWidth: 1)
    )
  }
}

struct SafetyResourceCard_Previews: PreviewProvider {
  static var previews: some View {
    SafetyResourceCard(
      resource: SafetyResource(
        id: "yorisoi",
        // ja: よりそいホットライン
        name: String(localized: "Yorisoi Hotline"),
        phoneNumber: "0120-279-338",
        // ja: 24時間・通話無料
        note: String(localized: "24 hours, toll-free"),
        url: nil
      )
    )
    .padding()
    .background(Color.igenSheet)
  }
}
