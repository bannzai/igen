---
feature: Share
verification: mobile-mcp
last_verified_commit: 260cc34ccaa5f1e5f0479e7e16d75806745d7829
last_verified_at: 2026-08-29
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

- [x] **共有導線**: 返書画面のヘッダー「Share」と末尾「Create a share card」のどちらからも共有カードのシートが開く。記録から再訪した返書でも同じ導線がある
  - 自動化: manual（遷移の目視確認が必要）
- [x] **共有カードのプレビュー**: 見出し「Share Card」、注記「Your worry is not included in the card」、縦型のカード画像（IGEN ロゴ・星座線アバター・偉人名または「Proverb」・格言・原文・出典）が表示され、相談本文がカードに含まれていない
  - 自動化: manual（カード画像の目視確認が必要）

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **共有導線**: 返書画面のヘッダー「Share」と末尾「Create a share card」のどちらからも共有カードのシートが開く。記録から再訪した返書でも同じ導線がある

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-29**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/75eb8e81-f8d6-40b4-9f6d-a18fd38581c7.png" width="320">
</details>

### **共有カードのプレビュー**: 見出し「Share Card」、注記「Your worry is not included in the card」、縦型のカード画像（IGEN ロゴ・星座線アバター・偉人名または「Proverb」・格言・原文・出典）が表示され、相談本文がカードに含まれていない

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-29**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/75eb8e81-f8d6-40b4-9f6d-a18fd38581c7.png" width="320">
</details>

</details>

---

## 2. 共有と保存

- [x] **共有シート**: 「Share」で iOS の共有シート（UIActivityViewController）が開き、カード画像が共有対象として表示される
  - 自動化: manual（共有シートの目視確認が必要）
- [ ] **画像を保存**: 「Save image」で写真への追加の許可ダイアログが出て、許可するとアラート「The share card has been saved to your photos.」が出る
  - 自動化: manual（許可ダイアログの操作と目視確認が必要）
  - ❌ 失敗: 「Save image」を押すと許可ダイアログもアラートも出ず、**アプリがその場で落ちてホーム画面に戻る**。2 回連続で再現（1 回目は返書画面からの共有カード、2 回目は記録から再訪した返書の共有カード）。落ちた後の起動は状態を保持しないコールドスタートになる。再現手順: 相談を 1 通送って返書を受け取る →「Share」または「Create a share card」→「Save image」。原因の推定: `ios/Igen/Features/Share/SharePage.swift` の `save(cardImage:)` は `PHPhotoLibrary.requestAuthorization(for: .addOnly)` を呼ばずに `PHPhotoLibrary.shared().performChanges` を実行する。未決定状態でこの API を呼ぶと読み書き（`.readWrite`）の許可フローが走り、`ios/Igen/Info.plist` に無い `NSPhotoLibraryUsageDescription` が要求されて即時終了する（同 plist にあるのは `NSPhotoLibraryAddUsageDescription` のみ）。修正の方向は `performChanges` の前に `.addOnly` の許可を明示的に要求するか、`NSPhotoLibraryUsageDescription` を追加するかのいずれか。runner のクラッシュログは simtunnel 経由では取得できず未確認（推定の根拠は再現手順とコード・plist の突き合わせ）。issue: 未起票
- [x] **戻る**: 「Back」でシートが閉じて返書画面に戻る
  - 自動化: manual（遷移の目視確認が必要）

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **共有シート**: 「Share」で iOS の共有シート（UIActivityViewController）が開き、カード画像が共有対象として表示される

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-29**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/1420a967-bc7f-4788-881f-685fef63282d.png" width="320">
</details>

### **画像を保存**: 「Save image」で写真への追加の許可ダイアログが出て、許可するとアラート「The share card has been saved to your photos.」が出る

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

### **戻る**: 「Back」でシートが閉じて返書画面に戻る

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-29**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/75eb8e81-f8d6-40b4-9f6d-a18fd38581c7.png" width="320">
</details>

</details>
