import SwiftUI

/// 共有カードの背景 (グラデーション + 静的な星屑)
struct ShareCardBackground: View {
  var body: some View {
    ZStack {
      LinearGradient(
        stops: [
          .init(color: Color(red: 7 / 255, green: 10 / 255, blue: 28 / 255), location: 0),
          .init(color: Color(red: 25 / 255, green: 18 / 255, blue: 67 / 255), location: 0.7),
          .init(color: Color(red: 35 / 255, green: 22 / 255, blue: 80 / 255), location: 1),
        ],
        startPoint: .top,
        endPoint: .bottom
      )
      // 静的な星屑 (座標はシード固定。ImageRenderer で描けるようアニメーションなし)
      Canvas { context, size in
        var seed: UInt64 = 0x51A4_CA4D
        func next() -> Double {
          seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
          return Double(seed >> 33) / Double(UInt64(1) << 31)
        }
        for _ in 0..<40 {
          let rect = CGRect(x: next() * size.width, y: next() * size.height, width: 1.2 + next() * 1.6, height: 1.2 + next() * 1.6)
          context.fill(
            Path(ellipseIn: rect),
            with: .color(Color.igenGoldBright.opacity(0.25 + next() * 0.5))
          )
        }
      }
    }
  }
}
