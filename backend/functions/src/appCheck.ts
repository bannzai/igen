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
 * 未設定・空・不正値の既定を monitor にするのは段階適用のため。App Check 未対応の
 * 既存クライアントを設定ミスで一斉に締め出さず、まず検証結果をログで観測して
 * 正当なリクエストがすべて検証を通ることを確認してから enforce へ切り替える
 */
export function resolveAppCheckEnforcement(
  raw: string | undefined,
): AppCheckEnforcement {
  return raw === "enforce" ? "enforce" : "monitor";
}
