import { describe, expect, it } from "vitest";
import { persons, quotes } from "./quotesDb";

// 名言 DB の整合性テスト。偽名言 (出典なし・LLM 生成) の混入を機械的に防ぐ
// (documents/PROJECT.md リスク 1、.claude/rules/firestore-rules.md「データ設計の決めごと」)
describe("quotes DB integrity", () => {
  it("id が一意である", () => {
    const personIds = persons.map((person) => person.id);
    expect(new Set(personIds).size).toBe(personIds.length);
    const quoteIds = quotes.map((quote) => quote.id);
    expect(new Set(quoteIds).size).toBe(quoteIds.length);
  });

  it("すべての名言に原文がある", () => {
    for (const quote of quotes) {
      expect(quote.original.trim(), quote.id).not.toBe("");
      expect(quote.originalLanguage.trim(), quote.id).not.toBe("");
    }
  });

  it("すべての名言に出典 (work) がある", () => {
    for (const quote of quotes) {
      expect(quote.source.work.ja.trim(), quote.id).not.toBe("");
      expect(quote.source.work.en.trim(), quote.id).not.toBe("");
    }
  });

  it("すべての名言に ja / en の訳文がある", () => {
    for (const quote of quotes) {
      expect(quote.text.ja.trim(), quote.id).not.toBe("");
      expect(quote.text.en.trim(), quote.id).not.toBe("");
    }
  });

  it("personId は収録人物を参照している", () => {
    const personIds = new Set(persons.map((person) => person.id));
    for (const quote of quotes) {
      if (quote.personId !== null) {
        expect(
          personIds.has(quote.personId),
          `${quote.id} -> ${quote.personId}`,
        ).toBe(true);
      }
    }
  });

  it("収録人物は全員パブリックドメイン (没後 70 年経過) である", () => {
    const currentYear = new Date().getFullYear();
    for (const person of persons) {
      expect(person.publicDomain.confirmed, person.id).toBe(true);
      expect(currentYear - person.died, person.id).toBeGreaterThanOrEqual(70);
    }
  });

  it("すべての人物に少なくとも 1 つの名言がある", () => {
    const referencedPersonIds = new Set(quotes.map((quote) => quote.personId));
    for (const person of persons) {
      expect(referencedPersonIds.has(person.id), person.id).toBe(true);
    }
  });
});
