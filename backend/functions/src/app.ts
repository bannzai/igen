import express, { type Express, type Request, type Response } from "express";
import { logger } from "firebase-functions";
import { detectCrisis } from "./crisis";
import type { CheckEntitlementFn } from "./entitlement";
import { db } from "./firestore";
import type {
  ClassifyCrisisFn,
  ComposeLetterFn,
  LetterLanguage,
} from "./letter";
import { validateLetterComposition } from "./letter";
import { MAX_CONCERN_CHARS } from "./openai";
import {
  consumeFreeQuota,
  consumeTicket,
  releaseFreeQuota,
  releaseTicket,
} from "./quota";
import { quotes } from "./quotesDb";
import { findLetterByRequestId, saveLetter } from "./store";

/** createApp へ注入する外部依存。テストではモックする。 */
export interface AppDeps {
  /** 返書を構成する。実装は openai.ts */
  composeLetter: ComposeLetterFn;
  /** 相談本文の危機判定のみを行う (無料枠切れでも安全案内を届ける二次判定)。実装は openai.ts */
  classifyCrisis: ClassifyCrisisFn;
  /** Firebase ID トークンを検証して uid を返す。実装は firebase-admin の verifyIdToken */
  verifyIdToken: (idToken: string) => Promise<{ uid: string }>;
  /** RevenueCat の購入状態を確認する。実装は entitlement.ts */
  checkEntitlement: CheckEntitlementFn;
}

/** 今回の返書の利用枠がどこから来たか。失敗時の返却先を揃えるために持ち回る */
type AccessGrant = "free" | "unlimited" | "ticket";

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

    const { text, language, timeZone, requestId } = req.body ?? {};
    if (typeof text !== "string" || text.trim() === "") {
      sendError(res, 400, "invalid_request", "body field 'text' is required");
      return;
    }
    if (requestId !== undefined && typeof requestId !== "string") {
      sendError(
        res,
        400,
        "invalid_request",
        "body field 'requestId' must be a string",
      );
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

    // 同じ requestId の返書が保存済みなら再生成せずそれを返す (POST の冪等化)。
    // 応答の受信前に通信が切れた場合でも、クライアントは同じ requestId の再送で保存済みの返書を回収できる
    if (requestId !== undefined) {
      const existing = await findLetterByRequestId(db, uid, requestId).catch(
        (error) => {
          // 照会の一時的な失敗では通常フローに進める (再生成されても requestId で重複は防がれる前提が崩れるだけ)
          logger.error("letter replay lookup failed", {
            uid,
            error: `${error}`,
          });
          return null;
        },
      );
      if (existing !== null) {
        // letter 内にも id を含める (クライアントの Codable が Letter 単体でデコードできるように)
        res.json({
          type: "letter",
          id: existing.id,
          letter: { id: existing.id, ...existing.letter },
        });
        return;
      }
    }

    // 危機ワードを検知したら返書は生成しない (無料枠も消費しない)。
    // 相談本文はセンシティブなデータとして扱い、保存もしない
    if (detectCrisis(text)) {
      res.json({ type: "safety" });
      return;
    }

    // 相談の受信時刻。無料枠の日付判定と、返書に保存する consultedAt (履歴の日付表示の基準) に同じ時刻を使う
    const receivedAt = new Date();

    // 無料枠 → サブスク (聞き放題) → 購入済みチケットの順に利用枠を確保する。
    // 無料枠の「1 日」の境界は quota.ts が保存済み timeZone で固定する (timeZone 切り替えによるリセット悪用の防止)
    let accessGrant: AccessGrant = "free";
    let quota: { consumed: boolean; date: string };
    try {
      quota = await consumeFreeQuota(db, uid, receivedAt, timeZone ?? "UTC");
    } catch (error) {
      logger.error("free quota transaction failed", { uid, error: `${error}` });
      sendError(
        res,
        503,
        "quota_unavailable",
        "failed to check the free quota",
      );
      return;
    }
    if (!quota.consumed) {
      // 購入状態の確認・チケット消費の失敗は 500 にせず「購入なし」として 429 に倒す
      // (RevenueCat 障害・未設定時に返書機能全体を止めず、未処理 rejection にもしないため)
      const entitlement = await deps.checkEntitlement(uid).catch((error) => {
        logger.error("entitlement check failed", { uid, error: `${error}` });
        return { unlimited: false, ticketsPurchased: 0 };
      });
      const ticketConsumed = entitlement.unlimited
        ? false
        : await consumeTicket(db, uid, entitlement.ticketsPurchased).catch(
            (error) => {
              logger.error("ticket transaction failed", {
                uid,
                error: `${error}`,
              });
              return false;
            },
          );
      if (entitlement.unlimited) {
        accessGrant = "unlimited";
      } else if (ticketConsumed) {
        accessGrant = "ticket";
      } else {
        // 利用枠がなくても危機判定は完了させる (キーワード判定の取りこぼしを LLM で補完する二段構え)。
        // 判定自体の失敗はキーワード判定を通過済みのため 429 に倒す
        const crisis = await deps
          .classifyCrisis({ concern: text })
          .catch((error) => {
            logger.error("crisis classification failed", {
              uid,
              error: `${error}`,
            });
            return false;
          });
        if (crisis) {
          res.json({ type: "safety" });
          return;
        }
        sendError(
          res,
          429,
          "free_quota_exceeded",
          "free letters for today are used up",
        );
        return;
      }
    }

    // 返書を返さずに終わる場合に、消費した利用枠 (無料枠またはチケット) を元へ戻す。
    // 補償の失敗でレスポンス (特にセーフティ応答) を失わないよう、失敗はログに留める
    const refundAccess = async (): Promise<void> => {
      try {
        if (accessGrant === "free") {
          await releaseFreeQuota(db, uid, quota.date);
        } else if (accessGrant === "ticket") {
          await releaseTicket(db, uid);
        }
      } catch (error) {
        logger.error("access refund failed", { uid, error: `${error}` });
      }
    };

    try {
      const composition = await deps.composeLetter({
        concern: text,
        language: letterLanguage,
        quotes,
      });
      // LLM 側の危機判定 (キーワード判定の取りこぼしを補完)。返書は返さず、利用枠を戻す
      if (composition.crisis) {
        await refundAccess();
        res.json({ type: "safety" });
        return;
      }
      // composer の実装 (OpenAI / フェイク) を問わず、返書契約に反するデータを保存・返却しない
      const problems = validateLetterComposition(composition);
      if (problems.length > 0) {
        throw new Error(`invalid letter composition: ${problems.join(", ")}`);
      }
      const saved = await saveLetter(db, uid, {
        concern: text,
        language: letterLanguage,
        timeZone: timeZone ?? null,
        requestId: requestId ?? null,
        consultedAt: receivedAt,
        composition,
      });
      // letter 内にも id を含める (クライアントの Codable が Letter 単体でデコードできるように)
      res.json({
        type: "letter",
        id: saved.id,
        letter: { id: saved.id, ...saved.letter },
      });
    } catch (error) {
      await refundAccess();
      // 相談本文はログに残さない (.claude/rules/firestore-rules.md「データ設計の決めごと」)
      logger.error("letter composition failed", { uid, error: `${error}` });
      sendError(res, 502, "generation_failed", "failed to compose the letter");
    }
  });

  return app;
}
