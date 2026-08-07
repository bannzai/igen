---
paths:
  - "ios/Igen/Features/**/*.swift"
  - "ios/Igen/Utils/Analytics/**/*.swift"
---

# コーディングルール（Analytics）

このドキュメントは、Analytics（イベントトラッキング）に関するコーディングルールを定義します。

## 相談本文を送らない

- Analytics のイベントパラメータに、ユーザーが入力した悩み・相談の本文や返書の本文を**絶対に含めない**（firestore-rules.md「データ設計の決めごと」と同一原則）
- 送ってよいのは件数・文字数・偉人 ID などのメタ情報のみ

## イベント名の制限

- `analytics.logEvent` に渡す文字列は、**40文字以内**という制限があるので注意してください
- 40文字以上になりそうな場合は機能名部分を2~3文字に略して送るようにしましょう

## イベント名は必ずハードコードで明示的に記述する

イベント名は文字列補間や三項演算子を使わず、ハードコードで記述する。条件によってイベント名が変わる場合は、if文で分岐してそれぞれのイベント名を明示的に書く。

### 良い例

```swift
if consultation == nil {
  analytics.logEvent("consultation_created", parameters: [...])
} else {
  analytics.logEvent("consultation_updated", parameters: [...])
}
```

### 悪い例

```swift
analytics.logEvent("consultation_\(consultation == nil ? "created" : "updated")", parameters: [...])
```

理由: イベント名を検索しやすく、コードレビューや解析時に一目でどのイベントが送信されているかわかるようにするため

## ボタン押下時と処理成功時の両方で送信する

ユーザーのインタラクションを正確に追跡するため、ボタン押下時と処理成功時の両方でanalyticsを送信する。

### ボタン押下時

- Button の action では analytics の処理（`logEvent`）を一番初めに行う
- logEvent に渡すパラメータの準備が必要なら、action の先頭（logEvent の直前）で宣言してよい。logEvent を物理的に最初の行にするためだけにパラメータを Button の外へ出さない
- イベント名: `{feature}_button_pressed`（ユーザーがボタンを押した事実を記録）

### 処理成功時

- イベント名: `{feature}_completed` や `{feature}_updated`（処理が成功した事実を記録）

### 例：相談の送信ボタン

- ボタン押下時: `home_ask_button_pressed`
- 返書生成成功時: `reply_generated`

理由: ボタン押下と処理成功を分けることで、エラー率や離脱率の分析が可能になる

## Toggle の追跡

Toggle の場合は Binding の setter でイベントを送信する。
`.onChange(of:)` は設定同期・購入状態の反映・リセット処理などプログラム的な状態更新でも発火し、ユーザーが操作していない `feature_enabled` / `feature_disabled` が記録されて利用率・離脱分析が歪むため、操作イベントの送信には使わない。

```swift
Toggle("Enable Feature", isOn: Binding(
  get: { isEnabled },
  set: { newValue in
    analytics.logEvent(newValue ? "feature_enabled" : "feature_disabled")
    isEnabled = newValue
  }
))
```

## 副作用は保存メソッド内ではなく呼び出し元で処理する

Analytics、dismiss、navigationなどの副作用は、保存メソッド内ではなく呼び出し元で処理する。

### 良い例

```swift
Button {
  analytics.logEvent("button_pressed")
  do {
    try saveData()
    analytics.logEvent("data_saved")
    dismiss()
  } catch {
    self.error = error
  }
}
```

### 悪い例

```swift
func saveData() {
  // データ保存
  analytics.logEvent("data_saved")  // ❌ 保存メソッド内でanalyticsを送信
  dismiss()  // ❌ 保存メソッド内でdismiss
}
```

理由:
- 保存メソッド（`saveXXX()`）は純粋にデータの保存のみを行い、analytics送信やdismiss()などの副作用は含めない
- 保存メソッドの責務を明確にし、テストや再利用が容易になる
