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
    classifyCrisis: async () => false,
    verifyIdToken: async (idToken) => {
      if (idToken.startsWith("token-")) {
        return { uid: idToken.slice("token-".length) };
      }
      throw new Error("invalid token");
    },
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

  it("timeZone を変えても無料枠はリセットされない (初回の timeZone で日付を固定する)", async () => {
    const app = createApp(
      fakeDeps({ composeLetter: async () => fakeComposition() }),
    );
    const first = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer token-letter-user-7")
      .send({ text: "今日の出来事", timeZone: "Pacific/Kiritimati" });
    expect(first.status).toBe(200);

    // 日付が変わって見える timeZone に切り替えても、保存済み timeZone の日付で判定される
    const second = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer token-letter-user-7")
      .send({ text: "もう一通", timeZone: "Etc/GMT+12" });
    expect(second.status).toBe(429);
    expect(second.body.error.code).toBe("free_quota_exceeded");
  });

  it("無料枠切れでも LLM の危機判定が真なら safety を返す", async () => {
    let classifyCalled = false;
    const app = createApp(
      fakeDeps({
        composeLetter: async () => fakeComposition(),
        classifyCrisis: async () => {
          classifyCalled = true;
          return true;
        },
      }),
    );
    const first = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer token-letter-user-8")
      .send({ text: "最初の相談" });
    expect(first.status).toBe(200);

    // キーワードに引っかからない危機表現でも、無料枠切れの段階で二次判定に到達する
    const second = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer token-letter-user-8")
      .send({ text: "今夜、高いところから飛び降りる計画がある" });
    expect(second.status).toBe(200);
    expect(second.body).toEqual({ type: "safety" });
    expect(classifyCalled).toBe(true);
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

  it("人物付きの格言に図解が付いたら 502 (返書契約に反するデータを通さない)", async () => {
    const app = createApp(
      fakeDeps({
        composeLetter: async () =>
          fakeComposition({
            diagram: {
              metaphor: "不要な図解",
              meaning: "人物がいる場合は付かないはず",
              usage: "付いてはいけない",
            },
          }),
      }),
    );
    const res = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer token-letter-user-9")
      .send({ text: "悩みごと" });
    expect(res.status).toBe(502);
  });

  it("生成文に医療を想起させる語が含まれたら 502", async () => {
    const app = createApp(
      fakeDeps({
        composeLetter: async () =>
          fakeComposition({ meaning: "これはあなたへの診断です。" }),
      }),
    );
    const res = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer token-letter-user-10")
      .send({ text: "悩みごと" });
    expect(res.status).toBe(502);
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
