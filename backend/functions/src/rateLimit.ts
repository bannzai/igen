import { createHash } from "node:crypto";
import type { Request } from "express";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import type { Firestore } from "firebase-admin/firestore";

/** レート制限の上限。 */
export interface RateLimitPolicy {
  /** 1 ウィンドウで許可するリクエスト数 */
  maxRequests: number;
  /** ウィンドウの長さ (秒) */
  windowSeconds: number;
}

/**
 * POST /letters に適用する IP 単位の上限。
 * 正規利用は無料枠 1 日 1 通で、聞き放題・チケットの有料ユーザーでも 1 時間に数通程度である。
 * 匿名 UID の再発行 (再インストール) で無料枠を取り直す濫用は uid 単位の枠では止まらないため、
 * 1 時間 30 通で頭打ちにして IP ごとの LLM 呼び出しコストの上限を決める。
 * モバイル回線の CGNAT や職場 Wi-Fi で複数ユーザーが同じ IP を共有しても、
 * 同一 1 時間内に 30 通を超える正規利用は想定しにくい
 */
export const LETTER_RATE_LIMIT_PER_IP: RateLimitPolicy = {
  maxRequests: 30,
  windowSeconds: 3600,
};

/**
 * リクエスト元の IP を取り出す。
 * Cloud Functions gen2 (Cloud Run) の前段プロキシは接続元 IP を X-Forwarded-For の末尾へ
 * 追記するため、クライアントが自分で付けた偽のヘッダは先頭側に来る。先頭を採用すると
 * 偽の IP を並べるだけで制限を回避できるので、末尾の要素を採用する
 */
export function clientIp(req: Request): string {
  const forwardedFor = req.headers["x-forwarded-for"];
  const rawHeader = Array.isArray(forwardedFor)
    ? forwardedFor.join(",")
    : forwardedFor;
  if (typeof rawHeader === "string" && rawHeader.trim() !== "") {
    const hops = rawHeader.split(",");
    return hops[hops.length - 1].trim();
  }
  // ヘッダが無いのはプロキシを経由しない直接接続 (ローカル実行・テスト)。
  // 取得できない場合も判定を素通しさせないため、共通のキーへ寄せる
  return req.socket.remoteAddress ?? "unknown";
}

/**
 * X-Forwarded-For に並んだホップ数。ヘッダが無ければ 0。
 * clientIp が末尾を採用する前提を、生 IP をログに出さずに本番で検証するための診断値。
 * デプロイ後、iOS アプリ (自前で X-Forwarded-For を付けない) からのリクエストで 1 なら
 * 「末尾 = クライアント IP」の前提が成り立つ。2 以上が常態なら前段プロキシが自分の IP を
 * 末尾に足しているので、clientIp の採用位置を見直す
 */
export function forwardedForHopCount(req: Request): number {
  const forwardedFor = req.headers["x-forwarded-for"];
  const rawHeader = Array.isArray(forwardedFor)
    ? forwardedFor.join(",")
    : forwardedFor;
  if (typeof rawHeader !== "string" || rawHeader.trim() === "") {
    return 0;
  }
  return rawHeader.split(",").length;
}

/**
 * IP に対応する rateLimits のドキュメント ID を作る。
 * 生の IP は通信元を特定できる情報のため Firestore に保存せず、ハッシュ値だけを鍵にする
 */
export function rateLimitKeyForIp(ip: string): string {
  return `ip:${createHash("sha256").update(ip).digest("hex")}`;
}

/**
 * rateLimits/{key} の固定ウィンドウを 1 回ぶん消費する。上限に達していれば書き込まず false を返す。
 * 滑走ウィンドウのようにリクエストの履歴を持たず、1 ドキュメント 1 トランザクションで
 * 判定を完結できるため固定ウィンドウを選ぶ (ウィンドウの境界をまたぐと短時間に上限の
 * 2 倍近くまで通り得るが、濫用の頭打ちという目的には十分)。
 * 同時リクエストで上限を超えないようトランザクションで行う。
 *
 * ドキュメントは無限に増え続けないよう Firestore の TTL ポリシーで自動削除する前提で、
 * 削除の基準になる expiresAt (ウィンドウの終了時刻) を書き込む。TTL ポリシーは
 * デプロイ環境ごとに一度だけ有効化する:
 * gcloud firestore fields ttls update expiresAt --collection-group=rateLimits --enable-ttl --project=igen-prod
 * TTL の削除は期限から最大 24 時間程度遅れる仕様だが、期限切れのドキュメントはウィンドウ外として
 * 新しいウィンドウで上書きされるため、削除の遅れは判定に影響しない
 */
export async function consumeRateLimit(
  firestore: Firestore,
  key: string,
  now: Date,
  policy: RateLimitPolicy,
): Promise<{ allowed: boolean }> {
  const rateLimitRef = firestore.collection("rateLimits").doc(key);
  return firestore.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(rateLimitRef);
    const storedWindowStart: Timestamp | undefined =
      snapshot.data()?.windowStart;
    const windowStart =
      storedWindowStart !== undefined &&
      now.getTime() - storedWindowStart.toMillis() < policy.windowSeconds * 1000
        ? storedWindowStart
        : Timestamp.fromDate(now);
    // 保存済みのウィンドウを続けているときだけ件数を引き継ぐ
    const count =
      windowStart === storedWindowStart ? (snapshot.data()?.count ?? 0) : 0;
    if (count >= policy.maxRequests) {
      return { allowed: false };
    }
    transaction.set(
      rateLimitRef,
      {
        windowStart,
        count: count + 1,
        expiresAt: Timestamp.fromMillis(
          windowStart.toMillis() + policy.windowSeconds * 1000,
        ),
        createdAt: snapshot.data()?.createdAt ?? FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    return { allowed: true };
  });
}
