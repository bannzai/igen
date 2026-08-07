---
paths:
  - ".plans/*.md"
---

# Plan ファイルチェックリスト

Plan mode でプランファイルを作成する際、以下のチェックリストをプランファイル末尾に追記すること。

前提スタック: SwiftUI (iOS 17+) + Firebase (Functions gen2 / Firestore / 匿名認証 / Analytics) + RevenueCat

## ルール
- 変更対象に応じて該当セクションのみ含める
- チェック項目は `- [ ]` 形式で記載
- プランには必ず変更対象ファイルごとに具体的な実装コード提案（コードブロック）を含めること

## チェックリストテンプレート

以下をプランファイル末尾に追記する。

---

## チェックリスト

### 実装内容
- [ ] 変更対象ファイルごとに具体的なコード提案をコードブロックで記載している
- [ ] 既存コードのパターン・構成を確認し、同じパターンで実装している
- [ ] 変更範囲が必要最小限であること

### iOS ビルド・テスト
- [ ] `xcodebuild build -project ios/Igen.xcodeproj -scheme Igen -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` が成功する（ログ全文を ./tmp に保存し warning / error を grep で検査）
- [ ] `xcodebuild test ... -only-testing:IgenTests` が全件パスする
- [ ] 新規・変更ロジックに対するユニットテストが存在する（なければ新規作成）

### バックエンド（backend/ 変更がある場合）
- [ ] `npm run lint` / `npm run build` / `npm test` が backend/functions で成功する（テストは emulator 配下）
- [ ] スキーマ変更がある場合、`documents/design/db-schema.md`・Functions・iOS の Codable struct を同一 PR で同期している
- [ ] 新規フィールドは Optional で追加している（firestore-rules.md）

### フォーマット
- [ ] 新規・編集した Swift ファイルに `swift-format -i` を適用済み（インデント2スペース）
- [ ] backend の TypeScript に Biome を適用済み

### UI（画面変更がある場合）
- [ ] `/sim-manager` でプロジェクト用シミュレータを起動し、実機挙動を目視確認（スクリーンショット取得）
- [ ] Maestro E2E（該当フローがあれば実行、なければ新規作成）

### 翻訳（UI 文言追加がある場合）
- [ ] `Text` / `String(localized:)` は英文で記述し、直上に `// ja:` コメントを付与
- [ ] `Localizable.xcstrings` に ja 翻訳を追加
- [ ] 医療を想起させる語（セラピー、カウンセリング、診断等）を UI 文言に使っていない

### 名言・格言データ（DB 追加・変更がある場合）
- [ ] すべてのデータに出典（人物・文献・言語）がある。出典不明・LLM 生成の文が混入していない
- [ ] 外国語由来のものは原文が併記されている
- [ ] 収録人物は死後 70 年経過（パブリックドメイン）の範囲である
- [ ] 訳文は、パブリックドメインの原文からの独自訳、または翻訳者・ライセンス・権利期間を確認済みのものである（現代の翻訳文には原著者と別に翻訳者の著作権が成立するため、市販書籍等の翻訳をそのまま取り込まない）

### Analytics（イベント追加がある場合）
- [ ] イベントパラメータに相談・返書の本文が含まれていない
