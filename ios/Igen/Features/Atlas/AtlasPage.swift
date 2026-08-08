import FirebaseAnalytics
import FirebaseAuth
import SwiftUI

/// 偉人図鑑 (星図)。相談を通じて出会った偉人が星座として夜空に灯り、未出会いは暗い星のみ表示する
struct AtlasPage: View {
  @State var encounters: [Encounter]?
  @State var loadFailed = false
  @State var newlyMetPersonIds: Set<String> = []
  /// 表示済み記録の保存先キー (匿名 UID を含む)。取得完了時に確定する
  @State var seenKey: String?

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
          AtlasPageBody(encounters: encounters, newlyMetPersonIds: newlyMetPersonIds) { personId in
            markPersonSeen(personId: personId)
          }
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
        // 「新しい星座が夜空に灯る」演出の表示済み記録は匿名 UID ごとに分ける
        // (401 回復でユーザーを作り直した場合に、前のユーザーの表示済み状態を引き継がないため)。
        // fetchEncounters が認証を確保済みのため currentUser は取得できる
        let key = "atlasSeenPersonIds.\(Auth.auth().currentUser?.uid ?? "unknown")"
        seenKey = key
        let seen = Set(
          (UserDefaults.standard.string(forKey: key) ?? "").split(separator: ",")
            .map(String.init)
        )
        newlyMetPersonIds = Set(fetched.map(\.personId)).subtracting(seen)
        encounters = fetched
        // 押下 (home_atlas_button_pressed) と分けて、星図が実際に表示できた数を記録する
        Analytics.logEvent("atlas_loaded", parameters: ["encounters_count": fetched.count])
      } catch {
        loadFailed = true
      }
    }
  }

  /// 点灯演出を最後まで見た (または演出なしで表示された) 人物だけを表示済みとして永続化する。
  /// 途中でアプリを閉じても、未再生の演出は次回また流れる
  private func markPersonSeen(personId: String) {
    if let seenKey {
      let seen = Set(
        (UserDefaults.standard.string(forKey: seenKey) ?? "").split(separator: ",").map(String.init)
      ).union([personId])
      UserDefaults.standard.set(seen.sorted().joined(separator: ","), forKey: seenKey)
    }
  }
}

/// 取得済みの出会い一覧から星図 (星座の配置・件数) を表示する
private struct AtlasPageBody: View {
  var encounters: [Encounter]
  var newlyMetPersonIds: Set<String>
  // 表示済みの永続化は UserDefaults のキーを持つ AtlasPage の責務のため、演出完了の通知だけを返す
  var onRevealFinished: (String) -> Void

  @State var selectedEncounter: Encounter?

  /// 星図上の配置 (0–100)。名言 DB に人物を追加したらここにも枠を追加する
  private static let slots: [(personId: String, x: Double, y: Double, scale: Double)] = [
    ("seneca", 26, 18, 1.0),
    ("confucius", 70, 14, 0.85),
    ("nietzsche", 30, 48, 0.9),
    ("zeami", 72, 44, 0.95),
    ("basho", 48, 76, 0.9),
  ]

  var body: some View {
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
            reveals: newlyMetPersonIds.contains(slot.personId),
            onRevealFinished: {
              onRevealFinished(slot.personId)
            }
          ) {
            Analytics.logEvent("atlas_person_button_pressed", parameters: nil)
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

    // 表示できる枠 (slots) に存在する人物だけを数える (旧バージョンに新人物が届いても件数が枠を超えない)
    let visibleMetCount = encounters.filter { encounter in
      Self.slots.contains { $0.personId == encounter.personId }
    }.count
    // ja: 出会った偉人 %lld / %lld
    Text("Great figures you have met: \(visibleMetCount) / \(Self.slots.count)")
      .font(.system(size: 12))
      .foregroundStyle(Color.igenTextGold)
      .padding(.bottom, 16)

    Color.clear.frame(height: 0)
      .sheet(item: $selectedEncounter) { encounter in
        // その偉人の返書はシート側で personId 指定で取得する (星図を開くだけで全返書を読まない)。
        // デザイン指定の下部プロフィールシートとして表示し、星図とのつながりを保つ
        AtlasProfilePage(encounter: encounter)
          .presentationDetents([.medium, .large])
      }
  }
}

/// 出会い済みの星座 1 体。新規の出会いは線が描き上がる演出付きで灯る
struct AtlasMetConstellation: View {
  var encounter: Encounter
  var scale: Double
  var reveals: Bool
  /// 点灯演出が最後まで表示された (演出なし表示を含む) ときに一度だけ呼ばれる
  var onRevealFinished: () -> Void
  var onPressed: () -> Void

  @State var start = Date.now
  /// 点灯演出が完了したか。完了後は TimelineView を止め、毎フレームの再評価を続けない
  @State var revealFinished = false
  @Environment(\.accessibilityReduceMotion) var reduceMotion
  @Environment(\.scenePhase) var scenePhase

  var body: some View {
    Button {
      onPressed()
    } label: {
      VStack(spacing: 4) {
        // 「視差効果を減らす」設定では点灯演出を流さず、最初から静的な星座を表示する
        if reveals && !revealFinished && !reduceMotion {
          TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSince(start)
            ConstellationAvatar(
              constellation: ConstellationData.constellation(for: encounter.personId),
              starProgress: min(elapsed / 0.8, 1),
              lineProgress: min(max((elapsed - 0.6) / 1.6, 0), 1)
            )
            .frame(width: 74 * scale, height: 74 * scale)
          }
          // scenePhase を id にして、バックグラウンド復帰時に task を再開する
          // (前面に戻るまで演出の完了扱いを保留し、TimelineView も止まったままにしない)
          .task(id: scenePhase) {
            // 演出をアプリが前面にある状態で見終えた場合だけ、静的表示へ切り替えて表示済みとして記録する。
            // 画面を離れた (sleep がキャンセルされた) 場合や背面のままの場合は記録せず、次回また演出を流す
            if scenePhase != .active {
              return
            }
            do {
              try await Task.sleep(for: .seconds(2.4))
            } catch {
              return
            }
            revealFinished = true
            onRevealFinished()
          }
        } else {
          ConstellationAvatar(constellation: ConstellationData.constellation(for: encounter.personId))
            .frame(width: 74 * scale, height: 74 * scale)
            .onAppear {
              // Reduce Motion で演出を流さない場合も、表示された時点で表示済みとして記録する
              if reveals && reduceMotion {
                onRevealFinished()
              }
            }
        }
        // 端末言語ではなくアプリに適用中のローカライズで判定する (アプリ単位の言語切り替えに追随)
        Text(encounter.person.name.localized(Bundle.main.preferredLocalizations.first == "ja" ? "ja" : "en"))
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
