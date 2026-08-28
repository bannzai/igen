import SwiftUI

/// オンボーディング 1 画面目。世界観と価値の宣言。
/// 散らばった星がセネカの星座線に描き上がる登場演出で、「偉人が現れる」体験を先に見せる (8BP #1)
struct OnboardingWelcomeStep: View {
  @State var start = Date.now
  /// 登場演出が完了したか。完了後は TimelineView を止め、毎フレームの再評価を続けない
  @State var revealFinished = false
  @Environment(\.accessibilityReduceMotion) var reduceMotion

  var body: some View {
    VStack(spacing: 24) {
      // ja: 偉言
      Text("IGEN")
        .font(.igenSerif(size: 20, weight: .bold))
        .tracking(8)
        .foregroundStyle(Color.igenGoldBright)
        .shadow(color: Color.igenGold.opacity(0.45), radius: 16)
        .padding(.vertical, 8)

      // 「視差効果を減らす」設定では演出を流さず、最初から静的な星座を表示する
      if reduceMotion || revealFinished {
        ConstellationAvatar(constellation: ConstellationData.constellation(for: "seneca"))
          .frame(width: 180, height: 180)
      } else {
        TimelineView(.animation) { timeline in
          let elapsed = timeline.date.timeIntervalSince(start)
          ConstellationAvatar(
            constellation: ConstellationData.constellation(for: "seneca"),
            starProgress: min(elapsed / 1.6, 1),
            lineProgress: min(max((elapsed - 1.2) / 1.6, 0), 1)
          )
          .frame(width: 180, height: 180)
        }
        .task {
          // 線の描画が終わる時刻まで待ってから静的表示に切り替える (画面を離れた場合はキャンセルされ、次回また流れる)
          do {
            try await Task.sleep(for: .seconds(3))
          } catch {
            return
          }
          revealFinished = true
        }
      }

      // ja: 今夜の悩みに 時を越えた返書を
      Text("A letter from across time for tonight")
        .font(.igenSerif(size: 22, weight: .semibold))
        .multilineTextAlignment(.center)
        .lineSpacing(8)
        .foregroundStyle(Color.igenText)

      // ja: 書くことは、自分と向き合う時間。偉言は、その時間に偉人のことばを添えます
      Text("Writing is time spent facing yourself. IGEN adds the words of the greats to that time.")
        .font(.system(size: 14))
        .multilineTextAlignment(.center)
        .lineSpacing(9)
        .foregroundStyle(Color.igenText.opacity(0.7))
    }
    .padding(.vertical, 16)
  }
}

struct OnboardingWelcomeStep_Previews: PreviewProvider {
  static var previews: some View {
    ZStack {
      StarfieldBackground()
      OnboardingWelcomeStep()
        .padding(.horizontal, 24)
    }
  }
}
