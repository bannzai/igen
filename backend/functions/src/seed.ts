import { FieldValue } from "firebase-admin/firestore";
import type { Firestore } from "firebase-admin/firestore";
import { db } from "./firestore";
import { persons, quotes } from "./quotesDb";

/**
 * 名言 DB (src/data/*.json) を Firestore の persons / quotes コレクションへ投入する。
 * ドキュメント id を固定して set するため何度実行しても同じ状態になる (冪等)。
 */
export async function seedQuotesDb(firestore: Firestore): Promise<void> {
  const batch = firestore.batch();
  for (const person of persons) {
    const ref = firestore.collection("persons").doc(person.id);
    batch.set(ref, {
      ...person,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  }
  for (const quote of quotes) {
    const ref = firestore.collection("quotes").doc(quote.id);
    batch.set(ref, {
      ...quote,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
}

// CLI 実行 (npm run seed): FIRESTORE_EMULATOR_HOST が設定されていればエミュレータへ、
// 未設定なら GCLOUD_PROJECT の実プロジェクトへ投入する
if (require.main === module) {
  seedQuotesDb(db)
    .then(() => {
      console.log(`seeded: ${persons.length} persons, ${quotes.length} quotes`);
      process.exit(0);
    })
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}
