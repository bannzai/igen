import personsJson from "./data/persons.json";
import quotesJson from "./data/quotes.json";

/** ロケールごとのテキスト。訳文はアプリ独自訳 (原文を併記して検証可能にする) */
export interface LocalizedText {
  ja: string;
  en: string;
}

/** 名言 DB に収録する人物。死後 70 年経過 (パブリックドメイン) のみ収録できる */
export interface Person {
  id: string;
  name: LocalizedText;
  /** 生年。紀元前は負数。不詳は null */
  born: number | null;
  /** 没年。紀元前は負数 */
  died: number;
  title: LocalizedText;
  bio: LocalizedText;
  /** 没後 70 年経過 (パブリックドメイン) の確認結果 */
  publicDomain: {
    confirmed: boolean;
    note?: string;
  };
}

/** 名言・格言・ことわざ。原文と出典を必須とする (documents/PROJECT.md リスク 1「偽名言」対策) */
export interface Quote {
  id: string;
  kind: "quote" | "proverb";
  /** 訳文。表示はロケールに応じて切り替える */
  text: LocalizedText;
  /** 原文。どのロケールでも改変せずそのまま併記する */
  original: string;
  /** 原文の言語 (ISO 639-1: la, zh, de, ja など) */
  originalLanguage: string;
  /** ことわざ等で発祥人物が特定できない場合は null */
  personId: string | null;
  /** マッチングの手がかりになるテーマタグ (ja) */
  themes: string[];
  source: {
    work: LocalizedText;
    detail?: LocalizedText;
    origTitle?: string;
    year?: string;
  };
}

/** 収録人物の一覧。データの実体は src/data/persons.json */
// JSON import は literal union (kind) や null 併用の personId が string に広がるため、型を明示して固定する
export const persons: Person[] = personsJson as Person[];

/** 名言・格言の一覧。データの実体は src/data/quotes.json */
export const quotes: Quote[] = quotesJson as Quote[];

/** id から人物を引く。存在しない場合は undefined */
export function findPerson(personId: string): Person | undefined {
  return persons.find((person) => person.id === personId);
}

/** id から名言を引く。存在しない場合は undefined */
export function findQuote(quoteId: string): Quote | undefined {
  return quotes.find((quote) => quote.id === quoteId);
}
