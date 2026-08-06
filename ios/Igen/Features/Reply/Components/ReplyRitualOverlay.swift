import SwiftUI

/// 返書の登場演出 (リチュアル)。散らばった星がアバター座標へ収束し、星座線が描かれ、
/// 偉人名がリビールされてから返書表示へ移る。初回はリッチ、2 回目以降は短縮 (テンポを守る)
struct ReplyRitualOverlay: View {
  var letter: Letter
  /// 2 回目以降の短縮演出にするか
  var short: Bool
  var onFinished: () -> Void

  @State var start = Date.now

  /// 演出の区切り時刻 (design_handoff_igen/README.md「回答演出」のフェーズ表)
  private var schedule: (appear: Double, converge: Double, lines: Double, total: Double) {
    short ? (0.09, 1.1, 2.1, 3.1) : (0.14, 2.3, 4.4, 6.2)
  }

  var body: some View {
    TimelineView(.animation) { timeline in
      let elapsed = timeline.date.timeIntervalSince(start)
      ZStack {
        Color(red: 5 / 255, green: 6 / 255, blue: 18 / 255).opacity(0.45)
          .ignoresSafeArea()

        VStack(spacing: 24) {
          Spacer()

          if elapsed >= schedule.appear {
            ConstellationAvatar(
              constellation: ConstellationData.constellation(for: letter.personId),
              starProgress: progress(elapsed, from: schedule.appear, to: schedule.converge),
              lineProgress: progress(elapsed, from: schedule.converge, to: schedule.lines)
            )
            .frame(width: 180, height: 180)
          } else {
            Color.clear.frame(width: 180, height: 180)
          }

          if elapsed >= schedule.lines {
            VStack(spacing: 8) {
              if let person = letter.person {
                Text(person.name.localized(letter.language))
                  .font(.igenSerif(size: 24, weight: .semibold))
                  .foregroundStyle(Color.igenText)
                // ja: %@が、あなたの空に現れました
                Text("\(person.name.localized(letter.language)) appeared in your sky")
                  .font(.system(size: 12))
                  .foregroundStyle(Color.igenText.opacity(0.6))
              }
            }
            .transition(.opacity)
          } else {
            // ja: 星々が、ことばを探しています…
            Text("The stars are searching for words…")
              .font(.igenSerif(size: 14))
              .foregroundStyle(Color.igenText.opacity(0.4 + 0.6 * (0.5 + 0.5 * sin(elapsed * 3))))
          }

          Spacer()

          Button {
            onFinished()
          } label: {
            // ja: スキップ
            Text("Skip")
              .font(.system(size: 13))
              .foregroundStyle(Color.igenText.opacity(0.6))
              .padding(.vertical, 10)
              .padding(.horizontal, 24)
          }
        }
        .padding(.vertical, 32)
      }
    }
    .task {
      // 演出終了で自動的に返書表示へ (スキップ時はこの task がキャンセルされる)
      try? await Task.sleep(for: .seconds(schedule.total))
      if !Task.isCancelled {
        onFinished()
      }
    }
  }

  private func progress(_ elapsed: Double, from: Double, to: Double) -> Double {
    if elapsed <= from {
      return 0
    }
    if elapsed >= to {
      return 1
    }
    // ease-out で減速しながら収束させる
    let linear = (elapsed - from) / (to - from)
    return 1 - pow(1 - linear, 3)
  }
}

struct ReplyRitualOverlay_Previews: PreviewProvider {
  static var previews: some View {
    ZStack {
      StarfieldBackground()
      ReplyRitualOverlay(letter: ReplyPage_Previews.senecaLetter, short: false, onFinished: {})
    }
  }
}
