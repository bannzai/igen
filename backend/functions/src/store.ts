import { FieldValue } from "firebase-admin/firestore";
import type { Firestore } from "firebase-admin/firestore";
import type { LetterComposition, LetterLanguage } from "./letter";
import { type Person, findPerson, findQuote } from "./quotesDb";

/**
 * 相談と返書を users/{uid}/letters へ保存し、保存したドキュメントの内容を返す。
 * 格言・人物はクライアントが quotes / persons コレクションを読めない (firestore.rules) ため、
 * DB の値をそのままスナップショットとして埋め込む。格言本文の出どころは常に名言 DB (ADR 0002)
 */
export async function saveLetter(
  firestore: Firestore,
  uid: string,
  input: {
    concern: string;
    language: LetterLanguage;
    composition: LetterComposition;
  },
): Promise<{ id: string; letter: Record<string, unknown> }> {
  const quote = findQuote(input.composition.quoteId);
  if (quote === undefined) {
    throw new Error(`quoteId not in DB: ${input.composition.quoteId}`);
  }
  const letter = {
    concern: input.concern,
    language: input.language,
    quoteId: quote.id,
    quote: {
      kind: quote.kind,
      text: quote.text,
      original: quote.original,
      originalLanguage: quote.originalLanguage,
      source: quote.source,
    },
    personId: quote.personId,
    person:
      quote.personId === null ? null : (findPerson(quote.personId) ?? null),
    oneliner: input.composition.oneliner,
    meaning: input.composition.meaning,
    closing: input.composition.closing,
    diagram: input.composition.diagram,
  };
  const ref = await firestore
    .collection("users")
    .doc(uid)
    .collection("letters")
    .add({
      ...letter,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  if (letter.personId !== null && letter.person !== null) {
    await recordEncounter(
      firestore,
      uid,
      letter.personId,
      letter.person,
      quote.id,
    );
  }
  return { id: ref.id, letter };
}

/**
 * 偉人図鑑 (星図) の出会い状態を users/{uid}/encounters/{personId} に記録する。
 * 既に出会っている場合は createdAt (初回の出会い) を保持したまま更新する (冪等)
 */
async function recordEncounter(
  firestore: Firestore,
  uid: string,
  personId: string,
  person: Person,
  quoteId: string,
): Promise<void> {
  const encounterRef = firestore
    .collection("users")
    .doc(uid)
    .collection("encounters")
    .doc(personId);
  const snapshot = await encounterRef.get();
  await encounterRef.set(
    {
      personId,
      person,
      lastQuoteId: quoteId,
      ...(snapshot.exists ? {} : { createdAt: FieldValue.serverTimestamp() }),
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}
