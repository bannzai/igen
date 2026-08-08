import { type Quote, findQuote } from "./quotesDb";

/** 返書の言語。訳文・解説をどの言語で返すかを決める (原文はどの言語でも併記する) */
export type LetterLanguage = "ja" | "en";

/** 話者が特定できない格言 (ことわざ等) を説明する図解カード (例え → 意味 → 使いどころ) */
export interface LetterDiagram {
  metaphor: string;
  meaning: string;
  usage: string;
}

/**
 * LLM が生成する部分。格言本文は含めない (quoteId で名言 DB を参照し、
 * 本文・原文・出典はサーバーが DB の値をそのまま使う。ADR 0002)
 */
export interface LetterComposition {
  quoteId: string;
  /** 悩みへのひとこと */
  oneliner: string;
  /** 格言の意味と文脈の解説 */
  meaning: string;
  /** 励ましの結び */
  closing: string;
  /** 話者がいない格言のときのみ非 null */
  diagram: LetterDiagram | null;
  /** LLM 側の危機判定 (キーワード判定を補完する二次シグナル) */
  crisis: boolean;
}

/** 返書を生成する関数。実装は openai.ts、テストではモックする */
export type ComposeLetterFn = (input: {
  concern: string;
  language: LetterLanguage;
  quotes: Quote[];
}) => Promise<LetterComposition>;

/** 相談本文が危機的かどうかだけを判定する関数。無料枠切れでも安全案内を届けるための二次判定。実装は openai.ts、テストではモックする */
export type ClassifyCrisisFn = (input: { concern: string }) => Promise<boolean>;

// 医療を想起させる語 (documents/PROJECT.md リスク 2)。システムプロンプトで禁止していても
// ユーザー本文の反復などで生成文へ混入しうるため、検証でも拒否して再試行に載せる
// 生成フィールド 1 つあたりの長さ上限。返書レイアウトの想定を大きく超える出力と
// Firestore ドキュメント上限 (1 MiB) への接近を保存前に拒否する
const MAX_GENERATED_FIELD_CHARS = 2000;

const BANNED_MEDICAL_TERMS = [
  "セラピー",
  "カウンセリング",
  "診断",
  "処方",
  "therapy",
  "counseling",
  "diagnosis",
  "prescription",
];

/**
 * LLM 応答の意味的整合を検証し、問題の一覧を返す (空配列なら妥当)。
 * JSON の形状は structured outputs が保証するため、ここでは DB との整合と
 * 生成文の内容 (空文字・禁止語) を見る
 */
export function validateLetterComposition(
  composition: LetterComposition,
): string[] {
  const problems: string[] = [];
  const quote = findQuote(composition.quoteId);
  if (quote === undefined) {
    problems.push(`quoteId not in DB: ${composition.quoteId}`);
    return problems;
  }
  if (quote.personId === null && composition.diagram === null) {
    problems.push("diagram is required for a quote without a person");
  }
  if (quote.personId !== null && composition.diagram !== null) {
    problems.push("diagram must be null for a quote with a person");
  }
  const generatedFields: Array<[string, string]> = [
    ["oneliner", composition.oneliner],
    ["meaning", composition.meaning],
    ["closing", composition.closing],
  ];
  if (composition.diagram !== null) {
    generatedFields.push(
      ["diagram.metaphor", composition.diagram.metaphor],
      ["diagram.meaning", composition.diagram.meaning],
      ["diagram.usage", composition.diagram.usage],
    );
  }
  for (const [field, value] of generatedFields) {
    if (value.trim() === "") {
      problems.push(`${field} is empty`);
    }
    if (value.length > MAX_GENERATED_FIELD_CHARS) {
      problems.push(`${field} is too long`);
    }
    const bannedTerm = BANNED_MEDICAL_TERMS.find((term) =>
      value.toLowerCase().includes(term.toLowerCase()),
    );
    if (bannedTerm !== undefined) {
      problems.push(`${field} contains a banned medical term: ${bannedTerm}`);
    }
  }
  return problems;
}
