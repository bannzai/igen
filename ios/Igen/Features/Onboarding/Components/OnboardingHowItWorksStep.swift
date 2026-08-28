import SwiftUI

/// オンボーディング 2 画面目。「書く → 偉人が現れる → 出典つきの返書」の体験を
/// 返書の図解カードと同じ様式の 3 ノード縦フローで伝える。機能一覧のツアーにはしない (8BP #2)
struct OnboardingHowItWorksStep: View {
  var body: some View {
    VStack(spacing: 24) {
      // ja: 書くと、偉人が現れる
      Text("Write, and a great figure appears")
        .font(.igenSerif(size: 22, weight: .semibold))
        .multilineTextAlignment(.center)
        .lineSpacing(8)
        .foregroundStyle(Color.igenText)
        .padding(.vertical, 16)

      VStack(spacing: 0) {
        OnboardingFlowNode(emphasized: false) {
          // ja: きょうのできごと・お悩みを書く
          Text("Write about your day or your worry")
        }
        OnboardingFlowConnector()
        OnboardingFlowNode(emphasized: true) {
          // ja: ふさわしい偉人が、あなたの空に現れる
          Text("A fitting great figure appears in your sky")
        }
        OnboardingFlowConnector()
        OnboardingFlowNode(emphasized: false) {
          // ja: 出典つきの返書が届く
          Text("A letter of reply arrives, with its source")
        }
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 16)
      .padding(.horizontal, 16)
      .overlay(
        RoundedRectangle(cornerRadius: 16)
          .stroke(Color.igenGold.opacity(0.3), lineWidth: 1)
      )
    }
    .padding(.vertical, 16)
  }
}

/// 体験フローの 1 ノード。emphasized のノード (偉人が現れる) を明朝体と強めの金枠で強調する
struct OnboardingFlowNode<Label: View>: View {
  var emphasized: Bool
  // 表示文言は呼び出し側の Text リテラルに残す (Localizable.xcstrings の自動抽出対象にするため)
  @ViewBuilder var label: Label

  var body: some View {
    VStack(spacing: 6) {
      Text(verbatim: "✦")
        .font(.system(size: 10))
        .foregroundStyle(Color.igenGold.opacity(emphasized ? 1 : 0.7))

      if emphasized {
        label
          .font(.igenSerif(size: 15, weight: .semibold))
          .multilineTextAlignment(.center)
          .lineSpacing(6)
          .foregroundStyle(Color.igenText)
      } else {
        label
          .font(.system(size: 13))
          .multilineTextAlignment(.center)
          .lineSpacing(6)
          .foregroundStyle(Color.igenText.opacity(0.85))
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 12)
    .padding(.horizontal, 12)
    .overlay(
      RoundedRectangle(cornerRadius: 10)
        .stroke(
          emphasized ? Color.igenGold.opacity(0.5) : Color.igenText.opacity(0.16),
          lineWidth: emphasized ? 1.2 : 1
        )
    )
  }
}

/// 体験フローのノード間をつなぐ金のグラデーション縦線
struct OnboardingFlowConnector: View {
  var body: some View {
    Rectangle()
      .fill(
        LinearGradient(
          colors: [Color.igenGold.opacity(0.2), Color.igenGold.opacity(0.7)],
          startPoint: .top,
          endPoint: .bottom
        )
      )
      .frame(width: 1, height: 16)
  }
}

struct OnboardingHowItWorksStep_Previews: PreviewProvider {
  static var previews: some View {
    ZStack {
      StarfieldBackground()
      OnboardingHowItWorksStep()
        .padding(.horizontal, 24)
    }
  }
}
