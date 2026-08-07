import { FieldValue } from "firebase-admin/firestore";
import type { Firestore } from "firebase-admin/firestore";

// 無料枠は 1 日 1 通 (documents/PROJECT.md「マネタイズ」)。
// IGEN_FREE_LETTERS_PER_DAY はローカル開発 (Emulator) で複数通の UI 検証をするための上書き
export const FREE_LETTERS_PER_DAY =
  Number(process.env.IGEN_FREE_LETTERS_PER_DAY ?? "") || 1;

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
 * 無料枠を 1 通ぶん消費する。超過していれば消費せず consumed: false を返す。
 * 「1 日」の境界には初回リクエスト時の timeZone を保存して使い続け、リクエストごとの
 * timeZone 変更で日付を往復させて無料枠をリセットする悪用を防ぐ (転居等で境界がずれる
 * 影響より、無制限の LLM 呼び出しを許す影響の方が大きいと判断)。
 * 同時リクエストで二重消費しないようトランザクションで行う
 */
export async function consumeFreeQuota(
  firestore: Firestore,
  uid: string,
  now: Date,
  requestedTimeZone: string,
): Promise<{ consumed: boolean; date: string }> {
  const userRef = firestore.collection("users").doc(uid);
  return firestore.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(userRef);
    const freeQuota = snapshot.data()?.freeQuota;
    const timeZone = freeQuota?.timeZone ?? requestedTimeZone;
    const date = localDate(now, timeZone);
    if (freeQuota?.date === date && freeQuota.count >= FREE_LETTERS_PER_DAY) {
      return { consumed: false, date };
    }
    const count = freeQuota?.date === date ? freeQuota.count + 1 : 1;
    transaction.set(
      userRef,
      {
        freeQuota: { date, count, timeZone },
        createdAt: snapshot.exists
          ? (snapshot.data()?.createdAt ?? FieldValue.serverTimestamp())
          : FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    return { consumed: true, date };
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
