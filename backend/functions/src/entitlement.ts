// RevenueCat の購入状態をサーバー側で確認し、無料枠 (1 日 1 通) 超過時の利用可否判定に使う
// (documents/PROJECT.md「マネタイズ」。購入状態の真実は RevenueCat 側にある)

// RevenueCat の entitlement 識別子。RevenueCat プロジェクト設定 (#16 公開前チェックリスト) と揃える
export const UNLIMITED_ENTITLEMENT_ID = "unlimited";

// 相談チケット (consumable) のストア商品 id。ASC の IAP 登録 (fastlane/in_app_purchases/appstore.config.json) と揃える。
// 識別子は作成後に変更できず、価格改定時は命名規則 (documents/app-store-connect.md「判断の記録」) に従い
// 価格を含む新しい id で商品を作り直すため、購入の累計は複数 id にまたがる。
// users/{uid}.ticketsUsed は商品を跨いだ累計で、旧 id で買った未使用チケットを失わないよう、
// 販売を終了した旧 id もこの配列に残し続ける
export const TICKET_PRODUCT_IDS = ["igen_ticket1_160yen"];

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
 * appUserID には Firebase 匿名認証の uid を使う (ADR 0001)。
 *
 * Sandbox 購入 (App Review の審査・TestFlight での確認) も本番で有効として扱う。
 * 審査員は本番バックエンドに接続したアプリで Sandbox Apple ID の購入を検証するため、
 * Sandbox を除外すると審査・サンドボックス課金の検証が成立しない
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
          }
        >;
        non_subscriptions?: Record<string, unknown[]>;
      };
    };
    const entitlement =
      body.subscriber?.entitlements?.[UNLIMITED_ENTITLEMENT_ID];
    // expires_date が null (買い切り等) または未来ならアクティブ。
    // App Store の Billing Grace Period 中は expires_date が過去でも
    // grace_period_expires_date まで有効として扱う (支払い再試行中の購読者を拒否しない)
    const now = new Date();
    const unlimited =
      entitlement !== undefined &&
      (entitlement.expires_date === null ||
        new Date(entitlement.expires_date) > now ||
        (entitlement.grace_period_expires_date != null &&
          new Date(entitlement.grace_period_expires_date) > now));
    return {
      unlimited,
      ticketsPurchased: TICKET_PRODUCT_IDS.reduce(
        (total, productId) =>
          total +
          (body.subscriber?.non_subscriptions?.[productId] ?? []).length,
        0,
      ),
    };
  };
}
