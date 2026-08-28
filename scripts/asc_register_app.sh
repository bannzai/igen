#!/usr/bin/env bash
# =============================================================================
# スクリプト名: asc_register_app.sh
# 用途:
#   fastlane/asc_submission_settings.json の bundleId / sku / primaryLocale / initialVersion に従って、
#   Apple Developer Portal に App ID (Bundle ID) を登録し、App Store Connect にアプリを作成する (issue #47)。
#   どちらも既に存在すれば作成せず、既存の ID を表示して終了する (冪等)。
# 使い方:
#   bash scripts/asc_register_app.sh            # 未登録なら登録し、App Store Connect の App ID を表示する
#   bash scripts/asc_register_app.sh --dry-run  # 存在確認のみ (書き込みなし)
# 環境変数 (必須):
#   ASC_API_KEY_ID / ASC_API_KEY_ISSUER_ID / ASC_API_KEY_P8_BASE64 : App Store Connect API キー (Bundle ID の登録と存在確認)
#   FASTLANE_USER : アプリ作成に使う Apple ID。App Store Connect のアプリ作成は公開 API に無く、
#                   fastlane produce (Apple ID の Web セッション) でしか行えない。セッションは
#                   ユーザーが事前に `fastlane spaceauth -u <Apple ID>` で生成しておく (agent は代行できない。TTY 必須)
#   FASTLANE_TEAM_ID / FASTLANE_ITC_TEAM_ID : 複数チーム所属時のチーム選択
# 環境変数 (任意):
#   ASC_API_SH : JWT 付き API ラッパのパス (既定: appstore-in-app-purchase skill の iap_api.sh)
# 終了コード:
#   0 登録済み (作成した・既に存在した) / 1 作成失敗、または --dry-run で未登録の差分あり / 2 前提条件不足
# 設計 WHY:
#   - Bundle ID は公開 API (POST /v1/bundleIds) で登録できるため JWT 認証で行い、
#     produce には --skip_devcenter を渡して Web セッションでの Developer Portal 操作を避ける
#   - アプリ名は primaryLocale の名前を produce に渡す。他ロケールの名前・URL 等は
#     scripts/asc_apply_submission_settings.sh が API で設定する
# =============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="$REPO_ROOT/fastlane/asc_submission_settings.json"
API="${ASC_API_SH:-$HOME/.claude/skills/appstore-in-app-purchase/scripts/iap_api.sh}"
DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

for cmd in jq fastlane; do
    command -v "$cmd" >/dev/null || { echo "[NG] $cmd が必要" >&2; exit 2; }
done
[ -r "$API" ] || { echo "[NG] API ラッパが見つからない: $API" >&2; exit 2; }
[ -r "$CONFIG" ] || { echo "[NG] 設定ファイルが見つからない: $CONFIG" >&2; exit 2; }
for v in ASC_API_KEY_ID ASC_API_KEY_ISSUER_ID ASC_API_KEY_P8_BASE64; do
    [ -n "${!v:-}" ] || { echo "[NG] 環境変数 $v が未設定" >&2; exit 2; }
done

BUNDLE_ID=$(jq -r '.bundleId' "$CONFIG")
# Developer Portal の App ID 名は ASCII しか受け付けない (日本語名は 409 ENTITY_ERROR.ATTRIBUTE.INVALID) ため、アプリ名とは別に持つ
PORTAL_NAME=$(jq -r '.developerPortalName' "$CONFIG")
SKU=$(jq -r '.sku' "$CONFIG")
PRIMARY_LOCALE=$(jq -r '.primaryLocale' "$CONFIG")
INITIAL_VERSION=$(jq -r '.initialVersion' "$CONFIG")
APP_NAME=$(jq -r --arg l "$PRIMARY_LOCALE" '.localizations[] | select(.locale == $l) | .name' "$CONFIG")
[ -n "$APP_NAME" ] || { echo "[NG] primaryLocale ($PRIMARY_LOCALE) の name が localizations に無い" >&2; exit 2; }

api() { bash "$API" "$@"; }
log() { printf '%s\n' "$*"; }
# --dry-run で検出した未登録の差分。asc_apply_submission_settings.sh と同様に非ゼロ終了で自動確認に伝える
DIFF_FOUND=0

# ---- 1. Bundle ID (Developer Portal) ----
log "== Bundle ID: $BUNDLE_ID"
BUNDLE_RECORD_ID=$(api GET "/v1/bundleIds?filter[identifier]=$BUNDLE_ID&fields[bundleIds]=identifier,platform" \
    | jq -r --arg b "$BUNDLE_ID" '.data[] | select(.attributes.identifier == $b) | .id' | head -1)
if [ -n "$BUNDLE_RECORD_ID" ]; then
    log "[OK] 登録済み (id=$BUNDLE_RECORD_ID)"
elif [ $DRY_RUN -eq 1 ]; then
    log "[DIFF] 未登録 (--dry-run なしで実行すると登録する)"
    DIFF_FOUND=1
else
    BUNDLE_RECORD_ID=$(api POST "/v1/bundleIds" "$(jq -n --arg b "$BUNDLE_ID" --arg n "$PORTAL_NAME" \
        '{data:{type:"bundleIds",attributes:{identifier:$b,name:$n,platform:"IOS"}}}')" | jq -r '.data.id')
    [ -n "$BUNDLE_RECORD_ID" ] && [ "$BUNDLE_RECORD_ID" != "null" ] || { echo "[NG] Bundle ID の登録に失敗" >&2; exit 1; }
    log "[OK] 登録した (id=$BUNDLE_RECORD_ID)"
fi

# ---- 2. App (App Store Connect) ----
log "== App: $APP_NAME ($BUNDLE_ID)"
find_app_id() {
    api GET "/v1/apps?filter[bundleId]=$BUNDLE_ID&fields[apps]=bundleId" \
        | jq -r --arg b "$BUNDLE_ID" '.data[] | select(.attributes.bundleId == $b) | .id' | head -1
}
APP_ID=$(find_app_id)
if [ -n "$APP_ID" ]; then
    log "[OK] 作成済み (APP_ID=$APP_ID)"
elif [ $DRY_RUN -eq 1 ]; then
    log "[DIFF] 未作成 (--dry-run なしで実行すると fastlane produce で作成する)"
    DIFF_FOUND=1
else
    for v in FASTLANE_USER FASTLANE_TEAM_ID FASTLANE_ITC_TEAM_ID; do
        [ -n "${!v:-}" ] || { echo "[NG] 環境変数 $v が未設定 (アプリ作成に必要)" >&2; exit 2; }
    done
    # Web セッションの失効時に対話 (パスワード / 2FA) へ落ちて TTY エラーになるのを避け、非対話で失敗させる
    FASTLANE_DISABLE_COLORS=1 FASTLANE_SKIP_UPDATE_CHECK=1 FASTLANE_OPT_OUT_USAGE=1 \
        fastlane produce \
        --username "$FASTLANE_USER" \
        --team_id "$FASTLANE_TEAM_ID" \
        --itc_team_id "$FASTLANE_ITC_TEAM_ID" \
        --app_identifier "$BUNDLE_ID" \
        --app_name "$APP_NAME" \
        --sku "$SKU" \
        --language "$PRIMARY_LOCALE" \
        --app_version "$INITIAL_VERSION" \
        --platform ios \
        --skip_devcenter </dev/null
    APP_ID=$(find_app_id)
    [ -n "$APP_ID" ] || { echo "[NG] produce 後もアプリが見つからない" >&2; exit 1; }
    log "[OK] 作成した (APP_ID=$APP_ID)"
fi
[ -n "$APP_ID" ] && log "APP_ID=$APP_ID"
if [ $DIFF_FOUND -eq 1 ]; then
    log "[WARN] dry-run: 未登録の差分あり (--dry-run なしで実行すると登録する)"
    exit 1
fi
exit 0
