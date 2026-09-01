# Shipaton 2026 提出ドラフト

公開状態・ストア URL・動画 URL などの判定値の正は `shipaton-submission/shipaton-submission.json` とする。提出直前の更新は JSON を先に更新して `check-submission.sh` で検証し、本ドキュメントと `shipaton-submission/devpost-submission.md` の該当箇所を追随させる。

公式ルール確認日: 2026-09-01

公式ルール:

https://revenuecat-shipaton-2026.devpost.com/rules

## 提出フォーム記入内容

| 項目 | ドラフト |
| --- | --- |
| アプリ名 | Dear Socrates（日本語名: 偉言） |
| 一言説明 | 悩みや一日のできごとを書くと、出典を確認できる偉人の言葉を軸に、一通の返書が届く iOS アプリ |
| カテゴリ | HAMM Award（主）、Most Viral App (Noise)（副） |
| App Store URL | 未確定。App Store Connect のバージョン 1.0.0 は `PREPARE_FOR_SUBMISSION` |
| デモ動画 URL | 未確定。ローカル動画（`shipaton-submission/output/shipaton-demo.mp4`）は生成・目視確認済み。YouTube または Vimeo への一般公開後に追記する |

Devpost に貼り付ける英語本文は次のファイルにまとめる。

`shipaton-submission/devpost-submission.md`

## 公式要件と現状

| 公式要件 | 現状 | 証跡・不足 |
| --- | --- | --- |
| 2026-07-31 から 2026-09-30 の間に初回公開 | 未完了 | App Store Connect の 1.0.0 は `PREPARE_FOR_SUBMISSION`。初回公開日とストア URL は公開後に確定する |
| iOS・iPadOS・macOS・Android のいずれかで動作 | 対応済み | SwiftUI の iOS 17+ アプリ |
| 米国から利用可能 | 未完了 | Apple の米国向け Lookup API は 2026-09-01 時点で 0 件。公開テリトリ確認が必要 |
| RevenueCat SDK で購入を提供 | 対応済み | `PurchasesSetup.swift` で SDK を初期化。RevenueCat API の差分検査で App、3商品、entitlement、offering、3 packages がすべて `NOOP` |
| アプリが安定して動き、動画の説明と一致 | 対応済み | Firebase Emulator と fake LLM に向けた実アプリを iPhone 15 Pro / iOS 18.5 Simulator 上で Maestro 操作して収録した（2026-09-01）。フレーム分割の目視確認で全シーンの内容一致を確認済み |
| 2分未満の実動作デモ動画 | ローカル生成済み | `shipaton-submission/output/shipaton-demo.mp4`（1080×1920、30fps、実尺112秒、機械検証全項目 PASS）。公開先は YouTube または Vimeo に限り、公開はユーザー判断で行う |
| 動画に無許諾の商標・音楽・素材を含めない | 対応済み | アプリ画面と自作カードだけを使用し、BGMは使用しない。フレーム目視で第三者素材が無いことを確認済み。登場する人物名は Socrates・Seneca のみで、古代の歴史上の人物のためパブリシティ権・肖像権の残存はなく、肖像は使わず独自の星座線表現で描き、引用は出典付きのパブリックドメイン文献に限る |
| 1024×1024 のアプリアイコン | 対応済み | `ios/Igen/Assets.xcassets/AppIcon.appiconset/AppIcon.png` |
| 1179×2556、端末フレームなしのスクリーンショット1枚以上 | 対応済み | `shipaton-submission/artifacts/igen-shipaton-screenshot.png`（返書画面、実測1179×2556、端末フレームなし） |
| 無料トライアルまたは審査員向け promo code | 未完了 | 公開前に方式を決め、審査員向け手順を提出文へ追記する |
| 英語以外の素材には英訳 | 対応済み | 提出本文、動画見出し、操作対象は英語で作成する |
| HAMM Award の収益設計と結果 | 一部対応 | 無料1日1通、160円チケット、月額480円の二層を実装済み。公開後の転換・収益実測値は未取得 |
| Most Viral App の Noise 運用と成果 | 未完了 | 共有カードは実装済み。Noiseでの公開、アカウントメール、投稿・ダウンロード実績が必要 |

## RevenueCat 統合の証跡

- SDK 実装: `ios/Igen/Utils/Purchases/PurchasesSetup.swift`
- バックエンドの entitlement / チケット判定: `backend/functions/src/entitlement.ts`、`backend/functions/src/app.ts`（無料1日1通を超えるアクセスの判定）
- 商品・entitlement・offering の宣言設定: `fastlane/in_app_purchases/revenuecat.config.json`
- RevenueCat project: `proj7dadaccf`（Igen）
- RevenueCat App: `app63dcf839b3`、bundle ID `com.bannzai.Igen`
- Products: `igen_ticket1_160yen`、`igen_unlimited_monthly_480yen`、`igen_unlimited_annual_3800yen`
- Entitlement: `unlimited`
- Offering: `default`
- 2026-09-01 の読み取り専用差分検査: create 0、attach 0、noop 9
- package の表示順が宣言設定と2件ずれているが、App・商品・entitlement・offering・package の存在と紐付けには不足がない
- 購入動作の証跡: StoreKit Configuration（`ios/IgenTests/Igen.storekit`）に対する `StoreKitConfigurationTests`（商品解決→購入→entitlement 付与）が 2026-09-01 の `xcodebuild test`（iOS 18.5 Simulator）で 3 件すべて passed

RevenueCat Dashboard:

https://app.revenuecat.com/projects/proj7dadaccf/product-catalog/products

## 提出直前に確定する項目

- App Store 公開 URL、初回公開日、米国ストアからのアクセス
- 審査員が全機能を試すための無料トライアルまたは promo code と手順
- YouTube または Vimeo の一般公開動画 URL
- App Store Connect と RevenueCat から取得したダウンロード、転換、売上などの実測値
- Most Viral App に応募する場合の Noise アカウントメール、投稿 URL、到達・ダウンロード結果
