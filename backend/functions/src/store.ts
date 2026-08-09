import { FieldValue, Timestamp } from "firebase-admin/firestore";
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
    /** 相談時の端末タイムゾーン。履歴の日付表示を相談時のまま固定するために保存する。不明なら null */
    timeZone: string | null;
    /** POST の冪等化に使うクライアント生成 ID。再送時の重複生成を防ぐ。未指定なら null */
    requestId: string | null;
    /** 相談の受信時刻。履歴の日付表示の基準 (生成完了時の createdAt では深夜送信で翌日にずれるため) */
    consultedAt: Date;
    composition: LetterComposition;
  },
): Promise<{ id: string; letter: Record<string, unknown> }> {
  const quote = findQuote(input.composition.quoteId);
  if (quote === undefined) {
    throw new Error(`quoteId not in DB: ${input.composition.quoteId}`);
  }
  // 返り値の letter は JSON レスポンスにそのまま載るため Timestamp を含めない
  // (Timestamp は JSON 化するとクライアントの Codable が解釈できない形になる)。
  // 相談時刻は日付表示の基準としてクライアントが必要とするため、ミリ秒 epoch で含める
  const letter = {
    consultedAt: input.consultedAt.getTime(),
    concern: input.concern,
    language: input.language,
    timeZone: input.timeZone,
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
  // 返書と出会い (encounters) は同一トランザクションで確定させる。
  // 別書き込みにすると encounter 側だけ失敗したとき返書だけが残り、
  // 再試行での履歴重複や星図との不整合が生じるため
  const letterRef = firestore
    .collection("users")
    .doc(uid)
    .collection("letters")
    .doc();
  await firestore.runTransaction(async (transaction) => {
    if (letter.personId !== null && letter.person !== null) {
      const encounterRef = firestore
        .collection("users")
        .doc(uid)
        .collection("encounters")
        .doc(letter.personId);
      // 既に出会っている場合は createdAt (初回の出会い) を保持したまま更新する (冪等)
      const snapshot = await transaction.get(encounterRef);
      transaction.set(
        encounterRef,
        {
          personId: letter.personId,
          person: letter.person,
          lastQuoteId: quote.id,
          ...(snapshot.exists
            ? {}
            : { createdAt: FieldValue.serverTimestamp() }),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    }
    transaction.set(letterRef, {
      ...letter,
      consultedAt: Timestamp.fromDate(input.consultedAt),
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  });
  return { id: letterRef.id, letter };
}

/**
 * 返書を伴わない終端応答 (safety) の完了種別を users/{uid}/letterRequests へ記録する。
 * 相談本文は保存しない (センシティブデータ。.claude/rules/firestore-rules.md)。
 * POST の応答を受信できなかったクライアントが、GET /letters の冪等照会で
 * safety の結果を回収できるようにするための記録。
 * 同じ requestId での再実行は同じ完了種別の上書きになるため冪等
 */
export async function saveSafetyOutcome(
  firestore: Firestore,
  uid: string,
  requestId: string,
): Promise<void> {
  await firestore
    .collection("users")
    .doc(uid)
    .collection("letterRequests")
    .doc(requestId)
    .set({
      outcome: "safety",
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
}

/**
 * requestId に対して safety の完了種別が記録済みかを返す (GET /letters の冪等照会用)。
 * 返書が保存されるケースは letters コレクションを requestId で照会するため、ここでは扱わない
 */
export async function findSafetyOutcome(
  firestore: Firestore,
  uid: string,
  requestId: string,
): Promise<boolean> {
  const document = await firestore
    .collection("users")
    .doc(uid)
    .collection("letterRequests")
    .doc(requestId)
    .get();
  return document.exists && document.data()?.outcome === "safety";
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
  // JSON レスポンスに載せるため、クライアントの Codable が解釈できない Timestamp フィールドを除外する。
  // 相談時刻は日付表示の基準としてクライアントが必要とするため、ミリ秒 epoch に変換して残す
  const { createdAt, updatedAt, consultedAt, ...letter } = document.data();
  return {
    id: document.id,
    letter: {
      ...letter,
      ...(consultedAt instanceof Timestamp
        ? { consultedAt: consultedAt.toMillis() }
        : {}),
    },
  };
}
