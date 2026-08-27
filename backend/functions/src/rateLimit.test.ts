import type { Request } from "express";
import { describe, expect, it } from "vitest";
import { db } from "./firestore";
import {
  clientIp,
  consumeRateLimit,
  forwardedForHopCount,
  rateLimitKeyForIp,
} from "./rateLimit";

/** clientIp が参照するヘッダとソケットだけを持つ Request。 */
function fakeRequest(
  headers: Record<string, string | string[]>,
  remoteAddress: string | undefined,
): Request {
  return { headers, socket: { remoteAddress } } as unknown as Request;
}

describe("clientIp", () => {
  it("X-Forwarded-For の末尾を採用する (先頭は偽装できる)", () => {
    expect(
      clientIp(
        fakeRequest({ "x-forwarded-for": "1.2.3.4, 198.51.100.7" }, "10.0.0.1"),
      ),
    ).toBe("198.51.100.7");
  });

  it("X-Forwarded-For が無ければ接続元アドレスを使う", () => {
    expect(clientIp(fakeRequest({}, "198.51.100.8"))).toBe("198.51.100.8");
  });

  it("接続元アドレスも取れなければ共通のキーへ寄せる", () => {
    expect(clientIp(fakeRequest({}, undefined))).toBe("unknown");
  });
});

describe("forwardedForHopCount", () => {
  it("X-Forwarded-For が無ければ 0", () => {
    expect(forwardedForHopCount(fakeRequest({}, "10.0.0.1"))).toBe(0);
  });

  it("単一の IP なら 1 (末尾 = クライアント IP の前提が成り立つ状態)", () => {
    expect(
      forwardedForHopCount(
        fakeRequest({ "x-forwarded-for": "198.51.100.7" }, "10.0.0.1"),
      ),
    ).toBe(1);
  });

  it("2 つ並んでいれば 2", () => {
    expect(
      forwardedForHopCount(
        fakeRequest({ "x-forwarded-for": "1.2.3.4, 198.51.100.7" }, "10.0.0.1"),
      ),
    ).toBe(2);
  });
});

describe("rateLimitKeyForIp", () => {
  it("生の IP を含まないハッシュ値を返す", () => {
    const key = rateLimitKeyForIp("198.51.100.9");
    expect(key).not.toContain("198.51.100.9");
    expect(key).toMatch(/^ip:[0-9a-f]{64}$/);
  });

  it("同じ IP からは同じキーが得られる (冪等)", () => {
    expect(rateLimitKeyForIp("198.51.100.9")).toBe(
      rateLimitKeyForIp("198.51.100.9"),
    );
  });
});

describe("consumeRateLimit", () => {
  it("上限に達すると拒否し、ウィンドウが切り替わると再び許可する", async () => {
    const policy = { maxRequests: 2, windowSeconds: 60 };
    const key = rateLimitKeyForIp("198.51.100.10");
    const windowStart = new Date("2026-01-01T00:00:00Z");

    expect(await consumeRateLimit(db, key, windowStart, policy)).toEqual({
      allowed: true,
    });
    expect(await consumeRateLimit(db, key, windowStart, policy)).toEqual({
      allowed: true,
    });
    expect(await consumeRateLimit(db, key, windowStart, policy)).toEqual({
      allowed: false,
    });
    // 上限に達したリクエストは書き込まない (拒否で件数を増やさない)
    const blocked = await db.collection("rateLimits").doc(key).get();
    expect(blocked.data()?.count).toBe(2);

    const afterWindow = new Date(
      windowStart.getTime() + (policy.windowSeconds + 1) * 1000,
    );
    expect(await consumeRateLimit(db, key, afterWindow, policy)).toEqual({
      allowed: true,
    });
    const reset = await db.collection("rateLimits").doc(key).get();
    expect(reset.data()?.count).toBe(1);
    expect(reset.data()?.windowStart.toMillis()).toBe(afterWindow.getTime());
  });

  it("expiresAt にウィンドウの終了時刻を書き、ウィンドウ切替で更新する (TTL の削除基準)", async () => {
    const policy = { maxRequests: 2, windowSeconds: 60 };
    const key = rateLimitKeyForIp("198.51.100.12");
    const windowStart = new Date("2026-01-01T00:00:00Z");

    await consumeRateLimit(db, key, windowStart, policy);
    const firstWindow = (
      await db.collection("rateLimits").doc(key).get()
    ).data();
    expect(firstWindow?.expiresAt.toMillis()).toBe(
      windowStart.getTime() + policy.windowSeconds * 1000,
    );

    // 同じウィンドウ内の消費では expiresAt を延長しない (ウィンドウの終了時刻が基準のため)
    await consumeRateLimit(
      db,
      key,
      new Date(windowStart.getTime() + 1000),
      policy,
    );
    const sameWindow = (
      await db.collection("rateLimits").doc(key).get()
    ).data();
    expect(sameWindow?.expiresAt.toMillis()).toBe(
      firstWindow?.expiresAt.toMillis(),
    );

    const afterWindow = new Date(
      windowStart.getTime() + (policy.windowSeconds + 1) * 1000,
    );
    await consumeRateLimit(db, key, afterWindow, policy);
    const nextWindow = (
      await db.collection("rateLimits").doc(key).get()
    ).data();
    expect(nextWindow?.expiresAt.toMillis()).toBe(
      afterWindow.getTime() + policy.windowSeconds * 1000,
    );
  });

  it("createdAt は最初の消費時のまま保たれる", async () => {
    const policy = { maxRequests: 5, windowSeconds: 60 };
    const key = rateLimitKeyForIp("198.51.100.11");
    const windowStart = new Date("2026-01-01T00:00:00Z");

    await consumeRateLimit(db, key, windowStart, policy);
    const created = (await db.collection("rateLimits").doc(key).get()).data()
      ?.createdAt;
    await consumeRateLimit(db, key, windowStart, policy);
    const updated = (await db.collection("rateLimits").doc(key).get()).data()
      ?.createdAt;
    expect(updated).toEqual(created);
  });
});
