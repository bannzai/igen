import SwiftUI

// MARK: - デザイントークンのタイポグラフィ (design_handoff_igen/README.md「Design Tokens」)

extension Font {
  /// 格言・見出し・偉人名に使う明朝体 (Shippori Mincho。バンドルフォント)
  static func igenSerif(size: CGFloat, weight: Weight = .regular) -> Font {
    switch weight {
    case .bold:
      return .custom("ShipporiMincho-Bold", size: size)
    case .semibold:
      return .custom("ShipporiMincho-SemiBold", size: size)
    case .medium:
      return .custom("ShipporiMincho-Medium", size: size)
    default:
      return .custom("ShipporiMincho-Regular", size: size)
    }
  }

  /// 原文の書体。欧文はイタリック (Georgia。デザイン指定)、
  /// CJK (ja / zh) は Georgia にグリフがなくフォールバックになるため明朝体で表示する
  static func igenOriginalText(size: CGFloat, originalLanguage: String) -> Font {
    if originalLanguage == "ja" || originalLanguage == "zh" {
      return igenSerif(size: size)
    }
    return .custom("Georgia-Italic", size: size)
  }
}
