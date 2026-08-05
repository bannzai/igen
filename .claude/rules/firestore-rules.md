---
paths:
  - "backend/**"
  - "documents/design/db-schema.md"
---

# Firestore ルール（スキーマ・アクセス方針・マイグレーション）

このドキュメントは、igen の DB（Cloud Firestore）に関する決めごとを定義します。構成決定の経緯は [ADR 0001](../../documents/adr/0001-ios-swiftui-firebase-functions-firestore.md) を参照。

## スキーマ定義の置き場所

- スキーマの単一の真実は `documents/design/db-schema.md`。コレクション構造・フィールド・型・インデックスをここに書く
- スキーマを変更する PR では、db-schema.md・Functions のコード・iOS の Codable struct を同一 PR で同期する

## クライアントからのアクセス方針

- **書き込みは Functions (Admin SDK) 経由に限定する**。クライアントは Firestore に直接書き込まない
  - 理由: 返書・図鑑の偽造や改竄の防止と、名言 DB の出典整合性（出典なしデータの混入防止）をサーバー側で保証するため
- クライアントからの読み取りは、自分のデータ（`users/{uid}` 配下）のみ security rules で許可する（`request.auth.uid == uid`）
- security rules は `backend/firestore.rules` に置き、上記方針（クライアント write 全面禁止・自分の read のみ許可）を実装する。方針を変える場合は ADR を書く

## マイグレーション

- 既存フィールドの型変更・リネームはしない。新フィールドを Optional として追加し、読み取り側で両対応する（クライアントの旧バージョンが残り続けるため）
- 一括変換が必要な場合は、Functions に管理用スクリプトとして実装し、実行手順と実行記録を PR に残す

## データ設計の決めごと

- ドキュメントには作成時刻 `createdAt`・更新時刻 `updatedAt`（サーバータイムスタンプ）を必ず持たせる
- 相談履歴はユーザーの内心に関わるセンシティブなデータとして扱う。Analytics やログに相談本文を含めない（イベントには件数・文字数などのメタ情報のみ許可）
- 名言・格言データは出典（人物・文献・言語）と原文を必須フィールドとする。出典のないデータ・LLM が生成した文を名言 DB に入れない
