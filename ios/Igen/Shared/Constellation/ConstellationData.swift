import Foundation

/// 星座線アバター 1 体ぶんの座標データ。
/// points は 0–100 に正規化した星の座標、lines は points のインデックスの組
/// (design_handoff_igen/igen-data.js と同じ形式)
struct Constellation {
  var points: [CGPoint]
  var lines: [(Int, Int)]
}

/// 人物 id → 星座線データ。新しい偉人を名言 DB に追加したらここにも座標を追加する
enum ConstellationData {
  static let byPersonId: [String: Constellation] = [
    "seneca": Constellation(
      points: [
        CGPoint(x: 50, y: 10), CGPoint(x: 43, y: 16), CGPoint(x: 45, y: 24), CGPoint(x: 55, y: 24),
        CGPoint(x: 57, y: 16), CGPoint(x: 36, y: 36), CGPoint(x: 64, y: 36), CGPoint(x: 74, y: 26),
        CGPoint(x: 30, y: 60), CGPoint(x: 26, y: 86), CGPoint(x: 50, y: 92), CGPoint(x: 68, y: 86),
        CGPoint(x: 58, y: 60), CGPoint(x: 44, y: 48),
      ],
      lines: [
        (0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (2, 5), (3, 6), (6, 7), (5, 8), (8, 9), (9, 10),
        (10, 11), (11, 12), (12, 6), (5, 13), (13, 12),
      ]
    ),
    "confucius": Constellation(
      points: [
        CGPoint(x: 50, y: 6), CGPoint(x: 44, y: 13), CGPoint(x: 56, y: 13), CGPoint(x: 45, y: 20),
        CGPoint(x: 55, y: 20), CGPoint(x: 50, y: 30), CGPoint(x: 36, y: 38), CGPoint(x: 64, y: 38),
        CGPoint(x: 28, y: 88), CGPoint(x: 50, y: 80), CGPoint(x: 72, y: 88), CGPoint(x: 50, y: 94),
      ],
      lines: [
        (0, 1), (0, 2), (1, 3), (2, 4), (3, 5), (4, 5), (3, 6), (4, 7), (6, 8), (7, 10), (8, 11),
        (10, 11), (6, 9), (7, 9),
      ]
    ),
    "nietzsche": Constellation(
      points: [
        CGPoint(x: 50, y: 9), CGPoint(x: 42, y: 16), CGPoint(x: 58, y: 16), CGPoint(x: 40, y: 27),
        CGPoint(x: 50, y: 24), CGPoint(x: 60, y: 27), CGPoint(x: 35, y: 40), CGPoint(x: 65, y: 40),
        CGPoint(x: 30, y: 70), CGPoint(x: 70, y: 70), CGPoint(x: 42, y: 90), CGPoint(x: 58, y: 90),
      ],
      lines: [
        (0, 1), (0, 2), (1, 3), (2, 5), (3, 4), (4, 5), (3, 6), (5, 7), (6, 7), (6, 8), (7, 9),
        (8, 10), (9, 11), (10, 11),
      ]
    ),
    // 能楽師の構え (右手に扇を掲げる姿) をイメージした線
    "zeami": Constellation(
      points: [
        CGPoint(x: 50, y: 8), CGPoint(x: 44, y: 14), CGPoint(x: 46, y: 22), CGPoint(x: 54, y: 22),
        CGPoint(x: 56, y: 14), CGPoint(x: 38, y: 34), CGPoint(x: 62, y: 34), CGPoint(x: 74, y: 26),
        CGPoint(x: 82, y: 18), CGPoint(x: 32, y: 60), CGPoint(x: 28, y: 88), CGPoint(x: 50, y: 84),
        CGPoint(x: 68, y: 88), CGPoint(x: 58, y: 58), CGPoint(x: 44, y: 46),
      ],
      lines: [
        (0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (2, 5), (3, 6), (6, 7), (7, 8), (5, 9), (9, 10),
        (10, 11), (11, 12), (12, 13), (13, 6), (5, 14), (14, 13),
      ]
    ),
    // 笠をかぶり杖をつく旅姿をイメージした線
    "basho": Constellation(
      points: [
        CGPoint(x: 50, y: 6), CGPoint(x: 38, y: 14), CGPoint(x: 62, y: 14), CGPoint(x: 46, y: 20),
        CGPoint(x: 54, y: 20), CGPoint(x: 36, y: 36), CGPoint(x: 64, y: 36), CGPoint(x: 72, y: 30),
        CGPoint(x: 76, y: 54), CGPoint(x: 74, y: 80), CGPoint(x: 30, y: 62), CGPoint(x: 26, y: 88),
        CGPoint(x: 48, y: 90), CGPoint(x: 62, y: 84), CGPoint(x: 52, y: 58),
      ],
      lines: [
        (0, 1), (0, 2), (1, 3), (2, 4), (3, 4), (3, 5), (4, 6), (6, 7), (7, 8), (8, 9), (5, 10),
        (10, 11), (11, 12), (12, 13), (13, 14), (14, 6), (5, 14),
      ]
    ),
  ]

  /// 人物が特定できない・座標未収録のときの汎用の星のかたまり (ことわざの演出などで使う)
  static let fallback = Constellation(
    points: [
      CGPoint(x: 50, y: 18), CGPoint(x: 34, y: 34), CGPoint(x: 66, y: 34), CGPoint(x: 26, y: 58),
      CGPoint(x: 50, y: 50), CGPoint(x: 74, y: 58), CGPoint(x: 38, y: 80), CGPoint(x: 62, y: 80),
    ],
    lines: [(0, 1), (0, 2), (1, 4), (2, 4), (3, 4), (4, 5), (4, 6), (4, 7)]
  )

  /// 人物 id から星座線データを引く。未収録なら fallback
  static func constellation(for personId: String?) -> Constellation {
    if let personId, let constellation = byPersonId[personId] {
      return constellation
    }
    return fallback
  }
}
