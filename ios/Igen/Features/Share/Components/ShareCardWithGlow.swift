import SwiftUI

/// 金色のグロー付きの共有カード。画面プレビューと ImageRenderer の書き出しで同じ装飾を使う
struct ShareCardWithGlow: View {
  var letter: Letter

  var body: some View {
    ShareCardView(letter: letter)
      .shadow(color: Color.igenGold.opacity(0.35), radius: 24)
  }
}
