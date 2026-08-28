#!/usr/bin/env bash
# =============================================================================
# スクリプト名: asc_upload_subscription_review_screenshot.sh
# 用途:
#   自動更新サブスクリプションの App Review 用スクリーンショットを App Store Connect に登録する (issue #48)。
#   appstore-in-app-purchase skill の iap_upload_review_screenshot.sh は consumable 等の inAppPurchases 専用で、
#   サブスクリプションは別リソース (subscriptionAppStoreReviewScreenshots) のため本スクリプトで扱う。
#   登録済みなら何もしない (サブスクリプション 1 件につき 1 枚。冪等)。
# 使い方:
#   bash scripts/asc_upload_subscription_review_screenshot.sh <SUBSCRIPTION_ID> <IMAGE_PATH>
# 環境変数 (必須):
#   ASC_API_KEY_ID / ASC_API_KEY_ISSUER_ID / ASC_API_KEY_P8_BASE64
# 環境変数 (任意):
#   ASC_API_SH : JWT 付き API ラッパのパス (既定: appstore-in-app-purchase skill の iap_api.sh)
# 出力:
#   SCREENSHOT_ID=<id> / STATE=<assetDeliveryState> / ACTION=<created|noop>
# 終了コード:
#   0 登録済み (作成した・既にあった) / 2 引数不足・ファイル不在・前提条件不足 / 4 API 失敗・処理失敗
# 設計 WHY:
#   reservation → CDN への PUT → checksum 付き commit → assetDeliveryState の polling という 3 段階は
#   iap_upload_review_screenshot.sh と同じで、リソース名と relationship 名だけが異なる
# =============================================================================
set -euo pipefail

API="${ASC_API_SH:-$HOME/.claude/skills/appstore-in-app-purchase/scripts/iap_api.sh}"
SUBSCRIPTION_ID="${1:?SUBSCRIPTION_ID が必要}"
IMAGE="${2:?IMAGE_PATH が必要}"
POLL_INTERVAL="${POLL_INTERVAL:-4}"
POLL_MAX_TRIES="${POLL_MAX_TRIES:-8}"

for cmd in jq curl md5; do
    command -v "$cmd" >/dev/null || { echo "[NG] $cmd が必要" >&2; exit 2; }
done
[ -r "$API" ] || { echo "[NG] API ラッパが見つからない: $API" >&2; exit 2; }
[ -f "$IMAGE" ] || { echo "[NG] ファイルが見つからない: $IMAGE" >&2; exit 2; }
for v in ASC_API_KEY_ID ASC_API_KEY_ISSUER_ID ASC_API_KEY_P8_BASE64; do
    [ -n "${!v:-}" ] || { echo "[NG] 環境変数 $v が未設定" >&2; exit 2; }
done

api() { bash "$API" "$@"; }
api_allow_404() { IAP_API_ALLOW_404=1 bash "$API" "$@" 2>/dev/null || { [ $? -eq 4 ] && echo '{"data":null}'; }; }
log() { printf '%s\n' "$*" >&2; }

EXISTING=$(api_allow_404 GET "/v1/subscriptions/$SUBSCRIPTION_ID/appStoreReviewScreenshot")
EXISTING_ID=$(jq -r '.data.id // empty' <<<"$EXISTING")
if [ -n "$EXISTING_ID" ]; then
    EXISTING_STATE=$(jq -r '.data.attributes.assetDeliveryState.state // "?"' <<<"$EXISTING")
    if [ "$EXISTING_STATE" = "COMPLETE" ]; then
        log "[OK] 登録済み (id=$EXISTING_ID, state=COMPLETE) → skip。差し替える場合は DELETE /v1/subscriptionAppStoreReviewScreenshots/$EXISTING_ID を先に実行する"
        printf 'SCREENSHOT_ID=%s\nSTATE=%s\nACTION=noop\n' "$EXISTING_ID" "$EXISTING_STATE"
        exit 0
    fi
    # COMPLETE 以外 (FAILED や、アップロード中断で残った AWAITING_UPLOAD 等) は提出に使えない。
    # Apple の仕様では FAILED 後は新しい reservation が必要なため、削除して作り直すことで再実行を収束させる
    log "[WARN] 既存スクリーンショットが未完了 (id=$EXISTING_ID, state=$EXISTING_STATE) → 削除して作り直す"
    api DELETE "/v1/subscriptionAppStoreReviewScreenshots/$EXISTING_ID" >/dev/null
fi

FILE_SIZE=$(stat -f %z "$IMAGE")
log "[reservation] $(basename "$IMAGE") (${FILE_SIZE} bytes) → subscription $SUBSCRIPTION_ID"
RESERVATION_RESP=$(api POST "/v1/subscriptionAppStoreReviewScreenshots" "$(jq -nc \
    --argjson size "$FILE_SIZE" --arg name "$(basename "$IMAGE")" --arg sub "$SUBSCRIPTION_ID" \
    '{data:{type:"subscriptionAppStoreReviewScreenshots",attributes:{fileSize:$size,fileName:$name},relationships:{subscription:{data:{type:"subscriptions",id:$sub}}}}}')")
SCREENSHOT_ID=$(jq -r '.data.id // empty' <<<"$RESERVATION_RESP")
[ -n "$SCREENSHOT_ID" ] || { echo "[NG] reservation に失敗" >&2; exit 4; }

while IFS= read -r OP; do
    HEADERS=()
    while IFS= read -r HEAD_KV; do
        HEADERS+=("-H" "$HEAD_KV")
    done < <(jq -r '.requestHeaders[]? | "\(.name): \(.value)"' <<<"$OP")
    TMP_PART=$(mktemp -t sub_part.XXXXXX)
    tail -c "+$(( $(jq -r '.offset // 0' <<<"$OP") + 1 ))" "$IMAGE" | head -c "$(jq -r '.length' <<<"$OP")" > "$TMP_PART"
    HTTP_CODE=$(curl -sS -X "$(jq -r '.method // "PUT"' <<<"$OP")" "${HEADERS[@]}" --data-binary "@$TMP_PART" -o /dev/null --write-out '%{http_code}' "$(jq -r '.url' <<<"$OP")")
    rm -f "$TMP_PART"
    case "$HTTP_CODE" in
        2*) log "[upload] PUT $HTTP_CODE OK" ;;
        *) echo "[NG] upload に失敗: HTTP $HTTP_CODE" >&2; exit 4 ;;
    esac
done < <(jq -c '.data.attributes.uploadOperations[]?' <<<"$RESERVATION_RESP")

# sourceFileChecksum は Apple のドキュメントどおり MD5 を渡す (SHA-256 でも COMPLETE になった実績はあるが仕様に合わせる)
api PATCH "/v1/subscriptionAppStoreReviewScreenshots/$SCREENSHOT_ID" "$(jq -nc --arg id "$SCREENSHOT_ID" --arg sum "$(md5 -q "$IMAGE")" \
    '{data:{type:"subscriptionAppStoreReviewScreenshots",id:$id,attributes:{uploaded:true,sourceFileChecksum:$sum}}}')" >/dev/null

FINAL_STATE="?"
for _ in $(seq 1 "$POLL_MAX_TRIES"); do
    sleep "$POLL_INTERVAL"
    FINAL_STATE=$(api GET "/v1/subscriptionAppStoreReviewScreenshots/$SCREENSHOT_ID?fields[subscriptionAppStoreReviewScreenshots]=assetDeliveryState" \
        | jq -r '.data.attributes.assetDeliveryState.state // "?"')
    log "[poll] state=$FINAL_STATE"
    case "$FINAL_STATE" in
        COMPLETE) break ;;
        FAILED) echo "[NG] assetDeliveryState=FAILED" >&2; exit 4 ;;
    esac
done
printf 'SCREENSHOT_ID=%s\nSTATE=%s\nACTION=created\n' "$SCREENSHOT_ID" "$FINAL_STATE"
[ "$FINAL_STATE" = "COMPLETE" ] || exit 4
