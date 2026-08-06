import { FieldValue } from "firebase-admin/firestore";
import type { Firestore } from "firebase-admin/firestore";

// 無料枠は 1 日 1 通 (documents/PROJECT.md「マネタイズ」)
export const FREE_LETTERS_PER_DAY = 1;

/** timeZone における日付 (YYYY-MM-DD)。無料枠の「1 日」の境界に使う。 */
export function localDate(date: Date, timeZone: string): string {
  try {
    // en-CA ロケールは YYYY-MM-DD 形式を返す
    return new Intl.DateTimeFormat("en-CA", { timeZone }).format(date);
  } catch {
    // 不正な timeZone でリクエスト全体を落とさないための保険。UTC の日付にフォールバックする
    return new Intl.DateTimeFormat("en-CA", { timeZone: "UTC" }).format(date);
  }
}

/**
 * 無料枠を 1 通ぶん消費する。超過していれば消費せず false を返す。
 * 同時リクエストで二重消費しないようトランザクションで行う
 */
export async function consumeFreeQuota(
  firestore: Firestore,
  uid: string,
  date: string,
): Promise<boolean> {
  const userRef = firestore.collection("users").doc(uid);
  return firestore.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(userRef);
    const freeQuota = snapshot.data()?.freeQuota;
    if (freeQuota?.date === date && freeQuota.count >= FREE_LETTERS_PER_DAY) {
      return false;
    }
    const count = freeQuota?.date === date ? freeQuota.count + 1 : 1;
    transaction.set(
      userRef,
      {
        freeQuota: { date, count },
        createdAt: snapshot.exists
          ? (snapshot.data()?.createdAt ?? FieldValue.serverTimestamp())
          : FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    return true;
  });
}

/**
 * 消費した無料枠を戻す。返書生成の失敗・LLM 危機判定で返書を返さなかったときに使う。
 */
export async function releaseFreeQuota(
  firestore: Firestore,
  uid: string,
  date: string,
): Promise<void> {
  const userRef = firestore.collection("users").doc(uid);
  await firestore.runTransaction(async (transaction) => {
    const freeQuota = (await transaction.get(userRef)).data()?.freeQuota;
    if (freeQuota?.date !== date || freeQuota.count <= 0) {
      return;
    }
    transaction.set(
      userRef,
      {
        freeQuota: { date, count: freeQuota.count - 1 },
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  });
}
