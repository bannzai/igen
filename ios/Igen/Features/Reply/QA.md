---
feature: Reply
verification: mobile-mcp
last_verified_commit: null
last_verified_at: null
---

# Reply QA

## 関連リンク

- 仕様: https://github.com/bannzai/igen/issues/8 （やること・完了条件）
- 関連: https://github.com/bannzai/igen/pull/25 （実装）、https://github.com/bannzai/igen/pull/32 （タイポグラフィ統一）

## 仕様チェックリスト

| ID | 期待挙動 | 対応項目 |
|----|---------|---------|
| S1 | 登場演出（星が集まり星座線で偉人が描かれる）の後に返書が表示される。初回はリッチ、2 回目以降は短縮 | 登場演出、2 回目以降の短縮演出 |
| S2 | 返書は「悩みへのひとこと → 格言（大きく）→ 意味と文脈 → 励ましの結び」の順で構成される | 返書の構成 |
| S3 | 偉人がいる場合はその偉人の星座線アバターと名前・肩書・生没年を表示する | 返書の構成 |
| S4 | 該当人物がいない格言・ことわざは図解カード（たとえ → 意味 → 使いどころ）で説明する | 図解カード（該当人物なし） |
| S5 | すべての格言に出典ブロック（作品名・原題・原文の言語・成立）を表示する | 出典ブロック |
| S6 | 外国語由来の格言は原文をそのまま併記し、訳文と並べる | 原文の併記 |

## 1. 登場演出

- [ ] **登場演出**: ホームからの遷移直後に星座線の演出と「<偉人名> appeared in your sky」（人物なしは「Words have reached your sky」）が表示され、「Skip」で演出を飛ばして返書本文に進める
  - 自動化: manual（アニメーションの目視確認が必要）
- [ ] **2 回目以降の短縮演出**: 2 通目以降は演出が短縮版になる（初回の約半分の時間で本文に進む）
  - 自動化: manual（2 通目の送信が必要。本番では無料枠の都合で同日に確認できないためチケット購入か翌日に確認する）

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **登場演出**: ホームからの遷移直後に星座線の演出と「<偉人名> appeared in your sky」（人物なしは「Words have reached your sky」）が表示され、「Skip」で演出を飛ばして返書本文に進める

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

### **2 回目以降の短縮演出**: 2 通目以降は演出が短縮版になる（初回の約半分の時間で本文に進む）

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

</details>

---

## 2. 返書本文

- [ ] **返書の構成**: 日付 → 偉人のアバター・名前・肩書・生没年 → ひとこと → 格言（大きく金色の罫線つき）→ 原文 → 「Meaning & Context」→ 結び「— from <偉人名>」→ 出典ブロック → 「Create a share card」→ 「Close」の順に表示され、文字の重なり・はみ出しが無い
  - 自動化: manual（返書内容の目視確認が必要）
- [ ] **出典ブロック**: 「Source」に「Work」（作品名）と「Language」（原文の言語名。Latin / Classical Chinese / German / Ancient Greek / Japanese / English のいずれか）が表示され、原題・成立年があればそれも表示される
  - 自動化: manual（出典の目視確認が必要）
- [ ] **原文の併記**: 「Original」に格言の原文がそのまま表示され、その下に訳文（表示言語に応じて Translation / 日本語訳）が並ぶ。漢文・ラテン語など原文の文字種が正しく描画される
  - 自動化: manual（原文の描画の目視確認が必要）
- [ ] **図解カード（該当人物なし）**: 該当人物のいない格言・ことわざでは、アバターの代わりに「Diagram — How the words work」の図解カード（Metaphor / Meaning / When to use）が表示される
  - 自動化: manual（どの格言が選ばれるかは LLM に依存するため、本番では再現に運が絡む。Emulator では本文に人物なし格言の quoteId を含めて `IGEN_FAKE_LLM=1` で再現できる）

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **返書の構成**: 日付 → 偉人のアバター・名前・肩書・生没年 → ひとこと → 格言（大きく金色の罫線つき）→ 原文 → 「Meaning & Context」→ 結び「— from <偉人名>」→ 出典ブロック → 「Create a share card」→ 「Close」の順に表示され、文字の重なり・はみ出しが無い

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

### **出典ブロック**: 「Source」に「Work」（作品名）と「Language」（原文の言語名。Latin / Classical Chinese / German / Ancient Greek / Japanese / English のいずれか）が表示され、原題・成立年があればそれも表示される

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

### **原文の併記**: 「Original」に格言の原文がそのまま表示され、その下に訳文（表示言語に応じて Translation / 日本語訳）が並ぶ。漢文・ラテン語など原文の文字種が正しく描画される

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

### **図解カード（該当人物なし）**: 該当人物のいない格言・ことわざでは、アバターの代わりに「Diagram — How the words work」の図解カード（Metaphor / Meaning / When to use）が表示される

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

</details>

---

## 3. 画面遷移

- [ ] **閉じる**: ヘッダーの「Close」または末尾の「Close」でホームに戻り、入力欄が空になっている
  - 自動化: manual（遷移の目視確認が必要）
- [ ] **記録・星図からの再訪**: 記録の一覧・星図のプロフィールから開いた返書は登場演出なしで本文が表示される
  - 自動化: manual（遷移の目視確認が必要）

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **閉じる**: ヘッダーの「Close」または末尾の「Close」でホームに戻り、入力欄が空になっている

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

### **記録・星図からの再訪**: 記録の一覧・星図のプロフィールから開いた返書は登場演出なしで本文が表示される

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

</details>
