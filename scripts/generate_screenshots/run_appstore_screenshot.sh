#!/usr/bin/env bash
#
# run_appstore_screenshot.sh
#
# 個別の App Store スクリーンショット撮影テストを実行するスクリプト。
# build_appstore_screenshot.sh で事前ビルド済みのテストを
# xcodebuild test-without-building で実行する。
#
# 【使い方】
# $ ./scripts/generate_screenshots/run_appstore_screenshot.sh <TEST_PATH> <RESULT_BUNDLE_PATH> [LANGUAGES]
#
# 引数:
#   $1: TEST_PATH - テスト実行パス (例: IgenUITests/AppStoreScreenshot1PageSnapshotUITest/testSnapshot)
#   $2: RESULT_BUNDLE_PATH - 結果バンドルの保存先 (例: tmp/appstore_screenshots/results/AppStoreScreenshot1PageSnapshotUITest.xcresult)
#   $3: LANGUAGES - 撮影する言語 (省略可、カンマ区切り例: "ja,en")
#
# 注意:
#   言語の絞り込みは TEST_RUNNER_SNAPSHOT_LANGUAGES 環境変数で行う。
#   xcodebuild の TEST_RUNNER_ プレフィックス機構により、テストランナープロセスへ
#   SNAPSHOT_LANGUAGES として引き渡され、
#   ios/IgenUITests/AppStoreScreenshots/Languages.swift の filteredLanguages() が読む。
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
PROJECT_ROOT_DIR="$SCRIPT_DIR/../../"
cd "$PROJECT_ROOT_DIR"

source scripts/generate_screenshots/appstore_screenshot_env.sh

TEST=$1
RESULT_BUNDLE_PATH=$2
LANGUAGES=${3:-""}

# DESTINATION を UDID 付きで組み立てる (シミュレータが無ければ作成・起動する)
ensure_simulator_booted

echo "==== Running test: $TEST ===="
echo "==== Result bundle: $RESULT_BUNDLE_PATH ===="
if [ -n "$LANGUAGES" ]; then
  echo "==== Languages: $LANGUAGES ===="
  export TEST_RUNNER_SNAPSHOT_LANGUAGES="$LANGUAGES"
fi

# 既存の結果バンドルが残っていると xcodebuild が失敗するため、実行前に消す
rm -rf "$RESULT_BUNDLE_PATH"
mkdir -p "$(dirname "$RESULT_BUNDLE_PATH")"

xcodebuild test-without-building \
  -project "$XCODE_PROJECT" \
  -scheme "$SCHEME" \
  -sdk iphonesimulator \
  -destination "$DESTINATION" \
  -only-testing:"$TEST" \
  -resultBundlePath "$RESULT_BUNDLE_PATH" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  "${XCODEBUILD_COMMON_FLAGS[@]}"

echo "==== Test completed: $TEST ===="
