---
feature: Share
verification: mobile-mcp
last_verified_commit: null
last_verified_at: null
---

# Share QA

## 関連リンク

- 仕様: https://github.com/bannzai/igen/issues/11 （やること・完了条件）
- 関連: https://github.com/bannzai/igen/pull/28 （実装）

## 仕様チェックリスト

| ID | 期待挙動 | 対応項目 |
|----|---------|---------|
| S1 | 返書を 1 枚の縦型カード画像にする（星空 + 星座線アバター + 格言 + 出典） | 共有カードのプレビュー |
| S2 | カードに悩みの本文を含めない | 共有カードのプレビュー（画像の目視）、ルート QA.md「プライバシー（静的検査）」 |
| S3 | 返書画面・振り返り詳細からの共有導線がある | 共有導線 |
| S4 | 共有シートから画像を書き出せる | 共有シート、画像を保存 |
| S5 | 共有イベントを Analytics に送る（本文は送らない） | ルート QA.md「プライバシー（静的検査）」 |

## 1. カード

- [ ] **共有導線**: 返書画面のヘッダー「Share」と末尾「Create a share card」のどちらからも共有カードのシートが開く。記録から再訪した返書でも同じ導線がある
  - 自動化: manual（遷移の目視確認が必要）
- [ ] **共有カードのプレビュー**: 見出し「Share Card」、注記「Your worry is not included in the card」、縦型のカード画像（IGEN ロゴ・星座線アバター・偉人名または「Proverb」・格言・原文・出典）が表示され、相談本文がカードに含まれていない
  - 自動化: manual（カード画像の目視確認が必要）

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **共有導線**: 返書画面のヘッダー「Share」と末尾「Create a share card」のどちらからも共有カードのシートが開く。記録から再訪した返書でも同じ導線がある

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

### **共有カードのプレビュー**: 見出し「Share Card」、注記「Your worry is not included in the card」、縦型のカード画像（IGEN ロゴ・星座線アバター・偉人名または「Proverb」・格言・原文・出典）が表示され、相談本文がカードに含まれていない

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

</details>

---

## 2. 共有と保存

- [ ] **共有シート**: 「Share」で iOS の共有シート（UIActivityViewController）が開き、カード画像が共有対象として表示される
  - 自動化: manual（共有シートの目視確認が必要）
- [ ] **画像を保存**: 「Save image」で写真への追加の許可ダイアログが出て、許可するとアラート「The share card has been saved to your photos.」が出る
  - 自動化: manual（許可ダイアログの操作と目視確認が必要）
- [ ] **戻る**: 「Back」でシートが閉じて返書画面に戻る
  - 自動化: manual（遷移の目視確認が必要）

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **共有シート**: 「Share」で iOS の共有シート（UIActivityViewController）が開き、カード画像が共有対象として表示される

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

### **画像を保存**: 「Save image」で写真への追加の許可ダイアログが出て、許可するとアラート「The share card has been saved to your photos.」が出る

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

### **戻る**: 「Back」でシートが閉じて返書画面に戻る

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

</details>
