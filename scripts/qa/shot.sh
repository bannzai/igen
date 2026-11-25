#!/usr/bin/env bash
# simtunnel のリモート Simulator のスクリーンショットを保存する。
#
# simtunnel screenshot / ios-wda.sh shot は MJPEG (serve_sim) 経由のため、
# serve_sim が未起動・停止していると「フレームを取得できなかった (受信 0 bytes)」で失敗する。
# こちらは WDA の GET /screenshot (base64 PNG) を使うので serve_sim に依存しない (その分やや遅い)。
#
# 使い方: shot.sh <session> <出力パス.png>
set -euo pipefail
session=$1
out=$2
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
curl -s -m 120 "http://simtunnel-${session}:8100/screenshot" -o "$tmp"
python3 - "$tmp" "$out" <<'PY'
import base64, json, pathlib, sys
data = json.load(open(sys.argv[1]))
value = data.get("value")
if not isinstance(value, str) or not value:
    raise SystemExit(f"ERROR: スクリーンショットを取得できませんでした: {str(data)[:200]}")
path = pathlib.Path(sys.argv[2])
path.parent.mkdir(parents=True, exist_ok=True)
path.write_bytes(base64.b64decode(value))
print(f"saved: {path} ({path.stat().st_size} bytes)")
PY
