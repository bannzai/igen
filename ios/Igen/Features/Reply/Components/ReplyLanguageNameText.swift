import SwiftUI

/// 原文言語コードの表示名。言語コード → 表示文言の対応は View 側で switch する
struct ReplyLanguageNameText: View {
  var code: String

  var body: some View {
    switch code {
    case "la":
      // ja: ラテン語
      Text("Latin")
    case "zh":
      // ja: 漢文
      Text("Classical Chinese")
    case "de":
      // ja: ドイツ語
      Text("German")
    case "grc":
      // ja: 古典ギリシア語
      Text("Ancient Greek")
    case "ja":
      // ja: 日本語
      Text("Japanese")
    case "en":
      // ja: 英語
      Text("English")
    default:
      Text(verbatim: code)
    }
  }
}
