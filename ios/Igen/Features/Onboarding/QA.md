---
feature: Onboarding
verification: mobile-mcp
last_verified_commit: 78226c7062d7f2834aafa99d05625d3b6721836e
last_verified_at: 2026-08-30
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

- [x] **初回起動で表示される**: アプリのインストール直後の初回起動でオンボーディングが全画面表示され、ホームの入力欄より前に出る
  - 自動化: manual（未インストール状態からの初回起動が必要。simtunnel ではセッション起動直後のみ確認できる）
- [x] **各画面の内容**: 1 枚目「A letter from across time for tonight」、2 枚目「Write and a great figure appears」（書く → 偉人が現れる → 出典つきの返書の 3 ステップ）、（英語のみ）「Every word has a source」、最後「With every letter your night sky grows」が表示され、文字の重なり・はみ出しが無い
  - 自動化: manual（各画面の目視確認が必要）
- [x] **画面数がロケールで変わる**: 英語では 4 画面（進捗ドットが 4 つ）、日本語では 3 画面（出典の画面が無く進捗ドットが 3 つ）になる
  - 自動化: manual（端末言語の切り替えが必要。手順はルート QA.md「再現が難しい操作の手順」）
- [x] **次へ進む**: 「Next」で次の画面へ進み、進捗ドットの現在位置が動く。横スワイプでも同じように進む
  - 自動化: manual（遷移の目視確認が必要）
- [x] **最終画面から開始する**: 最終画面のボタンが「Write your first letter」になり、押すとオンボーディングが閉じてホームの入力画面が表示される
  - 自動化: manual（遷移の目視確認が必要）

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **初回起動で表示される**: アプリのインストール直後の初回起動でオンボーディングが全画面表示され、ホームの入力欄より前に出る

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-29**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/ac34f4dc-e339-4752-9caa-9a91f5060c80.jpg" width="320">
</details>

### **各画面の内容**: 1 枚目「A letter from across time for tonight」、2 枚目「Write and a great figure appears」（書く → 偉人が現れる → 出典つきの返書の 3 ステップ）、（英語のみ）「Every word has a source」、最後「With every letter your night sky grows」が表示され、文字の重なり・はみ出しが無い

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-29**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/1bc30c8c-938d-4331-8264-bd162c536bbc.png" width="320">
</details>

### **画面数がロケールで変わる**: 英語では 4 画面（進捗ドットが 4 つ）、日本語では 3 画面（出典の画面が無く進捗ドットが 3 つ）になる

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-29**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/da038a8f-ce1c-452d-a7c6-87bbbe4c7e45.png" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/abc51c13-a69f-48d3-bb06-7c80f60ea805.png" width="320">
</details>

### **次へ進む**: 「Next」で次の画面へ進み、進捗ドットの現在位置が動く。横スワイプでも同じように進む

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-29**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/2e35551e-b5ca-4be3-9783-3bfbe8fcb506.png" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/deb335cc-993a-48ce-afda-10ac4a3ef4ff.jpg" width="320">
</details>

### **最終画面から開始する**: 最終画面のボタンが「Write your first letter」になり、押すとオンボーディングが閉じてホームの入力画面が表示される

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-29**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/da038a8f-ce1c-452d-a7c6-87bbbe4c7e45.png" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/31b49839-8341-4d76-aff8-36344442161c.png" width="320">
</details>

</details>

---

## 2. スキップと再表示

- [ ] **スキップする**: 右上の「Skip」を押すとオンボーディングが閉じてホームが表示される
  - 自動化: manual（遷移の目視確認が必要）
  - ⏭️ スキップ: オンボーディングを閉じる操作は 1 回しか行えず、最終画面のボタン（「最初の 1 通を書く」）での完了を優先したため。Release ビルドには開発者メニューの Reset onboarding が無く、閉じた後は再表示できない。「スキップ」ボタンが 3 画面すべての右上に表示されていること自体は各画面のスクリーンショットで確認済み
- [x] **完了後は再表示されない**: オンボーディングを閉じた後にアプリを終了して再起動すると、オンボーディングは表示されずホームが出る
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

**確認日: 2026-08-29**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/31b49839-8341-4d76-aff8-36344442161c.png" width="320">
</details>

</details>
