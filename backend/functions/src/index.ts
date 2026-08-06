import { onRequest } from "firebase-functions/v2/https";
import { createApp } from "./app";

const app = createApp();

// LLM 呼び出しを含むエンドポイントの追加時に timeoutSeconds・secrets を拡張する (ADR 0001)。
// region は Firestore (asia-northeast1) と揃える。
// maxInstances: 公開 API のため、暴走・悪用時のコストを抑える安全弁として低めに絞る
export const api = onRequest(
  {
    region: "asia-northeast1",
    invoker: "public",
    maxInstances: 10,
  },
  app,
);
