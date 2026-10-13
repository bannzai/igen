import Foundation
import Testing

@testable import Igen

struct AppStoreScreenshotCanvasTests {
  @Test
  func iphone69InchPortraitIsIphone() {
    #expect(AppStoreScreenshotCanvas(screenSize: CGSize(width: 440, height: 956)) == .iphone)
  }

  @Test
  func duoOuterDisplayIsDuoOuter() {
    #expect(AppStoreScreenshotCanvas(screenSize: CGSize(width: 466, height: 678)) == .duoOuter)
  }

  @Test
  func duoInnerDisplayLandscapeIsDuoInner() {
    #expect(AppStoreScreenshotCanvas(screenSize: CGSize(width: 951, height: 669)) == .duoInner)
  }
}
