#!/usr/bin/env bash
#
# organize_appstore_screenshots.sh
#
# xcrun xcresulttool export attachments で書き出したスクリーンショットを、
# fastlane が読む形式に配置し直すスクリプト。
# manifest.json の suggestedHumanReadableName を解析して
# fastlane/screenshots/{fastlane 言語ディレクトリ}/{番号}_APP_IPHONE_69_{番号}.png
# へリネーム・移動する。
#
# 【使い方】
# $ ./scripts/generate_screenshots/organize_appstore_screenshots.sh <SCREENSHOTS_DIR>
#
# 引数:
#   $1: SCREENSHOTS_DIR - xcresulttool で書き出した attachment のディレクトリ
#
# 【manifest.json の形式】
# テスト単位の配列で、各要素が attachments 配列を持つ。
#   [ { "testIdentifier": ..., "attachments": [
#       { "exportedFileName": "...png",
#         "suggestedHumanReadableName": "AppStoreScreenshot1PageSnapshotUITest---testSnapshot---ja---0_....png" } ] } ]
# 形式の揺れに強くするため、jq では階層を決め打ちせず
# exportedFileName と suggestedHumanReadableName を持つオブジェクトを再帰的に拾う。
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
PROJECT_ROOT_DIR="$SCRIPT_DIR/../../"
cd "$PROJECT_ROOT_DIR"

source scripts/generate_screenshots/appstore_screenshot_env.sh

SCREENSHOTS_DIR="$1"

if [ ! -d "$SCREENSHOTS_DIR" ]; then
  echo "Error: Directory not found: $SCREENSHOTS_DIR" >&2
  exit 1
fi

MANIFEST_FILE="$SCREENSHOTS_DIR/manifest.json"

if [ ! -f "$MANIFEST_FILE" ]; then
  echo "Error: manifest.json not found in $SCREENSHOTS_DIR" >&2
  exit 1
fi

if ! command -v jq &> /dev/null; then
  echo "Error: jq is required but not installed (brew install jq)" >&2
  exit 1
fi

echo "==== Organizing App Store screenshots to fastlane format ===="

organized_count=0

# attachment を1件ずつ処理する。while のボディをサブシェルにしないため process substitution を使う
while read -r attachment; do
  exported_file=$(echo "$attachment" | jq -r '.exportedFileName')
  suggested_name=$(echo "$attachment" | jq -r '.suggestedHumanReadableName')

  source_file="$SCREENSHOTS_DIR/$exported_file"
  if [ ! -f "$source_file" ]; then
    echo "Warning: File not found: $source_file"
    continue
  fi

  # suggestedHumanReadableName は
  # "{テストクラス}---{関数名}---{言語}---{index}_....png" の形式なので '---' で後ろから分解する
  name_without_ext="${suggested_name%.png}"

  index_and_suffix="${name_without_ext##*---}"
  temp="${name_without_ext%---*}"

  language="${temp##*---}"
  temp="${temp%---*}"

  function_name="${temp##*---}"
  test_class="${temp%---*}"

  if [ -z "$test_class" ] || [ -z "$function_name" ] || [ -z "$language" ] || [ -z "$index_and_suffix" ]; then
    echo "Warning: Unexpected format: $suggested_name"
    continue
  fi

  # テストクラス名 AppStoreScreenshot{N}PageSnapshotUITest から N を取り出す
  screenshot_number=$(echo "$test_class" | sed -E 's/AppStoreScreenshot([0-9]+)PageSnapshotUITest/\1/')

  if [ -z "$screenshot_number" ] || [ "$screenshot_number" = "$test_class" ]; then
    echo "Warning: Could not extract screenshot number from: $test_class"
    continue
  fi

  fastlane_lang=$(map_language_to_fastlane "$language")

  output_dir="${FASTLANE_SCREENSHOTS_DIR}/${fastlane_lang}"
  mkdir -p "$output_dir"

  new_filename="${screenshot_number}_${SCREENSHOT_FILENAME_SUFFIX}_${screenshot_number}.png"
  dest_file="$output_dir/$new_filename"

  mv "$source_file" "$dest_file"
  echo "Organized: $test_class ($language) -> ${fastlane_lang}/${new_filename}"
  organized_count=$((organized_count + 1))
done < <(jq -c '[.. | objects | select(has("exportedFileName") and has("suggestedHumanReadableName"))] | .[]' "$MANIFEST_FILE")

if [ "$organized_count" -eq 0 ]; then
  echo "Error: No screenshots were organized from $MANIFEST_FILE" >&2
  exit 1
fi

echo "==== Organization complete ($organized_count file(s)) ===="
echo "==== Screenshots organized in: ${FASTLANE_SCREENSHOTS_DIR}/ ===="
