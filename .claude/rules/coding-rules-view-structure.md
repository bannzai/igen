---
paths:
  - "ios/Igen/Features/**/*.swift"
---

# コーディングルール（View/Page/Sheet - 構造）

このドキュメントは、SwiftUI の View、Page、Sheet に関する構造面のコーディングルールを定義します。

## Feature構造とディレクトリ構成

### 各Featureは独立したディレクトリに配置する

- 機能ごとに `ios/Igen/Features/{FeatureName}/` ディレクトリを作成
- 例: `Features/Home/`, `Features/Reply/`, `Features/Archive/`, `Features/Collection/`

### エントリーポイントの命名規則

- 各Featureのエントリーポイントは、Viewである限り `{FeatureName}Page` で統一
- Sheet形式でも `{FeatureName}Page` とする（`{FeatureName}Sheet` は使わない）
- 例: `HomePage`, `ReplyPage`, `ArchivePage`

### コンポーネントの配置と命名

- `{Feature}PageBody`以外のprivate structは、`Features/{FeatureName}/Components/` ディレクトリに配置
- コンポーネント名は `{FeatureName}{ComponentName}` の形式で命名（Feature名をprefixとして付ける）
- ファイル名もコンポーネント名と同じにする
- 例: `Features/Reply/Components/ReplyQuoteCard.swift`

## PageBodyパターン

- **PageBodyパターンは非同期処理が必要な場合のみ使用する**
- PageやSheetといったエントリーポイントで非同期のデータ取得（Firestore のフェッチ等）が必要な場合、`{Feature}Page` でデータ取得を解決し、取得成功時に `{Feature}PageBody` を表示する
- 非同期処理が不要な場合は、PageBodyを作らず直接Pageにbodyを実装する
- PageBodyは常に `private struct` で宣言

## 状態管理

### @State には private をつけない

### 状態はコンポーネントに閉じる

- コールバック（onSuccess, onError, onSave, onCompleteなど）は極力書かない
- そのコンポーネントやPage、Sheet内部で処理を完結させる
- どうしても書く必要がある場合はコメントに理由を残す

## イニシャライザ

- 可能な限りmemberwise initializerを使用する。initは極力自分では書かない
- @State varもmemberwise initializerの対象になるので、条件付き初期化が必要な場合でもinitを書かずにmemberwise initializerで初期値を渡す
- memberwise initializerに使用されるプロパティを struct,class のすぐ下に書く。その他のstruct, classを構成するinternal,privateなプロパティをその下に書く
- **initに全てのフィールドをパラメータとして受け取ることを許容する**
  - テストやプレビューでのデータ作成を容易にするために、全てのフィールドをinitのパラメータとして追加することは許容される
  - 特定のパラメータが主にテストコードでのみ使用される場合は、そのパラメータの上にコメントで明記する
