// 危機ワード検知 (documents/PROJECT.md リスク 2)。
// 検知した場合は返書を生成せず、クライアントは相談窓口の案内画面を表示する。
// 単純な語句マッチは取りこぼしがあるため、LLM 側の危機判定 (LetterComposition.crisis) と
// 二段構えで運用する (design_handoff_igen/README.md「実装時の注意」)

// 日本語の危機ワード。部分一致で判定する
const CRISIS_KEYWORDS_JA = [
  "死にたい",
  "死のう",
  "消えたい",
  "自殺",
  "自傷",
  "リストカット",
  "生きていたくない",
  "生きている意味がない",
  "生きてる意味がない",
  "傷つけたい",
];

// 英語の危機ワード。小文字化した本文への部分一致で判定する
const CRISIS_KEYWORDS_EN = [
  "suicide",
  "kill myself",
  "end my life",
  "self-harm",
  "self harm",
  "want to die",
  "hurt myself",
];

/** 相談本文に危機ワードが含まれるかを判定する。 */
export function detectCrisis(text: string): boolean {
  if (CRISIS_KEYWORDS_JA.some((keyword) => text.includes(keyword))) {
    return true;
  }
  const lowered = text.toLowerCase();
  return CRISIS_KEYWORDS_EN.some((keyword) => lowered.includes(keyword));
}
