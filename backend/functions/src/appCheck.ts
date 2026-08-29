import { getAppCheck } from "firebase-admin/app-check";

/** App Check の適用モード。 */
export type AppCheckEnforcement =
  /** 検証結果をログに残すだけで、未検証のリクエストも処理する */
  | "monitor"
  /** 未検証のリクエストを 401 で拒否する */
  | "enforce";

/** App Check トークンを検証し、発行元のアプリ ID を返す。検証に失敗したら例外を投げる。 */
export type VerifyAppCheckTokenFn = (
  token: string,
) => Promise<{ appId: string }>;

/** クライアントが App Check トークンを載せるヘッダ名 (Firebase SDK の既定)。 */
export const APP_CHECK_HEADER = "X-Firebase-AppCheck";

/** firebase-admin による App Check トークンの検証を組み立てる。 */
export function createFirebaseAppCheckVerifier(): VerifyAppCheckTokenFn {
  return async (token) => {
    const verified = await getAppCheck().verifyToken(token);
    return { appId: verified.appId };
  };
}

/**
 * 環境変数の値を適用モードへ変換する。
 * 未リリースで締め出す既存クライアントが存在しないため、デプロイ環境の既定は enforce にして
 * LLM 費用の濫用対策を初回から有効にする (オーナー決定 2026-08-29、issue #43)。
 * Emulator の既定を monitor にするのは、ローカル開発のクライアントが demo-igen 向けで
 * App Check トークンを持たない (FirebaseSetup が factory を設定しない) ため。
 * 不正値を enforce 側に倒すのはフェイルクローズの判断で、設定ミスで守りが外れるより、
 * monitor にしたい場合は明示の指定を要求する方が安全。
 * enforce を戻す時は IGEN_APP_CHECK_ENFORCEMENT=monitor をデプロイ環境の env に設定する
 */
export function resolveAppCheckEnforcement(
  raw: string | undefined,
): AppCheckEnforcement {
  if (raw === "enforce" || raw === "monitor") {
    return raw;
  }
  return process.env.FUNCTIONS_EMULATOR === "true" ? "monitor" : "enforce";
}
