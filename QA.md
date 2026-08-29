---
feature: _root
verification: mobile-mcp
last_verified_commit: 260cc34ccaa5f1e5f0479e7e16d75806745d7829
last_verified_at: 2026-08-29
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

- 表示言語の切り替え（英語 / 日本語）: アプリ内に切り替え UI は無い。**simtunnel の runner では設定アプリで端末の優先言語を変更しない**（優先言語の追加・変更で SpringBoard がリロードされ、WDA が応答しなくなってセッションが watchdog に落とされる。2026-08-29 に実際にセッションが落ちた）。加えて、設定アプリ > Apps > Dear Socrates の「Language」行は端末の優先言語が 2 つ以上ないと現れないため、その経路自体が使えない。代わりに **WDA の `POST /session` の capabilities に起動引数 `-AppleLanguages` を載せて新しいセッションを作る**。アプリを一度終了してから作り直すこと（起動中のままだと launch が activate になり引数が反映されない）:

```bash
bash ~/.claude/skills/ios-simulator/scripts/ios-wda.sh --session <session> terminate com.bannzai.Igen
curl -s -X POST "http://simtunnel-<session>:8100/session" -H 'Content-Type: application/json' \
  -d '{"capabilities":{"alwaysMatch":{"bundleId":"com.bannzai.Igen","arguments":["-AppleLanguages","(ja)","-AppleLocale","ja_JP"],"shouldWaitForQuiescence":false}}}'
```

英語に戻すときは `(en)` / `en_US` を渡して同じ手順を踏む。既存セッションへの `POST /session/{sid}/wda/apps/launch` に `arguments` を渡しても言語は変わらない（2026-08-29 に確認）。**作ったセッション ID は `ios-wda.sh` のキャッシュ（`tmp/ios-wda/<WDA URL の cksum>.sid`）へ書き戻す**（書き戻さないと以降の `tap` / `swipe` が bundleId 無しで作られた古いセッションで実行され、アプリがバックグラウンドへ落ちてホーム画面や Spotlight を操作してしまう）。実機・ローカル Simulator では設定アプリ > Apps > Dear Socrates（偉言）> Language でも切り替えられる（`documents/app-review-notes.md`）が、その行は端末の優先言語が 2 つ以上ないと現れない
- 相談窓口の地域分岐: 窓口は端末の「言語」ではなく「地域」で選ぶ（`ios/Igen/Features/Safety/SafetyPage.swift` が `Locale.autoupdatingCurrent.region` で分岐する）。runner の既定は US なので 988 Suicide & Crisis Lifeline が出る。**JP の窓口（いのちの電話・よりそいホットライン・まもろうよ こころ）を見るための Region 変更は、simtunnel では行わない**（設定アプリでの Region 変更も優先言語の変更と同じく SpringBoard のリロードを伴い、WDA が落ちてセッションが終了する恐れがある。上記の言語切り替えと同じ理由）。JP の窓口は実機・ローカル Simulator で確認する
- 危機ワードの再現（本番）: 相談本文に `backend/functions/src/crisis.ts` のキーワード（例: `want to die` / `死にたい`）を含めて送信する。キーワード判定は LLM 呼び出し・無料枠消費の前に行われるため費用も無料枠も消費しない
- 無料枠超過の再現（本番）: 同じ匿名ユーザーで同日 2 通目を送信すると HTTP 429 でペイウォールが自動表示される（LLM は呼ばれない）
- 返書の登場演出の再表示: UserDefaults `ritualCount` を消す（アプリ削除）。星図の「新しい星座が灯る」演出の再表示: UserDefaults `atlasSeenPersonIds.<uid>` を消す（アプリ削除）
- 演出を省略したい時: 設定アプリ > Accessibility > Motion > Reduce Motion（登場演出・星座の点灯演出・ボタンの光が省略される）

## 実行ナレッジ

（run-qa が実行中の flaky・落とし穴の知見を蓄積する。運用ルールは ~/.claude/skills/setup-qa/references/qa-md-format.md を参照）

### simtunnel の Simulator では App Check のデバッグトークンを載せないと送信が 401 になる

発見日: 2026-08-29。事象: 新しいセッションの新規インストール直後に相談を送ると、待機表示すら出ずに数秒で「The letter could not be delivered. Please try again later.」になった。ネットワークは生きており（ペイウォールに RevenueCat 由来の `$2.99 / month` が出る）、Cloud Logging では `POST /api/letters` が 401 を返している（`gcloud logging read --project igen-prod` の httpRequest。クライアントは 401 でトークンを強制更新して 1 回だけ再送するため 1 回の送信につき 401 が 2 件並ぶ）。デプロイ済みの Cloud Run サービス `api` に `IGEN_APP_CHECK_ENFORCEMENT` が設定されておらず、`backend/functions/src/appCheck.ts` の既定で `enforce` になるため、App Check トークンが無い・未登録のリクエストは 401 `app_check_failed` で弾かれる。runner の Simulator は `AppCheckDebugProviderFactory` になり、デバッグトークンはインストールごとに変わるため、セッションを作り直すたびに未登録の状態になる。

対処: CLAUDE.md「実装したUIの検証」の 4 のとおり、`FIRAAppCheckDebugToken` を環境変数に載せてアプリを起動し直す。`tmp/qa/launch-appcheck.sh <session>` がこれを行う（`~/.config/igen/appcheck-debug-token-simtunnel.secret` から読み、WDA の `POST /session` の capabilities の `environment` に載せて新しいセッションを作り、session id を `ios-wda.sh` のキャッシュへ書き戻す）。**起動中のまま launch すると activate になり環境変数が反映されない**ため、必ず terminate してから作り直す。なお同 secret ファイルのコメントにある `ios-wda.sh ... launch --env-file <ファイル>` という使い方は、`ios-wda.sh` に `--env-file` が実装されていないため現状は使えない。

### runner の Simulator が外部の名前解決をできなくなることがある

発見日: 2026-08-29。事象: セッション途中から Simulator の全 HTTP 通信が失敗し、相談の送信が約 300 秒後に「The letter could not be delivered. Please try again later.」になった。Safari で `bannzai.github.io`（同じセッションで直前に開けていた）も「Safari can't open the page because the server can't be found.」になり、cloudfunctions.net 固有ではなく DNS 全体の障害と判明（ローカル macOS からは同じホストを解決できる）。WDA 自体は生存しており `status` / `elements` には応答する。対処: セッションを立て直す（`simtunnel up <session> --force`）。アプリ側の不具合と誤判定しないよう、送信が失敗したら Simulator の Safari で任意の外部サイトを開いて切り分ける（ただし Safari の操作自体が WDA を落としうるため、送信前の定型手順にはしない。下記「Simulator の Safari で URL を開くと WDA が無応答になりセッションが落ちることがある」を参照）。

### Simulator の Safari で URL を開くと WDA が無応答になりセッションが落ちることがある

発見日: 2026-08-29。事象: セッション `igen-49`（run 33243817014）で、WDA が ready になった直後に `ios-wda.sh launch com.apple.mobilesafari` → アドレスバーを tap → `keys` で URL + 改行を送って外部サイトへ遷移させたところ、その直後から WDA (:8100) が `status` にも `elements` にも応答しなくなり、watchdog が 4 回連続の無応答でセッションを終了した（09:07:18 UTC にセッション維持開始 → 09:08:12 に無応答 1/4 → 09:09:27 に終了）。Safari を前面にしたままの `elements`（WDA の `GET /source`）は Web の DOM 全体をアクセシビリティツリーに展開するため重く、これが引き金になった可能性がある。

対処と順序: **ネットワークの切り分けのために Safari を開くことを送信前の定型手順にしない**。危機ワードを含む相談の送信は無料枠も LLM 費用も消費しないので、まずそれを送るのが最も安全な疎通確認になる（成功すれば Safety の確認項目も同時に消化できる）。送信が約 300 秒後に「The letter could not be delivered. Please try again later.」で失敗した時にだけ、切り分けとして Safari を使う。その場合も Safari を前面にしたまま `elements` を叩かず、スクリーンショット（下記の `GET /screenshot`）で判定し、確認が終わったらすぐ `terminate com.apple.mobilesafari` する。

### simtunnel で端末の優先言語を変えるとセッションが落ちる

発見日: 2026-08-29。事象: 設定アプリ > General > Language & Region > Add Language… で日本語を追加した直後、WDA (:8100) が 3 回連続でヘルスチェックに応答せず、workflow の watchdog がセッションを終了した（run 33239337299 が failure）。対処: 端末の優先言語は変更せず、「動作確認手段 > 再現が難しい操作の手順」の `-AppleLanguages` 起動引数でアプリだけ言語を変える。なおセッションが落ちなかったとしても、優先言語への「追加」では日本語 UI にはならない（判定は `ios/Igen/Shared/AppLanguage.swift` の `Bundle.main.preferredLocalizations.first == "ja"` のみで、日本語を 2 番目に足しても `en` のまま）。

### 言語を変えて起動した後は ios-wda.sh のセッション ID を差し替える

発見日: 2026-08-29。事象: 起動引数付きで作った WDA セッションでアプリを日本語起動した後、`ios-wda.sh` の `tap` / `swipe` を実行するとアプリがバックグラウンドへ落ち、ホーム画面や Spotlight が操作された。`ios-wda.sh` は自分が作った別のセッション（bundleId 無し = SpringBoard 相当）を `tmp/ios-wda/<cksum>.sid` にキャッシュしており、WDA がそのセッションのアプリを前面化するため。対処: 起動時に作ったセッション ID を同じファイルへ書き戻す（`tmp/qa/launch-lang.sh` が実施する）。

### simtunnel のスクリーンショットは MJPEG 経由だと取れないことがある

発見日: 2026-08-29。事象: `ios-wda.sh shot` が「MJPEG フレームを取得できませんでした」、`simtunnel screenshot` が「フレームを取得できなかった (受信 0 bytes)」を返した（WDA 自体は `status` / `elements` に応答しており生存していた）。どちらも MJPEG (serve_sim) 経由のため、serve_sim が未起動・停止していると撮れない。対処: WDA の `GET /screenshot`（base64 PNG）を使う。serve_sim に依存しない:

```bash
curl -s "http://simtunnel-<session>:8100/screenshot" | python3 -c 'import base64,json,sys; sys.stdout.buffer.write(base64.b64decode(json.load(sys.stdin)["value"]))' > shot.png
```

## 横断確認項目

## 1. 起動と認証

- [x] **初回起動**: インストール直後の起動でオンボーディング（Onboarding QA.md 参照）が表示され、閉じた後にホーム画面（星空・入力カード・「Ask the Greats」）が表示され、エラーアラートが出ない
  - 自動化: manual（Simulator の初回起動状態の作成と目視確認が必要）
- [x] **匿名認証**: 起動後にそのまま相談を送信でき、返書または相談窓口案内が返る（匿名サインインが完了している）
  - 自動化: manual（送信結果は Firebase / LLM の応答に依存する）

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **初回起動**: インストール直後の起動でオンボーディング（Onboarding QA.md 参照）が表示され、閉じた後にホーム画面（星空・入力カード・「Ask the Greats」）が表示され、エラーアラートが出ない

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-29**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/ac34f4dc-e339-4752-9caa-9a91f5060c80.jpg" width="320">
</details>

### **匿名認証**: 起動後にそのまま相談を送信でき、返書または相談窓口案内が返る（匿名サインインが完了している）

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-29**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/205294e7-3628-419b-b286-f2eeb77a2d01.png" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/854b1f00-7a3c-4bd2-aefc-3c881b52742f.png" width="320">
</details>

</details>

---

## 2. 英語モード（Dear Socrates）

- [x] **英語で一通り動作する**: 端末言語 en で表示名が Dear Socrates になり、オンボーディング → ホーム → 送信 → 返書 → 共有カード → 記録 → 星図 → ペイウォールがすべて英語表示で動作し、文字のはみ出し・重なりが無い
  - 自動化: manual（各画面の目視確認が必要。英語 UI は runner の既定ロケールで確認できる）
- [x] **返書の言語**: 英語で送信した返書は格言の原文がそのまま併記され、訳文・解説が英語になる
  - 自動化: manual（返書内容は LLM の生成結果）

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **英語で一通り動作する**: 端末言語 en で表示名が Dear Socrates になり、オンボーディング → ホーム → 送信 → 返書 → 共有カード → 記録 → 星図 → ペイウォールがすべて英語表示で動作し、文字のはみ出し・重なりが無い

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-29**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/854b1f00-7a3c-4bd2-aefc-3c881b52742f.png" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/75eb8e81-f8d6-40b4-9f6d-a18fd38581c7.png" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/11b2ef28-00d2-41be-8ad7-532b12973ed6.png" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/b67df28a-7eee-4037-86f3-68bcdb4b281a.png" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/dbb04ebc-1455-4ea6-b186-758ad67c1285.png" width="320">
</details>

### **返書の言語**: 英語で送信した返書は格言の原文がそのまま併記され、訳文・解説が英語になる

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-29**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/854b1f00-7a3c-4bd2-aefc-3c881b52742f.png" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/c54b4795-2b8b-4aca-8d8e-e44b07a54619.png" width="320">
</details>

</details>

---

## 3. プライバシー（静的検査）

- [x] **Analytics に相談本文を送らない**: `grep -rn logEvent ios/Igen` で列挙した全イベントのパラメータが `text_length` / `quote_id` / `letters_count` / `encounters_count` / `package` / `step` / `index` / `skipped` のみで、相談本文・返書本文・自由入力の文字列が含まれない
  - 自動化: manual（grep の出力を目視で判定する。エビデンスは grep 結果の記録）
- [x] **共有カードに悩み本文を含めない**: `ios/Igen/Features/Share/` 配下（`Components/ShareCardView.swift` を含む）が `letter.concern` を参照しない（`grep -rn concern ios/Igen/Features/Share --include=*.swift` が空）
  - 自動化: manual（grep の出力を目視で判定する）

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **Analytics に相談本文を送らない**: `grep -rn logEvent ios/Igen` で列挙した全イベントのパラメータが `text_length` / `quote_id` / `letters_count` / `encounters_count` / `package` / `step` / `index` / `skipped` のみで、相談本文・返書本文・自由入力の文字列が含まれない

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-29**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/15456f97-453c-49ef-a1ec-fafcec85463c.png" width="320">
</details>

### **共有カードに悩み本文を含めない**: `ios/Igen/Features/Share/` 配下（`Components/ShareCardView.swift` を含む）が `letter.concern` を参照しない（`grep -rn concern ios/Igen/Features/Share --include=*.swift` が空）

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-29**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/c7810997-a7d2-45cf-bd45-de67e54d55e8.png" width="320">
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

**確認日: 2026-08-29**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/b0bde2de-6ab9-4a95-980f-70f8a404c37e.png" width="320">
</details>

</details>

---

## 機能別 QA.md

- [Onboarding](ios/Igen/Features/Onboarding/QA.md) — 初回起動オンボーディング
- [Home](ios/Igen/Features/Home/QA.md) — ホーム画面（入力・送信・音声入力・ペイウォール導線）
- [Reply](ios/Igen/Features/Reply/QA.md) — 返書画面（登場演出・出典・原文併記・図解カード）
- [Safety](ios/Igen/Features/Safety/QA.md) — 危機ワード検知 → 相談窓口案内
- [Paywall](ios/Igen/Features/Paywall/QA.md) — 無料枠超過 → ペイウォール・購入・復元・法務リンク
- [Archive](ios/Igen/Features/Archive/QA.md) — 記録（日付ごとの相談履歴・再訪）
- [Atlas](ios/Igen/Features/Atlas/QA.md) — 星図（出会った偉人・プロフィール）
- [Share](ios/Igen/Features/Share/QA.md) — 共有カード
- [Licenses](ios/Igen/Features/Licenses/QA.md) — OSS ライセンス一覧

推奨の実行順（無料枠 1 日 1 通を活かす）: 初回起動のオンボーディング → Archive の 0 件表示・Atlas の未出会い表示 → Safety（無料枠を消費しない）→ Home の通常送信（1 通目）→ Reply → Share → Archive → Atlas → Home の 2 通目送信 → Paywall → Licenses。

## QA 対象外

- `Debug`（`ios/Igen/Features/Debug/DebugMenuPage.swift`）: ファイル全体が `#if DEBUG` で囲まれた開発者メニューで、リリースビルド（App Store 配信・simtunnel の Release ビルド）には含まれない。到達導線であるホームの「Dev」ピルも `#if DEBUG` 限定

残る 9 feature はすべてユーザー操作で到達できる画面を持つ（`ios/Igen/Utils/*`・`ios/Igen/Shared/*` は Firebase / RevenueCat の初期化と API クライアントで feature ディレクトリではない。横断確認項目「起動と認証」で覆う）。
