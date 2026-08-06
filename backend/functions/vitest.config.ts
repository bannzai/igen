import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    // テストファイルは対象と同じディレクトリに置く (.claude/rules/testing-guidelines.md)
    include: ["src/**/*.test.ts"],
    // Firestore エミュレータへの初回接続 (gRPC ハンドシェイク + エミュレータの JIT) が
    // ファイルごとに数秒かかり、デフォルト 5 秒では負荷時にタイムアウトするため
    testTimeout: 15000,
  },
});
