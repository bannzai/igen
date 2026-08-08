import SwiftUI

/// 格言ブロックの上下に引く金色の罫線
struct ReplyGoldHairline: View {
  var body: some View {
    Rectangle()
      .fill(Color.igenGold.opacity(0.25))
      .frame(height: 1)
  }
}
