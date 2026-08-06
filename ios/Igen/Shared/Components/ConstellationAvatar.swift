import SwiftUI

/// 星座線アバター。点 (星) と細い光の線で偉人の姿を描く。
/// starProgress / lineProgress で登場演出 (星の収束 → 線の描画) を外部から駆動できる
struct ConstellationAvatar: View {
  var constellation: Constellation
  /// 星の収束度。0 = 散らばった状態、1 = 定位置
  var starProgress: Double = 1
  /// 線の描画割合。0 = 線なし、1 = 全て描画
  var lineProgress: Double = 1

  var body: some View {
    Canvas { context, size in
      let scale = min(size.width, size.height) / 100
      let lineCount = Double(constellation.lines.count)
      for (index, line) in constellation.lines.enumerated() {
        // 線ごとに順番に描画する (index が小さい線から)
        let progress = min(max(lineProgress * lineCount - Double(index), 0), 1)
        if progress <= 0 {
          continue
        }
        let from = constellation.points[line.0]
        let to = constellation.points[line.1]
        var path = Path()
        path.move(to: CGPoint(x: from.x * scale, y: from.y * scale))
        path.addLine(
          to: CGPoint(
            x: (from.x + (to.x - from.x) * progress) * scale,
            y: (from.y + (to.y - from.y) * progress) * scale
          )
        )
        context.stroke(path, with: .color(.igenConstellationLine.opacity(0.7)), lineWidth: 0.9 * scale)
      }

      for (index, point) in constellation.points.enumerated() {
        // 収束前の散らばり位置は星ごとに決め、収束は少しずつ遅らせる
        let scattered = Self.scatteredPoint(index: index)
        let delayedProgress = min(max(starProgress * 1.3 - Double(index % 7) * 0.04, 0), 1)
        let position = CGPoint(
          x: (scattered.x + (point.x - scattered.x) * delayedProgress) * scale,
          y: (scattered.y + (point.y - scattered.y) * delayedProgress) * scale
        )
        let radius = 1.7 * scale
        let rect = CGRect(x: position.x - radius, y: position.y - radius, width: radius * 2, height: radius * 2)
        var starContext = context
        starContext.addFilter(.shadow(color: .igenGold.opacity(0.8), radius: 2 * scale))
        starContext.fill(Path(ellipseIn: rect), with: .color(.igenGoldBright))
      }
    }
  }

  /// 収束前の散らばり位置 (0–100)。シード固定の擬似乱数で毎回同じ散らばりにする
  private static func scatteredPoint(index: Int) -> CGPoint {
    var seed = UInt64(index) &* 2_862_933_555_777_941_757 &+ 3_037_000_493
    func next() -> Double {
      seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
      return Double(seed >> 33) / Double(UInt64(1) << 31)
    }
    return CGPoint(x: next() * 140 - 20, y: next() * 140 - 20)
  }
}

struct ConstellationAvatar_Previews: PreviewProvider {
  static var previews: some View {
    ConstellationAvatar(constellation: ConstellationData.constellation(for: "seneca"))
      .frame(width: 130, height: 130)
      .background(Color.igenSheet)
  }
}
