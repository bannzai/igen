import SwiftUI
import UIKit

/// 共有先での完了・キャンセルを受け取れる共有シート (UIActivityViewController のラッパー)
struct ShareActivitySheet: UIViewControllerRepresentable {
  var cardImage: UIImage
  // 共有の成否は UIKit の completion でしか取れないため、コールバックで親へ伝える
  var onCompleted: (Bool) -> Void

  func makeUIViewController(context: Context) -> UIActivityViewController {
    let controller = UIActivityViewController(activityItems: [cardImage], applicationActivities: nil)
    controller.completionWithItemsHandler = { _, completed, _, _ in
      onCompleted(completed)
    }
    return controller
  }

  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
