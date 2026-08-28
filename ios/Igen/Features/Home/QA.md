---
feature: Home
verification: mobile-mcp
last_verified_commit: null
last_verified_at: null
---

# Home QA

## 関連リンク

- 仕様: https://github.com/bannzai/igen/issues/7 （やること・完了条件）
- 関連: https://github.com/bannzai/igen/pull/24 （実装）、https://github.com/bannzai/igen/pull/37 （待機文言の重なり解消・再試行強化）、https://github.com/bannzai/igen/issues/36 （実機フィードバック）

## 仕様チェックリスト

| ID | 期待挙動 | 対応項目 |
|----|---------|---------|
| S1 | 星空背景（藍〜紫のグラデーション + 金色の星）の中に入力エリアだけが置かれ、常時アニメーションする | ホーム画面の表示 |
| S2 | 入力エリアにプレースホルダ「きょうのできごと・お悩みをどうぞ」相当の案内が出て、テキスト入力できる | テキスト入力と送信ボタンの活性 |
| S3 | 音声入力（Speech framework）でテキストが入力でき、マイク・音声認識の許可導線がある | 音声入力 |
| S4 | 送信ボタン「偉人に聞く」で返書生成 API を呼び、返書画面へ遷移する | 送信して返書画面へ遷移 |
| S5 | 生成待ちの間に演出（待機表示）が出る | 送信して返書画面へ遷移 |
| S6 | 相談本文は 2,000 字（UTF-16）まで。超過時は警告が出て送信できない | 文字数上限の警告 |
| S7 | 送信失敗時はアラートで通知する（PR #37: 通信断時は保存済み結果の照会で回復を試みる） | 送信失敗のアラート |

## 1. 表示

- [ ] **ホーム画面の表示**: 星空背景の上に見出し「Tell me about your day, or what's on your mind」、入力カード、「Ask the Greats」ボタン、ヘッダーの「Star Atlas」「Archive」ピル、「See the unlimited plan」リンクが表示され、文字の重なり・はみ出しが無い
  - 自動化: manual（レイアウトの目視確認が必要）
- [ ] **テキスト入力と送信ボタンの活性**: 入力が空のとき「Ask the Greats」が無効（薄い表示）で、文字を入力すると有効になり、文字数カウンタが増える
  - 自動化: manual（活性状態の目視確認が必要）

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **ホーム画面の表示**: 星空背景の上に見出し「Tell me about your day, or what's on your mind」、入力カード、「Ask the Greats」ボタン、ヘッダーの「Star Atlas」「Archive」ピル、「See the unlimited plan」リンクが表示され、文字の重なり・はみ出しが無い

<details><summary>動作確認スクショ</summary>

（未実行）

</details>

### **テキスト入力と送信ボタンの活性**: 入力が空のとき「Ask the Greats」が無効（薄い表示）で、文字を入力すると有効になり、文字数カウンタが増える

<details><summary>動作確認スクショ</summary>

（未実行）

</details>

</details>

---

## 2. 送信

- [ ] **送信して返書画面へ遷移**: 相談本文を入力して「Ask the Greats」を押すと、キーボードが閉じて待機表示「The stars are searching for words…」が出て、返書画面（Reply）へ遷移する
  - 自動化: manual（返書は LLM の生成結果で内容が毎回変わる。本番では無料枠 1 通を消費する）
- [ ] **待機表示の重なりなし**: 待機中に入力カード・ボタンが待機表示と重なって見えない（issue #36 の再発防止）
  - 自動化: manual（待機中のスクリーンショットの目視確認が必要）
- [ ] **文字数上限の警告**: 2,000 字（UTF-16）を超える本文を入力すると警告「Please keep it within 2,000 characters (now N)」が表示され、「Ask the Greats」が無効になる
  - 自動化: manual（長文の入力と目視確認が必要）
- [ ] **送信失敗のアラート**: サーバーに到達できない状態で送信すると、保存済み結果の照会（最長 300 秒）の後にアラート「The letter could not be delivered. Please try again later.」が出る
  - 自動化: todo

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **送信して返書画面へ遷移**: 相談本文を入力して「Ask the Greats」を押すと、キーボードが閉じて待機表示「The stars are searching for words…」が出て、返書画面（Reply）へ遷移する

<details><summary>動作確認スクショ</summary>

（未実行）

</details>

### **待機表示の重なりなし**: 待機中に入力カード・ボタンが待機表示と重なって見えない（issue #36 の再発防止）

<details><summary>動作確認スクショ</summary>

（未実行）

</details>

### **文字数上限の警告**: 2,000 字（UTF-16）を超える本文を入力すると警告「Please keep it within 2,000 characters (now N)」が表示され、「Ask the Greats」が無効になる

<details><summary>動作確認スクショ</summary>

（未実行）

</details>

### **送信失敗のアラート**: サーバーに到達できない状態で送信すると、保存済み結果の照会（最長 300 秒）の後にアラート「The letter could not be delivered. Please try again later.」が出る

<details><summary>動作確認スクショ</summary>

（未実行）

</details>

</details>

---

## 3. 音声入力

- [ ] **音声入力**: マイクボタンを押すと音声認識・マイクの許可ダイアログが出て、許可後に「Listening…」が表示され、発話がテキストとして入力される
  - 自動化: manual（Simulator では音声入力を再現できないため実機で確認する）
- [ ] **許可拒否時のアラート**: 許可を拒否した状態でマイクボタンを押すとアラート「Microphone or speech recognition is not allowed. Please allow them in the Settings app.」が出る
  - 自動化: manual（許可ダイアログの操作と目視確認が必要）

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **音声入力**: マイクボタンを押すと音声認識・マイクの許可ダイアログが出て、許可後に「Listening…」が表示され、発話がテキストとして入力される

<details><summary>動作確認スクショ</summary>

（未実行）

</details>

### **許可拒否時のアラート**: 許可を拒否した状態でマイクボタンを押すとアラート「Microphone or speech recognition is not allowed. Please allow them in the Settings app.」が出る

<details><summary>動作確認スクショ</summary>

（未実行）

</details>

</details>

---

## 4. 画面遷移

- [ ] **星図・記録・ペイウォールへの導線**: 「Star Atlas」で星図、「Archive」で記録、「See the unlimited plan」でペイウォールのシートがそれぞれ開き、戻るとホームに戻る
  - 自動化: manual（遷移先の目視確認が必要）

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **星図・記録・ペイウォールへの導線**: 「Star Atlas」で星図、「Archive」で記録、「See the unlimited plan」でペイウォールのシートがそれぞれ開き、戻るとホームに戻る

<details><summary>動作確認スクショ</summary>

（未実行）

</details>

</details>
