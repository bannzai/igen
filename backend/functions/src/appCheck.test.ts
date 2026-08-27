import { describe, expect, it } from "vitest";
import { resolveAppCheckEnforcement } from "./appCheck";

describe("resolveAppCheckEnforcement", () => {
  it("enforce を指定したときだけ enforce になる", () => {
    expect(resolveAppCheckEnforcement("enforce")).toBe("enforce");
  });

  it("未設定・空・不正値は monitor にフォールバックする", () => {
    expect(resolveAppCheckEnforcement(undefined)).toBe("monitor");
    expect(resolveAppCheckEnforcement("")).toBe("monitor");
    expect(resolveAppCheckEnforcement("monitor")).toBe("monitor");
    // 大文字・真偽値らしき指定を enforce と解釈すると、設定ミスで正規クライアントを締め出す
    expect(resolveAppCheckEnforcement("ENFORCE")).toBe("monitor");
    expect(resolveAppCheckEnforcement("true")).toBe("monitor");
  });
});
