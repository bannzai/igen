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
    /** 成立年の表記。表示ロケールに応じて切り替える (クライアントでは翻訳しない) */
    year?: LocalizedText;
  };
}

/** ja / en の 2 言語が非 null の文字列で揃っているか */
function isLocalizedText(value: unknown): value is LocalizedText {
  return (
    typeof value === "object" &&
    value !== null &&
    typeof (value as LocalizedText).ja === "string" &&
    typeof (value as LocalizedText).en === "string"
  );
}

/** persons.json の 1 要素が Person スキーマに適合するかを検証し、不適合ならフィールド名付きで throw する */
function assertPersonSchema(person: Person): void {
  const errors: string[] = [];
  if (typeof person.id !== "string" || person.id === "") {
    errors.push("id");
  }
  if (!isLocalizedText(person.name)) {
    errors.push("name");
  }
  if (!(person.born === null || typeof person.born === "number")) {
    errors.push("born");
  }
  if (typeof person.died !== "number") {
    errors.push("died");
  }
  if (!isLocalizedText(person.title)) {
    errors.push("title");
  }
  if (!isLocalizedText(person.bio)) {
    errors.push("bio");
  }
  if (typeof person.publicDomain?.confirmed !== "boolean") {
    errors.push("publicDomain.confirmed");
  }
  if (errors.length > 0) {
    throw new Error(
      `persons.json の ${person.id || "(id なし)"} がスキーマに適合しない: ${errors.join(", ")}`,
    );
  }
}

/** quotes.json の 1 要素が Quote スキーマに適合するかを検証し、不適合ならフィールド名付きで throw する */
function assertQuoteSchema(quote: Quote): void {
  const errors: string[] = [];
  if (typeof quote.id !== "string" || quote.id === "") {
    errors.push("id");
  }
  if (quote.kind !== "quote" && quote.kind !== "proverb") {
    errors.push("kind");
  }
  if (!isLocalizedText(quote.text)) {
    errors.push("text");
  }
  if (typeof quote.original !== "string") {
    errors.push("original");
  }
  if (typeof quote.originalLanguage !== "string") {
    errors.push("originalLanguage");
  }
  if (!(quote.personId === null || typeof quote.personId === "string")) {
    errors.push("personId");
  }
  if (
    !Array.isArray(quote.themes) ||
    !quote.themes.every((theme) => typeof theme === "string")
  ) {
    errors.push("themes");
  }
  if (!isLocalizedText(quote.source?.work)) {
    errors.push("source.work");
  }
  if (
    quote.source?.detail !== undefined &&
    !isLocalizedText(quote.source.detail)
  ) {
    errors.push("source.detail");
  }
  if (
    quote.source?.origTitle !== undefined &&
    typeof quote.source.origTitle !== "string"
  ) {
    errors.push("source.origTitle");
  }
  if (quote.source?.year !== undefined && !isLocalizedText(quote.source.year)) {
    errors.push("source.year");
  }
  if (errors.length > 0) {
    throw new Error(
      `quotes.json の ${quote.id || "(id なし)"} がスキーマに適合しない: ${errors.join(", ")}`,
    );
  }
}

/** 収録人物の一覧。データの実体は src/data/persons.json */
// JSON import は literal union (kind) や null 併用の personId が string に広がるため、型を明示して固定する
export const persons: Person[] = personsJson as Person[];

/** 名言・格言の一覧。データの実体は src/data/quotes.json */
export const quotes: Quote[] = quotesJson as Quote[];

// 型アサーションは実データを検証しないため、モジュール読み込み時に必ず実行時スキーマ検証を通し、
// JSON 原本の破損 (フィールド欠落・型誤り・enum 外の値) が Firestore へ投入される前に失敗させる
for (const person of persons) {
  assertPersonSchema(person);
}
for (const quote of quotes) {
  assertQuoteSchema(quote);
}

/** id から人物を引く。存在しない場合は undefined */
export function findPerson(personId: string): Person | undefined {
  return persons.find((person) => person.id === personId);
}

/** id から名言を引く。存在しない場合は undefined */
export function findQuote(quoteId: string): Quote | undefined {
  return quotes.find((quote) => quote.id === quoteId);
}
