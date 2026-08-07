import { FieldValue } from "firebase-admin/firestore";
import type { Firestore } from "firebase-admin/firestore";
import type { LetterComposition, LetterLanguage } from "./letter";
import { findPerson, findQuote } from "./quotesDb";

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
    /** POST の冪等化に使うクライアント生成 ID。再送時の重複生成を防ぐ。未指定なら null */
    requestId: string | null;
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
    requestId: input.requestId,
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
  return { id: ref.id, letter };
}

/**
 * requestId で保存済みの返書を照会する (POST /letters の冪等化)。無ければ null
 */
export async function findLetterByRequestId(
  firestore: Firestore,
  uid: string,
  requestId: string,
): Promise<{ id: string; letter: Record<string, unknown> } | null> {
  const snapshot = await firestore
    .collection("users")
    .doc(uid)
    .collection("letters")
    .where("requestId", "==", requestId)
    .limit(1)
    .get();
  const document = snapshot.docs[0];
  if (document === undefined) {
    return null;
  }
  return { id: document.id, letter: document.data() };
}
