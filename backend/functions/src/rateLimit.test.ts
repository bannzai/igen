import type { Request } from "express";
import { describe, expect, it } from "vitest";
import { db } from "./firestore";
import { clientIp, consumeRateLimit, rateLimitKeyForIp } from "./rateLimit";

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
