import SwiftUI

/// 話者が特定できない格言・ことわざを説明する図解カード。
/// 「たとえ → 意味 → 使いどころ」の 3 ノード縦フローで、「意味」を強調する
struct ReplyDiagramCard: View {
  var diagram: LetterDiagram

  var body: some View {
    VStack(spacing: 0) {
      // ja: 図解 — ことばのしくみ
      Text("Diagram — How the words work")
        .font(.system(size: 11, weight: .semibold))
        .tracking(2)
        .foregroundStyle(Color.igenGold)
        .padding(.bottom, 14)

      ReplyDiagramNode(kind: .metaphor, text: diagram.metaphor)
      connector
      ReplyDiagramNode(kind: .meaning, text: diagram.meaning)
      connector
      ReplyDiagramNode(kind: .usage, text: diagram.usage)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 16)
    .padding(.horizontal, 16)
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .stroke(Color.igenGold.opacity(0.3), lineWidth: 1)
    )
  }

  private var connector: some View {
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

/// 図解カードのノード種別。表示文言・強調は View 側で switch する
enum ReplyDiagramNodeKind {
  case metaphor
  case meaning
  case usage
}

/// 図解カードの 1 ノード
struct ReplyDiagramNode: View {
  var kind: ReplyDiagramNodeKind
  var text: String

  var body: some View {
    VStack(spacing: 4) {
      switch kind {
      case .metaphor:
        // ja: たとえ
        Text("Metaphor")
          .font(.system(size: 10, weight: .semibold))
          .tracking(2)
          .foregroundStyle(Color.igenGold.opacity(0.8))
      case .meaning:
        // ja: 意味
        Text("Meaning")
          .font(.system(size: 10, weight: .semibold))
          .tracking(2)
          .foregroundStyle(Color.igenGold)
      case .usage:
        // ja: 使いどころ
        Text("When to use")
          .font(.system(size: 10, weight: .semibold))
          .tracking(2)
          .foregroundStyle(Color.igenGold.opacity(0.8))
      }

      if kind == .meaning {
        Text(text)
          .font(.igenSerif(size: 14, weight: .semibold))
          .multilineTextAlignment(.center)
          .foregroundStyle(Color.igenText)
      } else {
        Text(text)
          .font(.system(size: 12))
          .multilineTextAlignment(.center)
          .foregroundStyle(Color.igenText.opacity(0.85))
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 10)
    .padding(.horizontal, 12)
    .overlay(
      RoundedRectangle(cornerRadius: 10)
        .stroke(
          kind == .meaning ? Color.igenGold.opacity(0.5) : Color.igenText.opacity(0.16),
          lineWidth: kind == .meaning ? 1.2 : 1
        )
    )
  }
}

struct ReplyDiagramCard_Previews: PreviewProvider {
  static var previews: some View {
    ReplyDiagramCard(
      diagram: LetterDiagram(
        metaphor: "国境の翁の馬が逃げ、また戻ってくる",
        meaning: "不運と幸運は簡単には見分けられない",
        usage: "良し悪しをすぐに決めつけそうになったとき"
      )
    )
    .padding()
    .background(Color.igenSheet)
  }
}
