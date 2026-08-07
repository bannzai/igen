import SwiftUI

/// 偉人図鑑 (星図)。相談を通じて出会った偉人が星座として夜空に灯り、未出会いは暗い星のみ表示する
struct AtlasPage: View {
  @State var encounters: [Encounter]?
  @State var loadFailed = false
  @State var selectedEncounter: Encounter?
  /// 「新しい星座が夜空に灯る」演出を一度だけ流すための、表示済み人物 id (カンマ区切り)
  @AppStorage("atlasSeenPersonIds") var atlasSeenPersonIds = ""
  @State var newlyMetPersonIds: Set<String> = []

  /// 星図上の配置 (0–100)。名言 DB に人物を追加したらここにも枠を追加する
  private static let slots: [(personId: String, x: Double, y: Double, scale: Double)] = [
    ("seneca", 26, 18, 1.0),
    ("confucius", 70, 14, 0.85),
    ("nietzsche", 30, 48, 0.9),
    ("zeami", 72, 44, 0.95),
    ("basho", 48, 76, 0.9),
  ]

  var body: some View {
    ZStack {
      StarfieldBackground()

      VStack(spacing: 12) {
        // ja: あなたの星図
        Text("Your Star Atlas")
          .font(.system(size: 16, weight: .semibold, design: .serif))
          .tracking(4)
          .foregroundStyle(Color.igenGoldBright)
          .padding(.vertical, 8)

        // ja: 相談を通じて出会った偉人が、星座としてあなたの夜空に増えていきます
        Text("Great figures you've met through your letters light up as constellations in your night sky")
          .font(.system(size: 12))
          .multilineTextAlignment(.center)
          .foregroundStyle(Color.igenText.opacity(0.6))
          .padding(.horizontal, 24)

        if loadFailed {
          // ja: 星図を読み込めませんでした しばらくしてからもう一度お試しください
          Text("Your star atlas could not be loaded. Please try again later.")
            .font(.system(size: 13))
            .foregroundStyle(Color.igenText.opacity(0.7))
            .padding(.vertical, 32)
          Spacer()
        } else if let encounters {
          GeometryReader { geometry in
            ForEach(Self.slots, id: \.personId) { slot in
              let position = CGPoint(
                x: slot.x / 100 * geometry.size.width,
                y: slot.y / 100 * geometry.size.height
              )
              if let encounter = encounters.first(where: { $0.personId == slot.personId }) {
                AtlasMetConstellation(
                  encounter: encounter,
                  scale: slot.scale,
                  reveals: newlyMetPersonIds.contains(slot.personId)
                ) {
                  selectedEncounter = encounter
                }
                .position(x: position.x + 37 * slot.scale, y: position.y + 45 * slot.scale)
              } else {
                AtlasUnmetCluster()
                  .position(x: position.x + 20, y: position.y + 20)
              }
            }
          }
          .padding(.horizontal, 12)

          // ja: 出会った偉人 %lld / %lld
          Text("Great figures you have met: \(encounters.count) / \(Self.slots.count)")
            .font(.system(size: 12))
            .foregroundStyle(Color.igenTextGold)
            .padding(.bottom, 16)
        } else {
          Spacer()
          ProgressView()
            .tint(Color.igenGold)
          Spacer()
        }
      }
    }
    .task {
      do {
        let fetched = try await EncountersStore.fetchEncounters()
        let seen = Set(atlasSeenPersonIds.split(separator: ",").map(String.init))
        newlyMetPersonIds = Set(fetched.map(\.personId)).subtracting(seen)
        encounters = fetched
        atlasSeenPersonIds = fetched.map(\.personId).sorted().joined(separator: ",")
      } catch {
        loadFailed = true
      }
    }
    .sheet(item: $selectedEncounter) { encounter in
      // その偉人の返書はシート側で personId 指定で取得する (星図を開くだけで全返書を読まない)
      AtlasProfileSheet(encounter: encounter)
    }
  }
}

/// 出会い済みの星座 1 体。新規の出会いは線が描き上がる演出付きで灯る
struct AtlasMetConstellation: View {
  var encounter: Encounter
  var scale: Double
  var reveals: Bool
  var onPressed: () -> Void

  @State var start = Date.now
  /// 点灯演出が完了したか。完了後は TimelineView を止め、毎フレームの再評価を続けない
  @State var revealFinished = false

  var body: some View {
    Button {
      onPressed()
    } label: {
      VStack(spacing: 4) {
        if reveals && !revealFinished {
          TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSince(start)
            ConstellationAvatar(
              constellation: ConstellationData.constellation(for: encounter.personId),
              starProgress: min(elapsed / 0.8, 1),
              lineProgress: min(max((elapsed - 0.6) / 1.6, 0), 1)
            )
            .frame(width: 74 * scale, height: 74 * scale)
          }
          .task {
            // 線の描き上がり (0.6s 遅延 + 1.6s) が終わったら静的表示へ切り替える
            try? await Task.sleep(for: .seconds(2.4))
            revealFinished = true
          }
        } else {
          ConstellationAvatar(constellation: ConstellationData.constellation(for: encounter.personId))
            .frame(width: 74 * scale, height: 74 * scale)
        }
        Text(encounter.person.name.localized(Locale.autoupdatingCurrent.language.languageCode?.identifier == "ja" ? "ja" : "en"))
          .font(.system(size: 10))
          .foregroundStyle(Color.igenTextGold)
      }
    }
  }
}

/// 未出会いの枠。暗い点のみのクラスタで、線も名前も出さない
struct AtlasUnmetCluster: View {
  var body: some View {
    Canvas { context, size in
      let dots: [CGPoint] = [
        CGPoint(x: 0.1, y: 0.1), CGPoint(x: 0.7, y: 0.3), CGPoint(x: 0.3, y: 0.7),
        CGPoint(x: 0.9, y: 0.8),
      ]
      for dot in dots {
        let rect = CGRect(x: dot.x * size.width - 3, y: dot.y * size.height - 3, width: 6, height: 6)
        context.fill(
          Path(ellipseIn: rect),
          with: .color(Color(red: 215 / 255, green: 225 / 255, blue: 255 / 255).opacity(0.16))
        )
      }
    }
    .frame(width: 40, height: 40)
  }
}

struct AtlasPage_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      AtlasPage(encounters: [
        Encounter(
          personId: "seneca",
          person: ReplyPage_Previews.senecaLetter.person!,
          lastQuoteId: "seneca-non-quia-difficilia",
          createdAt: nil,
          updatedAt: nil
        )
      ])
    }
  }
}
