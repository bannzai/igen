import UIKit

@MainActor
final class PhotoLibraryImageSaver: NSObject {
  private var continuation: CheckedContinuation<Bool, Never>?

  /// ユーザーが明示的に保存するたび新しい画像を追加するため、この操作は冪等ではない。
  func save(_ image: UIImage) async -> Bool {
    await withCheckedContinuation { continuation in
      self.continuation = continuation
      UIImageWriteToSavedPhotosAlbum(
        image,
        self,
        #selector(image(_:didFinishSavingWithError:contextInfo:)),
        nil
      )
    }
  }

  @objc
  private func image(
    _ image: UIImage,
    didFinishSavingWithError error: Error?,
    contextInfo: UnsafeMutableRawPointer?
  ) {
    continuation?.resume(returning: error == nil)
    continuation = nil
  }
}
