---
feature: Archive
verification: mobile-mcp
last_verified_commit: null
last_verified_at: null
---

# Archive QA

## 関連リンク

- 仕様: https://github.com/bannzai/igen/issues/9 （やること・完了条件）
- 関連: https://github.com/bannzai/igen/pull/26 （実装）

## 仕様チェックリスト

| ID | 期待挙動 | 対応項目 |
|----|---------|---------|
| S1 | 日付ごとの相談一覧を表示する | 返書の一覧 |
| S2 | 一覧から返書の詳細を再訪できる（返書画面の表示コンポーネントを再利用） | 返書の再訪 |
| S3 | データは Firestore `users/{uid}/letters` から読み取る（クライアントは read のみ） | 返書の一覧 |
| S4 | 相談が無いときは空の案内を出す（実装: 「No letters yet. Write your first tonight.」） | 0 件の表示 |

## 1. 一覧

- [ ] **0 件の表示**: 相談をまだ送っていない状態で「Archive」を開くと、見出し「Your Letters」と案内「No letters yet. Write your first tonight.」が表示される
  - 自動化: manual（新規ユーザーの状態が必要。相談を送る前に確認する）
- [ ] **返書の一覧**: 相談を送った後にホームへ戻ってから「Archive」を開くと、新しい順に日付・相談本文（2 行まで）・偉人名のピル（人物なしは「Proverb & diagram」）・格言 1 行のカードが表示される
  - 自動化: manual（返書データが必要。ホームへ戻らずに再表示した場合は再取得しない実装のため、必ずホームを経由する）
- [ ] **追加読み込み**: 21 件以上の記録があるとき、末尾までスクロールすると次のページが読み込まれる
  - 自動化: todo

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **0 件の表示**: 相談をまだ送っていない状態で「Archive」を開くと、見出し「Your Letters」と案内「No letters yet. Write your first tonight.」が表示される

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

### **返書の一覧**: 相談を送った後にホームへ戻ってから「Archive」を開くと、新しい順に日付・相談本文（2 行まで）・偉人名のピル（人物なしは「Proverb & diagram」）・格言 1 行のカードが表示される

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

### **追加読み込み**: 21 件以上の記録があるとき、末尾までスクロールすると次のページが読み込まれる

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

</details>

---

## 2. 再訪と遷移

- [ ] **返書の再訪**: カードをタップすると登場演出なしで返書の本文（Reply）が表示され、「Close」で一覧に戻る
  - 自動化: manual（遷移の目視確認が必要）
- [ ] **ホームに戻る**: 「Home」ピルでホームに戻る
  - 自動化: manual（遷移の目視確認が必要）

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **返書の再訪**: カードをタップすると登場演出なしで返書の本文（Reply）が表示され、「Close」で一覧に戻る

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

### **ホームに戻る**: 「Home」ピルでホームに戻る

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

</details>
