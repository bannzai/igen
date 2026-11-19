#!/usr/bin/env bash
# App Check のデバッグトークンを環境変数に載せてアプリを起動する（simtunnel の runner 用）。
#
# runner のシミュレータは AppCheckDebugProviderFactory になるため、Firebase Console に登録済みの
# デバッグトークンを FIRAAppCheckDebugToken として渡さないと、enforce の本番 API が 401 を返す。
# 手順の SSOT は CLAUDE.md「実装したUIの検証」の 4。
#
# トークンは ~/.config/igen/appcheck-debug-token-simtunnel.secret から読み、argv・標準出力へ出さない。
#
# 作った session id は ios-wda.sh のキャッシュ (tmp/ios-wda/<cksum>.sid) へ書き戻す
# （書き戻さないと ios-wda.sh が別セッションで操作しアプリがバックグラウンドへ落ちる）。
#
# 使い方: launch-appcheck.sh <session>
set -euo pipefail
session=$1
secret_file="${HOME}/.config/igen/appcheck-debug-token-simtunnel.secret"
host="http://simtunnel-${session}:8100"
wda=~/.claude/skills/ios-simulator/scripts/ios-wda.sh

if [ ! -s "$secret_file" ]; then
  echo "ERROR: $secret_file が無い、または空です" >&2
  exit 1
fi

# 起動中のままだと launch が activate になり environment が反映されないため、必ず落としてから作り直す
bash "$wda" --session "$session" terminate com.bannzai.Igen >/dev/null 2>&1 || true
sleep 2

body=$(python3 - "$secret_file" <<'PY'
import json, sys
env = {}
for line in open(sys.argv[1], encoding="utf-8"):
    line = line.strip()
    if not line or line.startswith("#") or "=" not in line:
        continue
    key, value = line.split("=", 1)
    env[key.strip()] = value.strip()
if not env:
    raise SystemExit("ERROR: secret ファイルに KEY=VALUE 行がありません")
print(json.dumps({"capabilities": {"alwaysMatch": {
    "bundleId": "com.bannzai.Igen",
    "environment": env,
    "shouldWaitForQuiescence": False,
}}}, separators=(",", ":")))
PY
)

sid=$(printf '%s' "$body" | curl -s -m 90 -X POST "$host/session" -H 'Content-Type: application/json' --data-binary @- \
  | python3 -c 'import json,sys; print(json.load(sys.stdin).get("value",{}).get("sessionId",""))')
if [ -z "$sid" ]; then
  echo "ERROR: WDA セッションを作成できませんでした" >&2
  exit 1
fi

state_dir="${SIMTUNNEL_STATE_DIR:-${PWD}/tmp/ios-wda}"
state_key=$(printf '%s' "$host" | cksum | awk '{print $1}')
mkdir -p "$state_dir"
printf '%s\n' "$sid" > "${state_dir}/${state_key}.sid"

echo "sessionId= $sid"
echo "launched com.bannzai.Igen with App Check debug token (sid written to ${state_dir}/${state_key}.sid)"
