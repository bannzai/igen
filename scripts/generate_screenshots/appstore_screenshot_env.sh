#!/usr/bin/env bash
#
# appstore_screenshot_env.sh
#
# App Store スクリーンショット生成用の環境変数と共通関数を定義するスクリプト。
# 単体では実行せず、同ディレクトリの他のスクリプトから source して使用する。
#
# 【定義するもの】
# - Xcode プロジェクト / スキーム / UITest ターゲットのパス
# - ビルド成果物・結果バンドル・fastlane 出力先のパス
# - 共通関数 get_test_info / map_language_to_fastlane / ensure_simulator_booted
#

# Xcode プロジェクトとスキーム。UITest は Igen スキームの Testables に含まれる
export XCODE_PROJECT="ios/Igen.xcodeproj"
export SCHEME="Igen"
export UITEST_TARGET="IgenUITests"

# 撮影テストのソース置き場。generate スクリプトがここから対象テストを列挙する
export UITEST_SOURCE_DIR="ios/IgenUITests/AppStoreScreenshots"

# ビルド成果物と結果バンドルの置き場 (tmp/ は .gitignore 済み)
export DERIVED_DATA_PATH="tmp/appstore_screenshots/derived_data"
export RESULT_BUNDLE_BASE_DIR="tmp/appstore_screenshots/results"

# fastlane のスクリーンショット出力先
export FASTLANE_SCREENSHOTS_DIR="fastlane/screenshots"

# App Store の 6.9 インチ (1320x2868 px) 用のファイル名接頭辞と期待寸法
export SCREENSHOT_FILENAME_SUFFIX="APP_IPHONE_69"
export EXPECTED_PIXEL_WIDTH=1320
export EXPECTED_PIXEL_HEIGHT=2868

# シミュレータ名・デバイスタイプ。環境変数で上書きできる。
# 複数の worktree / セッションが同時にスクショ生成すると同名シミュレータの奪い合いで
# UITest が互いのアプリを落とし合うため、worktree ごとに専用名を渡して分離する
export DESTINATION_SIM_NAME="${DESTINATION_SIM_NAME:-igen-appstore-screenshots}"
# 6.9 インチのスクリーンショット (1320x2868 px) を撮るためのデバイスタイプ
export DESTINATION_SIM_DEVICE_TYPE="${DESTINATION_SIM_DEVICE_TYPE:-iPhone 17 Pro Max}"

# LicenseList の build tool plugin があるため、xcodebuild は毎回この指定が必要
export XCODEBUILD_COMMON_FLAGS=(-skipPackagePluginValidation)

# テストファイルパスからテスト実行パスと結果バンドルパスを取得する共通関数
# Usage: get_test_info <test_file_path>
# Returns: TEST_PATH RESULT_BUNDLE_PATH (スペース区切り)
get_test_info() {
  local test_file=$1
  local filename
  filename=$(basename "$test_file" .swift)
  local test_path="${UITEST_TARGET}/${filename}/testSnapshot"
  local result_bundle_path="${RESULT_BUNDLE_BASE_DIR}/${filename}.xcresult"
  echo "$test_path $result_bundle_path"
}

# 言語コードを fastlane / App Store Connect のディレクトリ名にマッピングする関数。
# igen の撮影対象は ios/IgenUITests/AppStoreScreenshots/Languages.swift の
# languageCodeAndLanguageWithRegion (ja / en) と揃える
map_language_to_fastlane() {
  local lang=$1
  case "$lang" in
    "en") echo "en-US" ;;
    *) echo "$lang" ;;
  esac
}

# DESTINATION_SIM_NAME のシミュレータを起動し、その UDID から DESTINATION を組み立てる関数。
# 作成・起動は PATH にある sim-boot に任せる (同名があれば再利用する冪等な動作)。
# OS バージョンは固定せず UDID で指定するため、Xcode 更新でランタイムが変わっても壊れない
ensure_simulator_booted() {
  echo "シミュレータ確認: name=${DESTINATION_SIM_NAME}, deviceType=${DESTINATION_SIM_DEVICE_TYPE}"
  SCRIPT_QUIET=1 sim-boot "$DESTINATION_SIM_NAME" "$DESTINATION_SIM_DEVICE_TYPE"

  local udid
  udid=$(xcrun simctl list devices -j |
    jq -r --arg name "$DESTINATION_SIM_NAME" '.devices | to_entries[] | .value[] | select(.name == $name) | .udid' |
    head -1)

  if [ -z "$udid" ]; then
    echo "エラー: シミュレータ '${DESTINATION_SIM_NAME}' の UDID を取得できませんでした。" >&2
    return 1
  fi

  export DESTINATION="platform=iOS Simulator,id=${udid}"
  echo "シミュレータ UDID: ${udid}"
}
