# DB スキーマ (Cloud Firestore)

igen の Firestore スキーマの単一の真実。コレクション構造・フィールド・型・インデックスをここに定義する。アクセス方針・マイグレーションの決めごとは `.claude/rules/firestore-rules.md` を参照。

## 共通の決めごと

- すべてのドキュメントに `createdAt` / `updatedAt` (サーバータイムスタンプ) を持たせる
- 書き込みは Functions (Admin SDK) 経由のみ。クライアントは自分の `users/{uid}` 配下の read のみ (`backend/firestore.rules`)
- 既存フィールドの型変更・リネームはしない。新フィールドは Optional で追加する

## コレクション

スキーマは各実装 issue で本ドキュメントに追記する。

### persons/{personId} — 名言 DB の収録人物

データの実体（バージョン管理される原本）は `backend/functions/src/data/persons.json`。TypeScript 型は `backend/functions/src/quotesDb.ts` の `Person`。

| フィールド | 型 | 説明 |
|---|---|---|
| id | string | slug（例: `seneca`）。ドキュメント id と一致させる |
| name | { ja, en } | 表示名 |
| born | number \| null | 生年。紀元前は負数。不詳は null |
| died | number | 没年。紀元前は負数 |
| title | { ja, en } | 肩書き（図鑑・返書の話者ブロックで表示） |
| bio | { ja, en } | 略歴（図鑑プロフィールで表示） |
| publicDomain | { confirmed: boolean, note?: string } | 没後 70 年経過（パブリックドメイン）の確認結果 |
| createdAt / updatedAt | Timestamp | seed 時にサーバータイムスタンプで付与 |

- 収録できるのは没後 70 年経過の人物のみ（documents/PROJECT.md リスク 3）。整合性テスト（`quotesDb.test.ts`）で機械的に検証する

### quotes/{quoteId} — 名言・格言・ことわざ

データの実体は `backend/functions/src/data/quotes.json`。TypeScript 型は `quotesDb.ts` の `Quote`。

| フィールド | 型 | 説明 |
|---|---|---|
| id | string | slug。ドキュメント id と一致させる |
| kind | "quote" \| "proverb" | 名言 / ことわざ・故事成語 |
| text | { ja, en } | 訳文（アプリ独自訳。原文を併記して検証可能にする） |
| original | string | **原文。必須**。どのロケールでも改変せず併記する |
| originalLanguage | string | 原文の言語（ISO 639-1: la, zh, de, ja 等） |
| personId | string \| null | 発祥人物。ことわざ等で特定できない場合は null（返書画面では図解カードで表示） |
| themes | string[] | マッチングの手がかりになるテーマタグ（ja） |
| source | { work: {ja,en}, detail?: {ja,en}, origTitle?: string, year?: string } | **出典。work は必須**（文献名・箇所・成立年） |
| createdAt / updatedAt | Timestamp | seed 時にサーバータイムスタンプで付与 |

- **出典のないデータ・LLM が生成した文を入れない**（偽名言対策。PROJECT.md リスク 1）。原文・出典の必須性は整合性テストで検証する

### 名言 DB の投入経路

- 原本は `backend/functions/src/data/*.json`（レビュー・監修の対象）
- `backend/functions` で `npm run seed` を実行すると Firestore の `persons` / `quotes` へ投入される（doc id 固定の set のため冪等）
  - Emulator へ投入する場合: `FIRESTORE_EMULATOR_HOST=127.0.0.1:8282 npm run seed`（エミュレータを起動しておく）
  - 実プロジェクトへ投入する場合: `GCLOUD_PROJECT=<project-id> npm run seed`（`GCLOUD_PROJECT` 未設定だと `demo-igen` にフォールバックするため必ず指定する。Firebase プロジェクト作成は issue #4）

### users/{uid}（issue #6 で定義）

- 相談と返書の履歴を `users/{uid}` 配下に保存する
- 無料枠（1 日 1 通）の判定に使う利用状況もここに置く

## インデックス

`backend/firestore.indexes.json` に定義する（現状なし）。
