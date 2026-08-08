import type { Express } from "express";
import { getAuth } from "firebase-admin/auth";
import { defineSecret } from "firebase-functions/params";
import { onRequest } from "firebase-functions/v2/https";
import { createApp } from "./app";
import {
  createFakeCrisisClassifier,
  createFakeLetterComposer,
} from "./fakeLlm";
// firebase-admin の初期化を先に済ませる (getAuth が初期化済みの app を要求するため)
import "./firestore";
import {
  createOpenAICrisisClassifier,
  createOpenAILetterComposer,
} from "./openai";

const openaiApiKey = defineSecret("OPENAI_API_KEY");

// シークレット (OPENAI_API_KEY) はハンドラ実行時にしか読めないため、
// アプリはコールドスタート後の初回リクエストで一度だけ組み立てる
let app: Express | undefined;

// LLM 呼び出し (返書生成) を含むため timeout を長めに取る (ADR 0001)。
// region は Firestore (asia-northeast1) と揃える。
// maxInstances: 公開 API のため、暴走・悪用時の LLM 呼び出しコストを抑える安全弁として低めに絞る
export const api = onRequest(
  {
    region: "asia-northeast1",
    timeoutSeconds: 300,
    secrets: [openaiApiKey],
    invoker: "public",
    maxInstances: 10,
  },
  (req, res) => {
    if (app === undefined) {
      // フェイク LLM は Emulator でのローカル開発専用。本番環境に IGEN_FAKE_LLM が
      // 誤って設定されても定型返書・フェイク危機判定へ切り替わらないよう、Emulator 実行時のみ許可する
      const usesFakeLlm =
        process.env.FUNCTIONS_EMULATOR === "true" &&
        process.env.IGEN_FAKE_LLM === "1";
      // ADR 0002: モデルはコード変更なしで差し替えられるよう環境変数にする
      const openaiOptions = {
        apiKey: openaiApiKey.value(),
        model: process.env.OPENAI_MODEL ?? "gpt-5.6",
      };
      app = createApp({
        composeLetter: usesFakeLlm
          ? createFakeLetterComposer()
          : createOpenAILetterComposer(openaiOptions),
        classifyCrisis: usesFakeLlm
          ? createFakeCrisisClassifier()
          : createOpenAICrisisClassifier(openaiOptions),
        verifyIdToken: (idToken) => getAuth().verifyIdToken(idToken),
      });
    }
    app(req, res);
  },
);
