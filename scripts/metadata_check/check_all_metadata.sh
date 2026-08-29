#!/usr/bin/env bash
#
# check_all_metadata.sh
#
# fastlane/metadata/<locale>/ のストアメタデータを検査する。
#   1. 文字数制限 (name / subtitle 30、keywords 100、promotional_text 170、description 4000)。文字数は Unicode 文字単位
#   2. 医療を想起させる語 (documents/PROJECT.md リスク 2) が含まれていないこと
# 1 件でも違反があれば exit 1。ストアへの反映 (fastlane deliver) の前と、メタデータを編集した後に実行する。
#
# 使い方:
#   ./scripts/metadata_check/check_all_metadata.sh            # 全ロケール
#   ./scripts/metadata_check/check_all_metadata.sh ja         # ロケール指定
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
PROJECT_ROOT_DIR="$SCRIPT_DIR/../.."
cd "$PROJECT_ROOT_DIR"

METADATA_DIR="fastlane/metadata"
# 医療を想起させる語。UI 文言と同じ方針でストア文言にも使わない (design_handoff_igen/README.md「デザイン原則」)
FORBIDDEN_WORDS_REGEX='セラピー|カウンセリング|診断|処方|therap|counsel|diagnos|prescri'

if [ $# -ge 1 ]; then
  locales=("$@")
else
  locales=()
  for dir in "$METADATA_DIR"/*/; do
    locales+=("$(basename "$dir")")
  done
fi

failures=0

# 文字数を Unicode 文字単位で数える (wc -m はロケール依存のため python を使う)
count_chars() {
  python3 -c 'import sys; print(len(sys.stdin.read()))' < "$1"
}

check_limit() {
  local file=$1
  local limit=$2
  if [ ! -f "$file" ]; then
    echo "MISSING  $file"
    failures=$((failures + 1))
    return
  fi
  local count
  count=$(count_chars "$file")
  if [ "$count" -gt "$limit" ]; then
    echo "TOO LONG $file ($count > $limit)"
    failures=$((failures + 1))
  else
    echo "OK       $file ($count / $limit)"
  fi
}

for locale in "${locales[@]}"; do
  dir="$METADATA_DIR/$locale"
  echo "==== $locale ===="
  check_limit "$dir/name.txt" 30
  check_limit "$dir/subtitle.txt" 30
  check_limit "$dir/keywords.txt" 100
  check_limit "$dir/promotional_text.txt" 170
  check_limit "$dir/description.txt" 4000

  # grep -i は日本語には効かないが、対象の日本語は片仮名・漢字の固定表記のため問題ない
  if grep -n -i -E "$FORBIDDEN_WORDS_REGEX" "$dir"/*.txt; then
    echo "FORBIDDEN WORD FOUND in $dir"
    failures=$((failures + 1))
  else
    echo "OK       no forbidden words in $dir"
  fi
done

if [ "$failures" -gt 0 ]; then
  echo "==== FAILED: $failures issue(s) ===="
  exit 1
fi
echo "==== ALL OK ===="
