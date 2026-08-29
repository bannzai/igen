#!/usr/bin/env bash
#
# build_appstore_screenshot.sh
#
# App Store スクリーンショット用の UITest をビルドするスクリプト。
# xcodebuild build-for-testing で事前ビルドし、以降の撮影を
# test-without-building で回せるようにする。
#
# 【使い方】
# $ ./scripts/generate_screenshots/build_appstore_screenshot.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
PROJECT_ROOT_DIR="$SCRIPT_DIR/../../"
cd "$PROJECT_ROOT_DIR"

source scripts/generate_screenshots/appstore_screenshot_env.sh

# DESTINATION を UDID 付きで組み立てる (シミュレータが無ければ作成・起動する)
ensure_simulator_booted

echo "==== Building AppStore Screenshot Tests ===="
xcodebuild build-for-testing \
  -project "$XCODE_PROJECT" \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  "${XCODEBUILD_COMMON_FLAGS[@]}"

echo "==== Build completed ===="
