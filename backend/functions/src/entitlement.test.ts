import { afterEach, describe, expect, it, vi } from "vitest";
import {
  TICKET_PRODUCT_ID,
  UNLIMITED_ENTITLEMENT_ID,
  createNoEntitlementChecker,
  createRevenueCatEntitlementChecker,
} from "./entitlement";

// RevenueCat REST API は呼ばず、GET /v1/subscribers の応答 body だけを差し替えて判定ロジックを検証する
function stubSubscriberResponse(subscriber: unknown) {
  return vi.spyOn(globalThis, "fetch").mockResolvedValue(
    new Response(JSON.stringify({ subscriber }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    }),
  );
}

function futureDateText(): string {
  return new Date(Date.now() + 60 * 60 * 1000).toISOString();
}

function pastDateText(): string {
  return new Date(Date.now() - 60 * 60 * 1000).toISOString();
}

afterEach(() => {
  vi.restoreAllMocks();
});

describe("createNoEntitlementChecker", () => {
  it("常に購入なしを返す", async () => {
    const checker = createNoEntitlementChecker();
    expect(await checker("uid")).toEqual({
      unlimited: false,
      ticketsPurchased: 0,
    });
  });
});

describe("createRevenueCatEntitlementChecker", () => {
  it("有効期限が未来のサブスクは unlimited になる", async () => {
    stubSubscriberResponse({
      entitlements: {
        [UNLIMITED_ENTITLEMENT_ID]: { expires_date: futureDateText() },
      },
    });
    const checker = createRevenueCatEntitlementChecker({ apiKey: "test-key" });
    expect(await checker("uid")).toEqual({
      unlimited: true,
      ticketsPurchased: 0,
    });
  });

  it("Sandbox のサブスク (App Review・TestFlight) も unlimited として数える", async () => {
    stubSubscriberResponse({
      entitlements: {
        [UNLIMITED_ENTITLEMENT_ID]: {
          expires_date: futureDateText(),
          product_identifier: "igen_unlimited_monthly",
        },
      },
      subscriptions: {
        igen_unlimited_monthly: { is_sandbox: true },
      },
    });
    const checker = createRevenueCatEntitlementChecker({ apiKey: "test-key" });
    expect(await checker("uid")).toEqual({
      unlimited: true,
      ticketsPurchased: 0,
    });
  });

  it("Sandbox のチケット購入 (App Review・TestFlight) も枚数に数える", async () => {
    stubSubscriberResponse({
      non_subscriptions: {
        [TICKET_PRODUCT_ID]: [{ is_sandbox: true }, { is_sandbox: false }],
      },
    });
    const checker = createRevenueCatEntitlementChecker({ apiKey: "test-key" });
    expect(await checker("uid")).toEqual({
      unlimited: false,
      ticketsPurchased: 2,
    });
  });

  it("有効期限が過去のサブスクは unlimited にならない", async () => {
    stubSubscriberResponse({
      entitlements: {
        [UNLIMITED_ENTITLEMENT_ID]: { expires_date: pastDateText() },
      },
    });
    const checker = createRevenueCatEntitlementChecker({ apiKey: "test-key" });
    expect(await checker("uid")).toEqual({
      unlimited: false,
      ticketsPurchased: 0,
    });
  });

  it("有効期限切れでも猶予期間中なら unlimited になる", async () => {
    stubSubscriberResponse({
      entitlements: {
        [UNLIMITED_ENTITLEMENT_ID]: {
          expires_date: pastDateText(),
          grace_period_expires_date: futureDateText(),
        },
      },
    });
    const checker = createRevenueCatEntitlementChecker({ apiKey: "test-key" });
    expect(await checker("uid")).toEqual({
      unlimited: true,
      ticketsPurchased: 0,
    });
  });

  it("expires_date が null のサブスクは unlimited になる", async () => {
    stubSubscriberResponse({
      entitlements: {
        [UNLIMITED_ENTITLEMENT_ID]: { expires_date: null },
      },
    });
    const checker = createRevenueCatEntitlementChecker({ apiKey: "test-key" });
    expect(await checker("uid")).toEqual({
      unlimited: true,
      ticketsPurchased: 0,
    });
  });

  it("購入情報がない uid は購入なしになる", async () => {
    stubSubscriberResponse({ entitlements: {}, non_subscriptions: {} });
    const checker = createRevenueCatEntitlementChecker({ apiKey: "test-key" });
    expect(await checker("uid")).toEqual({
      unlimited: false,
      ticketsPurchased: 0,
    });
  });

  it("RevenueCat がエラーを返したら例外にする", async () => {
    vi.spyOn(globalThis, "fetch").mockResolvedValue(
      new Response("", { status: 500 }),
    );
    const checker = createRevenueCatEntitlementChecker({ apiKey: "test-key" });
    await expect(checker("uid")).rejects.toThrow(
      "revenuecat subscriber lookup failed: status=500",
    );
  });
});
