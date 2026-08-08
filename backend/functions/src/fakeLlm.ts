import type { ClassifyCrisisFn, ComposeLetterFn } from "./letter";

// ローカル開発 (Emulator) 用のフェイク LLM。実 API キーなしで E2E フローを完結させるための開発ハーネスで、
// 環境変数 IGEN_FAKE_LLM=1 のときだけ index.ts が使う。本番コードパスでは使われない。
// マッチング: 相談本文に quoteId が含まれていればその格言 (UI 検証でパターンを固定するため)、
// なければテーマタグの部分一致、どれにも当たらなければ先頭の格言を選ぶ
export function createFakeLetterComposer(): ComposeLetterFn {
  return async (input) => {
    const quote =
      input.quotes.find((candidate) => input.concern.includes(candidate.id)) ??
      input.quotes.find((candidate) =>
        candidate.themes.some((theme) => input.concern.includes(theme)),
      ) ??
      input.quotes[0];
    const ja = input.language === "ja";
    return {
      quoteId: quote.id,
      oneliner: ja
        ? "お便りを読みました。その悩みに、そっと寄り添う言葉を選びました。"
        : "I have read your letter, and chosen words to sit quietly beside your worry.",
      meaning: ja
        ? `「${quote.source.work.ja}」に残るこの言葉は、あなたの今夜の悩みにも通じています。`
        : `These words, preserved in "${quote.source.work.en}", speak to your worry tonight as well.`,
      closing: ja
        ? "星のもとで、あなたの明日を見守っています。"
        : "Under the stars, I will be watching over your tomorrow.",
      diagram:
        quote.personId === null
          ? {
              metaphor: ja
                ? "ことわざが描く情景"
                : "The image the proverb paints",
              meaning: ja ? "そこから伝わる教え" : "The lesson it carries",
              usage: ja
                ? "こんな夜に思い出す言葉"
                : "A phrase to recall on nights like this",
            }
          : null,
      // 相談本文に "fake-crisis" を含めるとセーフティ画面の E2E を再現できる
      // (無料枠が残っている通常フローでは composeLetter の結果の crisis が採用されるため)
      crisis: input.concern.includes("fake-crisis"),
    };
  };
}

/**
 * ローカル開発用のフェイク危機判定 (無料枠切れ時の二次判定)。
 * セーフティ画面の E2E を再現できるよう、相談本文に "fake-crisis" が含まれるときだけ危機ありを返す
 */
export function createFakeCrisisClassifier(): ClassifyCrisisFn {
  return async (input) => input.concern.includes("fake-crisis");
}
