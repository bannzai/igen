import express, { type Express, type Request, type Response } from "express";
import { logger } from "firebase-functions";
import { detectCrisis } from "./crisis";
import { db } from "./firestore";
import type { ComposeLetterFn, LetterLanguage } from "./letter";
import { MAX_CONCERN_CHARS } from "./openai";
import { consumeFreeQuota, localDate, releaseFreeQuota } from "./quota";
import { quotes } from "./quotesDb";
import { saveLetter } from "./store";

/** createApp へ注入する外部依存。テストではモックする。 */
export interface AppDeps {
  /** 返書を構成する。実装は openai.ts */
  composeLetter: ComposeLetterFn;
  /** Firebase ID トークンを検証して uid を返す。実装は firebase-admin の verifyIdToken */
  verifyIdToken: (idToken: string) => Promise<{ uid: string }>;
}

/** 共通エラー形状でレスポンスを返す。 */
function sendError(
  res: Response,
  status: number,
  code: string,
  message: string,
): void {
  res.status(status).json({ error: { code, message } });
}

/** Authorization: Bearer ヘッダを検証して uid を返す。失敗時は null (401 は呼び出し元で返す)。 */
async function authenticate(
  deps: AppDeps,
  req: Request,
): Promise<string | null> {
  const authorization = req.headers.authorization;
  if (
    typeof authorization !== "string" ||
    !authorization.startsWith("Bearer ")
  ) {
    return null;
  }
  try {
    return (await deps.verifyIdToken(authorization.slice("Bearer ".length)))
      .uid;
  } catch {
    return null;
  }
}

/** API の Express アプリを組み立てる。 */
export function createApp(deps: AppDeps): Express {
  const app = express();
  app.use(express.json({ limit: "1mb" }));

  app.get("/health", (_req: Request, res: Response) => {
    res.json({ status: "ok" });
  });

  // 相談を受け取り返書を生成する。
  // フロー: 認証 → 入力検証 → 危機ワード判定 → 無料枠消費 → LLM マッチング → 保存
  app.post("/letters", async (req: Request, res: Response) => {
    const uid = await authenticate(deps, req);
    if (uid === null) {
      sendError(
        res,
        401,
        "unauthenticated",
        "valid Authorization bearer token is required",
      );
      return;
    }

    const { text, language, timeZone } = req.body ?? {};
    if (typeof text !== "string" || text.trim() === "") {
      sendError(res, 400, "invalid_request", "body field 'text' is required");
      return;
    }
    if (text.length > MAX_CONCERN_CHARS) {
      sendError(
        res,
        400,
        "invalid_request",
        `body field 'text' must be at most ${MAX_CONCERN_CHARS} characters`,
      );
      return;
    }
    if (language !== undefined && language !== "ja" && language !== "en") {
      sendError(
        res,
        400,
        "invalid_request",
        "body field 'language' must be 'ja' or 'en'",
      );
      return;
    }
    if (timeZone !== undefined && typeof timeZone !== "string") {
      sendError(
        res,
        400,
        "invalid_request",
        "body field 'timeZone' must be a string",
      );
      return;
    }
    const letterLanguage: LetterLanguage = language ?? "ja";

    // 危機ワードを検知したら返書は生成しない (無料枠も消費しない)。
    // 相談本文はセンシティブなデータとして扱い、保存もしない
    if (detectCrisis(text)) {
      res.json({ type: "safety" });
      return;
    }

    const date = localDate(new Date(), timeZone ?? "UTC");
    if (!(await consumeFreeQuota(db, uid, date))) {
      sendError(
        res,
        429,
        "free_quota_exceeded",
        "free letters for today are used up",
      );
      return;
    }

    try {
      const composition = await deps.composeLetter({
        concern: text,
        language: letterLanguage,
        quotes,
      });
      // LLM 側の危機判定 (キーワード判定の取りこぼしを補完)。返書は返さず、無料枠を戻す
      if (composition.crisis) {
        await releaseFreeQuota(db, uid, date);
        res.json({ type: "safety" });
        return;
      }
      const saved = await saveLetter(db, uid, {
        concern: text,
        language: letterLanguage,
        composition,
      });
      res.json({ type: "letter", id: saved.id, letter: saved.letter });
    } catch (error) {
      await releaseFreeQuota(db, uid, date);
      // 相談本文はログに残さない (.claude/rules/firestore-rules.md「データ設計の決めごと」)
      logger.error("letter composition failed", { uid, error: `${error}` });
      sendError(res, 502, "generation_failed", "failed to compose the letter");
    }
  });

  return app;
}
