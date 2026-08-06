import request from "supertest";
import { describe, expect, it } from "vitest";
import { type AppDeps, createApp } from "./app";

// health はどの依存も使わないため、呼ばれたら失敗するモックを渡す
const deps: AppDeps = {
  composeLetter: async () => {
    throw new Error("composeLetter must not be called");
  },
  verifyIdToken: async () => {
    throw new Error("verifyIdToken must not be called");
  },
  checkEntitlement: async () => {
    throw new Error("checkEntitlement must not be called");
  },
};

const app = createApp(deps);

describe("GET /health", () => {
  it("200 で status ok を返す", async () => {
    const res = await request(app).get("/health");
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ status: "ok" });
  });
});
