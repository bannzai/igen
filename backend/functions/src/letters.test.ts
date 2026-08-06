import request from "supertest";
import { describe, expect, it } from "vitest";
import { type AppDeps, createApp } from "./app";
import { db } from "./firestore";
import type { LetterComposition } from "./letter";
import { findQuote } from "./quotesDb";

/** テスト用の AppDeps。verifyIdToken は "token-{uid}" 形式のトークンだけを受け付ける */
function fakeDeps(overrides: Partial<AppDeps> = {}): AppDeps {
  return {
    composeLetter: async () => {
      throw new Error("composeLetter is not stubbed");
    },
    verifyIdToken: async (idToken) => {
      if (idToken.startsWith("token-")) {
        return { uid: idToken.slice("token-".length) };
      }
      throw new Error("invalid token");
    },
    checkEntitlement: async () => ({ unlimited: false, ticketsPurchased: 0 }),
    ...overrides,
  };
}

/** テスト用の LetterComposition。 */
function fakeComposition(
  overrides: Partial<LetterComposition> = {},
): LetterComposition {
  return {
    quoteId: "seneca-non-quia-difficilia",
    oneliner: "その一歩をためらう夜もあるでしょう。",
    meaning:
      "この言葉は、困難の多くが踏み出さないことから生まれると説いています。",
    closing: "あなたの挑戦を、星々とともに見守っています。",
    diagram: null,
    crisis: false,
    ...overrides,
  };
}

describe("POST /letters", () => {
  it("Authorization ヘッダが無いと 401", async () => {
    const app = createApp(fakeDeps());
    const res = await request(app).post("/letters").send({ text: "悩み" });
    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe("unauthenticated");
  });

  it("不正なトークンは 401", async () => {
    const app = createApp(fakeDeps());
    const res = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer bad")
      .send({ text: "悩み" });
    expect(res.status).toBe(401);
  });

  it("text が無いと 400", async () => {
    const app = createApp(fakeDeps());
    const res = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer token-u")
      .send({});
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("invalid_request");
  });

  it("正常系: 名言 DB の格言そのままの返書が返り、Firestore に保存される", async () => {
    const app = createApp(
      fakeDeps({ composeLetter: async () => fakeComposition() }),
    );
    const res = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer token-letter-user-1")
      .send({ text: "新しい仕事に挑戦するのが怖い", timeZone: "Asia/Tokyo" });

    expect(res.status).toBe(200);
    expect(res.body.type).toBe("letter");
    const dbQuote = findQuote("seneca-non-quia-difficilia");
    expect(res.body.letter.quote.original).toBe(dbQuote?.original);
    expect(res.body.letter.quote.text.ja).toBe(dbQuote?.text.ja);
    expect(res.body.letter.person.name.ja).toBe("セネカ");
    expect(res.body.letter.diagram).toBeNull();

    const saved = await db
      .collection("users")
      .doc("letter-user-1")
      .collection("letters")
      .doc(res.body.id)
      .get();
    expect(saved.exists).toBe(true);
    expect(saved.data()?.concern).toBe("新しい仕事に挑戦するのが怖い");
    expect(saved.data()?.quote.original).toBe(dbQuote?.original);
    expect(saved.data()?.createdAt).toBeDefined();

    const user = await db.collection("users").doc("letter-user-1").get();
    expect(user.data()?.freeQuota.count).toBe(1);
  });

  it("無料枠 (1 日 1 通) を超えると 429", async () => {
    const app = createApp(
      fakeDeps({ composeLetter: async () => fakeComposition() }),
    );
    const first = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer token-letter-user-2")
      .send({ text: "続けてもいいのか迷う" });
    expect(first.status).toBe(200);

    const second = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer token-letter-user-2")
      .send({ text: "もう一通聞きたい" });
    expect(second.status).toBe(429);
    expect(second.body.error.code).toBe("free_quota_exceeded");
  });

  it("危機ワードを含む相談は返書を生成せず safety を返す (LLM も呼ばず保存もしない)", async () => {
    let composeCalled = false;
    const app = createApp(
      fakeDeps({
        composeLetter: async () => {
          composeCalled = true;
          return fakeComposition();
        },
      }),
    );
    const res = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer token-letter-user-3")
      .send({ text: "もう死にたいと思ってしまう" });

    expect(res.status).toBe(200);
    expect(res.body).toEqual({ type: "safety" });
    expect(composeCalled).toBe(false);

    const letters = await db
      .collection("users")
      .doc("letter-user-3")
      .collection("letters")
      .get();
    expect(letters.size).toBe(0);
    // 無料枠も消費しない
    const user = await db.collection("users").doc("letter-user-3").get();
    expect(user.exists).toBe(false);
  });

  it("LLM の危機判定でも safety を返し、無料枠を戻す", async () => {
    let attempt = 0;
    const app = createApp(
      fakeDeps({
        composeLetter: async () => {
          attempt += 1;
          return attempt === 1
            ? fakeComposition({ crisis: true })
            : fakeComposition();
        },
      }),
    );
    const first = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer token-letter-user-4")
      .send({ text: "つらいことがあった" });
    expect(first.status).toBe(200);
    expect(first.body).toEqual({ type: "safety" });

    // 無料枠が戻っているので同日でももう一度送れる
    const second = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer token-letter-user-4")
      .send({ text: "気を取り直して相談したい" });
    expect(second.status).toBe(200);
    expect(second.body.type).toBe("letter");
  });

  it("LLM が DB に無い quoteId を返したら 502 (格言の捏造を通さない)", async () => {
    const app = createApp(
      fakeDeps({
        composeLetter: async () => fakeComposition({ quoteId: "not-in-db" }),
      }),
    );
    const res = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer token-letter-user-5")
      .send({ text: "悩みごと" });
    expect(res.status).toBe(502);
    expect(res.body.error.code).toBe("generation_failed");

    const letters = await db
      .collection("users")
      .doc("letter-user-5")
      .collection("letters")
      .get();
    expect(letters.size).toBe(0);
  });

  it("返書生成で図鑑の出会い (encounters) が記録され、再度の出会いでも createdAt が保持される", async () => {
    const app = createApp(
      fakeDeps({ composeLetter: async () => fakeComposition() }),
    );
    const first = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer token-letter-user-7")
      .send({ text: "挑戦が怖い" });
    expect(first.status).toBe(200);

    const encounterRef = db
      .collection("users")
      .doc("letter-user-7")
      .collection("encounters")
      .doc("seneca");
    const firstSnapshot = await encounterRef.get();
    expect(firstSnapshot.exists).toBe(true);
    expect(firstSnapshot.data()?.person.name.ja).toBe("セネカ");
    const firstCreatedAt = firstSnapshot.data()?.createdAt;

    // 無料枠 (1 日 1 通) を Admin SDK でリセットして同日 2 通目を送れるようにする
    await db
      .collection("users")
      .doc("letter-user-7")
      .set({ freeQuota: { date: "1970-01-01", count: 0 } }, { merge: true });
    const second = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer token-letter-user-7")
      .send({ text: "また挑戦の悩み" });
    expect(second.status).toBe(200);
    const secondSnapshot = await encounterRef.get();
    expect(secondSnapshot.data()?.createdAt).toEqual(firstCreatedAt);
  });

  it("聞き放題 (unlimited) のユーザーは無料枠を超えても返書を受け取れる", async () => {
    const app = createApp(
      fakeDeps({
        composeLetter: async () => fakeComposition(),
        checkEntitlement: async () => ({
          unlimited: true,
          ticketsPurchased: 0,
        }),
      }),
    );
    const first = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer token-letter-user-8")
      .send({ text: "1 通目 (無料枠)" });
    expect(first.status).toBe(200);

    const second = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer token-letter-user-8")
      .send({ text: "2 通目 (聞き放題)" });
    expect(second.status).toBe(200);
    expect(second.body.type).toBe("letter");
  });

  it("購入済みチケットがあれば無料枠超過後も 1 枚につき 1 通送れる", async () => {
    const app = createApp(
      fakeDeps({
        composeLetter: async () => fakeComposition(),
        checkEntitlement: async () => ({
          unlimited: false,
          ticketsPurchased: 1,
        }),
      }),
    );
    const first = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer token-letter-user-9")
      .send({ text: "1 通目 (無料枠)" });
    expect(first.status).toBe(200);

    const second = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer token-letter-user-9")
      .send({ text: "2 通目 (チケット)" });
    expect(second.status).toBe(200);

    const third = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer token-letter-user-9")
      .send({ text: "3 通目 (チケット切れ)" });
    expect(third.status).toBe(429);
    expect(third.body.error.code).toBe("free_quota_exceeded");

    const user = await db.collection("users").doc("letter-user-9").get();
    expect(user.data()?.ticketsUsed).toBe(1);
  });

  it("人物のいないことわざは person が null で図解カードが付く", async () => {
    const app = createApp(
      fakeDeps({
        composeLetter: async () =>
          fakeComposition({
            quoteId: "saio-ga-uma",
            diagram: {
              metaphor: "国境の翁の馬が逃げ、また戻ってくる",
              meaning: "不運と幸運は簡単には見分けられない",
              usage: "良し悪しをすぐに決めつけそうになったとき",
            },
          }),
      }),
    );
    const res = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer token-letter-user-6")
      .send({ text: "不運なことが続いている" });

    expect(res.status).toBe(200);
    expect(res.body.letter.person).toBeNull();
    expect(res.body.letter.diagram.meaning).toBe(
      "不運と幸運は簡単には見分けられない",
    );
    expect(res.body.letter.quote.original).toBe("塞翁失馬");
  });
});
