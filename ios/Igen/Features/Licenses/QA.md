---
feature: Licenses
verification: mobile-mcp
last_verified_commit: null
last_verified_at: null
---

# Licenses QA

## 関連リンク

- 仕様: 仕様なし QA（issue は無く、https://github.com/bannzai/igen/pull/40 の実装内容が正）
- 関連: https://github.com/bannzai/igen/pull/40 （OSS ライセンス一覧表示を追加）

## 1. 一覧

- [ ] **ライセンス一覧の表示**: ペイウォールの「Open Source Licenses」でシートが開き、見出し「Open Source Licenses」と依存パッケージ（Firebase / RevenueCat / LicenseList 等）のライセンス一覧が空でなく表示される
  - 自動化: manual（一覧はビルド時に LicenseList の plugin が生成するため、ビルドごとの目視確認が必要）
- [ ] **ライセンス詳細**: 一覧の項目をタップするとライセンス本文とリポジトリへのリンクが表示される
  - 自動化: manual（遷移の目視確認が必要）
- [ ] **閉じる**: 「Close」でシートが閉じてペイウォールに戻る
  - 自動化: manual（遷移の目視確認が必要）

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **ライセンス一覧の表示**: ペイウォールの「Open Source Licenses」でシートが開き、見出し「Open Source Licenses」と依存パッケージ（Firebase / RevenueCat / LicenseList 等）のライセンス一覧が空でなく表示される

<details><summary>動作確認スクショ</summary>

（未実行）

</details>

### **ライセンス詳細**: 一覧の項目をタップするとライセンス本文とリポジトリへのリンクが表示される

<details><summary>動作確認スクショ</summary>

（未実行）

</details>

### **閉じる**: 「Close」でシートが閉じてペイウォールに戻る

<details><summary>動作確認スクショ</summary>

（未実行）

</details>

</details>
