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

/**
 * LLM 応答の意味的整合を検証し、問題の一覧を返す (空配列なら妥当)。
 * JSON の形状は structured outputs が保証するため、ここでは DB との整合だけを見る
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
  if (composition.oneliner.trim() === "") {
    problems.push("oneliner is empty");
  }
  if (composition.meaning.trim() === "") {
    problems.push("meaning is empty");
  }
  if (composition.closing.trim() === "") {
    problems.push("closing is empty");
  }
  if (quote.personId === null && composition.diagram === null) {
    problems.push("diagram is required for a quote without a person");
  }
  return problems;
}
