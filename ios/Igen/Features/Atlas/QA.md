---
feature: Atlas
verification: mobile-mcp
last_verified_commit: 78226c7062d7f2834aafa99d05625d3b6721836e
last_verified_at: 2026-08-30
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

- [x] **未出会いの表示**: 相談をまだ送っていない状態で「Star Atlas」を開くと、見出し「Your Star Atlas」、5 つの暗い星のかたまり（名前なし）、「Great figures you have met: 0 / 5」が表示される
  - 自動化: manual（新規ユーザーの状態が必要。相談を送る前に確認する）
- [x] **出会い後の表示**: 返書を受け取った偉人の星座が線でつながって明るく灯り、名前が表示され、カウンタが「1 / 5」になる
  - 自動化: manual（返書の偉人が星図の 5 枠 — セネカ / 孔子 / ニーチェ / 世阿弥 / 芭蕉 — に含まれる必要がある。含まれない偉人だった場合はその旨を記録する）
- [x] **新しい星座の演出**: 出会い後に初めて星図を開いたとき、星が集まって星座線が描かれる演出が再生され、2 回目以降は演出なしで表示される
  - 自動化: manual（アニメーションの目視確認が必要）
  - ✅ 参考: 出会い後に初めて星図を開いた直後のスクリーンショット（tmp/qa/shots/c3-12-atlas-first.png）では Zeami の星が光っているだけで星座線がまだ描かれておらず、5 秒後（c3-13-atlas-settled.png）に線が引かれた状態になった。アプリ再起動後に開いた時（c3-15-atlas-after-restart.png）は最初から線が描かれた状態で、2 回目以降は演出なしという仕様と整合する
- [x] **再起動後も維持**: アプリを終了して再起動しても出会い済みの星座が灯ったまま表示される
  - 自動化: manual（アプリの終了・再起動と目視確認が必要）

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **未出会いの表示**: 相談をまだ送っていない状態で「Star Atlas」を開くと、見出し「Your Star Atlas」、5 つの暗い星のかたまり（名前なし）、「Great figures you have met: 0 / 5」が表示される

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-29**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/5db950e0-aa2c-4239-85c0-4078e41b3513.png" width="320">
</details>

### **出会い後の表示**: 返書を受け取った偉人の星座が線でつながって明るく灯り、名前が表示され、カウンタが「1 / 5」になる

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-29**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/b67df28a-7eee-4037-86f3-68bcdb4b281a.png" width="320">
</details>

### **新しい星座の演出**: 出会い後に初めて星図を開いたとき、星が集まって星座線が描かれる演出が再生され、2 回目以降は演出なしで表示される

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-29**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/2459858e-25ad-4ba9-8c66-d1de653be7f5.png" width="320">
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/b67df28a-7eee-4037-86f3-68bcdb4b281a.png" width="320">
</details>

### **再起動後も維持**: アプリを終了して再起動しても出会い済みの星座が灯ったまま表示される

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-29**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/59468448-d1a4-4467-9547-c15cf59b21f6.png" width="320">
</details>

</details>

---

## 2. プロフィール

- [ ] **プロフィール**: 灯った偉人をタップするとシートに名前・肩書・生没年・紹介文、「Words you received」（もらった格言の一覧）、「Read the letter」が表示される
  - 自動化: manual（出会い済みの偉人が必要）
  - ❌ 失敗: シートに名前・肩書・生没年・紹介文までは出るが、**「Words you received」（もらった格言の一覧）と「Read the letter」ボタンがどちらも表示されない**（シートを一番上まで引き上げても紹介文の下は空白）。再現手順: 相談を 1 通送って返書を受け取る → ホーム →「Star Atlas」→ 灯った偉人（今回は Zeami）をタップ。原因: `ios/Igen/Features/Atlas/AtlasProfilePage.swift` は取得した返書が空でないときだけこの 2 つを描画し（`if !letters.isEmpty`）、取得に失敗しても `catch` で `letters = []` にするだけで何も出さない。その取得 `LettersStore.fetchLetters(personId:)` は `whereField("personId", isEqualTo:)` と `order(by: "consultedAt", descending: true)` の複合クエリで Firestore の複合インデックスを必要とするが、**igen-prod にはデプロイされていない**（`gcloud firestore indexes composite list --project igen-prod` が `Listed 0 items.`）。インデックス定義自体は `backend/firestore.indexes.json` に存在するため、未デプロイが原因。記録の一覧（`consultedAt` の単一フィールド順のみ）は既定インデックスで通るため正常に出ており、症状がプロフィールだけに出ることとも整合する。issue: https://github.com/bannzai/igen/issues/61
- [ ] **返書を読む**: 「Read the letter」で登場演出なしの返書（Reply）が開き、「Close」でプロフィールに戻る
  - 自動化: manual（遷移の目視確認が必要）
  - ❌ 失敗（上記「プロフィール」に起因）: プロフィールに「Read the letter」ボタンが表示されないため押せず、この経路の返書を開けない。ボタンが出ない原因と再現手順は「プロフィール」の記載を参照
- [x] **閉じる**: × でシートが閉じ、ホームのピルまたは戻る操作でホームに戻る
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

**確認日: 2026-08-29**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/a459b17e-facd-43ca-81da-330f40ef7899.png" width="320">
</details>

</details>
