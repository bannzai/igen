import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    // テストファイルは対象と同じディレクトリに置く (.claude/rules/testing-guidelines.md)
    include: ["src/**/*.test.ts"],
    // Firestore エミュレータへの初回接続 (gRPC ハンドシェイク + エミュレータの JIT) が
    // ファイルごとに数秒かかり、複数ファイルの同時接続 + マシン高負荷時は 15 秒でも
    // タイムアウトすることがあるため余裕を持たせる
    testTimeout: 30000,
  },
});
