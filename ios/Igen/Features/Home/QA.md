---
feature: Home
verification: mobile-mcp
last_verified_commit: 78226c7062d7f2834aafa99d05625d3b6721836e
last_verified_at: 2026-08-30
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

- [x] **ホーム画面の表示**: 星空背景の上に見出し「Tell me about your day, or what's on your mind」、入力カード、「Ask the Greats」ボタン、ヘッダーの「Star Atlas」「Archive」ピル、「See the unlimited plan」リンクが表示され、文字の重なり・はみ出しが無い
  - 自動化: manual（レイアウトの目視確認が必要）
- [x] **テキスト入力と送信ボタンの活性**: 入力が空のとき「Ask the Greats」が無効（薄い表示）で、文字を入力すると有効になり、文字数カウンタが増える
  - 自動化: manual（活性状態の目視確認が必要）

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **ホーム画面の表示**: 星空背景の上に見出し「Tell me about your day, or what's on your mind」、入力カード、「Ask the Greats」ボタン、ヘッダーの「Star Atlas」「Archive」ピル、「See the unlimited plan」リンクが表示され、文字の重なり・はみ出しが無い

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-29**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/825bb59f-b1d1-4e35-a086-0034fa4ca751.png" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/31b49839-8341-4d76-aff8-36344442161c.png" width="320">
</details>

### **テキスト入力と送信ボタンの活性**: 入力が空のとき「Ask the Greats」が無効（薄い表示）で、文字を入力すると有効になり、文字数カウンタが増える

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-29**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/1a2c8d85-67d4-4692-a156-01de2955125b.jpg" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/3bc094ab-1673-4e6f-84f3-ad1f4ccb4c36.jpg" width="320">
</details>

</details>

---

## 2. 送信

- [x] **送信して返書画面へ遷移**: 相談本文を入力して「Ask the Greats」を押すと、キーボードが閉じて待機表示「The stars are searching for words…」が出て、返書画面（Reply）へ遷移する
  - 自動化: manual（返書は LLM の生成結果で内容が毎回変わる。本番では無料枠 1 通を消費する）
- [x] **待機表示の重なりなし**: 待機中に入力カード・ボタンが待機表示と重なって見えない（issue #36 の再発防止）
  - 自動化: manual（待機中のスクリーンショットの目視確認が必要）
- [ ] **文字数上限の警告**: 2,000 字（UTF-16）を超える本文を入力すると警告「Please keep it within 2,000 characters (now N)」が表示され、「Ask the Greats」が無効になる
  - 自動化: manual（長文の入力と目視確認が必要）
  - ⏭️ スキップ: main 取り込み前のセッションで確認済み（`a` を 2,010 文字入力してカウンタ 2,010・警告「Please keep it within 2,000 characters (now 2,010)」・「Ask the Greats」が無効になることを確認）。main の取り込みでオンボーディング等が入った後は再確認していないため、この記録では通過にしない
- [x] **送信失敗のアラート**: サーバーに到達できない状態で送信すると、保存済み結果の照会（最長 300 秒）の後にアラート「The letter could not be delivered. Please try again later.」が出て、「OK」で閉じると入力本文が保持されたままホームに戻る
  - 自動化: manual（サーバーに到達できない状態を作る必要がある。2026-08-29 の QA では runner の Simulator が名前解決できない状態で意図せず再現できた）

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **送信して返書画面へ遷移**: 相談本文を入力して「Ask the Greats」を押すと、キーボードが閉じて待機表示「The stars are searching for words…」が出て、返書画面（Reply）へ遷移する

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-29**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/0a882349-d46c-40a8-9522-14ca5ed50474.png" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/854b1f00-7a3c-4bd2-aefc-3c881b52742f.png" width="320">
</details>

### **待機表示の重なりなし**: 待機中に入力カード・ボタンが待機表示と重なって見えない（issue #36 の再発防止）

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-29**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/0a882349-d46c-40a8-9522-14ca5ed50474.png" width="320">
</details>

### **文字数上限の警告**: 2,000 字（UTF-16）を超える本文を入力すると警告「Please keep it within 2,000 characters (now N)」が表示され、「Ask the Greats」が無効になる

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

### **送信失敗のアラート**: サーバーに到達できない状態で送信すると、保存済み結果の照会（最長 300 秒）の後にアラート「The letter could not be delivered. Please try again later.」が出て、「OK」で閉じると入力本文が保持されたままホームに戻る

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-29**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/559b7051-a077-4879-8669-fdde990eee54.png" width="320">
</details>

</details>

---

## 3. 音声入力

- [ ] **音声入力**: マイクボタンを押すと音声認識・マイクの許可ダイアログが出て、許可後に「Listening…」が表示され、発話がテキストとして入力される
  - 自動化: manual（Simulator では音声入力を再現できないため実機で確認する）
  - ⏭️ スキップ: Simulator ではマイク入力を再現できない。実機で確認する
- [ ] **許可拒否時のアラート**: 許可を拒否した状態でマイクボタンを押すとアラート「Microphone or speech recognition is not allowed. Please allow them in the Settings app.」が出る
  - 自動化: manual（許可ダイアログの操作と目視確認が必要）
  - ⏭️ スキップ: main 取り込み前のセッションで確認済み（マイクボタン → 許可ダイアログで拒否 → アラート「Microphone or speech recognition is not allowed. Please allow them in the Settings app.」）。main の取り込み後は再確認していないため、この記録では通過にしない

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

- [x] **星図・記録・ペイウォールへの導線**: 「Star Atlas」で星図、「Archive」で記録、「See the unlimited plan」でペイウォールのシートがそれぞれ開き、戻るとホームに戻る
  - 自動化: manual（遷移先の目視確認が必要）

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **星図・記録・ペイウォールへの導線**: 「Star Atlas」で星図、「Archive」で記録、「See the unlimited plan」でペイウォールのシートがそれぞれ開き、戻るとホームに戻る

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-29**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/5db950e0-aa2c-4239-85c0-4078e41b3513.png" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/d83aaebc-5bec-4378-b8e1-634861f97bb8.png" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/73569495-ea10-4f59-9945-b8fa8ce763a5.png" width="320">
</details>

</details>
