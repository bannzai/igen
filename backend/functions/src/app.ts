import express, { type Express, type Request, type Response } from "express";

/** API の Express アプリを組み立てる。エンドポイントは返書生成 API の実装 issue で拡張する。 */
export function createApp(): Express {
  const app = express();
  app.use(express.json({ limit: "1mb" }));

  app.get("/health", (_req: Request, res: Response) => {
    res.json({ status: "ok" });
  });

  return app;
}
