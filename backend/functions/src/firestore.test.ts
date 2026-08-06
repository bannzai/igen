import { describe, expect, it } from "vitest";
import { db } from "./firestore";

// Firestore はモックせず、firebase emulators:exec 配下の実エミュレータに接続して検証する
// (.claude/rules/testing-guidelines.md)
describe("firestore emulator", () => {
  it("エミュレータに書き込んだドキュメントを読み戻せる", async () => {
    const ref = db.collection("healthcheck").doc("ping");
    await ref.set({ ok: true });
    const snapshot = await ref.get();
    expect(snapshot.data()).toEqual({ ok: true });
  });
});
