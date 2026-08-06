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
});
