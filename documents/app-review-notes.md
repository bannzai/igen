# App Review メモ（審査員向けノート）

App Store Connect の「App Review に関する情報 > メモ」欄に貼る文面。審査提出時にこのファイルの英語文面をそのまま使う（メモ欄は英語で書く。issue #16「審査対応」）。

## メモ欄に貼る文面（英語）

```
ABOUT THIS APP
igen / Dear Socrates is an entertainment app: you write down a worry or
something that happened today, and a great figure from history "replies"
with a letter of encouragement built around a quote or proverb with a
verified source. It is not a medical, therapy, or counseling service and
does not present itself as one.

NO ACCOUNT REQUIRED
The app uses Firebase Anonymous Authentication. No sign-up, email, or
demo account is needed — just launch the app and write a message.

LANGUAGE MODES (Japanese 偉言 / English "Dear Socrates")
The app follows the device language. On a device set to English it runs
entirely in English under the name "Dear Socrates"; on a Japanese device
it runs as 偉言 (igen). To switch without changing the device language:
iOS Settings > Apps > Dear Socrates > Language, then choose 日本語 or
English. All screens, and the generated reply letters, follow the
selected language.

IN-APP PURCHASES
The free tier allows 1 reply letter per day. Additional letters are
available via a consumable ticket, and an auto-renewing subscription
removes the daily limit. Purchases are processed through the App Store
(RevenueCat SDK) and can be tested with a sandbox account.

SAFETY FEATURE
If the input contains phrases suggesting self-harm (e.g. "I want to
disappear"), the app does not generate a reply. Instead it shows a quiet
support screen with regional helpline contacts. This can be verified by
entering such a phrase on the home screen.
```

## 日本語での補足（メモ欄には貼らない）

- 英語モードの切り替え: アプリは端末言語に追随する。端末言語を変えずに試す場合は「設定 > アプリ > 偉言 (Dear Socrates) > 言語」でアプリ単位の言語を切り替えられる（`Localizable.xcstrings` / `InfoPlist.xcstrings` の CFBundleDisplayName でロケール別に表示名が変わる）
- セーフティの動作確認手順は上記の通りホーム入力で再現できる（危機ワードの判定はバックエンド `backend/functions/src/crisis.ts`）
- 提出時は文言が実装と一致しているか（無料枠の通数・課金形態）を再確認してから貼ること
