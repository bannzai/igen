import FirebaseAnalytics
import RevenueCat
import SwiftUI

/// ペイウォール。無料 1 日 1 通 + 相談チケット (consumable) + 聞き放題サブスクの 2 層構成
/// (documents/PROJECT.md「マネタイズ」、design_handoff_igen/README.md「ペイウォール」)
struct PaywallPage: View {
  @Environment(\.dismiss) var dismiss
  @State var offerings: Offerings?
  @State var offeringsLoadFailed = false
  @State var purchasing = false
  @State var purchaseErrorAlertIsPresented = false
  @State var purchasesUnavailableAlertIsPresented = false
  @State var restoreDoneAlertIsPresented = false
  @State var licensesSheetIsPresented = false

  /// チケット (consumable) のパッケージ。offering に別の custom package があっても
  /// バックエンドが数えるストア商品 ID (PurchasesSetup.ticketProductID) と一致するものだけを選ぶ
  private func ticketPackage(offerings: Offerings?) -> Package? {
    offerings?.current?.availablePackages.first(where: {
      $0.storeProduct.productIdentifier == PurchasesSetup.ticketProductID
    })
  }

  /// offering の取得中か (SDK が使える環境でのみ真になりうる)。取得完了までプランを出さずに待たせる
  private var offeringsLoading: Bool {
    PurchasesSetup.isAvailable && offerings == nil && !offeringsLoadFailed
  }

  var body: some View {
    ZStack {
      StarfieldBackground()

      ScrollView {
        VStack(spacing: 16) {
          HStack {
            Spacer()
            Button {
              Analytics.logEvent("paywall_close_button_pressed", parameters: nil)
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

          if offeringsLoading {
            ProgressView()
              .tint(Color.igenGoldBright)
              .padding(.vertical, 24)
          }

          // 価格はストアが正を持つ。解決できなかったプランは代わりの金額を出さずに伏せる (#59)
          if let monthlyPackage = offerings?.current?.monthly {
            PaywallUnlimitedPlanCard(package: monthlyPackage, purchasing: purchasing) {
              Analytics.logEvent("paywall_subscribe_button_pressed", parameters: nil)
              purchase(packageType: .monthly)
            }
          }

          if let ticketPackage = ticketPackage(offerings: offerings) {
            PaywallTicketPlanCard(package: ticketPackage, purchasing: purchasing) {
              Analytics.logEvent("paywall_ticket_button_pressed", parameters: nil)
              purchase(packageType: .custom)
            }
          }

          if offeringsLoadFailed {
            Button {
              Analytics.logEvent("paywall_price_retry_button_pressed", parameters: nil)
              Task {
                await loadOfferings()
              }
            } label: {
              // ja: 価格を読み込めませんでした タップして再試行
              Text("Prices could not be loaded. Tap to retry.")
                .font(.system(size: 12))
                .foregroundStyle(Color.igenGoldBright)
            }
          }

          VStack(spacing: 10) {
            HStack(spacing: 16) {
              Button {
                Analytics.logEvent("paywall_restore_button_pressed", parameters: nil)
                restore()
              } label: {
                // ja: 購入の復元
                Text("Restore purchases")
              }
              Link(destination: legalDocumentURL(fileBaseName: "Terms", language: appLanguage())) {
                // ja: 利用規約
                Text("Terms of Service")
              }
              Link(destination: legalDocumentURL(fileBaseName: "PrivacyPolicy", language: appLanguage())) {
                // ja: プライバシーポリシー
                Text("Privacy Policy")
              }
            }
            Link(
              destination: legalDocumentURL(
                fileBaseName: "SpecifiedCommercialTransactionAct",
                language: appLanguage()
              )
            ) {
              // ja: 特定商取引法に基づく表示
              Text("Disclosure under the Specified Commercial Transactions Act")
            }
            Button {
              Analytics.logEvent("paywall_licenses_button_pressed", parameters: nil)
              licensesSheetIsPresented = true
            } label: {
              // ja: オープンソースライセンス
              Text("Open Source Licenses")
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
    .sheet(isPresented: $licensesSheetIsPresented) {
      LicensesPage()
    }
    .task {
      Analytics.logEvent("paywall_shown", parameters: nil)
      // 起動直後は匿名認証・RevenueCat の初期化が終わっていないことがあるため、
      // 使えるようになるまで短い間隔で待ってから取得する (数秒で諦めて準備中の表示に倒す)
      for _ in 0..<10 {
        if PurchasesSetup.isAvailable {
          break
        }
        try? await Task.sleep(for: .milliseconds(500))
      }
      await loadOfferings()
    }
  }

  /// offering を取得する。失敗したら再試行導線を表示する
  private func loadOfferings() async {
    if !PurchasesSetup.isAvailable {
      // 初期化が終わらない場合も失敗状態にして再試行導線を出す (シートを開き直さずに読み直せるように)
      offeringsLoadFailed = true
      return
    }
    offeringsLoadFailed = false
    do {
      let loadedOfferings = try await Purchases.shared.offerings()
      offerings = loadedOfferings
      // offering を取得できても購入できる package が 1 つも解決できなければ購入手段が無いため、
      // 読み込み失敗として再試行導線に倒す
      if loadedOfferings.current?.monthly == nil, ticketPackage(offerings: loadedOfferings) == nil {
        offeringsLoadFailed = true
        return
      }
      Analytics.logEvent("paywall_offerings_loaded", parameters: nil)
    } catch {
      offeringsLoadFailed = true
    }
  }

  /// offering からパッケージを選んで購入する。SDK 未設定・未初期化の間は準備中の案内を出す
  private func purchase(packageType: PackageType) {
    if !PurchasesSetup.isAvailable {
      purchasesUnavailableAlertIsPresented = true
      return
    }
    let package = packageType == .monthly ? offerings?.current?.monthly : ticketPackage(offerings: offerings)
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
    if !PurchasesSetup.isAvailable {
      purchasesUnavailableAlertIsPresented = true
      return
    }
    Task {
      do {
        _ = try await Purchases.shared.restorePurchases()
        Analytics.logEvent("paywall_restore_completed", parameters: nil)
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
