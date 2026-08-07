---
paths:
  - "ios/Igen/Features/**/*.swift"
---

# コーディングルール（View/Page/Sheet - UI記述）

このドキュメントは、SwiftUI の View、Page、Sheet に関するUI記述のコーディングルールを定義します。

## UIの記述

### Viewは構造体で定義

- Viewは `var someView: some View` のようにプロパティで宣言しない
- 必ず `struct SomeView: View` のように構造体で定義する

### コンポーネント内部のTextやTextField

- String型の変数で表示内容を決定しない。Localizable.xcstrings の自動生成の対象外になるから
- TextやTextFieldなど、UIに表示される文字列は、TextやTextFieldに直接リテラルで渡す
- `let text: LocalizedStringKey` にしろということではありません。引数を受け取ったり変数を渡す書き方はやめてください
- 例外: 格言・ことわざの本文・原文・出典・偉人名・返書本文、および相談本文などのユーザーが入力したコンテンツはデータであり、変数のまま `Text` に渡してよい（localization-guidelines.md 参照）

### .padding

- .paddingを.top,.bottom,.leading,.trailingだけ使うのはやめましょう
- .verticalまたは.horizontalでレイアウトを整えてください

### Section header

- **Section の header に追加する Text には `.textCase(nil)` を追加する**
- SwiftUI の Section は、デフォルトで header の Text を大文字に変換するため、ローカライズされた文字列をそのまま表示する目的で無効化する

### alert/confirmationDialog/sheetの命名

- alertやconfirmationDialogの表示に使うプロパティの名前は、 `{usecase|feature name}{Alert|ConfirmationDialog|Sheet}IsPresented` のように命名してください
- 例: `paywallSheetIsPresented`, `safetyGuideSheetIsPresented`

## enum と View

- **enum に表示用の文字列やアイコンを返すプロパティは持たせない**
- `var label: String` や `var systemImage: String` のような表示ロジックは enum ではなく View に書く
- enum は純粋なデータ型として定義し、表示に関するロジックは使用側（View）で switch 文を使って判定する

## Xcode Preview

- **`#Preview` ではなく `PreviewProvider` を使用する**
- Swift 5.9で導入された `#Preview` マクロではなく、従来の `PreviewProvider` プロトコルを使用する

## Slot-based Layout

- コンポーネント設計はSlot-based Layoutの原則に従う
- UI要素（String, Color, UUID等）を抽象化して渡さない
- 具体的な型（Consultation, Reply, GreatFigure等）をそのまま渡す
- 異なる型には個別のコンポーネントを作成する
- **原則の例外**: 挙動が完全に同じで型だけが異なる場合、enum argumentで型を受け取ることを許容する

## `.disabled()` と `.onTapGesture` の組み合わせの禁止

- toolbar, ToolbarItem, Menu などのフレームワーク固有の挙動がある箇所では `.disabled()` + `.onTapGesture` パターンを使用しない。代わりに、Button の action 内に全てのロジック（条件分岐含む）を記述する

## UI実装後の見た目確認

- UIを実装・変更した場合は、`/sim-manager` でプロジェクト用シミュレータを起動し、`/verify-ui-mobile-mcp` でシミュレータ上の実行中アプリを目視確認する
