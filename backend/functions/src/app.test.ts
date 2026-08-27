import request from "supertest";
import { describe, expect, it } from "vitest";
import { type AppDeps, createApp } from "./app";

// health はどの依存も使わないため、呼ばれたら失敗するモックを渡す。
// App Check は enforce にして、/health が検証の対象外であることを確かめる
const deps: AppDeps = {
  composeLetter: async () => {
    throw new Error("composeLetter must not be called");
  },
  classifyCrisis: async () => {
    throw new Error("classifyCrisis must not be called");
  },
  verifyIdToken: async () => {
    throw new Error("verifyIdToken must not be called");
  },
  checkEntitlement: async () => {
    throw new Error("checkEntitlement must not be called");
  },
  verifyAppCheckToken: async () => {
    throw new Error("verifyAppCheckToken must not be called");
  },
  appCheckEnforcement: "enforce",
  // /health はレート制限を消費しないため、上限は判定に影響しない
  letterRateLimit: { maxRequests: 1, windowSeconds: 3600 },
};

const app = createApp(deps);

describe("GET /health", () => {
  it("200 で status ok を返す", async () => {
    const res = await request(app).get("/health");
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ status: "ok" });
  });

  it("App Check が enforce でもヘッダ無しで 200 (死活監視を締め出さない)", async () => {
    const res = await request(app).get("/health");
    expect(res.status).toBe(200);
  });
});
