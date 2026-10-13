#if DEBUG
  import SwiftUI

  /// App Store スクリーンショットの撮影端末 (iPhone 17 Pro Max、6.9 インチ) の画面サイズ (pt)。
  /// フレーム内のアプリ画面は、どの描画先でもこのサイズで描いてから縮小する
  enum AppStoreScreenshotDevice {
    static let screenSize = CGSize(width: 440, height: 956)
  }

  /// スクショを描く画面 (撮影する simulator のディスプレイ) の種別。描画先ごとにキャッチコピーとフレームの配置を変える
  enum AppStoreScreenshotCanvas: Equatable {
    /// iPhone 6.9 インチの縦画面
    case iphone
    /// iPhone Duo の外側ディスプレイ (閉じた姿勢) の縦画面。iPhone より横に広く縦に短い
    case duoOuter
    /// iPhone Duo の内側ディスプレイ (開いた姿勢) の横画面
    case duoInner

    /// 画面サイズから描画先を判定する。横長なら Duo の内側、縦長は縦横比で iPhone と Duo の外側を見分ける
    /// (size class は iPhone 6.9 インチと Duo の外側で同じ compact × regular のため使えない)
    init(screenSize: CGSize) {
      if screenSize.width > screenSize.height {
        self = .duoInner
      } else if screenSize.height / screenSize.width < 1.8 {
        // iPhone 6.9 インチ (440×956 pt) の縦横比は約 2.2、Duo の外側 (466×678 pt) は約 1.5。その中間を境にする
        self = .duoOuter
      } else {
        self = .iphone
      }
    }
  }

  /// スクショ 1 枚のレイアウト。星空背景の上にキャッチコピーとデバイスフレーム付きのアプリ画面を置く。
  /// 縦画面 (iPhone・Duo の外側) ではキャッチコピーを上、フレームを下に置き、横画面 (Duo の内側) では
  /// キャッチコピーを左、フレームを右に置く。
  /// フレームは画面の端で見切れる前提で組み、アプリ画面の下部にあるボタンは見せない
  struct AppStoreScreenshotFrameLayout<Content: View>: View {
    var title: LocalizedStringResource
    var subtitle: LocalizedStringResource
    @ViewBuilder var content: () -> Content

    var body: some View {
      GeometryReader { geometry in
        ZStack {
          StarfieldBackground()

          switch AppStoreScreenshotCanvas(screenSize: geometry.size) {
          case .iphone:
            portrait(topPadding: 88, titleSize: 34, subtitleSize: 17, frameScale: 0.86)
          case .duoOuter:
            // 外側は iPhone より縦が短いため、見出しを詰めてフレームを小さくし、アプリ画面の見える範囲を iPhone と揃える
            portrait(topPadding: 48, titleSize: 28, subtitleSize: 15, frameScale: 0.72)
          case .duoInner:
            landscape
          }
        }
      }
      .ignoresSafeArea()
    }

    /// 縦画面のレイアウト。キャッチコピーの下にフレームを置き、フレームの下端は画面外にはみ出す
    private func portrait(topPadding: CGFloat, titleSize: CGFloat, subtitleSize: CGFloat, frameScale: CGFloat)
      -> some View
    {
      VStack(spacing: 0) {
        AppStoreScreenshotCaption(
          title: title,
          subtitle: subtitle,
          titleSize: titleSize,
          subtitleSize: subtitleSize,
          alignment: .center
        )
        // フレームが画面外にはみ出しても見出しが縮められないよう、文言の高さを固定する
        .fixedSize(horizontal: false, vertical: true)
        .padding(.top, topPadding)
        .padding(.horizontal, 32)

        AppStoreScreenshotDeviceFrame(scale: frameScale, content: content)
          .padding(.top, 32)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    /// 横画面のレイアウト。左にキャッチコピーを縦中央で置き、右に縦向きのフレームを置いて下端は画面外にはみ出す
    private var landscape: some View {
      HStack(alignment: .top, spacing: 0) {
        AppStoreScreenshotCaption(
          title: title,
          subtitle: subtitle,
          titleSize: 40,
          subtitleSize: 19,
          alignment: .leading
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.leading, 72)
        .padding(.trailing, 32)

        AppStoreScreenshotDeviceFrame(scale: 0.78, content: content)
          .padding(.top, 56)
          .padding(.trailing, 72)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
  }

  /// キャッチコピー (見出しと補足)。縦画面では中央揃え、横画面では左揃えで使う
  private struct AppStoreScreenshotCaption: View {
    var title: LocalizedStringResource
    var subtitle: LocalizedStringResource
    var titleSize: CGFloat
    var subtitleSize: CGFloat
    var alignment: TextAlignment

    var body: some View {
      VStack(alignment: alignment == .leading ? .leading : .center, spacing: 14) {
        Text(title)
          .font(.igenSerif(size: titleSize, weight: .semibold))
          .multilineTextAlignment(alignment)
          .lineSpacing(10)
          .foregroundStyle(Color.igenGoldBright)
          .shadow(color: Color.igenGold.opacity(0.45), radius: 16)
        Text(subtitle)
          .font(.system(size: subtitleSize))
          .multilineTextAlignment(alignment)
          .lineSpacing(6)
          .foregroundStyle(Color.igenText.opacity(0.75))
      }
    }
  }

  /// iPhone 風のフレーム (角丸のベゼル + ステータスバー)。中身を端末のネイティブ画面サイズで描いてから scale 倍に縮小する
  struct AppStoreScreenshotDeviceFrame<Content: View>: View {
    /// 画面に収まるようフレームを縮小する倍率 (描画先ごとに AppStoreScreenshotFrameLayout が決める)
    var scale: CGFloat
    @ViewBuilder var content: () -> Content

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
