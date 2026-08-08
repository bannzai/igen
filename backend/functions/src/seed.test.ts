import { describe, expect, it } from "vitest";
import { db } from "./firestore";
import { persons, quotes } from "./quotesDb";
import { seedQuotesDb } from "./seed";

// seed は Firestore エミュレータに対して実行する (.claude/rules/testing-guidelines.md)
describe("seedQuotesDb", () => {
  it("persons / quotes を Firestore へ投入し、再実行しても件数が変わらない (冪等)", async () => {
    await seedQuotesDb(db);
    await seedQuotesDb(db);

    const personsSnapshot = await db.collection("persons").get();
    expect(personsSnapshot.size).toBe(persons.length);
    const quotesSnapshot = await db.collection("quotes").get();
    expect(quotesSnapshot.size).toBe(quotes.length);

    const seneca = await db.collection("persons").doc("seneca").get();
    expect(seneca.data()?.name.ja).toBe("セネカ");
    expect(seneca.data()?.createdAt).toBeDefined();
  });

  it("原本に無いドキュメントは削除される (原本から排除した名言を配信し続けない)", async () => {
    await db.collection("quotes").doc("stale-quote").set({ id: "stale-quote" });

    await seedQuotesDb(db);

    const staleQuote = await db.collection("quotes").doc("stale-quote").get();
    expect(staleQuote.exists).toBe(false);
  });

  it("再実行しても既存ドキュメントの createdAt は変わらない", async () => {
    await seedQuotesDb(db);
    const firstCreatedAt = (
      await db.collection("persons").doc("seneca").get()
    ).data()?.createdAt;

    await seedQuotesDb(db);

    const secondCreatedAt = (
      await db.collection("persons").doc("seneca").get()
    ).data()?.createdAt;
    expect(secondCreatedAt.isEqual(firstCreatedAt)).toBe(true);
  });
});
