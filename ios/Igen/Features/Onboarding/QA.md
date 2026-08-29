---
feature: Onboarding
verification: mobile-mcp
last_verified_commit: null
last_verified_at: null
---

# Onboarding QA

## 関連リンク

- 仕様: https://github.com/bannzai/igen/issues/42 （初回起動オンボーディングの設計と実装）
- 関連: https://github.com/bannzai/igen/pull/56 （実装）

## 仕様チェックリスト

| ID | 期待挙動 | 対応項目 |
|----|---------|---------|
| S1 | 初回起動時にオンボーディングが表示され、閉じた後は再表示されない | 初回起動で表示される、完了後は再表示されない |
| S2 | 「書く → 偉人が現れる → 星図に増えていく」という体験の価値を最初の相談の前に伝える | 各画面の内容 |
| S3 | 日本語は 3 画面の短尺、英語は信頼の根拠（出典）を足した 4 画面の長尺にする | 画面数がロケールで変わる |
| S4 | 最後の画面の「最初の 1 通を書く」でホームの入力へ着地する | 最終画面から開始する |
| S5 | どの画面からでもスキップできる | スキップする |

## 1. 表示と遷移

- [ ] **初回起動で表示される**: アプリのインストール直後の初回起動でオンボーディングが全画面表示され、ホームの入力欄より前に出る
  - 自動化: manual（未インストール状態からの初回起動が必要。simtunnel ではセッション起動直後のみ確認できる）
- [ ] **各画面の内容**: 1 枚目「A letter from across time for tonight」、2 枚目「Write and a great figure appears」（書く → 偉人が現れる → 出典つきの返書の 3 ステップ）、（英語のみ）「Every word has a source」、最後「With every letter your night sky grows」が表示され、文字の重なり・はみ出しが無い
  - 自動化: manual（各画面の目視確認が必要）
- [ ] **画面数がロケールで変わる**: 英語では 4 画面（進捗ドットが 4 つ）、日本語では 3 画面（出典の画面が無く進捗ドットが 3 つ）になる
  - 自動化: manual（端末言語の切り替えが必要。手順はルート QA.md「再現が難しい操作の手順」）
- [ ] **次へ進む**: 「Next」で次の画面へ進み、進捗ドットの現在位置が動く。横スワイプでも同じように進む
  - 自動化: manual（遷移の目視確認が必要）
- [ ] **最終画面から開始する**: 最終画面のボタンが「Write your first letter」になり、押すとオンボーディングが閉じてホームの入力画面が表示される
  - 自動化: manual（遷移の目視確認が必要）

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **初回起動で表示される**: アプリのインストール直後の初回起動でオンボーディングが全画面表示され、ホームの入力欄より前に出る

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

### **各画面の内容**: 1 枚目「A letter from across time for tonight」、2 枚目「Write and a great figure appears」（書く → 偉人が現れる → 出典つきの返書の 3 ステップ）、（英語のみ）「Every word has a source」、最後「With every letter your night sky grows」が表示され、文字の重なり・はみ出しが無い

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

### **画面数がロケールで変わる**: 英語では 4 画面（進捗ドットが 4 つ）、日本語では 3 画面（出典の画面が無く進捗ドットが 3 つ）になる

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

### **次へ進む**: 「Next」で次の画面へ進み、進捗ドットの現在位置が動く。横スワイプでも同じように進む

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

### **最終画面から開始する**: 最終画面のボタンが「Write your first letter」になり、押すとオンボーディングが閉じてホームの入力画面が表示される

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

</details>

---

## 2. スキップと再表示

- [ ] **スキップする**: 右上の「Skip」を押すとオンボーディングが閉じてホームが表示される
  - 自動化: manual（遷移の目視確認が必要）
- [ ] **完了後は再表示されない**: オンボーディングを閉じた後にアプリを終了して再起動すると、オンボーディングは表示されずホームが出る
  - 自動化: manual（アプリの終了・再起動と目視確認が必要）

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **スキップする**: 右上の「Skip」を押すとオンボーディングが閉じてホームが表示される

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

### **完了後は再表示されない**: オンボーディングを閉じた後にアプリを終了して再起動すると、オンボーディングは表示されずホームが出る

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

</details>
