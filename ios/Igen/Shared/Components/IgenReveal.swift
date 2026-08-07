import SwiftUI

/// 返書のブロックを 0.15s 刻みの stagger で出現させる修飾子
/// (opacity + blur + 上昇。design_handoff_igen/README.md の igenReveal)
private struct IgenReveal: ViewModifier {
  var index: Int
  var enabled: Bool
  @State var revealed = false
  @Environment(\.accessibilityReduceMotion) var reduceMotion

  func body(content: Content) -> some View {
    content
      .opacity(enabled && !revealed ? 0 : 1)
      .blur(radius: enabled && !revealed ? 6 : 0)
      .offset(y: enabled && !revealed ? 10 : 0)
      .onAppear {
        // 「視差効果を減らす」設定では blur・上昇・stagger の演出を行わず即時表示する
        if reduceMotion {
          revealed = true
          return
        }
        withAnimation(.easeOut(duration: 0.9).delay(Double(index) * 0.15)) {
          revealed = true
        }
      }
  }
}

extension View {
  /// 返書ブロックの stagger 出現。index の順に 0.15s ずつ遅れて現れる。
  /// enabled が false のとき (振り返りからの再訪など) は演出せず即時表示する
  // 標準 API のミラーではないが、既存呼び出しと修飾子らしい読み味を保つため第一引数のラベルを省略している
  func igenReveal(_ index: Int, enabled: Bool = true) -> some View {
    modifier(IgenReveal(index: index, enabled: enabled))
  }
}
