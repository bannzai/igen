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

  /// ラテン語などの欧文原文に使うイタリック (Georgia。デザイン指定)
  static func igenOriginalText(size: CGFloat) -> Font {
    .custom("Georgia-Italic", size: size)
  }
}
