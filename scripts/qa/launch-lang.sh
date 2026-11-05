#!/usr/bin/env bash
# アプリを指定言語で起動する（端末の優先言語を変えずに済ませる）。
#
# WDA の POST /session の capabilities に arguments を載せて新しいセッションを作る経路だけが有効で、
# 既存セッションへの POST /session/{sid}/wda/apps/launch に arguments を渡しても言語は変わらない。
#
# 作った session id は ios-wda.sh のキャッシュ (tmp/ios-wda/<cksum>.sid) へ書き戻す。
# 書き戻さないと ios-wda.sh が bundleId 無しで作った古いセッション (SpringBoard 相当) で操作し、
# tap/swipe のたびにアプリがバックグラウンドへ落ちる。
#
# 使い方: launch-lang.sh <session> <ja|en>
set -euo pipefail
session=$1
lang=$2
case "$lang" in
  ja) locale=ja_JP ;;
  en) locale=en_US ;;
  *) echo "ERROR: lang は ja か en" >&2; exit 1 ;;
esac
host="http://simtunnel-${session}:8100"
wda=~/.claude/skills/ios-simulator/scripts/ios-wda.sh

# 起動中のままだと launch が activate になり引数が反映されないため、必ず落としてから作り直す
bash "$wda" --session "$session" terminate com.bannzai.Igen >/dev/null 2>&1 || true
sleep 2

sid=$(curl -s -m 90 -X POST "$host/session" -H 'Content-Type: application/json' \
  -d "{\"capabilities\":{\"alwaysMatch\":{\"bundleId\":\"com.bannzai.Igen\",\"arguments\":[\"-AppleLanguages\",\"($lang)\",\"-AppleLocale\",\"$locale\"],\"shouldWaitForQuiescence\":false}}}" \
  | python3 -c 'import json,sys; print(json.load(sys.stdin).get("value",{}).get("sessionId",""))')
if [ -z "$sid" ]; then
  echo "ERROR: WDA セッションを作成できませんでした" >&2
  exit 1
fi

# ios-wda.sh と同じ規則 (SIMTUNNEL_STATE_DIR / WDA_URL の cksum) で保存先を決める
state_dir="${SIMTUNNEL_STATE_DIR:-${PWD}/tmp/ios-wda}"
state_key=$(printf '%s' "$host" | cksum | awk '{print $1}')
mkdir -p "$state_dir"
printf '%s\n' "$sid" > "${state_dir}/${state_key}.sid"

echo "sessionId= $sid"
echo "launched com.bannzai.Igen with lang=$lang (sid written to ${state_dir}/${state_key}.sid)"
