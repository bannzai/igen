import SwiftUI

/// 返書のブロックを 0.15s 刻みの stagger で出現させる修飾子
/// (opacity + blur + 上昇。design_handoff_igen/README.md の igenReveal)
private struct IgenReveal: ViewModifier {
  var index: Int
  @State var revealed = false

  func body(content: Content) -> some View {
    content
      .opacity(revealed ? 1 : 0)
      .blur(radius: revealed ? 0 : 6)
      .offset(y: revealed ? 0 : 10)
      .onAppear {
        withAnimation(.easeOut(duration: 0.9).delay(Double(index) * 0.15)) {
          revealed = true
        }
      }
  }
}

extension View {
  /// 返書ブロックの stagger 出現。index の順に 0.15s ずつ遅れて現れる
  func igenReveal(_ index: Int) -> some View {
    modifier(IgenReveal(index: index))
  }
}
