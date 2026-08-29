#!/usr/bin/env bash
#
# generate_appstore_screenshots.sh
#
# App Store スクリーンショットを生成するメインスクリプト。
# SwiftUI で組んだスクショ画面 (ios/Igen/AppStoreScreenshots/) を UITest で撮影し、
# fastlane/screenshots/{ja,en-US}/ に配置するまでを一括で行う。
#
# 【処理の流れ】
# 1. シミュレータを起動する (sim-boot 経由。既存があれば再利用)
# 2. build-for-testing で UITest をビルドする (--skip-build でスキップ)
# 3. 撮影テストを1つずつ test-without-building で実行する
# 4. xcresult から attachment を書き出し、fastlane 形式に配置する
# 5. 生成された PNG の寸法と alpha を sips で検査する
#
# 【使い方】
# 1. 全スクリーンショットを全言語で生成:
#    $ ./scripts/generate_screenshots/generate_appstore_screenshots.sh
#
# 2. 特定の言語のみで生成:
#    $ ./scripts/generate_screenshots/generate_appstore_screenshots.sh -l "ja"
#
# 3. 特定の番号のスクリーンショットのみ生成:
#    $ ./scripts/generate_screenshots/generate_appstore_screenshots.sh -n "1"
#    $ ./scripts/generate_screenshots/generate_appstore_screenshots.sh -n "1-3,5"
#
# 4. ビルドをスキップして実行:
#    $ ./scripts/generate_screenshots/generate_appstore_screenshots.sh --skip-build
#
# 5. ヘルプを表示:
#    $ ./scripts/generate_screenshots/generate_appstore_screenshots.sh -h
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
PROJECT_ROOT_DIR="$SCRIPT_DIR/../../"
cd "$PROJECT_ROOT_DIR"

source scripts/generate_screenshots/appstore_screenshot_env.sh

# 撮影対象の全言語 (Languages.swift の languageCodeAndLanguageWithRegion と揃える)
ALL_LANGUAGES=(ja en)

# 一時ディレクトリ (xcresult から書き出した attachment の置き場)
TEMP_SCREENSHOTS_DIR="tmp/appstore_screenshots/exported"

cleanup_temp_files() {
  rm -rf "$TEMP_SCREENSHOTS_DIR"
}

# Ctrl+C (SIGINT) / SIGTERM でのクリーンアップ。
# 子プロセス (xcodebuild) を残さないようプロセスグループごと止める
cleanup() {
  trap - SIGINT SIGTERM
  echo "==== Interrupted by user (Ctrl+C) ====" >&3
  echo "==== Interrupted by user (Ctrl+C) ===="
  cleanup_temp_files
  exit 130
}
trap cleanup SIGINT SIGTERM

# オプション解析
SKIP_BUILD=false
LANGUAGES=""
SCREENSHOT_NUMBERS=""
while [[ $# -gt 0 ]]; do
  case $1 in
    -l|--languages)
      LANGUAGES="$2"
      shift 2
      ;;
    -n|--numbers)
      SCREENSHOT_NUMBERS="$2"
      shift 2
      ;;
    --skip-build)
      SKIP_BUILD=true
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  -l LANGS           撮影する言語をカンマ区切りで指定 (例: \"ja,en\", デフォルト: ${ALL_LANGUAGES[*]})"
      echo "  -n NUMS            撮影するスクリーンショット番号を指定 (例: \"1,2\" or \"1-6\", デフォルト: 全番号)"
      echo "  --skip-build       build-for-testing をスキップ"
      echo "  -h, --help         このヘルプメッセージを表示"
      echo ""
      echo "Environment variables:"
      echo "  DESTINATION_SIM_NAME         使用するシミュレータ名 (デフォルト: igen-appstore-screenshots)"
      echo "  DESTINATION_SIM_DEVICE_TYPE  シミュレータのデバイスタイプ (デフォルト: iPhone 17 Pro Max)"
      echo ""
      echo "Examples:"
      echo "  # 全言語・全番号で生成"
      echo "  $0"
      echo ""
      echo "  # 1枚目だけ日本語で生成"
      echo "  $0 -n \"1\" -l \"ja\""
      echo ""
      echo "  # ビルドをスキップして全て再生成"
      echo "  $0 --skip-build"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# ログファイルの設定。
# fd 3 をコンソール出力として確保し、stdout/stderr はログファイルへリダイレクトする
exec 3>&1 4>&2
LOG_DIR="$(pwd)/tmp"
mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_DIR}/generate_appstore_screenshots.$(date +%Y%m%d_%H%M%S).logs.txt"
exec >"$LOG_FILE" 2>&1
echo "Log file: $LOG_FILE" >&3

# 進行ログをログファイルとコンソールの両方へ出す
sep() {
  printf '\n==== %s ====\n' "$*"
  printf '==== %s ====\n' "$*" >&3
}

# スクリーンショット番号でテストファイルを絞り込む関数。
# カンマ区切り ("1,2,3") と範囲指定 ("1-6") の混在に対応する
filter_test_files() {
  local numbers=$1
  local all_files=$2
  local filtered=""

  IFS=',' read -ra parts <<< "$numbers"
  for part in "${parts[@]}"; do
    if [[ "$part" == *-* ]]; then
      local start=${part%-*}
      local end=${part#*-}
      for ((i=start; i<=end; i++)); do
        local match
        match=$(echo "$all_files" | grep "AppStoreScreenshot${i}PageSnapshotUITest.swift" || true)
        [ -n "$match" ] && filtered+="$match"$'\n'
      done
    else
      local match
      match=$(echo "$all_files" | grep "AppStoreScreenshot${part}PageSnapshotUITest.swift" || true)
      [ -n "$match" ] && filtered+="$match"$'\n'
    fi
  done

  echo "$filtered" | sort -u | grep -v '^$'
}

# 1つのテストを実行し、xcresult から書き出して fastlane 形式に配置する
run_single_test() {
  local test_file=$1
  local test_count=$2
  local total_count=$3

  sep "Processing test $test_count/$total_count: $(basename "$test_file")"

  local test_path result_bundle_path
  read -r test_path result_bundle_path <<< "$(get_test_info "$test_file")"

  sep "Test path: $test_path"
  sep "Result bundle: $result_bundle_path"

  # 撮影に失敗した時に前回の PNG が残って検査を通過しないよう、対象言語の出力を先に消す
  local number lang
  number=$(basename "$test_file" .swift | sed -E 's/AppStoreScreenshot([0-9]+)PageSnapshotUITest/\1/')
  for lang in "${TARGET_LANGUAGES[@]}"; do
    rm -f "${FASTLANE_SCREENSHOTS_DIR}/$(map_language_to_fastlane "$lang")/${number}_${SCREENSHOT_FILENAME_SUFFIX}_${number}.png"
  done

  # 呼び出し元が if 条件で使うと関数内で set -e が効かなくなるため、各工程の失敗を明示的に返す
  ./scripts/generate_screenshots/run_appstore_screenshot.sh "$test_path" "$result_bundle_path" "$LANGUAGES" || return 1

  if [ ! -d "$result_bundle_path" ]; then
    echo "Error: Result bundle not found: $result_bundle_path" >&3
    return 1
  fi

  sep "Extracting screenshots: $result_bundle_path"
  local test_temp_dir="${TEMP_SCREENSHOTS_DIR}/$(basename "$test_file" .swift)"
  rm -rf "$test_temp_dir"
  mkdir -p "$test_temp_dir"

  xcrun xcresulttool export attachments \
    --path "$result_bundle_path" \
    --output-path "$test_temp_dir" || return 1

  sep "Organizing screenshots to fastlane format"
  ./scripts/generate_screenshots/organize_appstore_screenshots.sh "$test_temp_dir" || return 1

  rm -rf "$test_temp_dir"
}

mkdir -p "$TEMP_SCREENSHOTS_DIR"

# 対象言語を決める (-l 未指定なら全言語)
if [ -n "$LANGUAGES" ]; then
  IFS=',' read -ra TARGET_LANGUAGES <<< "$LANGUAGES"
  sep "Languages: $LANGUAGES"
else
  TARGET_LANGUAGES=("${ALL_LANGUAGES[@]}")
  sep "Languages: ${ALL_LANGUAGES[*]} (all)"
fi

# シミュレータの起動と DESTINATION の解決
ensure_simulator_booted

# ビルド
if [ "$SKIP_BUILD" = false ]; then
  sep "Building AppStore Screenshot Tests"
  ./scripts/generate_screenshots/build_appstore_screenshot.sh
else
  sep "Skipping build (--skip-build specified)"
fi

# 撮影テストファイルの列挙
sep "Collecting AppStore screenshot test files"
test_files=$(find "$UITEST_SOURCE_DIR" -type f -name "*SnapshotUITest.swift" 2>/dev/null | sort)

if [ -z "$test_files" ]; then
  echo "Error: No AppStoreScreenshot test files found in ${UITEST_SOURCE_DIR}/" >&3
  exit 1
fi

if [ -n "$SCREENSHOT_NUMBERS" ]; then
  sep "Filtering by screenshot numbers: $SCREENSHOT_NUMBERS"
  test_files=$(filter_test_files "$SCREENSHOT_NUMBERS" "$test_files")

  if [ -z "$test_files" ]; then
    echo "Error: No test files match the specified numbers: $SCREENSHOT_NUMBERS" >&3
    exit 1
  fi
fi

total_count=$(echo "$test_files" | wc -l | tr -d ' ')
sep "Found $total_count AppStore screenshot test(s), running sequentially"

# 撮影ループ (シミュレータ1台で逐次実行する)
failed_tests=""
test_count=0
for test_file in $test_files; do
  test_count=$((test_count + 1))
  if ! run_single_test "$test_file" "$test_count" "$total_count"; then
    failed_tests+="  - $(basename "$test_file")"$'\n'
  fi
done

cleanup_temp_files

if [ -n "$failed_tests" ]; then
  sep "ERROR: The following tests failed"
  echo "$failed_tests" >&3
  echo "$failed_tests"
  echo "ログファイル: $LOG_FILE" >&3
  exit 1
fi

# 生成された PNG の機械検査 (寸法と alpha)。
# App Store Connect は 6.9 インチ枠に 1320x2868 の alpha なし PNG を要求する
sep "Verifying generated screenshots (${EXPECTED_PIXEL_WIDTH}x${EXPECTED_PIXEL_HEIGHT}, no alpha)"
verify_failed=""
verified_count=0
for test_file in $test_files; do
  filename=$(basename "$test_file" .swift)
  number=$(echo "$filename" | sed -E 's/AppStoreScreenshot([0-9]+)PageSnapshotUITest/\1/')
  for lang in "${TARGET_LANGUAGES[@]}"; do
    lang=$(echo "$lang" | tr -d ' ')
    fastlane_lang=$(map_language_to_fastlane "$lang")
    png="${FASTLANE_SCREENSHOTS_DIR}/${fastlane_lang}/${number}_${SCREENSHOT_FILENAME_SUFFIX}_${number}.png"

    if [ ! -f "$png" ]; then
      verify_failed+="  - $png (ファイルが存在しない)"$'\n'
      continue
    fi

    sips_output=$(sips -g pixelWidth -g pixelHeight -g hasAlpha "$png")
    echo "$sips_output"
    width=$(echo "$sips_output" | awk '/pixelWidth:/ {print $2}')
    height=$(echo "$sips_output" | awk '/pixelHeight:/ {print $2}')
    has_alpha=$(echo "$sips_output" | awk '/hasAlpha:/ {print $2}')

    if [ "$width" != "$EXPECTED_PIXEL_WIDTH" ] || [ "$height" != "$EXPECTED_PIXEL_HEIGHT" ]; then
      verify_failed+="  - $png (寸法が ${width}x${height}。期待は ${EXPECTED_PIXEL_WIDTH}x${EXPECTED_PIXEL_HEIGHT})"$'\n'
    fi
    if [ "$has_alpha" != "no" ]; then
      verify_failed+="  - $png (alpha あり)"$'\n'
    fi
    verified_count=$((verified_count + 1))
  done
done

if [ -n "$verify_failed" ]; then
  sep "ERROR: Screenshot verification failed"
  echo "$verify_failed" >&3
  echo "$verify_failed"
  echo "ログファイル: $LOG_FILE" >&3
  exit 1
fi

sep "Verified $verified_count screenshot(s)"
sep "All done."
sep "App Store screenshots saved to: ${FASTLANE_SCREENSHOTS_DIR}/"
echo "ログファイル: $LOG_FILE" >&3
