---
feature: Archive
verification: mobile-mcp
last_verified_commit: 260cc34ccaa5f1e5f0479e7e16d75806745d7829
last_verified_at: 2026-08-29
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

- [x] **0 件の表示**: 相談をまだ送っていない状態で「Archive」を開くと、見出し「Your Letters」と案内「No letters yet. Write your first tonight.」が表示される
  - 自動化: manual（新規ユーザーの状態が必要。相談を送る前に確認する）
- [x] **返書の一覧**: 相談を送った後にホームへ戻ってから「Archive」を開くと、新しい順に日付・相談本文（2 行まで）・偉人名のピル（人物なしは「Proverb & diagram」）・格言 1 行のカードが表示される
  - 自動化: manual（返書データが必要。ホームへ戻らずに再表示した場合は再取得しない実装のため、必ずホームを経由する）
- [ ] **追加読み込み**: 21 件以上の記録があるとき、末尾までスクロールすると次のページが読み込まれる
  - 自動化: todo
  - ⏭️ スキップ: 21 件以上の記録を作るには相談を 21 通送る必要があり、無料枠 1 日 1 通・実 LLM 費用の制約から作れないため未確認

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **0 件の表示**: 相談をまだ送っていない状態で「Archive」を開くと、見出し「Your Letters」と案内「No letters yet. Write your first tonight.」が表示される

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-29**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/d83aaebc-5bec-4378-b8e1-634861f97bb8.png" width="320">
</details>

### **返書の一覧**: 相談を送った後にホームへ戻ってから「Archive」を開くと、新しい順に日付・相談本文（2 行まで）・偉人名のピル（人物なしは「Proverb & diagram」）・格言 1 行のカードが表示される

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-29**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/11b2ef28-00d2-41be-8ad7-532b12973ed6.png" width="320">
</details>

### **追加読み込み**: 21 件以上の記録があるとき、末尾までスクロールすると次のページが読み込まれる

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

</details>

---

## 2. 再訪と遷移

- [x] **返書の再訪**: カードをタップすると登場演出なしで返書の本文（Reply）が表示され、「Close」で一覧に戻る
  - 自動化: manual（遷移の目視確認が必要）
- [x] **ホームに戻る**: 「Home」ピルでホームに戻る
  - 自動化: manual（遷移の目視確認が必要）

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **返書の再訪**: カードをタップすると登場演出なしで返書の本文（Reply）が表示され、「Close」で一覧に戻る

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-29**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/11b2ef28-00d2-41be-8ad7-532b12973ed6.png" width="320">
</details>

### **ホームに戻る**: 「Home」ピルでホームに戻る

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-29**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/31b49839-8341-4d76-aff8-36344442161c.png" width="320">
</details>

</details>
