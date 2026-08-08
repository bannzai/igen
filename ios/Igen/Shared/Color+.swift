import SwiftUI

// MARK: - デザイントークンの色 (design_handoff_igen/README.md「Design Tokens」)

extension Color {
  /// 金 (明)。ロゴ・格言・星
  static let igenGoldBright = Color(red: 245 / 255, green: 223 / 255, blue: 164 / 255)
  /// 金 (主アクセント)。枠・ラベル
  static let igenGold = Color(red: 232 / 255, green: 201 / 255, blue: 122 / 255)
  /// 金 (暗)。グラデーションの下端
  static let igenGoldDark = Color(red: 201 / 255, green: 162 / 255, blue: 77 / 255)
  /// 文字用の淡金
  static let igenTextGold = Color(red: 232 / 255, green: 217 / 255, blue: 176 / 255)
  /// 本文
  static let igenText = Color(red: 236 / 255, green: 231 / 255, blue: 244 / 255)
  /// 金グラデーションのボタン上の濃色
  static let igenButtonText = Color(red: 36 / 255, green: 22 / 255, blue: 80 / 255)
  /// カード面
  static let igenCard = Color(red: 16 / 255, green: 15 / 255, blue: 48 / 255)
  /// シート面
  static let igenSheet = Color(red: 12 / 255, green: 11 / 255, blue: 38 / 255)
  /// 対訳ブロック面
  static let igenBilingual = Color(red: 12 / 255, green: 12 / 255, blue: 40 / 255)
  /// 星座線
  static let igenConstellationLine = Color(red: 190 / 255, green: 205 / 255, blue: 255 / 255)
}
