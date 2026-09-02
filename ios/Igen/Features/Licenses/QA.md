---
feature: Licenses
verification: mobile-mcp
last_verified_commit: 78226c7062d7f2834aafa99d05625d3b6721836e
last_verified_at: 2026-08-30
---

# Licenses QA

## 関連リンク

- 仕様: 仕様なし QA（issue は無く、https://github.com/bannzai/igen/pull/40 の実装内容が正）
- 関連: https://github.com/bannzai/igen/pull/40 （OSS ライセンス一覧表示を追加）

## 1. 一覧

- [x] **ライセンス一覧の表示**: ペイウォールの「Open Source Licenses」でシートが開き、見出し「Open Source Licenses」と依存パッケージ（Firebase / RevenueCat / LicenseList 等）のライセンス一覧が空でなく表示される
  - 自動化: manual（一覧はビルド時に LicenseList の plugin が生成するため、ビルドごとの目視確認が必要）
- [x] **ライセンス詳細**: 一覧の項目をタップするとライセンス本文とリポジトリへのリンクが表示される
  - 自動化: manual（遷移の目視確認が必要）
- [x] **閉じる**: 「Close」でシートが閉じてペイウォールに戻る
  - 自動化: manual（遷移の目視確認が必要）

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **ライセンス一覧の表示**: ペイウォールの「Open Source Licenses」でシートが開き、見出し「Open Source Licenses」と依存パッケージ（Firebase / RevenueCat / LicenseList 等）のライセンス一覧が空でなく表示される

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-29**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/3bfbb4eb-6535-4f43-b252-3ca3dbb1b3db.png" width="320">
</details>

### **ライセンス詳細**: 一覧の項目をタップするとライセンス本文とリポジトリへのリンクが表示される

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-29**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/f5ec322d-bcba-4f7b-9860-873b1a8ebde0.png" width="320">
</details>

### **閉じる**: 「Close」でシートが閉じてペイウォールに戻る

<details><summary>動作確認スクショ</summary>

**確認日: 2026-08-29**
<img src="https://pub-7f3469dd3e2e445b9b8ec2d1381b5ea8.r2.dev/bannzai/igen/20260829/73569495-ea10-4f59-9945-b8fa8ce763a5.png" width="320">
</details>

</details>
