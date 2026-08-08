import { FieldValue } from "firebase-admin/firestore";
import type { Firestore } from "firebase-admin/firestore";
import { db } from "./firestore";
import { persons, quotes } from "./quotesDb";

// Firestore の WriteBatch は 1 バッチ 500 書き込みまで。serverTimestamp などの
// transform が別カウントされる場合でも超えないよう、半分の 250 件ごとに commit する
const batchWriteLimit = 250;

/** コレクション同期の 1 ドキュメント分の操作 (原本にあれば set、原本に無い既存分は delete) */
type SyncOperation =
  | {
      kind: "set";
      collection: string;
      id: string;
      data: Record<string, unknown>;
    }
  | { kind: "delete"; collection: string; id: string };

/**
 * コレクションを原本 items と同期する操作列を作る。
 * 原本から消えた既存ドキュメントは削除対象にし (原本から排除した名言を配信し続けないため)、
 * 既存ドキュメントの createdAt は保持して実際の作成時刻を失わない。
 */
async function collectionSyncOperations(
  firestore: Firestore,
  collectionName: string,
  items: Array<{ id: string }>,
): Promise<SyncOperation[]> {
  const snapshot = await firestore.collection(collectionName).get();
  const existingCreatedAtById = new Map(
    snapshot.docs.map((doc) => [doc.id, doc.get("createdAt")]),
  );
  const itemIds = new Set(items.map((item) => item.id));
  const operations: SyncOperation[] = items.map((item) => ({
    kind: "set",
    collection: collectionName,
    id: item.id,
    data: {
      ...item,
      createdAt:
        existingCreatedAtById.get(item.id) ?? FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    },
  }));
  for (const doc of snapshot.docs) {
    if (!itemIds.has(doc.id)) {
      operations.push({
        kind: "delete",
        collection: collectionName,
        id: doc.id,
      });
    }
  }
  return operations;
}

/**
 * 名言 DB (src/data/*.json) を Firestore の persons / quotes コレクションへ同期する。
 * 原本に無いドキュメントの削除と createdAt の保持により、何度実行しても同じ状態になる (冪等)。
 */
export async function seedQuotesDb(firestore: Firestore): Promise<void> {
  const personOperations = await collectionSyncOperations(
    firestore,
    "persons",
    persons,
  );
  const quoteOperations = await collectionSyncOperations(
    firestore,
    "quotes",
    quotes,
  );
  // 500 件超で複数バッチに分かれ、途中の commit 失敗で処理が止まっても
  // 参照先 (人物) が先に消えないよう、人物 upsert → 名言 upsert → 名言 delete → 人物 delete の順に並べる
  const operations = [
    ...personOperations.filter((operation) => operation.kind === "set"),
    ...quoteOperations.filter((operation) => operation.kind === "set"),
    ...quoteOperations.filter((operation) => operation.kind === "delete"),
    ...personOperations.filter((operation) => operation.kind === "delete"),
  ];
  for (let index = 0; index < operations.length; index += batchWriteLimit) {
    const batch = firestore.batch();
    for (const operation of operations.slice(index, index + batchWriteLimit)) {
      const ref = firestore.collection(operation.collection).doc(operation.id);
      if (operation.kind === "set") {
        batch.set(ref, operation.data);
      } else {
        batch.delete(ref);
      }
    }
    await batch.commit();
  }
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
