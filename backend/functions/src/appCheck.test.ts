import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { resolveAppCheckEnforcement } from "./appCheck";

describe("resolveAppCheckEnforcement", () => {
  // テスト実行環境の ambient な FUNCTIONS_EMULATOR に結果が左右されないよう、各テストで固定する。
  // 退避・復元に delete を使うと biome の lint/performance/noDelete に触れるため、
  // 環境変数の差し替えを目的に用意された vitest の stubEnv を使う
  beforeEach(() => {
    vi.stubEnv("FUNCTIONS_EMULATOR", undefined);
  });

  afterEach(() => {
    vi.unstubAllEnvs();
  });

  it("明示指定はそのまま採用する", () => {
    expect(resolveAppCheckEnforcement("enforce")).toBe("enforce");
    expect(resolveAppCheckEnforcement("monitor")).toBe("monitor");
    // Emulator でも明示指定が優先される
    vi.stubEnv("FUNCTIONS_EMULATOR", "true");
    expect(resolveAppCheckEnforcement("enforce")).toBe("enforce");
    expect(resolveAppCheckEnforcement("monitor")).toBe("monitor");
  });

  it("未設定・空・不正値はデプロイ環境では enforce (フェイルクローズ)", () => {
    expect(process.env.FUNCTIONS_EMULATOR).toBeUndefined();
    expect(resolveAppCheckEnforcement(undefined)).toBe("enforce");
    expect(resolveAppCheckEnforcement("")).toBe("enforce");
    expect(resolveAppCheckEnforcement("ENFORCE")).toBe("enforce");
    expect(resolveAppCheckEnforcement("true")).toBe("enforce");
  });

  it("未設定・空・不正値は Emulator では monitor (ローカルのクライアントはトークンを持たない)", () => {
    vi.stubEnv("FUNCTIONS_EMULATOR", "true");
    expect(resolveAppCheckEnforcement(undefined)).toBe("monitor");
    expect(resolveAppCheckEnforcement("")).toBe("monitor");
    expect(resolveAppCheckEnforcement("ENFORCE")).toBe("monitor");
    expect(resolveAppCheckEnforcement("true")).toBe("monitor");
  });
});
