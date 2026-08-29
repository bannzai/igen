---
feature: Safety
verification: mobile-mcp
last_verified_commit: null
last_verified_at: null
---

# Safety QA

## 関連リンク

- 仕様: https://github.com/bannzai/igen/issues/12 （やること・完了条件）、`documents/PROJECT.md`「リスクと対策」2
- 関連: https://github.com/bannzai/igen/pull/29 （実装）、https://github.com/bannzai/igen/pull/31 （US 向け窓口）、https://github.com/bannzai/igen/issues/16 （公開前チェックリスト「セーフティが動作することを確認する」）

## 仕様チェックリスト

| ID | 期待挙動 | 対応項目 |
|----|---------|---------|
| S1 | 危機ワードを含む相談では返書ではなく相談窓口の案内画面が表示される | 危機ワードで案内画面が表示される |
| S2 | 通常の相談では案内画面が出ない | 通常の相談では案内が出ない |
| S3 | 案内画面は公的な相談窓口への導線を持ち、静かで誠実なトーン。専門の支援は提供できない旨を明示する | 案内画面の内容 |
| S4 | 英語モード（US）向けの窓口（988）にも対応する | 地域別の窓口（US / JP） |
| S5 | 案内画面の表示は Analytics に送るが相談本文は送らない | ルート QA.md「プライバシー（静的検査）」で確認 |
| S6 | 危機判定では無料枠・チケットを消費しない（`backend/functions/src/app.ts`） | 無料枠を消費しない |

## 1. 危機ワード検知

- [ ] **危機ワードで案内画面が表示される**: 相談本文に危機ワード（英語: `want to die`、日本語: `死にたい`。一覧は `backend/functions/src/crisis.ts`）を含めて送信すると、返書画面ではなく全画面の案内画面が表示される
  - 自動化: manual（送信結果の目視確認が必要。キーワード判定は LLM の前に行われるため費用は発生しない）
  - ⏭️ スキップ: 2026-08-29 の simtunnel セッション igen-49 で runner の Simulator が名前解決に失敗し（Safari で `asia-northeast1-igen-prod.cloudfunctions.net` も `bannzai.github.io` も「Safari can't open the page because the server can't be found.」）、相談の送信が 2 回とも約 300 秒の再照会の後に「The letter could not be delivered. Please try again later.」で失敗したため、送信後の画面に到達できず未確認。無料枠は未消費のまま
- [ ] **通常の相談では案内が出ない**: 危機ワードを含まない相談では返書画面が表示され、案内画面は出ない
  - 自動化: manual（Home「送信して返書画面へ遷移」と同じ送信で確認する）
  - ⏭️ スキップ: 2026-08-29 の simtunnel セッション igen-49 で runner の Simulator が名前解決に失敗し（Safari で `asia-northeast1-igen-prod.cloudfunctions.net` も `bannzai.github.io` も「Safari can't open the page because the server can't be found.」）、相談の送信が 2 回とも約 300 秒の再照会の後に「The letter could not be delivered. Please try again later.」で失敗したため、送信後の画面に到達できず未確認。無料枠は未消費のまま
- [ ] **無料枠を消費しない**: 危機ワードの送信の後に通常の相談を送信すると、ペイウォールではなく返書が返る（無料枠が残っている）
  - 自動化: manual（送信順の制御と目視確認が必要）
  - ⏭️ スキップ: 2026-08-29 の simtunnel セッション igen-49 で runner の Simulator が名前解決に失敗し（Safari で `asia-northeast1-igen-prod.cloudfunctions.net` も `bannzai.github.io` も「Safari can't open the page because the server can't be found.」）、相談の送信が 2 回とも約 300 秒の再照会の後に「The letter could not be delivered. Please try again later.」で失敗したため、送信後の画面に到達できず未確認。無料枠は未消費のまま

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **危機ワードで案内画面が表示される**: 相談本文に危機ワード（英語: `want to die`、日本語: `死にたい`。一覧は `backend/functions/src/crisis.ts`）を含めて送信すると、返書画面ではなく全画面の案内画面が表示される

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

### **通常の相談では案内が出ない**: 危機ワードを含まない相談では返書画面が表示され、案内画面は出ない

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

### **無料枠を消費しない**: 危機ワードの送信の後に通常の相談を送信すると、ペイウォールではなく返書が返る（無料枠が残っている）

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

</details>

---

## 2. 案内画面

- [ ] **案内画面の内容**: 「Thank you for telling me something so important.」、専門の支援を提供できない旨の文言、相談窓口カード、「No letter has been sent for this consultation.」、「Back to Home」が表示され、星空の演出が暗く抑えられている
  - 自動化: manual（トーン・レイアウトの目視確認が必要）
  - ⏭️ スキップ: 2026-08-29 の simtunnel セッション igen-49 で runner の Simulator が名前解決に失敗し（Safari で `asia-northeast1-igen-prod.cloudfunctions.net` も `bannzai.github.io` も「Safari can't open the page because the server can't be found.」）、相談の送信が 2 回とも約 300 秒の再照会の後に「The letter could not be delivered. Please try again later.」で失敗したため、送信後の画面に到達できず未確認。無料枠は未消費のまま
- [ ] **地域別の窓口（US / JP）**: 端末の地域が US なら「988 Suicide & Crisis Lifeline」、JP なら「いのちの電話」「よりそいホットライン」「まもろうよ こころ」、それ以外なら「Find a Helpline」が表示される（分岐は言語ではなく地域）
  - 自動化: manual（地域の切り替えは設定アプリで行う。ルート QA.md「再現が難しい操作の手順」参照）
  - ⏭️ スキップ: 2026-08-29 の simtunnel セッション igen-49 で runner の Simulator が名前解決に失敗し（Safari で `asia-northeast1-igen-prod.cloudfunctions.net` も `bannzai.github.io` も「Safari can't open the page because the server can't be found.」）、相談の送信が 2 回とも約 300 秒の再照会の後に「The letter could not be delivered. Please try again later.」で失敗したため、送信後の画面に到達できず未確認。無料枠は未消費のまま
- [ ] **窓口リンク**: 電話番号のカードをタップすると `tel:` の発信確認、Web の窓口をタップすると Safari で該当ページが開く
  - 自動化: manual（Simulator では発信できないため `tel:` は確認ダイアログまで。Web は遷移先の目視確認）
  - ⏭️ スキップ: 2026-08-29 の simtunnel セッション igen-49 で runner の Simulator が名前解決に失敗し（Safari で `asia-northeast1-igen-prod.cloudfunctions.net` も `bannzai.github.io` も「Safari can't open the page because the server can't be found.」）、相談の送信が 2 回とも約 300 秒の再照会の後に「The letter could not be delivered. Please try again later.」で失敗したため、送信後の画面に到達できず未確認。無料枠は未消費のまま
- [ ] **ホームに戻る**: 「Back to Home」でホームに戻り、入力欄が空になっている
  - 自動化: manual（遷移の目視確認が必要）
  - ⏭️ スキップ: 2026-08-29 の simtunnel セッション igen-49 で runner の Simulator が名前解決に失敗し（Safari で `asia-northeast1-igen-prod.cloudfunctions.net` も `bannzai.github.io` も「Safari can't open the page because the server can't be found.」）、相談の送信が 2 回とも約 300 秒の再照会の後に「The letter could not be delivered. Please try again later.」で失敗したため、送信後の画面に到達できず未確認。無料枠は未消費のまま

#### 動作確認
<details>
<summary>動作確認エビデンス</summary>

### **案内画面の内容**: 「Thank you for telling me something so important.」、専門の支援を提供できない旨の文言、相談窓口カード、「No letter has been sent for this consultation.」、「Back to Home」が表示され、星空の演出が暗く抑えられている

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

### **地域別の窓口（US / JP）**: 端末の地域が US なら「988 Suicide & Crisis Lifeline」、JP なら「いのちの電話」「よりそいホットライン」「まもろうよ こころ」、それ以外なら「Find a Helpline」が表示される（分岐は言語ではなく地域）

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

### **窓口リンク**: 電話番号のカードをタップすると `tel:` の発信確認、Web の窓口をタップすると Safari で該当ページが開く

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

### **ホームに戻る**: 「Back to Home」でホームに戻り、入力欄が空になっている

<details><summary>動作確認スクショ</summary>

（未実行）
</details>

</details>
