---
feature: Paywall
verification: mobile-mcp
last_verified_commit: null
last_verified_at: null
---

# Paywall QA

## 関連リンク

- 仕様: https://github.com/bannzai/igen/issues/13 （やること・完了条件）、`documents/PROJECT.md`「マネタイズ」
- 関連: https://github.com/bannzai/igen/pull/30 （実装）、https://github.com/bannzai/igen/pull/39 （法務リンクの公開 URL 化）、https://github.com/bannzai/igen/pull/57 （IAP の ASC 登録と RevenueCat の products / entitlements / offerings 設定）

## 仕様チェックリスト

| ID | 期待挙動 | 対応項目 |
|----|---------|---------|
| S1 | 無料枠（1 日 1 通）超過時にペイウォールが出て、チケット購入 or サブスクを訴求する | 無料枠超過でペイウォールが自動表示 |
| S2 | ペイウォールに聞き放題（サブスク）と相談チケット（consumable）の 2 プランがあり、価格は RevenueCat の offerings から表示する | ペイウォールの表示 |
| S3 | サンドボックスでチケット購入・サブスク購入・リストアが通る（チケットの現行商品 ID は `igen_ticket1_160yen`） | サブスク購入、チケット購入、購入の復元 |
| S4 | 無料枠超過 → ペイウォール → 購入 → 相談続行のフローが通る | 購入後に相談を続行 |
| S5 | 利用規約・プライバシーポリシー・特定商取引法に基づく表示への導線があり、遷移先が公開されている | 法務リンク 3 種 |
| S6 | 図鑑・履歴の蓄積と課金の物語設計を UI 文言に反映する | ペイウォールの表示 |

## 1. 表示

- [ ] **ペイウォールの表示**: ホームの「See the unlimited plan」でシートが開き、見出し「Your night sky, unlimited.」、「Unlimited — 'Hoshiyomi'」（Most popular、Start Hoshiyomi）、「Ticket — 'Hitoshizuku'」（Buy a ticket）、「Restore purchases」、法務リンク 3 種、「Open Source Licenses」、注記「Payment is processed by the App Store. You can cancel anytime.」が表示される
  - 自動化: manual（レイアウトの目視確認が必要）
- [ ] **価格の表示**: RevenueCat の offerings から取得した価格が各プランに表示される（取得できない時は「Prices could not be loaded. Tap to retry.」が出て再試行できる）
  - 自動化: manual（RevenueCat の public API key は gitignore した `ios/Config.local.xcconfig` 経由で注入する。simtunnel の runner では Secrets `REVENUECAT_PUBLIC_API_KEY_IOS` から生成され、未登録なら空値になり「準備中」表示になる）
  - ❌ 失敗: US ストアフロントの端末で、サブスクは RevenueCat 由来の `$2.99 / 月`（USD）なのに、チケットは `¥160 / 1通`（JPY）と表示され、同じストアフロントの 2 商品で通貨が食い違う。この `¥160 / 1通` は `ios/Igen/Features/Paywall/Components/PaywallTicketPlanCard.swift` が `package?.storeProduct.localizedPriceString` を取得できない時に出す `Text(verbatim: "¥160 / 1通")` の仮価格と完全に一致する。サブスクが同じストアフロントから USD を取得できている以上、チケットの package が取れていれば USD になるはずで、チケットの package が offering から取得できていないことを示す。仕様では取得できない時は「価格を読み込めませんでした。タップして再試行できます。」を出して再試行できるはずだが、チケットはエラー表示にならず実際の請求額と異なる通貨の価格が黙って表示される。再現手順: ホームの「聞き放題プランをみる」でペイウォールを開く（相談の送信は不要）。RevenueCat の offering 設定（チケットの現行商品 ID は `igen_ticket1_160yen`）との照合が必要。issue: https://github.com/bannzai/igen/issues/59
- [ ] **閉じる**: 右上の × でシートが閉じてホームに戻る
  - 自動化: manual（遷移の目視確認が必要）

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **ペイウォールの表示**: ホームの「See the unlimited plan」でシートが開き、見出し「Your night sky, unlimited.」、「Unlimited — 'Hoshiyomi'」（Most popular、Start Hoshiyomi）、「Ticket — 'Hitoshizuku'」（Buy a ticket）、「Restore purchases」、法務リンク 3 種、「Open Source Licenses」、注記「Payment is processed by the App Store. You can cancel anytime.」が表示される

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

### **価格の表示**: RevenueCat の offerings から取得した価格が各プランに表示される（取得できない時は「Prices could not be loaded. Tap to retry.」が出て再試行できる）

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

### **閉じる**: 右上の × でシートが閉じてホームに戻る

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

</details>

---

## 2. 無料枠超過

- [ ] **無料枠超過でペイウォールが自動表示**: 同じ匿名ユーザーで同日 2 通目の相談を送信すると、返書ではなくペイウォールのシートが自動で開く（HTTP 429）
  - 自動化: manual（1 通目の送信後に 2 通目を送る手順と目視確認が必要）
  - ⏭️ スキップ: 2026-08-29 の simtunnel セッション igen-49 で runner の Simulator が名前解決に失敗し（Safari で `asia-northeast1-igen-prod.cloudfunctions.net` も `bannzai.github.io` も「Safari can't open the page because the server can't be found.」）、相談の送信が 2 回とも約 300 秒の再照会の後に「The letter could not be delivered. Please try again later.」で失敗したため、送信後の画面に到達できず未確認。無料枠は未消費のまま

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **無料枠超過でペイウォールが自動表示**: 同じ匿名ユーザーで同日 2 通目の相談を送信すると、返書ではなくペイウォールのシートが自動で開く（HTTP 429）

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

</details>

---

## 3. 購入と復元

- [ ] **サブスク購入**: 「Start Hoshiyomi」でサンドボックスの購入シートが出て、購入完了後にシートが閉じる
  - 自動化: manual（サンドボックス購入は StoreKit / RevenueCat の状態に依存する。RevenueCat の API key が空の環境ではアラート「Purchases are not available yet. Please check back soon.」が出る）
  - ⏭️ スキップ: 実課金が発生しうるため simtunnel の runner では実行しない。サンドボックス購入は実機・TestFlight で確認する
- [ ] **チケット購入**: 「Buy a ticket」でサンドボックスの購入シートが出て、購入完了後にシートが閉じる
  - 自動化: manual（同上）
  - ⏭️ スキップ: 実課金が発生しうるため simtunnel の runner では実行しない。サンドボックス購入は実機・TestFlight で確認する（「価格の表示」の ❌ のとおり、チケットの package が offering から取得できていない疑いがあるため、実機確認時はあわせて購入可否も見る）
- [ ] **購入の復元**: 「Restore purchases」でアラート「Your purchases have been restored.」が出る
  - 自動化: manual（同上）
- [ ] **購入後に相談を続行**: 購入後に相談を送信すると無料枠超過でも返書が返る
  - 自動化: manual（購入が通る環境が必要）

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **サブスク購入**: 「Start Hoshiyomi」でサンドボックスの購入シートが出て、購入完了後にシートが閉じる

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

### **チケット購入**: 「Buy a ticket」でサンドボックスの購入シートが出て、購入完了後にシートが閉じる

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

### **購入の復元**: 「Restore purchases」でアラート「Your purchases have been restored.」が出る

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

### **購入後に相談を続行**: 購入後に相談を送信すると無料枠超過でも返書が返る

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

</details>

---

## 4. 法務リンク

- [ ] **法務リンク 3 種**: 「Terms of Service」「Privacy Policy」「Disclosure under the Specified Commercial Transactions Act」をタップすると Safari で `bannzai.github.io` の該当ページが開き、表示言語と同じ言語の本文が表示される（Safari の URL バーはドメインまでしか出さないため `-ja.html` / `-en.html` のパス自体は本文の言語で判定する。URL の組み立ては `ios/Igen/Shared/LegalDocumentURL.swift`、6 URL の HTTP 200 確認はルート QA.md「法務ドキュメント」）
  - 自動化: manual（遷移先の目視確認が必要）
- [ ] **OSS ライセンス**: 「Open Source Licenses」で Licenses のシートが開く（内容は Licenses QA.md）
  - 自動化: manual（遷移の目視確認が必要）

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **法務リンク 3 種**: 「Terms of Service」「Privacy Policy」「Disclosure under the Specified Commercial Transactions Act」をタップすると Safari で `bannzai.github.io` の該当ページが開き、表示言語と同じ言語の本文が表示される（Safari の URL バーはドメインまでしか出さないため `-ja.html` / `-en.html` のパス自体は本文の言語で判定する。URL の組み立ては `ios/Igen/Shared/LegalDocumentURL.swift`、6 URL の HTTP 200 確認はルート QA.md「法務ドキュメント」）

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

### **OSS ライセンス**: 「Open Source Licenses」で Licenses のシートが開く（内容は Licenses QA.md）

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

</details>
