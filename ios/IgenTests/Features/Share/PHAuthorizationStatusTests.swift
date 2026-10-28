import Photos
import Testing

@testable import Igen

struct PHAuthorizationStatusTests {
  @Test
  func authorizedStatusesAllowAddingAssets() {
    #expect(PHAuthorizationStatus.authorized.allowsAddingAssets)
    #expect(PHAuthorizationStatus.limited.allowsAddingAssets)
  }

  @Test
  func unauthorizedStatusesDoNotAllowAddingAssets() {
    #expect(!PHAuthorizationStatus.notDetermined.allowsAddingAssets)
    #expect(!PHAuthorizationStatus.restricted.allowsAddingAssets)
    #expect(!PHAuthorizationStatus.denied.allowsAddingAssets)
  }
}
