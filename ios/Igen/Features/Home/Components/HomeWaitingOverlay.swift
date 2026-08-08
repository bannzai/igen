import SwiftUI

/// 返書生成を待つ間のオーバーレイ。星が集まる本演出は返書画面 issue (#8) で作り込む
struct HomeWaitingOverlay: View {
  @State var pulsing = false
  @Environment(\.accessibilityReduceMotion) var reduceMotion

  var body: some View {
    ZStack {
      Color(red: 5 / 255, green: 6 / 255, blue: 18 / 255).opacity(0.45)
        .ignoresSafeArea()
      // ja: 星々が、ことばを探しています…
      Text("The stars are searching for words…")
        .font(.system(size: 14, design: .serif))
        .foregroundStyle(Color(red: 236 / 255, green: 231 / 255, blue: 244 / 255))
        .opacity(pulsing ? 0.4 : 1)
        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulsing)
        .onAppear {
          // 「視差効果を減らす」設定では明滅させない (返書生成中は数分続きうるため)
          if !reduceMotion {
            pulsing = true
          }
        }
    }
  }
}

struct HomeWaitingOverlay_Previews: PreviewProvider {
  static var previews: some View {
    HomeWaitingOverlay()
  }
}
