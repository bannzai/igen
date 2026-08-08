import SwiftUI
import UIKit

/// 共有先での完了・キャンセルを受け取れる共有シート (UIActivityViewController のラッパー)
struct ShareActivitySheet: UIViewControllerRepresentable {
  var cardImage: UIImage
  // 共有の成否と選ばれた共有先は UIKit の completion でしか取れないため、コールバックで親へ伝える
  // (保存・コピーを SNS 共有と区別して計測できるよう activityType も渡す)
  var onCompleted: (Bool, UIActivity.ActivityType?) -> Void

  func makeUIViewController(context: Context) -> UIActivityViewController {
    let controller = UIActivityViewController(activityItems: [cardImage], applicationActivities: nil)
    controller.completionWithItemsHandler = { activityType, completed, _, _ in
      onCompleted(completed, activityType)
    }
    return controller
  }

  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
