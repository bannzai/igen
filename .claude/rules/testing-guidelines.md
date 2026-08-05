---
paths:
  - "ios/IgenTests/**/*.swift"
  - "ios/IgenUITests/**/*.swift"
  - "backend/functions/**/*.test.ts"
  - ".maestro/**/*.yaml"
---

# テストガイドライン

このドキュメントは、igen プロジェクトのテストディレクトリの用途とテスト作成のガイドラインを定義します。

## テストディレクトリの用途

### ios/IgenTests/

**ロジックの単体テスト**を配置する。ビジネスロジック、計算関数、ユーティリティ関数などのユニットテストを書く。

- 配置場所: プロダクションコードのディレクトリ構造と一致させる
  - プロダクション: `ios/Igen/Features/Home/ConsultationInput.swift`
  - テスト: `ios/IgenTests/Features/Home/ConsultationInputTests.swift`
- Swift Testing (`@Test` / `#expect`) を使用する

### ios/IgenUITests/

**UITestとAppStoreスクリーンショット自動化**を行う。

### backend/functions/

**バックエンドのテスト**を配置する。テストファイルは対象と同じディレクトリに `*.test.ts` で置く。

- Vitest を `firebase emulators:exec --only firestore` 配下で実行し、Firestore は実エミュレータに接続する（Firestore をモックしない）
- LLM 呼び出しは依存注入でモックする。**テストから実 LLM API を呼ばない**（コストと再現性のため）
- 名言 DB のデータ検証（出典必須・原文必須などの整合性チェック）もテストとして書く

### .maestro/

**Maestro E2Eテスト**を配置する。

- 配置場所: `.maestro/flows/` にYAMLフローファイルを配置
- 実行方法: `maestro test .maestro/flows/`
- フローの作成は `/maestro-flow-writer` を参照する
- 注意: 返書生成はバックエンド（LLM）に依存する。E2E フローの前提条件（エミュレータ・スタブの起動方法）をフロー内コメントまたは README に明記する
