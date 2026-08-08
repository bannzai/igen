import SwiftUI

/// 全画面共通の星空背景。深い藍〜紫のグラデーションの上で、
/// 星の明滅・紫の霧の横流れ・流れ星を常時アニメーションで描く (design_handoff_igen/README.md「Interactions & Behavior」)。
/// 常時アニメーションを伴う描画のため、パフォーマンスの例外規定 (.claude/rules/coding-rules.md) に該当する。
/// 星の座標・位相は初期化時に決定し、毎フレームは描画だけを行う
struct StarfieldBackground: View {
  /// 星 1 つの描画パラメータ
  private struct Star {
    var x: Double
    var y: Double
    var radius: Double
    var phase: Double
    var speed: Double
  }

  // デザイン指定の星の個数
  private static let starCount = 95

  // 乱数シードを固定した線形合同法で座標を決める (起動ごとに星空が変わらないようにする)
  private static let stars: [Star] = {
    var seed: UInt64 = 0x16E4_0001
    func next() -> Double {
      seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
      return Double(seed >> 33) / Double(UInt64(1) << 31)
    }
    return (0..<starCount).map { _ in
      Star(
        x: next(),
        y: next(),
        radius: 0.6 + next() * 1.4,
        phase: next() * 2 * .pi,
        speed: 0.4 + next() * 0.9
      )
    }
  }()

  @Environment(\.accessibilityReduceMotion) var reduceMotion

  var body: some View {
    // 「視差効果を減らす」設定では描画更新を止め、固定時刻の静止背景にする (流れ星も描かない)
    TimelineView(.animation(minimumInterval: nil, paused: reduceMotion)) { timeline in
      Canvas { context, size in
        let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
        drawMist(context: context, size: size, time: time)
        drawStars(context: context, size: size, time: time)
        if reduceMotion == false {
          drawShootingStar(context: context, size: size, time: time)
        }
      }
    }
    .background(
      LinearGradient(
        stops: [
          .init(color: Color(red: 7 / 255, green: 10 / 255, blue: 28 / 255), location: 0),
          .init(color: Color(red: 13 / 255, green: 17 / 255, blue: 48 / 255), location: 0.45),
          .init(color: Color(red: 25 / 255, green: 18 / 255, blue: 67 / 255), location: 0.78),
          .init(color: Color(red: 35 / 255, green: 22 / 255, blue: 80 / 255), location: 1),
        ],
        startPoint: .top,
        endPoint: .bottom
      )
    )
    .ignoresSafeArea()
  }

  private func drawStars(context: GraphicsContext, size: CGSize, time: Double) {
    for star in Self.stars {
      // sin 波 + 個別位相での明滅
      let twinkle = 0.45 + 0.55 * (0.5 + 0.5 * sin(time * star.speed + star.phase))
      let rect = CGRect(
        x: star.x * size.width - star.radius,
        y: star.y * size.height - star.radius,
        width: star.radius * 2,
        height: star.radius * 2
      )
      context.fill(
        Path(ellipseIn: rect),
        with: .color(Color(red: 245 / 255, green: 223 / 255, blue: 164 / 255).opacity(twinkle))
      )
    }
  }

  private func drawMist(context: GraphicsContext, size: CGSize, time: Double) {
    // 紫の霧 3 枚がゆっくり横に流れる
    for index in 0..<3 {
      let drift =
        (time * (0.006 + Double(index) * 0.004) + Double(index) * 0.37)
        .truncatingRemainder(dividingBy: 1.4) - 0.2
      let center = CGPoint(
        x: drift * size.width,
        y: (0.25 + Double(index) * 0.28) * size.height
      )
      let mistRect = CGRect(
        x: center.x - size.width * 0.45,
        y: center.y - size.height * 0.12,
        width: size.width * 0.9,
        height: size.height * 0.24
      )
      var mistContext = context
      mistContext.addFilter(.blur(radius: 40))
      mistContext.fill(
        Path(ellipseIn: mistRect),
        with: .color(Color(red: 80 / 255, green: 60 / 255, blue: 160 / 255).opacity(0.10))
      )
    }
  }

  private func drawShootingStar(context: GraphicsContext, size: CGSize, time: Double) {
    // 一定間隔で 1 本の流れ星を描く。周期ごとに出現位置・角度を変える
    let period = 8.0
    let cycle = floor(time / period)
    let progress = (time - cycle * period) / 0.9
    if progress >= 1 {
      return
    }
    var seed = UInt64(cycle.truncatingRemainder(dividingBy: 100_000)) &+ 7
    func next() -> Double {
      seed = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
      return Double(seed >> 33) / Double(UInt64(1) << 31)
    }
    let start = CGPoint(x: (0.2 + next() * 0.7) * size.width, y: (0.05 + next() * 0.3) * size.height)
    let length = 90.0 + next() * 60
    let end = CGPoint(x: start.x - length, y: start.y + length * 0.55)
    let head = CGPoint(
      x: start.x + (end.x - start.x) * progress,
      y: start.y + (end.y - start.y) * progress
    )
    var path = Path()
    path.move(to: start)
    path.addLine(to: head)
    let fade = 1 - progress
    context.stroke(
      path,
      with: .linearGradient(
        Gradient(colors: [
          Color(red: 232 / 255, green: 201 / 255, blue: 122 / 255).opacity(0),
          Color(red: 245 / 255, green: 223 / 255, blue: 164 / 255).opacity(0.8 * fade),
        ]),
        startPoint: start,
        endPoint: head
      ),
      lineWidth: 1.4
    )
  }
}

struct StarfieldBackground_Previews: PreviewProvider {
  static var previews: some View {
    StarfieldBackground()
  }
}
