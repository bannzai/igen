# 0002. 返書生成の LLM は OpenAI API（structured outputs）を使い、役割をマッチングと文脈づけに限定する

## Status

Accepted

## Context

返書生成 API（相談本文 → 偉人・格言のマッチング → 語りかけ形式の返書）には LLM が必要（[documents/PROJECT.md](../PROJECT.md) MVP スコープ 2）。要件は次のとおり。

- 日本語・英語の両方で返書を生成できること（US 向け Dear Socrates モード）
- 決まった JSON 形状で応答を受け取れること（クライアントの表示ブロックが固定のため）
- **格言本文を LLM に生成させないこと**（PROJECT.md リスク 1「偽名言」。ネット流通の名言は誤帰属だらけで、LLM に任せると捏造する）
- TypeScript（Cloud Functions gen2）から呼び出せること

候補は OpenAI（yomon [ADR 0006](https://github.com/bannzai/yomon/blob/main/documents/adr/0006-ai-openai.md) と同構成）と Anthropic Claude（[ADR 0001](0001-ios-swiftui-firebase-functions-firestore.md) 時点の候補）。

## Decision

- プロバイダ: **OpenAI API**、SDK は **openai（npm、v6）**。yomon で実績のある構成（structured outputs・secret 管理・DI モックのテスト）をそのまま流用し、Shipaton 2026 までの実装期間を機能開発に使う
- モデル: **`gpt-5.6`** をデフォルトとし、モデル ID は環境変数 `OPENAI_MODEL` で差し替え可能にする（コスト調整をコード変更なしで行う。yomon ADR 0006 と同方針）
- 出力形式: **structured outputs（`response_format` の `json_schema` + `strict: true`）** で応答の JSON 形状を API レベルで保証する
- **LLM の役割はマッチングと文脈づけに限定する**:
  - LLM の応答は `quoteId`（名言 DB の id）+ ひとこと・意味と文脈・結び・図解カードのみ
  - `quoteId` はスキーマの enum に**名言 DB の id 一覧を埋め込み**、DB に存在しない格言を返せないよう API レベルで制約する
  - 格言本文・原文・出典は応答に含めず、サーバーが DB の値をそのまま返書に組み立てる（LLM 経由の改変を構造的に排除）
- 認証: `OPENAI_API_KEY` を Firebase Secret Manager（`defineSecret`）で管理する
- テスト: LLM は `ComposeLetterFn` として依存注入し、テストではモックする（実 API を呼ばない）

## Consequences

- 良い点
  - 偽名言対策が「レビューで防ぐ」ではなく「スキーマと組み立てで構造的に防ぐ」形になる
  - yomon の実装パターン（requestValidatedJson・意味的バリデーション + 1 回リトライ）を流用できる
  - モデル変更・コスト調整が環境変数で完結する
- 悪い点・トレードオフ
  - 名言 DB が増えると enum とプロンプトに載せる DB 情報が長くなる。収録数が数百件規模になったら、事前絞り込み（テーマタグでの候補選定）を検討する
  - マッチング品質は DB の収録数に依存する。初期は 9 件のため、悩みによっては最適でない格言が選ばれうる（DB 拡充で改善する）
