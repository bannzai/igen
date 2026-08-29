#if DEBUG
  import SwiftUI

  /// App Store スクリーンショットの撮影端末 (iPhone 17 Pro Max、6.9 インチ) の画面サイズ (pt)。
  /// フレーム内のアプリ画面もこのサイズで描いてから縮小する
  enum AppStoreScreenshotDevice {
    static let screenSize = CGSize(width: 440, height: 956)
  }

  /// スクショ 1 枚のレイアウト。星空背景の上にキャッチコピー (上) とデバイスフレーム付きのアプリ画面 (下) を置く。
  /// フレームは画面下端で見切れる前提で組み、アプリ画面の下部にあるボタンは見せない
  struct AppStoreScreenshotFrameLayout<Content: View>: View {
    var title: LocalizedStringResource
    var subtitle: LocalizedStringResource
    @ViewBuilder var content: () -> Content

    var body: some View {
      ZStack {
        StarfieldBackground()

        VStack(spacing: 0) {
          VStack(spacing: 14) {
            Text(title)
              .font(.igenSerif(size: 34, weight: .semibold))
              .multilineTextAlignment(.center)
              .lineSpacing(10)
              .foregroundStyle(Color.igenGoldBright)
              .shadow(color: Color.igenGold.opacity(0.45), radius: 16)
            Text(subtitle)
              .font(.system(size: 17))
              .multilineTextAlignment(.center)
              .lineSpacing(6)
              .foregroundStyle(Color.igenText.opacity(0.75))
          }
          // フレームが画面外にはみ出しても見出しが縮められないよう、文言の高さを固定する
          .fixedSize(horizontal: false, vertical: true)
          .padding(.top, 88)
          .padding(.horizontal, 32)

          AppStoreScreenshotDeviceFrame(content: content)
            .padding(.top, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      }
      .ignoresSafeArea()
    }
  }

  /// iPhone 風のフレーム (角丸のベゼル + ステータスバー)。中身を端末のネイティブ画面サイズで描いてから縮小する
  struct AppStoreScreenshotDeviceFrame<Content: View>: View {
    @ViewBuilder var content: () -> Content

    // 画面幅に収まるようフレームを縮小する倍率
    private let scale: CGFloat = 0.86
    private let cornerRadius: CGFloat = 62
    private let bezelWidth: CGFloat = 12

    var body: some View {
      let size = AppStoreScreenshotDevice.screenSize
      content()
        .frame(width: size.width, height: size.height)
        .overlay(alignment: .top) {
          AppStoreScreenshotStatusBar()
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .padding(bezelWidth)
        .background(
          RoundedRectangle(cornerRadius: cornerRadius + bezelWidth, style: .continuous)
            .fill(Color(red: 14 / 255, green: 12 / 255, blue: 30 / 255))
        )
        .overlay(
          RoundedRectangle(cornerRadius: cornerRadius + bezelWidth, style: .continuous)
            .stroke(Color.igenGold.opacity(0.55), lineWidth: 2)
        )
        .shadow(color: Color.igenGold.opacity(0.22), radius: 40)
        .scaleEffect(scale, anchor: .top)
        .frame(
          width: (size.width + bezelWidth * 2) * scale,
          height: (size.height + bezelWidth * 2) * scale,
          alignment: .top
        )
    }
  }

  /// 撮影用の擬似ステータスバー (時刻・Dynamic Island・電波と電池)
  struct AppStoreScreenshotStatusBar: View {
    var body: some View {
      ZStack {
        Capsule()
          .fill(Color.black)
          .frame(width: 126, height: 37)
        HStack {
          Text(verbatim: "9:41")
            .font(.system(size: 17, weight: .semibold))
          Spacer()
          HStack(spacing: 6) {
            Image(systemName: "cellularbars")
            Image(systemName: "wifi")
            Image(systemName: "battery.100percent")
          }
          .font(.system(size: 15, weight: .semibold))
        }
        .padding(.horizontal, 36)
      }
      .foregroundStyle(Color.igenText)
      .padding(.top, 14)
    }
  }

  /// フレーム内に描くアプリ画面の土台。星空背景の上に、ステータスバー・Dynamic Island ぶんの上余白を確保して画面を描く
  struct AppStoreScreenshotMockScreen<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
      ZStack {
        StarfieldBackground()
        content()
      }
      .safeAreaPadding(.top, 62)
    }
  }
#endif
