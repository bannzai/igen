import request from "supertest";
import { describe, expect, it } from "vitest";
import { createApp } from "./app";

const app = createApp();

describe("GET /health", () => {
  it("200 で status ok を返す", async () => {
    const res = await request(app).get("/health");
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ status: "ok" });
  });
});
