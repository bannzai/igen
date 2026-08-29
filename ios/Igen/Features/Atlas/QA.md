---
feature: Atlas
verification: mobile-mcp
last_verified_commit: null
last_verified_at: null
---

# Atlas QA

## 関連リンク

- 仕様: https://github.com/bannzai/igen/issues/10 （やること・完了条件）
- 関連: https://github.com/bannzai/igen/pull/27 （実装）

## 仕様チェックリスト

| ID | 期待挙動 | 対応項目 |
|----|---------|---------|
| S1 | 出会った偉人が星座として夜空に灯り、未出会いは暗い星だけを表示する | 未出会いの表示、出会い後の表示 |
| S2 | 新しい偉人と出会った時に「新しい星座が夜空に灯る」演出が出る | 新しい星座の演出 |
| S3 | 偉人タップでプロフィール（人物・生没年・出典情報）と、その偉人から過去にもらった言葉の一覧を表示する | プロフィール |
| S4 | 出会い状態は Firestore に保存され、再起動後も維持される | 再起動後も維持 |

## 1. 星図

- [ ] **未出会いの表示**: 相談をまだ送っていない状態で「Star Atlas」を開くと、見出し「Your Star Atlas」、5 つの暗い星のかたまり（名前なし）、「Great figures you have met: 0 / 5」が表示される
  - 自動化: manual（新規ユーザーの状態が必要。相談を送る前に確認する）
- [ ] **出会い後の表示**: 返書を受け取った偉人の星座が線でつながって明るく灯り、名前が表示され、カウンタが「1 / 5」になる
  - 自動化: manual（返書の偉人が星図の 5 枠 — セネカ / 孔子 / ニーチェ / 世阿弥 / 芭蕉 — に含まれる必要がある。含まれない偉人だった場合はその旨を記録する）
  - ⏭️ スキップ: 2026-08-29 の simtunnel セッション igen-49 で runner の Simulator が名前解決に失敗し（Safari で `asia-northeast1-igen-prod.cloudfunctions.net` も `bannzai.github.io` も「Safari can't open the page because the server can't be found.」）、相談の送信が 2 回とも約 300 秒の再照会の後に「The letter could not be delivered. Please try again later.」で失敗したため、送信後の画面に到達できず未確認。無料枠は未消費のまま
- [ ] **新しい星座の演出**: 出会い後に初めて星図を開いたとき、星が集まって星座線が描かれる演出が再生され、2 回目以降は演出なしで表示される
  - 自動化: manual（アニメーションの目視確認が必要）
  - ⏭️ スキップ: 2026-08-29 の simtunnel セッション igen-49 で runner の Simulator が名前解決に失敗し（Safari で `asia-northeast1-igen-prod.cloudfunctions.net` も `bannzai.github.io` も「Safari can't open the page because the server can't be found.」）、相談の送信が 2 回とも約 300 秒の再照会の後に「The letter could not be delivered. Please try again later.」で失敗したため、送信後の画面に到達できず未確認。無料枠は未消費のまま
- [ ] **再起動後も維持**: アプリを終了して再起動しても出会い済みの星座が灯ったまま表示される
  - 自動化: manual（アプリの終了・再起動と目視確認が必要）
  - ⏭️ スキップ: 2026-08-29 の simtunnel セッション igen-49 で runner の Simulator が名前解決に失敗し（Safari で `asia-northeast1-igen-prod.cloudfunctions.net` も `bannzai.github.io` も「Safari can't open the page because the server can't be found.」）、相談の送信が 2 回とも約 300 秒の再照会の後に「The letter could not be delivered. Please try again later.」で失敗したため、送信後の画面に到達できず未確認。無料枠は未消費のまま

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **未出会いの表示**: 相談をまだ送っていない状態で「Star Atlas」を開くと、見出し「Your Star Atlas」、5 つの暗い星のかたまり（名前なし）、「Great figures you have met: 0 / 5」が表示される

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

### **出会い後の表示**: 返書を受け取った偉人の星座が線でつながって明るく灯り、名前が表示され、カウンタが「1 / 5」になる

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

### **新しい星座の演出**: 出会い後に初めて星図を開いたとき、星が集まって星座線が描かれる演出が再生され、2 回目以降は演出なしで表示される

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

### **再起動後も維持**: アプリを終了して再起動しても出会い済みの星座が灯ったまま表示される

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

</details>

---

## 2. プロフィール

- [ ] **プロフィール**: 灯った偉人をタップするとシートに名前・肩書・生没年・紹介文、「Words you received」（もらった格言の一覧）、「Read the letter」が表示される
  - 自動化: manual（出会い済みの偉人が必要）
  - ⏭️ スキップ: 2026-08-29 の simtunnel セッション igen-49 で runner の Simulator が名前解決に失敗し（Safari で `asia-northeast1-igen-prod.cloudfunctions.net` も `bannzai.github.io` も「Safari can't open the page because the server can't be found.」）、相談の送信が 2 回とも約 300 秒の再照会の後に「The letter could not be delivered. Please try again later.」で失敗したため、送信後の画面に到達できず未確認。無料枠は未消費のまま
- [ ] **返書を読む**: 「Read the letter」で登場演出なしの返書（Reply）が開き、「Close」でプロフィールに戻る
  - 自動化: manual（遷移の目視確認が必要）
  - ⏭️ スキップ: 2026-08-29 の simtunnel セッション igen-49 で runner の Simulator が名前解決に失敗し（Safari で `asia-northeast1-igen-prod.cloudfunctions.net` も `bannzai.github.io` も「Safari can't open the page because the server can't be found.」）、相談の送信が 2 回とも約 300 秒の再照会の後に「The letter could not be delivered. Please try again later.」で失敗したため、送信後の画面に到達できず未確認。無料枠は未消費のまま
- [ ] **閉じる**: × でシートが閉じ、ホームのピルまたは戻る操作でホームに戻る
  - 自動化: manual（遷移の目視確認が必要）

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **プロフィール**: 灯った偉人をタップするとシートに名前・肩書・生没年・紹介文、「Words you received」（もらった格言の一覧）、「Read the letter」が表示される

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

### **返書を読む**: 「Read the letter」で登場演出なしの返書（Reply）が開き、「Close」でプロフィールに戻る

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

### **閉じる**: × でシートが閉じ、ホームのピルまたは戻る操作でホームに戻る

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

</details>
