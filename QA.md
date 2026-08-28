---
feature: _root
verification: mobile-mcp
last_verified_commit: null
last_verified_at: null
---

# QA 全体ガイド

## 対象環境

| 経路 | ビルド | 接続先 | 用途 |
| --- | --- | --- | --- |
| simtunnel（GitHub Actions 上の iOS Simulator。既定） | Release | 本番 Firebase `igen-prod`（Functions は実 LLM を呼ぶ） | リリース前 QA・UI 変更の確認。runner の Simulator は英語ロケール・US リージョン・UTC で動く。相談の送信 1 通ごとに LLM 費用が発生し、無料枠は匿名ユーザーごとに 1 日 1 通 |
| ローカル Simulator（例外時のみ。`CLAUDE.md`「実装したUIの検証」の条件） | Debug | Firebase Emulator `demo-igen`（Functions / Firestore / Auth） | 危機判定・無料枠超過などを安価に再現したい時。`IGEN_FAKE_LLM=1` で定型返書、`IGEN_FREE_LETTERS_PER_DAY=N` で無料枠を増やせる（どちらも Emulator 実行時のみ有効。`backend/functions/src/index.ts` / `quota.ts`） |

Debug ビルドは既定で Emulator（127.0.0.1）に向くため runner 上では通信できない。Debug のまま本番へ向けたい時だけ環境変数 `IGEN_USE_PROD=1`（simctl では `SIMCTL_CHILD_IGEN_USE_PROD=1`）を付ける（`ios/Igen/Utils/Firebase/FirebaseSetup.swift`）。

## 起動方法

simtunnel（手順の SSOT は `CLAUDE.md`「実装したUIの検証」）:

```bash
# 検証対象のブランチを push してから
~/ghq/github.com/bannzai/simtunnel/local/simtunnel up <session> --ref <ブランチ名> --duration 180 --wait
~/ghq/github.com/bannzai/simtunnel/local/simtunnel mcp-config <session> <worktree の絶対パス> --name mobile
# 終了
~/ghq/github.com/bannzai/simtunnel/local/simtunnel down <session>
```

ローカル（Emulator）:

```bash
# backend
cd backend/functions
npm ci
IGEN_FAKE_LLM=1 IGEN_FREE_LETTERS_PER_DAY=5 npm run serve   # auth / functions / firestore の Emulator
FIRESTORE_EMULATOR_HOST=127.0.0.1:8282 npm run seed          # persons / quotes の投入（別ターミナル）
# ios（Debug）
xcodebuild build -project ios/Igen.xcodeproj -scheme Igen \
  -destination 'platform=iOS Simulator,id=<DEVICE_UDID>' -derivedDataPath ./tmp/DerivedData \
  -skipPackagePluginValidation
xcrun simctl install <DEVICE_UDID> ./tmp/DerivedData/Build/Products/Debug-iphonesimulator/Igen.app
xcrun simctl launch <DEVICE_UDID> com.bannzai.Igen
```

Bundle ID: `com.bannzai.Igen`。表示名は端末言語 ja で「偉言」、それ以外で「Dear Socrates」（`ios/Igen/Resources/InfoPlist.xcstrings`）。

## ログイン方法

Firebase Authentication の匿名認証のみ。起動時に自動でサインインし、UID がそのまま RevenueCat の appUserID になる。アカウント UI・サインアウト UI は無い。新しいユーザーで試したい時はアプリを削除して再インストールする（simtunnel ではセッションの再起動）。

## 動作確認手段

- Simulator の用意（simtunnel とローカルの使い分け）: `/ios-simulator` Phase 1
- 画面操作・スクリーンショット: `/verify-ui-mobile-mcp`（simtunnel 経由でもそのまま動く。セッション途中から simtunnel を使う時は `.mcp.json` が読まれないため `bash ~/.claude/skills/ios-simulator/scripts/ios-wda.sh --session <session> ...` を使う）
- Maestro flow は未整備（`自動化: auto` の項目は無い）
- エビデンスの画像は `gh-r2-image` でアップロードした URL のみを記録する

### 再現が難しい操作の手順

- 端末言語の切り替え（英語 / 日本語）: アプリ内に切り替え UI は無い。Simulator の設定アプリ > Apps > Dear Socrates（偉言）> Language で切り替える（`documents/app-review-notes.md`）。simtunnel の runner は英語ロケールで起動する
- 相談窓口の地域分岐: 窓口は端末の「言語」ではなく「地域」で選ぶ（`ios/Igen/Features/Safety/SafetyPage.swift`）。JP の窓口を見るには設定アプリ > General > Language & Region > Region を Japan にする。runner の既定は US
- 危機ワードの再現（本番）: 相談本文に `backend/functions/src/crisis.ts` のキーワード（例: `want to die` / `死にたい`）を含めて送信する。キーワード判定は LLM 呼び出し・無料枠消費の前に行われるため費用も無料枠も消費しない
- 無料枠超過の再現（本番）: 同じ匿名ユーザーで同日 2 通目を送信すると HTTP 429 でペイウォールが自動表示される（LLM は呼ばれない）
- 返書の登場演出の再表示: UserDefaults `ritualCount` を消す（アプリ削除）。星図の「新しい星座が灯る」演出の再表示: UserDefaults `atlasSeenPersonIds.<uid>` を消す（アプリ削除）
- 演出を省略したい時: 設定アプリ > Accessibility > Motion > Reduce Motion（登場演出・星座の点灯演出・ボタンの光が省略される）

## 実行ナレッジ

（まだ知見なし。run-qa が実行中の flaky・落とし穴の知見を蓄積する。運用ルールは ~/.claude/skills/setup-qa/references/qa-md-format.md を参照）

## 横断確認項目

## 1. 起動と認証

- [ ] **初回起動**: インストール直後の起動でホーム画面（星空・入力カード・「Ask the Greats」）が表示され、エラーアラートが出ない
  - 自動化: manual（Simulator の初回起動状態の作成と目視確認が必要）
- [ ] **匿名認証**: 起動後にそのまま相談を送信でき、返書または相談窓口案内が返る（匿名サインインが完了している）
  - 自動化: manual（送信結果は Firebase / LLM の応答に依存する）

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **初回起動**: インストール直後の起動でホーム画面（星空・入力カード・「Ask the Greats」）が表示され、エラーアラートが出ない

<details><summary>動作確認スクショ</summary>

（未実行）

</details>

### **匿名認証**: 起動後にそのまま相談を送信でき、返書または相談窓口案内が返る（匿名サインインが完了している）

<details><summary>動作確認スクショ</summary>

（未実行）

</details>

</details>

---

## 2. 英語モード（Dear Socrates）

- [ ] **英語で一通り動作する**: 端末言語 en で表示名が Dear Socrates になり、ホーム → 送信 → 返書 → 共有カード → 記録 → 星図 → ペイウォールがすべて英語表示で動作し、文字のはみ出し・重なりが無い
  - 自動化: manual（各画面の目視確認が必要。英語 UI は runner の既定ロケールで確認できる）
- [ ] **返書の言語**: 英語で送信した返書は格言の原文がそのまま併記され、訳文・解説が英語になる
  - 自動化: manual（返書内容は LLM の生成結果）

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **英語で一通り動作する**: 端末言語 en で表示名が Dear Socrates になり、ホーム → 送信 → 返書 → 共有カード → 記録 → 星図 → ペイウォールがすべて英語表示で動作し、文字のはみ出し・重なりが無い

<details><summary>動作確認スクショ</summary>

（未実行）

</details>

### **返書の言語**: 英語で送信した返書は格言の原文がそのまま併記され、訳文・解説が英語になる

<details><summary>動作確認スクショ</summary>

（未実行）

</details>

</details>

---

## 3. プライバシー（静的検査）

- [x] **Analytics に相談本文を送らない**: `grep -rn logEvent ios/Igen` で列挙した全イベントのパラメータが `text_length` / `quote_id` / `letters_count` / `encounters_count` / `package` のみで、相談本文・返書本文・自由入力の文字列が含まれない
  - 自動化: manual（grep の出力を目視で判定する。エビデンスは grep 結果の記録）
- [x] **共有カードに悩み本文を含めない**: `ios/Igen/Features/Share/` 配下（`Components/ShareCardView.swift` を含む）が `letter.concern` を参照しない（`grep -rn concern ios/Igen/Features/Share --include=*.swift` が空）
  - 自動化: manual（grep の出力を目視で判定する）

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **Analytics に相談本文を送らない**: `grep -rn logEvent ios/Igen` で列挙した全イベントのパラメータが `text_length` / `quote_id` / `letters_count` / `encounters_count` / `package` のみで、相談本文・返書本文・自由入力の文字列が含まれない

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-28**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260828/559bff76-0bc5-4bee-8220-fff1999d7e82.png" width="320">

</details>

### **共有カードに悩み本文を含めない**: `ios/Igen/Features/Share/` 配下（`Components/ShareCardView.swift` を含む）が `letter.concern` を参照しない（`grep -rn concern ios/Igen/Features/Share --include=*.swift` が空）

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-28**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260828/07e46fbd-874d-4ffa-87e5-8bc9fdc4f11c.png" width="320">

</details>

</details>

---

## 4. 法務ドキュメント

- [x] **法務リンク 3 種の遷移先が 200**: `ios/Igen/Shared/LegalDocumentURL.swift` が組み立てる利用規約 / プライバシーポリシー / 特定商取引法に基づく表示の URL（ja / en 各 3 = 6 URL）に curl して全て HTTP 200
  - 自動化: manual（curl の結果を記録する）

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **法務リンク 3 種の遷移先が 200**: `ios/Igen/Shared/LegalDocumentURL.swift` が組み立てる利用規約 / プライバシーポリシー / 特定商取引法に基づく表示の URL（ja / en 各 3 = 6 URL）に curl して全て HTTP 200

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-28**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260828/6d9222b5-b238-461f-94e9-ea249a4378cd.png" width="320">

</details>

</details>

---

## 機能別 QA.md

- [Home](ios/Igen/Features/Home/QA.md) — ホーム画面（入力・送信・音声入力・ペイウォール導線）
- [Reply](ios/Igen/Features/Reply/QA.md) — 返書画面（登場演出・出典・原文併記・図解カード）
- [Safety](ios/Igen/Features/Safety/QA.md) — 危機ワード検知 → 相談窓口案内
- [Paywall](ios/Igen/Features/Paywall/QA.md) — 無料枠超過 → ペイウォール・購入・復元・法務リンク
- [Archive](ios/Igen/Features/Archive/QA.md) — 記録（日付ごとの相談履歴・再訪）
- [Atlas](ios/Igen/Features/Atlas/QA.md) — 星図（出会った偉人・プロフィール）
- [Share](ios/Igen/Features/Share/QA.md) — 共有カード
- [Licenses](ios/Igen/Features/Licenses/QA.md) — OSS ライセンス一覧

推奨の実行順（無料枠 1 日 1 通を活かす）: Archive の 0 件表示・Atlas の未出会い表示 → Safety（無料枠を消費しない）→ Home の通常送信（1 通目）→ Reply → Share → Archive → Atlas → Home の 2 通目送信 → Paywall → Licenses。

## QA 対象外

対象外の feature は無い。`ios/Igen/Features/*` の 8 feature はすべてユーザー操作で到達できる画面を持つ（`ios/Igen/Utils/*`・`ios/Igen/Shared/*` は Firebase / RevenueCat の初期化と API クライアントで feature ディレクトリではない。横断確認項目「起動と認証」で覆う）。
