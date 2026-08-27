import request from "supertest";
import { describe, expect, it } from "vitest";
import { type AppDeps, createApp } from "./app";
import { db } from "./firestore";
import type { LetterComposition } from "./letter";
import { findQuote } from "./quotesDb";

/** テスト用の App Check トークン。verifyAppCheckToken はこの値だけを受け付ける */
const validAppCheckToken = "appcheck-valid";

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
    checkEntitlement: async () => ({ unlimited: false, ticketsPurchased: 0 }),
    verifyAppCheckToken: async (token) => {
      if (token !== validAppCheckToken) {
        throw new Error("invalid app check token");
      }
      return { appId: "1:000000000000:ios:0000000000000000" };
    },
    appCheckEnforcement: "monitor",
    // 既存のテストは App Check ヘッダを付けずに送るため、既定は本番と同じ monitor にする
    // (段階適用の既定値。appCheck.ts の resolveAppCheckEnforcement を参照)。
    // レート制限は同一 IP (ローカルループバック) から多数の相談を送るテストが
    // 制限に掛からないよう、上限を大きく取る
    letterRateLimit: { maxRequests: 1000, windowSeconds: 3600 },
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

  it("返書生成で図鑑の出会い (encounters) が記録され、再度の出会いでも createdAt が保持される", async () => {
    const app = createApp(
      fakeDeps({ composeLetter: async () => fakeComposition() }),
    );
    const first = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer token-letter-user-11")
      .send({ text: "挑戦が怖い" });
    expect(first.status).toBe(200);

    const encounterRef = db
      .collection("users")
      .doc("letter-user-11")
      .collection("encounters")
      .doc("seneca");
    const firstSnapshot = await encounterRef.get();
    expect(firstSnapshot.exists).toBe(true);
    expect(firstSnapshot.data()?.person.name.ja).toBe("セネカ");
    const firstCreatedAt = firstSnapshot.data()?.createdAt;

    // 無料枠 (1 日 1 通) を Admin SDK でリセットして同日 2 通目を送れるようにする
    await db
      .collection("users")
      .doc("letter-user-11")
      .set({ freeQuota: { date: "1970-01-01", count: 0 } }, { merge: true });
    const second = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer token-letter-user-11")
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
      .set("Authorization", "Bearer token-letter-user-12")
      .send({ text: "1 通目 (無料枠)" });
    expect(first.status).toBe(200);

    const second = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer token-letter-user-12")
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
      .set("Authorization", "Bearer token-letter-user-13")
      .send({ text: "1 通目 (無料枠)" });
    expect(first.status).toBe(200);

    const second = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer token-letter-user-13")
      .send({ text: "2 通目 (チケット)" });
    expect(second.status).toBe(200);

    const third = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer token-letter-user-13")
      .send({ text: "3 通目 (チケット切れ)" });
    expect(third.status).toBe(429);
    expect(third.body.error.code).toBe("free_quota_exceeded");

    const user = await db.collection("users").doc("letter-user-13").get();
    expect(user.data()?.ticketsUsed).toBe(1);
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

describe("GET /letters (requestId での冪等照会)", () => {
  it("Authorization ヘッダが無いと 401", async () => {
    const app = createApp(fakeDeps());
    const res = await request(app).get("/letters").query({ requestId: "r-1" });
    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe("unauthenticated");
  });

  it("requestId が無いと 400", async () => {
    const app = createApp(fakeDeps());
    const res = await request(app)
      .get("/letters")
      .set("Authorization", "Bearer token-replay-user-1");
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("invalid_request");
  });

  it("保存済みの返書が無ければ 404", async () => {
    const app = createApp(fakeDeps());
    const res = await request(app)
      .get("/letters")
      .set("Authorization", "Bearer token-replay-user-1")
      .query({ requestId: "unknown-request" });
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe("letter_not_found");
  });

  it("POST で保存済みの返書を同じ envelope で返し、利用枠は消費しない", async () => {
    const app = createApp(
      fakeDeps({ composeLetter: async () => fakeComposition() }),
    );
    const posted = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer token-replay-user-2")
      .send({
        text: "新しい仕事に挑戦するのが怖い",
        requestId: "replay-req-1",
        timeZone: "Asia/Tokyo",
      });
    expect(posted.status).toBe(200);

    const replayed = await request(app)
      .get("/letters")
      .set("Authorization", "Bearer token-replay-user-2")
      .query({ requestId: "replay-req-1" });
    expect(replayed.status).toBe(200);
    expect(replayed.body.type).toBe("letter");
    expect(replayed.body.id).toBe(posted.body.id);
    expect(replayed.body.letter.id).toBe(posted.body.id);
    expect(replayed.body.letter.quote.original).toBe(
      posted.body.letter.quote.original,
    );
    expect(replayed.body.letter.consultedAt).toBe(
      posted.body.letter.consultedAt,
    );

    // 読み取り専用の照会は無料枠を消費しない (POST の 1 消費のまま)
    const user = await db.collection("users").doc("replay-user-2").get();
    expect(user.data()?.freeQuota.count).toBe(1);
  });

  it("他ユーザーの requestId では取得できない", async () => {
    const app = createApp(
      fakeDeps({ composeLetter: async () => fakeComposition() }),
    );
    const posted = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer token-replay-user-3")
      .send({ text: "続けてもいいのか迷う", requestId: "replay-req-2" });
    expect(posted.status).toBe(200);

    const other = await request(app)
      .get("/letters")
      .set("Authorization", "Bearer token-replay-user-4")
      .query({ requestId: "replay-req-2" });
    expect(other.status).toBe(404);
  });
});

describe("GET /letters (safety の完了種別の回収)", () => {
  it("危機ワードの相談は safety の完了種別が記録され、冪等照会で回収できる", async () => {
    const app = createApp(fakeDeps());
    const posted = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer token-safety-user-1")
      .send({ text: "もう死にたいくらいつらい", requestId: "safety-req-1" });
    expect(posted.status).toBe(200);
    expect(posted.body.type).toBe("safety");

    const replayed = await request(app)
      .get("/letters")
      .set("Authorization", "Bearer token-safety-user-1")
      .query({ requestId: "safety-req-1" });
    expect(replayed.status).toBe(200);
    expect(replayed.body.type).toBe("safety");

    // 完了種別の記録に相談本文を含めない (センシティブデータ)
    const outcome = await db
      .collection("users")
      .doc("safety-user-1")
      .collection("letterRequests")
      .doc("safety-req-1")
      .get();
    expect(outcome.exists).toBe(true);
    expect(outcome.data()?.outcome).toBe("safety");
    expect(Object.keys(outcome.data() ?? {}).sort()).toEqual([
      "createdAt",
      "outcome",
      "updatedAt",
    ]);
  });

  it("LLM 側の危機判定による safety も冪等照会で回収できる", async () => {
    const app = createApp(
      fakeDeps({
        composeLetter: async () => fakeComposition({ crisis: true }),
      }),
    );
    const posted = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer token-safety-user-2")
      .send({ text: "つらいことがあった", requestId: "safety-req-2" });
    expect(posted.status).toBe(200);
    expect(posted.body.type).toBe("safety");

    const replayed = await request(app)
      .get("/letters")
      .set("Authorization", "Bearer token-safety-user-2")
      .query({ requestId: "safety-req-2" });
    expect(replayed.status).toBe(200);
    expect(replayed.body.type).toBe("safety");
  });

  it("requestId なしの危機相談は記録なしで safety を返す", async () => {
    const app = createApp(fakeDeps());
    const posted = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer token-safety-user-3")
      .send({ text: "消えたいと思ってしまう" });
    expect(posted.status).toBe(200);
    expect(posted.body.type).toBe("safety");
  });
});

describe("App Check の検証", () => {
  it("monitor ではヘッダが無くても返書を返す (未対応クライアントを締め出さない)", async () => {
    const app = createApp(
      fakeDeps({ composeLetter: async () => fakeComposition() }),
    );
    const res = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer token-appcheck-user-1")
      .send({ text: "監視モードの相談" });
    expect(res.status).toBe(200);
    expect(res.body.type).toBe("letter");
  });

  it("enforce ではヘッダが無いと 401", async () => {
    const app = createApp(
      fakeDeps({
        composeLetter: async () => fakeComposition(),
        appCheckEnforcement: "enforce",
      }),
    );
    const res = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer token-appcheck-user-2")
      .send({ text: "ヘッダ無しの相談" });
    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe("app_check_failed");
  });

  it("enforce では検証に失敗するトークンは 401", async () => {
    const app = createApp(
      fakeDeps({
        composeLetter: async () => fakeComposition(),
        appCheckEnforcement: "enforce",
      }),
    );
    const res = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer token-appcheck-user-3")
      .set("X-Firebase-AppCheck", "appcheck-forged")
      .send({ text: "偽トークンの相談" });
    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe("app_check_failed");
  });

  it("enforce でも検証を通るトークンなら返書を返す", async () => {
    const app = createApp(
      fakeDeps({
        composeLetter: async () => fakeComposition(),
        appCheckEnforcement: "enforce",
      }),
    );
    const res = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer token-appcheck-user-4")
      .set("X-Firebase-AppCheck", validAppCheckToken)
      .send({ text: "正規クライアントからの相談" });
    expect(res.status).toBe(200);
    expect(res.body.type).toBe("letter");
  });

  it("enforce では GET /letters もヘッダが無いと 401", async () => {
    const app = createApp(fakeDeps({ appCheckEnforcement: "enforce" }));
    const res = await request(app)
      .get("/letters")
      .set("Authorization", "Bearer token-appcheck-user-5")
      .query({ requestId: "appcheck-req-1" });
    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe("app_check_failed");
  });
});

describe("IP 単位のレート制限", () => {
  it("uid を変えても同じ IP からの相談は上限を超えると 429", async () => {
    const app = createApp(
      fakeDeps({
        composeLetter: async () => fakeComposition(),
        letterRateLimit: { maxRequests: 2, windowSeconds: 3600 },
      }),
    );
    // リクエストごとに uid を変えるのは、再インストールによる匿名 UID の再発行を再現するため
    const first = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer token-ratelimit-user-1")
      .set("X-Forwarded-For", "203.0.113.10")
      .send({ text: "1 通目" });
    expect(first.status).toBe(200);

    const second = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer token-ratelimit-user-2")
      .set("X-Forwarded-For", "203.0.113.10")
      .send({ text: "2 通目" });
    expect(second.status).toBe(200);

    const third = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer token-ratelimit-user-3")
      .set("X-Forwarded-For", "203.0.113.10")
      .send({ text: "3 通目" });
    expect(third.status).toBe(429);
    expect(third.body.error.code).toBe("rate_limited");

    // 別の IP は同じ上限に巻き込まれない
    const otherIp = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer token-ratelimit-user-4")
      .set("X-Forwarded-For", "203.0.113.11")
      .send({ text: "別の IP からの 1 通目" });
    expect(otherIp.status).toBe(200);
  });

  it("X-Forwarded-For の先頭に偽の IP を足しても末尾の IP で数える", async () => {
    const app = createApp(
      fakeDeps({
        composeLetter: async () => fakeComposition(),
        letterRateLimit: { maxRequests: 1, windowSeconds: 3600 },
      }),
    );
    const first = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer token-ratelimit-user-5")
      .set("X-Forwarded-For", "203.0.113.12")
      .send({ text: "1 通目" });
    expect(first.status).toBe(200);

    // クライアントが自分で付けたヘッダは前段プロキシの追記より前 (先頭側) に来る
    const spoofed = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer token-ratelimit-user-6")
      .set("X-Forwarded-For", "1.2.3.4, 203.0.113.12")
      .send({ text: "偽装した 2 通目" });
    expect(spoofed.status).toBe(429);
    expect(spoofed.body.error.code).toBe("rate_limited");
  });

  it("レート制限に掛かったリクエストでは LLM の危機判定を呼ばない", async () => {
    let classifyCalled = false;
    const app = createApp(
      fakeDeps({
        composeLetter: async () => fakeComposition(),
        classifyCrisis: async () => {
          classifyCalled = true;
          return true;
        },
        letterRateLimit: { maxRequests: 1, windowSeconds: 3600 },
      }),
    );
    const first = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer token-ratelimit-user-7")
      .set("X-Forwarded-For", "203.0.113.13")
      .send({ text: "1 通目" });
    expect(first.status).toBe(200);

    const second = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer token-ratelimit-user-8")
      .set("X-Forwarded-For", "203.0.113.13")
      .send({ text: "2 通目" });
    expect(second.status).toBe(429);
    expect(classifyCalled).toBe(false);
  });

  it("危機ワードを含む相談はレート制限に達していても safety を返す", async () => {
    const app = createApp(
      fakeDeps({
        composeLetter: async () => fakeComposition(),
        letterRateLimit: { maxRequests: 1, windowSeconds: 3600 },
      }),
    );
    const first = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer token-ratelimit-user-9")
      .set("X-Forwarded-For", "203.0.113.14")
      .send({ text: "1 通目" });
    expect(first.status).toBe(200);

    // キーワードによる危機判定はレート制限より前に済んでいる
    const crisis = await request(app)
      .post("/letters")
      .set("Authorization", "Bearer token-ratelimit-user-10")
      .set("X-Forwarded-For", "203.0.113.14")
      .send({ text: "もう死にたいと思ってしまう" });
    expect(crisis.status).toBe(200);
    expect(crisis.body).toEqual({ type: "safety" });
  });
});
