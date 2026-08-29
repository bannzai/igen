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

シミュレータでの動作確認は、ローカル Mac ではなく GitHub Actions 上の iOS Simulator（simtunnel。caller workflow は `.github/workflows/simulator-session.yml`）で行う。ローカルのシミュレータは開発機のリソースを圧迫するため、ローカル `sim-boot`（`/sim-manager`）を使うのは次の場合だけにする:

- 変更に秘匿情報が含まれていて、public なこのリポジトリへ push できない
- simtunnel が使えない（Maestro E2E・XCUITest など runner 上で実行できない用途、tailnet 未接続、macOS Runner の並列上限など。判断基準は `~/.claude/skills/ios-simulator/SKILL.md` の Phase 1）

手順（このリポジトリの作業ディレクトリで実行する。session 名は小文字英数字とハイフンのみで、worktree ごとに一意にする。例: `igen-41`）:

1. 変更をコミットしてブランチを push する（通常は PR も作成する）。動作確認のために commit / PR を作ってよい
2. `~/ghq/github.com/bannzai/simtunnel/local/simtunnel up <session> --ref <ブランチ名> --wait` でセッションを起動する。build job がそのブランチを Release でビルドして runner の Simulator に install する（Release は本番 igen-prod に向くため、相談の送信は実 LLM 費用が発生する。Debug は Firebase Emulator に向くため runner 上では通信できない）
3. `~/ghq/github.com/bannzai/simtunnel/local/simtunnel mcp-config <session> <worktree の絶対パス> --name mobile` で `.mcp.json` を書き、`/verify-ui-mobile-mcp` で確認する
4. App Check の検証を通したい場合（enforce 時や `app check verified` ログの確認）: runner のシミュレータは Debug provider になり、登録済みデバッグトークンが必要。セッション確立後にアプリを terminate し、WDA の `POST /session/{sid}/wda/apps/launch` の `environment` に `FIRAAppCheckDebugToken=<トークン>` を載せて relaunch してから確認する（トークンは `~/.config/igen/appcheck-debug-token-simtunnel.secret`。argv・ログ・リポジトリに値を書かない）。monitor モードならトークン無しでもリクエストは処理される（検証失敗として `app check verification failed` がログに残るだけで、検証を通過するわけではない）
5. 確認が終わったら `~/ghq/github.com/bannzai/simtunnel/local/simtunnel down <session>` で runner を解放する（放置しても `duration_minutes` で自動終了する）

| 目的 | スキル |
|---|---|
| シミュレータの用意（UI確認の起点。simtunnel とローカルの使い分け） | `/ios-simulator` |
| シミュレータ上での動作確認（中心） | `/verify-ui-mobile-mcp` |
| E2Eテストフローの作成 | `/maestro-flow-writer` |

### 実装後のテスト必須ルール

実装後は手動テスト前に必ず、以下のテストを実行する。該当するものがなければテストを新規作成する。作成・実行が難しい場合はユーザーに報告する。

- **ユニットテスト**: 該当する既存テストの実行、または新規テストの作成・実行
- **シミュレータでのUI確認**: UI変更がある場合、上記「実装したUIの検証」の手順で simtunnel のセッションを起動し、runner 上のシミュレータで実行中のアプリを目視確認する

### PR作成時の動作確認の軌跡

- PRを作成する際は、動作確認のスクリーンショットを `gh-r2-image` でアップロードし、PR本文に埋め込んで軌跡を残すこと
