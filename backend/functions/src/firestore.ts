import { getApps, initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";

if (getApps().length === 0) {
  // エミュレータ実行 (テスト・ローカル) では GCLOUD_PROJECT が未設定のことがあるため、
  // .firebaserc の default と同じ demo プロジェクト ID にフォールバックする
  initializeApp({ projectId: process.env.GCLOUD_PROJECT ?? "demo-igen" });
}

/** アプリ全体で共有する Firestore クライアント。 */
export const db = getFirestore();
