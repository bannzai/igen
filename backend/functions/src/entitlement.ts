// RevenueCat の購入状態をサーバー側で確認し、無料枠 (1 日 1 通) 超過時の利用可否判定に使う
// (documents/PROJECT.md「マネタイズ」。購入状態の真実は RevenueCat 側にある)

// RevenueCat の entitlement 識別子。RevenueCat プロジェクト設定 (#16 公開前チェックリスト) と揃える
export const UNLIMITED_ENTITLEMENT_ID = "unlimited";

// 相談チケット (consumable) のストア商品 id。ASC の IAP 登録 (#16) と揃える
export const TICKET_PRODUCT_ID = "igen_ticket_1";

/** uid の購入状態。unlimited はサブスク、ticketsPurchased は購入済みチケットの累計 */
export interface Entitlement {
  unlimited: boolean;
  ticketsPurchased: number;
}

/** 購入状態を確認する関数。実装は RevenueCat REST API、テストではモックする */
export type CheckEntitlementFn = (uid: string) => Promise<Entitlement>;

/** 購入機能が未設定の間に使う、常に「購入なし」を返すチェッカー。 */
export function createNoEntitlementChecker(): CheckEntitlementFn {
  return async () => ({ unlimited: false, ticketsPurchased: 0 });
}

/**
 * RevenueCat REST API (GET /v1/subscribers/{uid}) で購入状態を確認するチェッカーを作る。
 * appUserID には Firebase 匿名認証の uid を使う (ADR 0001)
 */
export function createRevenueCatEntitlementChecker(options: {
  apiKey: string;
}): CheckEntitlementFn {
  return async (uid) => {
    const response = await fetch(
      `https://api.revenuecat.com/v1/subscribers/${encodeURIComponent(uid)}`,
      {
        headers: {
          Authorization: `Bearer ${options.apiKey}`,
          "Content-Type": "application/json",
        },
        // RevenueCat の応答停止で Functions の実行期限 (300 秒) を使い切らないよう短い期限で失敗させ、
        // 呼び出し元の「購入なし」フォールバック (app.ts の catch) へ流す
        signal: AbortSignal.timeout(10_000),
      },
    );
    if (!response.ok) {
      throw new Error(
        `revenuecat subscriber lookup failed: status=${response.status}`,
      );
    }
    const body = (await response.json()) as {
      subscriber?: {
        entitlements?: Record<
          string,
          {
            expires_date: string | null;
            grace_period_expires_date?: string | null;
            /** 購入元のストア。Sandbox 購入は "app_store_sandbox"/"play_store_sandbox" などになる */
            store?: string;
            is_sandbox?: boolean;
          }
        >;
        non_subscriptions?: Record<string, { is_sandbox?: boolean }[]>;
      };
    };
    const entitlement =
      body.subscriber?.entitlements?.[UNLIMITED_ENTITLEMENT_ID];
    // Sandbox の購入 (TestFlight 等) は課金されていないため、本番では利用枠として数えない
    // (Emulator 実行時は開発検証のため数える)
    const countsSandbox = process.env.FUNCTIONS_EMULATOR === "true";
    // expires_date が null (買い切り等) または未来ならアクティブ。
    // App Store の Billing Grace Period 中は expires_date が過去でも
    // grace_period_expires_date まで有効として扱う (支払い再試行中の購読者を拒否しない)
    const now = new Date();
    const isSandboxEntitlement =
      entitlement?.is_sandbox === true ||
      (entitlement?.store?.includes("sandbox") ?? false);
    const unlimited =
      entitlement !== undefined &&
      (countsSandbox || !isSandboxEntitlement) &&
      (entitlement.expires_date === null ||
        new Date(entitlement.expires_date) > now ||
        (entitlement.grace_period_expires_date != null &&
          new Date(entitlement.grace_period_expires_date) > now));
    // Sandbox 購入 (TestFlight 等) は課金されていないため、本番の利用枠として数えない
    // (Emulator 実行時は開発検証のため数える)
    const ticketPurchases =
      body.subscriber?.non_subscriptions?.[TICKET_PRODUCT_ID] ?? [];
    return {
      unlimited,
      ticketsPurchased: ticketPurchases.filter(
        (purchase) => countsSandbox || purchase.is_sandbox !== true,
      ).length,
    };
  };
}
