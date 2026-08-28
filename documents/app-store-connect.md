# App Store Connect / RevenueCat の設定

App Store Connect (ASC) と RevenueCat に対する設定は、リポジトリ内の定義ファイルを正とし、スクリプトで冪等に適用する。Web UI で直接変えた設定はスクリプトの再実行で定義どおりに戻るため、変更は定義ファイル側で行う。

| 対象 | 定義ファイル (SSOT) | 適用コマンド (リポジトリルートで実行) |
|---|---|---|
| Bundle ID の登録・アプリの作成 | `fastlane/asc_submission_settings.json` (`bundleId` / `developerPortalName` / `sku` / `primaryLocale` / `initialVersion`) | `bash scripts/asc_register_app.sh` |
| カテゴリ・ロケール別アプリ名とプライバシーポリシー URL・利用規約 (EULA)・年齢制限指定・App Review メモ | `fastlane/asc_submission_settings.json` と `documents/app-review-notes.md` (メモ本文) | `bash scripts/asc_apply_submission_settings.sh` (`--dry-run` で差分確認のみ) |
| App Privacy (プライバシー「栄養ラベル」) | `fastlane/app_privacy_details.json` | `bash ~/.claude/skills/appstore-app-privacy/scripts/privacy_apply.sh --app-identifier com.bannzai.Igen --username "$FASTLANE_USER" --team-id "$FASTLANE_ITC_TEAM_ID" --json-path fastlane/app_privacy_details.json` |
| 課金商品 (consumable) | `fastlane/in_app_purchases/appstore.config.json` の `iaps[]` | `bash ~/.claude/skills/appstore-in-app-purchase/scripts/iap_apply_config.sh --config fastlane/in_app_purchases/appstore.config.json` |
| 自動更新サブスクリプション | 同ファイルの `subscriptionGroups[]` | `bash ~/.claude/skills/appstore-in-app-purchase/scripts/iap_apply_subscriptions.sh --config fastlane/in_app_purchases/appstore.config.json`。全テリトリー価格は `iap_expand_subscription_prices.sh <SUBSCRIPTION_ID> JPN <価格>` で展開する |
| 課金商品の App Review 用スクリーンショット (READY_TO_SUBMIT に必要) | ペイウォールのスクリーンショット (simtunnel で撮影) | consumable は同 skill の `iap_upload_review_screenshot.sh <IAP_ID> <画像>`、サブスクリプションは `bash scripts/asc_upload_subscription_review_screenshot.sh <SUBSCRIPTION_ID> <画像>` |
| RevenueCat の App・products・entitlement・offering | `fastlane/in_app_purchases/revenuecat.config.json` | `bash ~/.claude/skills/revenuecat-product-setup/scripts/rc_diff_config.sh fastlane/in_app_purchases/revenuecat.config.json` で差分確認 → `rc_apply_config.sh <同じパス>` で適用 (config はパス引数で渡す) |
| 課金の CLI 検証 (StoreKit Configuration) | `ios/IgenTests/Igen.storekit` (商品 ID・価格は appstore.config.json と一致させる) | `xcodebuild test ... -only-testing:IgenTests/StoreKitConfigurationTests` (iOS 26.2 以下の simulator で実行する) |

## 認証情報

- ASC API キー: 環境変数 `ASC_API_KEY_ID` / `ASC_API_KEY_ISSUER_ID` / `ASC_API_KEY_P8_BASE64` (JWT 認証。Bundle ID 登録・提出前設定・課金商品に使う)
- Apple ID の Web セッション: `fastlane spaceauth -u <Apple ID>` で事前に生成する (アプリの作成と App Privacy は公開 API に無く、fastlane spaceship でしか行えない)。`FASTLANE_USER` / `FASTLANE_TEAM_ID` / `FASTLANE_ITC_TEAM_ID` で Apple ID とチームを指定する
- RevenueCat (設定用): 環境変数 `REVENUECAT_PROJECT_CONFIGURATION_API_KEY_V2` (v2 secret key。`project_configuration:{projects,apps,products,entitlements,offerings,packages}` の read_write が必要)
- RevenueCat (backend 実行時): Firebase Secret `REVENUECAT_API_KEY` (v1 secret key。`backend/functions/src/index.ts` が参照し、`entitlement.ts` の Subscriber API `GET /v1/subscribers/{uid}` に使う)。RevenueCat プロジェクトを作り直した時は新プロジェクトの v1 key を `firebase functions:secrets:set REVENUECAT_API_KEY --project igen-prod` で登録し、Functions を再デプロイしないと購入状態を照会できない
- App Review の連絡先 (氏名・メール・電話) は個人情報のためリポジトリに置かず、`ASC_REVIEW_CONTACT_FIRST_NAME` / `ASC_REVIEW_CONTACT_LAST_NAME` / `ASC_REVIEW_CONTACT_EMAIL` / `ASC_REVIEW_CONTACT_PHONE` の環境変数で `scripts/asc_apply_submission_settings.sh` に渡す

## 判断の記録

- 利用規約 (EULA): ASC には利用規約の URL 欄が無く、カスタムライセンス契約の本文欄しか無い。サブスクリプションの審査で求められる利用規約リンクの提示先として、日英の規約とプライバシーポリシーの公開 URL を含む本文を全テリトリー向けに設定している
- App Privacy: 相談内容 (`OTHER_USER_CONTENT`) と匿名識別子 (`USER_ID`)、購入情報 (`PURCHASE_HISTORY`) は Firebase 匿名認証の UID でサーバー側の相談履歴と RevenueCat (`Purchases.logIn`) に紐付くため「ユーザーに紐付く」として申告する。Firebase Analytics の利用状況 (`PRODUCT_INTERACTION`) と、Analytics が収集するアプリインスタンス識別子 (`DEVICE_ID`。Firebase の App Store データ開示ガイドに従う) はユーザー ID を設定していないため「紐付かない」。Crashlytics・広告 SDK・IDFA は使っていないため `CRASH_DATA` / トラッキングは申告しない。音声入力は Apple の Speech framework が処理し提供者は音声データを取得しないため申告しない。根拠は `docs/PrivacyPolicy-ja.md`「収集する利用者情報および収集方法」
- 課金商品の識別子は `~/.claude/documents/rules/iap-product-identifier-naming.md` に従い価格を含める (`igen_ticket1_160yen` / `igen_unlimited_monthly_480yen` / `igen_unlimited_annual_3800yen`)。identifier は作成後に変更できないため、価格改定時は新しい識別子で作り直す
- 年額 `igen_unlimited_annual_3800yen` は ASC と RevenueCat (`$rc_annual`) に先行登録しているが、ペイウォール (`ios/Igen/Features/Paywall/PaywallPage.swift`) は月額パッケージだけを表示・購入する。審査員が購入経路を辿れない商品を提出すると差し戻されるため、年額はペイウォールに年額の選択肢を追加したバージョンと一緒に審査提出する (それまで `iap_submit.sh` の対象に含めない)
