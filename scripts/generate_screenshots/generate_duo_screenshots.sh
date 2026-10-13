#!/usr/bin/env bash
#
# generate_duo_screenshots.sh
#
# iPhone Duo (折りたたみ端末) 用の App Store スクリーンショットを、外側ディスプレイと内側ディスプレイの
# 両方で生成するスクリプト。撮る画面と言語は iPhone 6.9 インチ版 (generate_appstore_screenshots.sh) と同じ。
#
# 【出力先】
# fastlane deliver は Duo の寸法を受け付けず、fastlane/screenshots/{lang}/ に置くとアップロード全体が止まるため、
# deliver が読まない fastlane/screenshots_duo/ に置く (App Store Connect へは手で上げる。README 参照)。
#   fastlane/screenshots_duo/outer/{ja,en-US}/{番号}_APP_IPHONE_DUO_{番号}.png  (1398x2034 px、閉じた姿勢)
#   fastlane/screenshots_duo/inner/{ja,en-US}/{番号}_APP_IPHONE_DUO_{番号}.png  (2853x2007 px、開いた姿勢・横)
#
# 【処理の流れ】
# 1. 外側: 閉じた姿勢で generate_appstore_screenshots.sh を実行する (出力先・寸法を環境変数で Duo 用に変える。
#    XCTAttachment で撮れるため、ビルド・撮影・配置・検査は 6.9 インチ版と同じ経路)
# 2. 内側: 姿勢を開いた状態に切り替え、撮影テストごとに xcodebuild をバックグラウンドで実行する。
#    テスト (XCTestCase+AppStoreScreenshots.swift) がページを表示して同期ディレクトリに `{名前}.ready` を書くたびに、
#    ホスト側 (本スクリプト) が `xcrun simctl io --display=primary-1` で内側ディスプレイを撮り、
#    magick で alpha を落として配置し、`{名前}.done` を書いてテストを次へ進める。
#    XCTest の API では内側ディスプレイを仕様の寸法で撮れないため、この同期方式にしている
# 3. 姿勢を閉じた状態に戻し、生成した PNG の寸法・alpha・枚数を sips で検査する
#
# 姿勢の切り替えは ios-simulator skill の duo-pose.sh (Device Hub のウィンドウをアクセシビリティ API で操作する) に
# 任せるため、ローカルの Mac でしか実行できない。
#
# 【使い方】
#   $ ./scripts/generate_screenshots/generate_duo_screenshots.sh              # 全言語・全番号
#   $ ./scripts/generate_screenshots/generate_duo_screenshots.sh -n "1" -l "ja"   # 1 枚だけ (配管の確認用)
#   $ ./scripts/generate_screenshots/generate_duo_screenshots.sh --skip-build
#   オプションは generate_appstore_screenshots.sh と同じ (-l / -n / --skip-build / -h)
#
# 【環境変数】
#   DESTINATION_SIM_NAME  使用するシミュレータ名 (デフォルト: igen-appstore-screenshots-duo)
#   DUO_POSE_SCRIPT       姿勢を切り替えるスクリプト (デフォルト: ~/.claude/skills/ios-simulator/scripts/duo-pose.sh)
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
PROJECT_ROOT_DIR="$SCRIPT_DIR/../../"
cd "$PROJECT_ROOT_DIR"

# iPhone Duo は iOS 27.1 以降のシミュレータにしか無い。機種名は sim-boot が simctl の devicetype に解決する
export DESTINATION_SIM_NAME="${DESTINATION_SIM_NAME:-igen-appstore-screenshots-duo}"
export DESTINATION_SIM_DEVICE_TYPE="iPhone Duo"
# App Store Connect の表示タイプ (外側・内側は同じ 1 つの表示タイプ)
export SCREENSHOT_FILENAME_SUFFIX="APP_IPHONE_DUO"

DUO_SCREENSHOTS_DIR="fastlane/screenshots_duo"
OUTER_DIR="${DUO_SCREENSHOTS_DIR}/outer"
INNER_DIR="${DUO_SCREENSHOTS_DIR}/inner"
# Apple のスクリーンショット仕様 (https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications)
# の iPhone Duo の寸法。内側は横 (2853x2007) を選ぶ: 開いた姿勢のシミュレータは向きが横になり、simctl の
# スクリーンショットがそのまま横の寸法で撮れるため
OUTER_WIDTH=1398
OUTER_HEIGHT=2034
INNER_WIDTH=2853
INNER_HEIGHT=2007

DUO_POSE_SCRIPT="${DUO_POSE_SCRIPT:-$HOME/.claude/skills/ios-simulator/scripts/duo-pose.sh}"
INNER_SYNC_BASE_DIR="$(pwd)/tmp/appstore_screenshots/duo_inner_sync"

# 外側の生成に渡すオプション (本スクリプトと同じ)
GENERATE_ARGS=("$@")
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
      shift
      ;;
    -h|--help)
      sed -n '2,/^set -euo pipefail/p' "$0" | sed '$d' | sed -E 's/^# ?//'
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

if [ ! -f "$DUO_POSE_SCRIPT" ]; then
  echo "Error: duo-pose.sh が見つかりません: $DUO_POSE_SCRIPT (DUO_POSE_SCRIPT で指定できます)" >&2
  exit 1
fi
for tool in magick jq sips; do
  if ! command -v "$tool" &> /dev/null; then
    echo "Error: $tool が必要です (brew install imagemagick jq)" >&2
    exit 1
  fi
done

# 内側の撮影の詳細ログ (xcodebuild の出力) の置き場。進行はコンソールにも出す
LOG_DIR="$(pwd)/tmp"
mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_DIR}/generate_duo_screenshots.$(date +%Y%m%d_%H%M%S).logs.txt"
echo "Log file: $LOG_FILE"

sep() {
  printf '\n==== %s ====\n' "$*" | tee -a "$LOG_FILE"
}

source scripts/generate_screenshots/appstore_screenshot_env.sh

# 姿勢を切り替える。起動直後は有効なディスプレイを判定できず STATUS=ERROR になることがあるため数回やり直す。
# 切り替えの直後は画面が落ち着いていないため、撮る前に数秒おく (ios-simulator skill の実測)
set_duo_pose() {
  local pose=$1 attempt output
  for attempt in 1 2 3 4 5; do
    if output=$(bash "$DUO_POSE_SCRIPT" set --udid "$SIMULATOR_UDID" "$pose" 2>&1); then
      echo "$output" | tee -a "$LOG_FILE"
      sleep 5
      return 0
    fi
    echo "$output" | tee -a "$LOG_FILE"
    sleep 3
  done
  echo "Error: 姿勢を $pose に切り替えられませんでした" >&2
  return 1
}

# {クラス名}---{関数名}---{言語}---{index}.ready を受けて内側ディスプレイを 1 枚撮り、配置して .done を書く
capture_inner_display() {
  local ready_file=$1
  local name language test_class screenshot_number fastlane_lang output_dir dest_file raw_file
  name=$(basename "$ready_file" .ready)

  # organize_appstore_screenshots.sh と同じ分解 ('---' で後ろから index・言語・関数名・クラス名)
  local temp="${name%---*}"
  language="${temp##*---}"
  temp="${temp%---*}"
  test_class="${temp%---*}"
  screenshot_number=$(echo "$test_class" | sed -E 's/AppStoreScreenshot([0-9]+)PageSnapshotUITest/\1/')
  if [ -z "$language" ] || [ -z "$screenshot_number" ] || [ "$screenshot_number" = "$test_class" ]; then
    echo "Error: 同期ファイル名を解釈できません: $name" >&2
    return 1
  fi

  fastlane_lang=$(map_language_to_fastlane "$language")
  output_dir="${INNER_DIR}/${fastlane_lang}"
  mkdir -p "$output_dir"
  dest_file="${output_dir}/${screenshot_number}_${SCREENSHOT_FILENAME_SUFFIX}_${screenshot_number}.png"
  raw_file="${ready_file%.ready}.raw.png"

  # simctl のスクリーンショットは alpha 付きのため、落としてから配置する
  xcrun simctl io "$SIMULATOR_UDID" screenshot --display=primary-1 "$raw_file" >> "$LOG_FILE" 2>&1
  magick "$raw_file" -alpha remove -alpha off "$dest_file"
  echo "Captured inner: $test_class ($language) -> $dest_file" | tee -a "$LOG_FILE"

  rm -f "$ready_file"
  touch "${ready_file%.ready}.done"
}

# 内側ディスプレイ用に撮影テストを 1 本実行する。xcodebuild をバックグラウンドで動かし、
# テストが書く .ready を拾っては撮る。テストが終わる (xcodebuild が返る) まで繰り返す
run_inner_test() {
  local test_file=$1
  local test_path result_bundle_path sync_dir xcodebuild_pid ready_file
  read -r test_path result_bundle_path <<< "$(get_test_info "$test_file")"
  sep "Inner: running $test_path"

  sync_dir="${INNER_SYNC_BASE_DIR}/$(basename "$test_file" .swift)"
  rm -rf "$sync_dir"
  mkdir -p "$sync_dir"

  TEST_RUNNER_SNAPSHOT_INNER_SYNC_DIR="$sync_dir" \
    ./scripts/generate_screenshots/run_appstore_screenshot.sh "$test_path" "$result_bundle_path" "$LANGUAGES" \
    >> "$LOG_FILE" 2>&1 &
  xcodebuild_pid=$!

  while kill -0 "$xcodebuild_pid" 2> /dev/null; do
    for ready_file in "$sync_dir"/*.ready; do
      [ -f "$ready_file" ] || continue
      capture_inner_display "$ready_file" || {
        kill "$xcodebuild_pid" 2> /dev/null || true
        return 1
      }
    done
    sleep 1
  done

  if ! wait "$xcodebuild_pid"; then
    echo "Error: 内側の撮影テストが失敗しました: $test_path (ログ: $LOG_FILE)" >&2
    return 1
  fi
}

# ---- 1. シミュレータの用意と外側 (閉じた姿勢) ----
ensure_simulator_booted | tee -a "$LOG_FILE"
SIMULATOR_UDID="${DESTINATION#*id=}"

sep "Pose: closed (outer display)"
set_duo_pose closed

sep "Outer: generating via generate_appstore_screenshots.sh"
FASTLANE_SCREENSHOTS_DIR="$OUTER_DIR" \
  EXPECTED_PIXEL_WIDTH="$OUTER_WIDTH" \
  EXPECTED_PIXEL_HEIGHT="$OUTER_HEIGHT" \
  ./scripts/generate_screenshots/generate_appstore_screenshots.sh ${GENERATE_ARGS[@]+"${GENERATE_ARGS[@]}"}

# ---- 2. 内側 (開いた姿勢) ----
test_files=$(find "$UITEST_SOURCE_DIR" -type f -name "*SnapshotUITest.swift" | sort)
if [ -n "$SCREENSHOT_NUMBERS" ]; then
  filtered=""
  IFS=',' read -ra parts <<< "$SCREENSHOT_NUMBERS"
  for part in "${parts[@]}"; do
    if [[ "$part" == *-* ]]; then
      for ((i=${part%-*}; i<=${part#*-}; i++)); do
        filtered+=$(echo "$test_files" | grep "AppStoreScreenshot${i}PageSnapshotUITest.swift" || true)$'\n'
      done
    else
      filtered+=$(echo "$test_files" | grep "AppStoreScreenshot${part}PageSnapshotUITest.swift" || true)$'\n'
    fi
  done
  test_files=$(echo "$filtered" | sort -u | grep -v '^$')
fi

if [ -n "$LANGUAGES" ]; then
  IFS=',' read -ra TARGET_LANGUAGES <<< "$LANGUAGES"
else
  TARGET_LANGUAGES=(ja en)
fi

# 撮影に失敗した時に前回の PNG が残って検査を通過しないよう、対象の出力を先に消す
for test_file in $test_files; do
  number=$(basename "$test_file" .swift | sed -E 's/AppStoreScreenshot([0-9]+)PageSnapshotUITest/\1/')
  for lang in "${TARGET_LANGUAGES[@]}"; do
    rm -f "${INNER_DIR}/$(map_language_to_fastlane "$lang")/${number}_${SCREENSHOT_FILENAME_SUFFIX}_${number}.png"
  done
done

sep "Pose: open (inner display)"
set_duo_pose open

inner_failed=""
for test_file in $test_files; do
  if ! run_inner_test "$test_file"; then
    inner_failed+="  - $(basename "$test_file")"$'\n'
  fi
done

# ---- 3. 姿勢を戻して検査 ----
sep "Pose: closed (restore)"
set_duo_pose closed

if [ -n "$inner_failed" ]; then
  sep "ERROR: The following inner tests failed"
  echo "$inner_failed"
  exit 1
fi

sep "Verifying Duo screenshots (outer ${OUTER_WIDTH}x${OUTER_HEIGHT}, inner ${INNER_WIDTH}x${INNER_HEIGHT}, no alpha)"
verify_failed=""
verified_count=0
for test_file in $test_files; do
  number=$(basename "$test_file" .swift | sed -E 's/AppStoreScreenshot([0-9]+)PageSnapshotUITest/\1/')
  for lang in "${TARGET_LANGUAGES[@]}"; do
    fastlane_lang=$(map_language_to_fastlane "$(echo "$lang" | tr -d ' ')")
    for display in outer inner; do
      png="${DUO_SCREENSHOTS_DIR}/${display}/${fastlane_lang}/${number}_${SCREENSHOT_FILENAME_SUFFIX}_${number}.png"
      if [ "$display" = outer ]; then
        expected_width=$OUTER_WIDTH
        expected_height=$OUTER_HEIGHT
      else
        expected_width=$INNER_WIDTH
        expected_height=$INNER_HEIGHT
      fi

      if [ ! -f "$png" ]; then
        verify_failed+="  - $png (ファイルが存在しない)"$'\n'
        continue
      fi
      sips_output=$(sips -g pixelWidth -g pixelHeight -g hasAlpha "$png")
      echo "$sips_output" >> "$LOG_FILE"
      width=$(echo "$sips_output" | awk '/pixelWidth:/ {print $2}')
      height=$(echo "$sips_output" | awk '/pixelHeight:/ {print $2}')
      has_alpha=$(echo "$sips_output" | awk '/hasAlpha:/ {print $2}')
      if [ "$width" != "$expected_width" ] || [ "$height" != "$expected_height" ]; then
        verify_failed+="  - $png (寸法が ${width}x${height}。期待は ${expected_width}x${expected_height})"$'\n'
      fi
      if [ "$has_alpha" != "no" ]; then
        verify_failed+="  - $png (alpha あり)"$'\n'
      fi
      verified_count=$((verified_count + 1))
    done
  done
done

if [ -n "$verify_failed" ]; then
  sep "ERROR: Screenshot verification failed"
  echo "$verify_failed"
  exit 1
fi

sep "Verified $verified_count Duo screenshot(s)"
sep "All done. Duo screenshots saved to: ${DUO_SCREENSHOTS_DIR}/ (outer / inner)"
echo "ログファイル: $LOG_FILE"
