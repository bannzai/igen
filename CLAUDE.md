「偉言（igen）」という、悩みや今日のできごとを書くと、それに適した偉人が現れて出典付きの格言・ことわざで励ましてくれる iOS アプリを開発しています。チャットではなく「人生相談への返書」フォーマット。カウンセリング・セラピーは名乗らず、UI 文言にも医療を想起させる語（セラピー、カウンセリング、診断、処方など）を使いません。

要件・競合調査・マネタイズ・リスクは `documents/PROJECT.md` を参照してください。インフラ構成の決定は `documents/adr/0001-ios-swiftui-firebase-functions-firestore.md` にまとまっています。

## 技術構成

- クライアント: SwiftUI (iOS 17+)。`ios/` 配下
- バックエンド: Cloud Functions for Firebase (gen2) / Node.js 22 / TypeScript。`backend/` 配下。LLM 呼び出しと Firestore への書き込みはすべてここを経由する
- DB: Cloud Firestore。スキーマは `documents/design/db-schema.md` を単一の真実とする。ルールは `.claude/rules/firestore-rules.md`
- 認証: Firebase Authentication 匿名認証
- 課金: RevenueCat（相談チケット consumable + 聞き放題サブスク）
- Analytics: Firebase Analytics
- 法務ドキュメント: `docs/`（GitHub Pages で公開予定）
- UI デザイン: `design_handoff_igen/` が最終形（High-fidelity プロトタイプ）。UI 実装時は同ディレクトリの README をデザインの SSOT として再現する

## コードフォーマッター

- Swift: **swift-format**（Apple 公式）。indent は 2 スペース。Swift ファイルを新規作成・編集した場合、コミット前に `swift-format -i <対象ファイル>` を実行すること
- TypeScript (backend): **Biome**。lint と format を 1 ツールで完結させる

## 注意書き

- **main への push は禁止**
- **Maestro の成果物（`takeScreenshot` で生成される `.png` ファイル）はコミットしない**
- 名言・格言のデータに出典のないもの・LLM が生成したものを混入させない（`documents/PROJECT.md` のリスク 1「偽名言」参照）

## ビルド・テスト・UI検証・検証方法

### iOS（`ios/` スキャフォールド後）

コンパイルチェック:

```bash
xcodebuild build \
  -project ios/Igen.xcodeproj \
  -scheme Igen \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

単体テストの実行:

```bash
xcodebuild test \
  -project ios/Igen.xcodeproj \
  -scheme Igen \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:IgenTests
```

ビルド・テストのログは全文を `./tmp/` に保存し、warning / error を grep で検査して判定する。

### バックエンド（`backend/` スキャフォールド後）

```bash
cd backend/functions
npm run lint    # Biome
npm run build   # tsc
npm test        # firebase emulators:exec --only firestore 配下で実行（Firestore はモックしない）
```

LLM 呼び出しは依存注入でモックする。ローカル開発は Firebase Emulator Suite（プロジェクト ID `demo-igen`）を使い、実プロジェクトなしで完結させる。

### 実装したUIの検証

シミュレータ上での動作確認は `/sim-manager` を起点にプロジェクト固有のシミュレータを起動して行うこと。既存の任意のシミュレータを掴まない。

| 目的 | スキル |
|---|---|
| シミュレータの起動・管理（UI確認の起点） | `/sim-manager` |
| シミュレータ上での動作確認（中心） | `/verify-ui-mobile-mcp` |
| E2Eテストフローの作成 | `/maestro-flow-writer` |

### 実装後のテスト必須ルール

実装後は手動テスト前に必ず、以下のテストを実行する。該当するものがなければテストを新規作成する。作成・実行が難しい場合はユーザーに報告する。

- **ユニットテスト**: 該当する既存テストの実行、または新規テストの作成・実行
- **シミュレータでのUI確認**: UI変更がある場合、`/sim-manager` でシミュレータを起動し、シミュレータ上の実行中アプリで目視確認する

### PR作成時の動作確認の軌跡

- PRを作成する際は、動作確認のスクリーンショットを `gh-r2-image` でアップロードし、PR本文に埋め込んで軌跡を残すこと

<!-- qa-config begin -->
## QA

本リポジトリは QA.md 体系で手動 QA を管理する (整備: setup-qa skill、実施・記録: run-qa skill)。ルートの `QA.md` が起点で、feature ごとの QA.md がテスト項目と最終実行記録を持つ。

- 機能実装・UI 変更を含む PR は、作成前に該当 feature の QA を実施し、結果 (チェック・エビデンス・`last_verified_commit` / `last_verified_at`) を QA.md に記録する。未検証の項目は未検証である旨を QA.md に明記する (検証したことにしない)
- QA 対象 feature・対象外 feature・横断確認項目はルート `QA.md` を参照する
- QA.md のフォーマットは setup-qa skill の `references/qa-md-format.md` を SSOT とする (skill が無い環境では本リポジトリの既存 QA.md の形式に合わせる)
- 新規 feature の追加時は setup-qa skill の雛形で対応する QA.md を新設する
<!-- qa-config end -->
