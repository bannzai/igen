import FirebaseAnalytics
import RevenueCat
import SwiftUI

/// ペイウォール。無料 1 日 1 通 + 相談チケット (consumable) + 聞き放題サブスクの 2 層構成
/// (documents/PROJECT.md「マネタイズ」、design_handoff_igen/README.md「ペイウォール」)
struct PaywallPage: View {
  @Environment(\.dismiss) var dismiss
  @State var offerings: Offerings?
  @State var purchasing = false
  @State var purchaseErrorAlertIsPresented = false
  @State var purchasesUnavailableAlertIsPresented = false
  @State var restoreDoneAlertIsPresented = false

  var body: some View {
    ZStack {
      StarfieldBackground()

      ScrollView {
        VStack(spacing: 16) {
          HStack {
            Spacer()
            Button {
              dismiss()
            } label: {
              Image(systemName: "xmark")
                .font(.system(size: 14))
                .foregroundStyle(Color.igenText.opacity(0.6))
                .frame(width: 44, height: 44)
            }
          }

          // ja: 夜空を、聞き放題に。
          Text("Your night sky, unlimited.")
            .font(.igenSerif(size: 22, weight: .semibold))
            .multilineTextAlignment(.center)
            .foregroundStyle(Color.igenGoldBright)

          // ja: 無料の返書は 1日1通 もっと話したい夜のために
          Text("Free letters arrive once a day. For the nights you want to talk more.")
            .font(.system(size: 13))
            .multilineTextAlignment(.center)
            .lineSpacing(8)
            .foregroundStyle(Color.igenText.opacity(0.8))

          PaywallUnlimitedPlanCard(purchasing: purchasing) {
            Analytics.logEvent("paywall_subscribe_button_pressed", parameters: nil)
            purchase(packageType: .monthly)
          }

          PaywallTicketPlanCard(purchasing: purchasing) {
            Analytics.logEvent("paywall_ticket_button_pressed", parameters: nil)
            purchase(packageType: .custom)
          }

          HStack(spacing: 16) {
            Button {
              Analytics.logEvent("paywall_restore_button_pressed", parameters: nil)
              restore()
            } label: {
              // ja: 購入の復元
              Text("Restore purchases")
            }
            // 法務ドキュメントの公開 URL は #16 (GitHub Pages 有効化) で確定する
            Link(destination: URL(string: "https://github.com/bannzai/igen/blob/main/docs/Terms-ja.md")!) {
              // ja: 利用規約
              Text("Terms of Service")
            }
            Link(destination: URL(string: "https://github.com/bannzai/igen/blob/main/docs/PrivacyPolicy-ja.md")!) {
              // ja: プライバシーポリシー
              Text("Privacy Policy")
            }
          }
          .font(.system(size: 11))
          .foregroundStyle(Color.igenText.opacity(0.6))

          // ja: お支払いは App Store 経由 いつでも解約できます
          Text("Payment is processed by the App Store. You can cancel anytime.")
            .font(.system(size: 10))
            .foregroundStyle(Color.igenText.opacity(0.45))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
      }
    }
    // ja: 購入を完了できませんでした しばらくしてからもう一度お試しください
    .alert("The purchase could not be completed. Please try again later.", isPresented: $purchaseErrorAlertIsPresented) {}
    // ja: 購入はただいま準備中です もうしばらくお待ちください
    .alert("Purchases are not available yet. Please check back soon.", isPresented: $purchasesUnavailableAlertIsPresented) {}
    // ja: 購入情報を確認しました
    .alert("Your purchases have been restored.", isPresented: $restoreDoneAlertIsPresented) {}
    .task {
      Analytics.logEvent("paywall_shown", parameters: nil)
      if PurchasesSetup.isConfigured {
        offerings = try? await Purchases.shared.offerings()
      }
    }
  }

  /// offering からパッケージを選んで購入する。SDK 未設定の間は準備中の案内を出す
  private func purchase(packageType: PackageType) {
    if !PurchasesSetup.isConfigured {
      purchasesUnavailableAlertIsPresented = true
      return
    }
    let package =
      packageType == .monthly
      ? offerings?.current?.monthly
      : offerings?.current?.availablePackages.first(where: { $0.packageType == .custom })
    if let package {
      purchasing = true
      Task {
        do {
          let result = try await Purchases.shared.purchase(package: package)
          if !result.userCancelled {
            Analytics.logEvent("paywall_purchase_completed", parameters: ["package": package.identifier])
            dismiss()
          }
        } catch {
          purchaseErrorAlertIsPresented = true
        }
        purchasing = false
      }
    } else {
      purchasesUnavailableAlertIsPresented = true
    }
  }

  private func restore() {
    if !PurchasesSetup.isConfigured {
      purchasesUnavailableAlertIsPresented = true
      return
    }
    Task {
      do {
        _ = try await Purchases.shared.restorePurchases()
        restoreDoneAlertIsPresented = true
      } catch {
        purchaseErrorAlertIsPresented = true
      }
    }
  }
}

struct PaywallPage_Previews: PreviewProvider {
  static var previews: some View {
    PaywallPage()
  }
}
