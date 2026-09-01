import Photos

extension PHAuthorizationStatus {
  var allowsAddingAssets: Bool {
    self == .authorized || self == .limited
  }
}
