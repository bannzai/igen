# 0001. クライアントは SwiftUI、バックエンドは Firebase Functions (gen2) + Firestore + 匿名認証を使う

## Status

Accepted

## Context

偉言（igen）は「悩みを書くと LLM が適した偉人・格言をマッチングして返書を生成する」iOS アプリで、次の要件がある（[documents/PROJECT.md](../PROJECT.md)）。

- LLM API の呼び出しを含むため、API キーをクライアントに置けずサーバー側の実行環境が必須。1 リクエストが数十秒かかっても耐えられること
- 相談履歴（悩みと返書）は機種変更で消えない**クラウド同期**とする（オーナー決定）。履歴の蓄積によるパーソナライズを課金理由に置くため、サーバー側から履歴を参照できる構成が望ましい
- サインアップ画面を置かず即利用開始できること。課金 (RevenueCat) はユーザー識別子と紐付けること
- Shipaton 2026（締切 2026-09-30）に間に合わせるため、実績のある構成で運用コストを最小にしたい

クライアントは iOS 専用（iPhone 縦持ち）で、星空演出・音声入力を含むデザイン重視のアプリになる。

## Decision

オーナー確認済み（2026-08-05）の以下の構成とする。

- クライアント: **SwiftUI (iOS 17+)**
  - iOS 専用に集中する。星空演出（Canvas / TimelineView）、音声入力（Speech framework）、課金（RevenueCat）をネイティブ API で素直に実装できる
  - コーディング規約は noodphoto / Focus のものをベースに `.claude/rules/` へ取り込む
- バックエンド: **Cloud Functions for Firebase (gen2) / Node.js 22 / TypeScript**（yomon ADR 0001 と同構成）
  - LLM 呼び出しを含むエンドポイントは `timeoutSeconds` を長めに設定する
  - ローカル開発は Firebase Emulator Suite（`demo-` プレフィックスのプロジェクト ID）で実プロジェクトなしに開発・テストできるようにする
  - LLM プロバイダの選定は本 ADR の対象外とし、バックエンド実装時に別 ADR で決める
- DB: **Cloud Firestore**
  - 相談履歴を `users/{uid}` 配下に保存する。スキーマは `documents/design/db-schema.md` を単一の真実とする
  - **書き込みは Functions (Admin SDK) 経由に限定**し、クライアントからは自分のデータの読み取りのみ許可する（返書の偽造・改竄防止と、名言 DB の出典整合性をサーバー側で保証するため）。詳細は `.claude/rules/firestore-rules.md`
- 認証: **Firebase Authentication 匿名認証**
  - サインアップ画面なしで即利用開始。RevenueCat の appUserID に匿名 UID を使い、購入状態とサーバー側の相談履歴を同一 ID で紐付ける
- Analytics: **Firebase Analytics**
- 課金: **RevenueCat**（相談チケット consumable + 聞き放題サブスクの 2 層）

検討した代替案:

- バックエンドに Cloudflare Workers: 軽量・安価だが、匿名認証・Firestore・Analytics を Firebase に置く以上、実行環境も Firebase に寄せた方が構成が単純。yomon での実績も流用できる
- バックエンドに Supabase Edge Functions: kaiyaku で実績はあるが、匿名認証 + iOS SDK + Analytics の組み合わせは Firebase の方が揃っている
- 履歴のローカル保存のみ (SwiftData): MVP は最速だが機種変更で消える。クラウド同期をオーナーが選択した

## Consequences

- 良い点
  - yomon（backend）・noodphoto / Focus（iOS）の構成・規約・CI をほぼそのまま流用でき、Shipaton までの実装期間を機能開発に使える
  - 匿名 UID を軸に「履歴のクラウド蓄積 → パーソナライズ → 課金理由」の設計（PROJECT.md のマネタイズ）がそのまま実現できる
  - Emulator Suite によりバックエンドのテストがローカル完結する
- 悪い点・トレードオフ
  - 匿名認証はアプリ削除で UID が失われる。購入の復元は RevenueCat のレシート同期で救えるが、相談履歴は失われる（Sign in with Apple による引き継ぎはフェーズ 2 で検討）
  - 書き込みを Functions 経由に限定するため、オフライン時は相談を送信できない（返書生成が LLM 依存である以上、元々オフラインでは成立しない）
  - gen2 関数はコールドスタートがあり初回リクエストのレイテンシが大きい（返書生成の演出時間で吸収する）
  - Firebase プロジェクトの新規作成・課金アカウントのリンクはオーナーの承認を得てから行う（~/.claude/rules/confirm-before-cloud-project-creation.md）
