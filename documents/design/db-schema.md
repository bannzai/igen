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
| source | { work: {ja,en}, detail?: {ja,en}, origTitle?: string, year?: {ja,en} } | **出典。work は必須**（文献名・箇所・成立年）。year は表示ロケールに応じて切り替える（クライアントでは翻訳しない） |
| createdAt / updatedAt | Timestamp | seed 時にサーバータイムスタンプで付与 |

- **出典のないデータ・LLM が生成した文を入れない**（偽名言対策。PROJECT.md リスク 1）。原文・出典の必須性は整合性テストで検証する

### 名言 DB の投入経路

- 原本は `backend/functions/src/data/*.json`（レビュー・監修の対象）
- `backend/functions` で `npm run seed` を実行すると Firestore の `persons` / `quotes` へ投入される（doc id 固定の set のため冪等）
  - Emulator へ投入する場合: `FIRESTORE_EMULATOR_HOST=127.0.0.1:8282 npm run seed`（エミュレータを起動しておく）
  - 実プロジェクトへの投入は Firebase プロジェクト作成後（issue #4）

### users/{uid} — ユーザーの利用状況

書き込みは Functions のみ。クライアントは自分の uid 配下を read できる。

| フィールド | 型 | 説明 |
|---|---|---|
| freeQuota | { date: string, count: number, timeZone: string } | 無料枠（1 日 1 通）の消費状況。timeZone は初回リクエスト時の端末タイムゾーンで固定し（リクエストごとの変更で日付を往復させるリセット悪用の防止）、date はその timeZone での YYYY-MM-DD。日付が変わると新しい date で上書きされる（日次リセット） |
| ticketsUsed | number | 使用済みの相談チケット枚数。購入数（RevenueCat の non_subscriptions）との差分が残チケット |
| createdAt / updatedAt | Timestamp | サーバータイムスタンプ |

- 無料枠の消費・返却はトランザクションで行う（`backend/functions/src/quota.ts`）。LLM 失敗・危機判定で返書を返さなかった場合は返却する

### users/{uid}/letters/{letterId} — 相談と返書

書き込みは Functions のみ（`POST /letters`）。振り返り画面はクライアントがここを直接 read する。

| フィールド | 型 | 説明 |
|---|---|---|
| concern | string | 相談本文（センシティブデータ。Analytics・ログに載せない） |
| language | "ja" \| "en" | 返書の言語 |
| timeZone | string \| null | 相談時の端末タイムゾーン。履歴の日付表示を相談時のまま固定するために使う |
| requestId | string \| null | クライアント生成のリクエスト ID。POST /letters の冪等化（応答喪失時の再送で重複生成しない）に使う |
| consultedAt | Timestamp | 相談の受信時刻。履歴の日付表示の基準（createdAt は生成完了時のため深夜送信で翌日にずれる） |
| quoteId | string | 名言 DB の参照 |
| quote | { kind, text: {ja,en}, original, originalLanguage, source } | 名言 DB の値のスナップショット。クライアントは quotes コレクションを読めないため埋め込む。**本文の出どころは常に名言 DB**（ADR 0002） |
| personId | string \| null | 話者。ことわざ等は null |
| person | { id, name, born, died, title, bio, publicDomain } \| null | persons のスナップショット |
| oneliner / meaning / closing | string | LLM が生成する、ひとこと・意味と文脈・結び |
| diagram | { metaphor, meaning, usage } \| null | 話者がいない場合の図解カード |
| createdAt / updatedAt | Timestamp | サーバータイムスタンプ |

- 危機ワード検知時（`type: "safety"` 応答）は相談を**保存しない**（センシティブデータを残さない）

### users/{uid}/encounters/{personId} — 偉人図鑑（星図）の出会い状態

書き込みは Functions のみ（返書生成時に自動で追加）。星図画面はクライアントがここを直接 read する。

| フィールド | 型 | 説明 |
|---|---|---|
| personId | string | 出会った人物。ドキュメント id と一致 |
| person | Person スナップショット | 図鑑プロフィールの表示用 |
| lastQuoteId | string | 最後にもらった言葉 |
| createdAt | Timestamp | **初回の出会い**。再度の出会いでは更新しない |
| updatedAt | Timestamp | サーバータイムスタンプ |

## インデックス

`backend/firestore.indexes.json` に定義する。

| コレクション | フィールド | 用途 |
|---|---|---|
| letters | personId ASC, createdAt DESC | 星図のプロフィールで「その偉人からもらった返書」を新しい順に取得するクエリ（`LettersStore.fetchLetters(personId:)`） |
