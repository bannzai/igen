import SwiftUI

struct HomePage: View {
  var body: some View {
    ZStack {
      // 星空アニメーション背景はホーム画面の実装 issue で置き換える (それまでの仮のグラデーション)
      LinearGradient(
        colors: [
          Color(red: 7 / 255, green: 10 / 255, blue: 28 / 255),
          Color(red: 35 / 255, green: 22 / 255, blue: 80 / 255),
        ],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()

      // ja: きょうのできごと・お悩みを どうぞ
      Text("Tell me about your day, or what's on your mind")
        .foregroundStyle(Color(red: 236 / 255, green: 231 / 255, blue: 244 / 255))
    }
  }
}

struct HomePage_Previews: PreviewProvider {
  static var previews: some View {
    HomePage()
  }
}
