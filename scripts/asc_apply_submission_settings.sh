#!/usr/bin/env bash
# =============================================================================
# スクリプト名: asc_apply_submission_settings.sh
# 用途:
#   App Store Connect の公開に必要な基本設定 (カテゴリ・ロケール別のアプリ名とプライバシーポリシー URL・
#   利用規約 (EULA)・年齢制限指定・App Review メモ) を fastlane/asc_submission_settings.json の定義どおりに
#   API で適用する (issue #47)。各項目は「現状 GET → 差分があれば PATCH/POST → 再 GET で検証」の順で処理し、
#   すでに定義どおりなら書き込まない (冪等)。アプリ自体の作成は scripts/asc_register_app.sh が行う。
# 使い方:
#   bash scripts/asc_apply_submission_settings.sh            # 差分を適用して検証
#   bash scripts/asc_apply_submission_settings.sh --dry-run  # 現状と差分の表示のみ (書き込みなし)
# 環境変数 (必須):
#   ASC_API_KEY_ID / ASC_API_KEY_ISSUER_ID / ASC_API_KEY_P8_BASE64
# 環境変数 (任意):
#   ASC_REVIEW_CONTACT_FIRST_NAME / ASC_REVIEW_CONTACT_LAST_NAME / ASC_REVIEW_CONTACT_EMAIL / ASC_REVIEW_CONTACT_PHONE :
#     App Review の連絡先。個人情報をリポジトリに含めないため設定 JSON ではなく環境変数で渡す。
#     未設定の項目は書き込まず、既存値があればそのまま残す (審査提出前に人間が設定する)
#   ASC_API_SH : JWT 付き API ラッパのパス (既定: appstore-in-app-purchase skill の iap_api.sh)
# 終了コード:
#   0 すべて定義どおり (適用済み・検証済み) / 1 検証不一致または API 失敗 / 2 前提条件不足
# 依存コマンド: bash 4+, jq, awk, curl, openssl (ラッパ経由)
# 設計 WHY:
#   - JWT 生成と HTTP ハンドリングは既存 skill のラッパに委ね、本スクリプトは ASC リソースの差分適用だけを持つ
#   - App Review メモの本文は documents/app-review-notes.md の最初のコードブロックを正とし、JSON に転記しない
#   - EULA は App Store Connect では「カスタムライセンス契約」の本文欄しか無いため、規約の公開 URL を含む本文を
#     全テリトリー向けに設定する (サブスクリプションの審査で求められる利用規約リンクの提示先)
# =============================================================================
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="$REPO_ROOT/fastlane/asc_submission_settings.json"
API="${ASC_API_SH:-$HOME/.claude/skills/appstore-in-app-purchase/scripts/iap_api.sh}"
DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

for cmd in jq awk; do
    command -v "$cmd" >/dev/null || { echo "[NG] $cmd が必要" >&2; exit 2; }
done
[ -r "$API" ] || { echo "[NG] API ラッパが見つからない: $API" >&2; exit 2; }
[ -r "$CONFIG" ] || { echo "[NG] 設定ファイルが見つからない: $CONFIG" >&2; exit 2; }
for v in ASC_API_KEY_ID ASC_API_KEY_ISSUER_ID ASC_API_KEY_P8_BASE64; do
    [ -n "${!v:-}" ] || { echo "[NG] 環境変数 $v が未設定" >&2; exit 2; }
done

BUNDLE_ID=$(jq -r '.bundleId' "$CONFIG")
NOTES_SOURCE="$REPO_ROOT/$(jq -r '.reviewDetail.notesSource' "$CONFIG")"
[ -r "$NOTES_SOURCE" ] || { echo "[NG] App Review メモの元ファイルが無い: $NOTES_SOURCE" >&2; exit 2; }
FAILED=0

api() { bash "$API" "$@"; }
api_allow_404() { IAP_API_ALLOW_404=1 bash "$API" "$@" 2>/dev/null || { [ $? -eq 4 ] && echo '{"data":null}'; }; }
log() { printf '%s\n' "$*"; }
mark_failed() { FAILED=1; if [ $DRY_RUN -eq 1 ]; then log "[DIFF] $*"; else log "[NG] $*"; fi; }

APP_ID=$(api GET "/v1/apps?filter[bundleId]=$BUNDLE_ID&fields[apps]=bundleId" \
    | jq -r --arg b "$BUNDLE_ID" '.data[] | select(.attributes.bundleId == $b) | .id' | head -1)
[ -n "$APP_ID" ] || { echo "[NG] $BUNDLE_ID のアプリが App Store Connect に無い (先に scripts/asc_register_app.sh を実行する)" >&2; exit 2; }
log "App: $BUNDLE_ID (APP_ID=$APP_ID)"

# 公開済みと編集中の appInfo が併存する場合があるため、編集対象の state を明示して選ぶ
APP_INFO=$(api GET "/v1/apps/$APP_ID/appInfos?fields[appInfos]=state")
APP_INFO_ID=$(jq -r '[.data[] | select(.attributes.state == "PREPARE_FOR_SUBMISSION" or .attributes.state == "DEVELOPER_REJECTED" or .attributes.state == "REJECTED" or .attributes.state == "METADATA_REJECTED" or .attributes.state == "WAITING_FOR_REVIEW")] | first | .id // empty' <<<"$APP_INFO")
if [ -z "$APP_INFO_ID" ]; then
    APP_INFO_ID=$(jq -r '[.data[] | select(.attributes.state == "READY_FOR_DISTRIBUTION")] | first | .id // empty' <<<"$APP_INFO")
    [ -n "$APP_INFO_ID" ] && log "[WARN] 編集中の appInfo が無いため公開済みの appInfo を対象にする"
fi
[ -n "$APP_INFO_ID" ] || { echo "[NG] 対象の appInfo が見つからない (state 一覧: $(jq -r '[.data[].attributes.state] | join(",")' <<<"$APP_INFO"))" >&2; exit 1; }

# ---- 1. カテゴリ ----
log "== カテゴリ"
WANT_PRIMARY=$(jq -r '.categories.primary' "$CONFIG")
WANT_SECONDARY=$(jq -r '.categories.secondary' "$CONFIG")
get_categories() {
    api GET "/v1/appInfos/$APP_INFO_ID?include=primaryCategory,secondaryCategory" \
        | jq -r '[.data.relationships.primaryCategory.data.id // "null", .data.relationships.secondaryCategory.data.id // "null"] | join(" ")'
}
CUR=$(get_categories)
log "現状: primary/secondary = $CUR / 定義: $WANT_PRIMARY $WANT_SECONDARY"
if [ "$CUR" != "$WANT_PRIMARY $WANT_SECONDARY" ] && [ $DRY_RUN -eq 0 ]; then
    api PATCH "/v1/appInfos/$APP_INFO_ID" "$(jq -n --arg id "$APP_INFO_ID" --arg p "$WANT_PRIMARY" --arg s "$WANT_SECONDARY" \
        '{data:{type:"appInfos",id:$id,relationships:{primaryCategory:{data:{type:"appCategories",id:$p}},secondaryCategory:{data:{type:"appCategories",id:$s}}}}}')" >/dev/null
    CUR=$(get_categories)
    log "適用後: $CUR"
fi
[ "$CUR" = "$WANT_PRIMARY $WANT_SECONDARY" ] && log "[OK] カテゴリ" || mark_failed "カテゴリが定義と不一致"

# ---- 2. ロケール別のアプリ名・プライバシーポリシー URL ----
log "== アプリ名・プライバシーポリシー URL"
LOCALIZATIONS=$(api GET "/v1/appInfos/$APP_INFO_ID/appInfoLocalizations?fields[appInfoLocalizations]=locale,name,privacyPolicyUrl&limit=50")
get_localization() {
    local loc_id="$1"
    api GET "/v1/appInfoLocalizations/$loc_id?fields[appInfoLocalizations]=locale,name,privacyPolicyUrl" \
        | jq -S '.data.attributes | {name, privacyPolicyUrl}'
}
while read -r locale; do
    WANT=$(jq -S --arg l "$locale" '.localizations[] | select(.locale == $l) | {name, privacyPolicyUrl}' "$CONFIG")
    LOC_ID=$(jq -r --arg l "$locale" '.data[] | select(.attributes.locale == $l) | .id' <<<"$LOCALIZATIONS" | head -1)
    log "- $locale"
    if [ -z "$LOC_ID" ]; then
        log "  現状: 未作成"
        if [ $DRY_RUN -eq 0 ]; then
            LOC_ID=$(api POST "/v1/appInfoLocalizations" "$(jq -n --arg info "$APP_INFO_ID" --arg l "$locale" --argjson a "$WANT" \
                '{data:{type:"appInfoLocalizations",attributes:($a + {locale:$l}),relationships:{appInfo:{data:{type:"appInfos",id:$info}}}}}')" | jq -r '.data.id')
        fi
    else
        CUR=$(get_localization "$LOC_ID")
        if [ "$CUR" != "$WANT" ]; then
            log "  現状: $(jq -c . <<<"$CUR")"
            if [ $DRY_RUN -eq 0 ]; then
                api PATCH "/v1/appInfoLocalizations/$LOC_ID" "$(jq -n --arg id "$LOC_ID" --argjson a "$WANT" \
                    '{data:{type:"appInfoLocalizations",id:$id,attributes:$a}}')" >/dev/null
            fi
        else
            log "  現状: 定義どおり"
        fi
    fi
    if [ -z "$LOC_ID" ] || [ "$LOC_ID" = "null" ]; then
        mark_failed "$locale のローカライズが未作成"
        continue
    fi
    CUR=$(get_localization "$LOC_ID")
    [ "$CUR" = "$WANT" ] && log "  [OK] $locale" || mark_failed "$locale のローカライズが定義と不一致: $(jq -c . <<<"$CUR")"
done < <(jq -r '.localizations[].locale' "$CONFIG")
# 定義に無いロケール (Web UI で追加された・定義から外した) は公開対象に残さない。
# 定義ファイルを正とする方針のため削除して収束させる (primaryLocale は定義に含める前提)
while read -r extra_id extra_locale; do
    if [ $DRY_RUN -eq 1 ]; then
        mark_failed "定義に無いロケール $extra_locale が ASC に残っている (--dry-run なしで実行すると削除する)"
        continue
    fi
    api DELETE "/v1/appInfoLocalizations/$extra_id" >/dev/null
    log "- $extra_locale: 定義に無いため削除した"
done < <(jq -r --argjson want "$(jq -c '[.localizations[].locale]' "$CONFIG")" \
    '.data[] | select(.attributes.locale as $l | $want | index($l) | not) | "\(.id) \(.attributes.locale)"' <<<"$LOCALIZATIONS")

# ---- 3. 利用規約 (EULA) ----
log "== 利用規約 (EULA)"
WANT_EULA=$(jq -r '.eula.agreementText' "$CONFIG")
ALL_TERRITORIES=$(api GET "/v1/territories?limit=200" | jq -c '[.data[].id] | sort')
get_eula() {
    # EULA 未設定の間は GET が 404 になる。このエンドポイントは include / limit パラメータを受け付けないため、
    # テリトリーは endUserLicenseAgreements/{id}/territories で別に取得する
    local eula eula_id
    eula=$(api_allow_404 GET "/v1/apps/$APP_ID/endUserLicenseAgreement")
    if [ "$(jq -r '.data' <<<"$eula")" = "null" ]; then
        echo "none"
        return
    fi
    eula_id=$(jq -r '.data.id' <<<"$eula")
    echo "$eula_id"
    jq -r '.data.attributes.agreementText' <<<"$eula"
    api GET "/v1/endUserLicenseAgreements/$eula_id/territories?limit=200" | jq -c '[.data[].id] | sort'
}
CUR_EULA=$(get_eula)
if [ "$CUR_EULA" = "none" ]; then
    log "現状: 未設定"
    if [ $DRY_RUN -eq 0 ]; then
        api POST "/v1/endUserLicenseAgreements" "$(jq -n --arg app "$APP_ID" --arg t "$WANT_EULA" --argjson ts "$ALL_TERRITORIES" \
            '{data:{type:"endUserLicenseAgreements",attributes:{agreementText:$t},relationships:{app:{data:{type:"apps",id:$app}},territories:{data:[$ts[] | {type:"territories",id:.}]}}}}')" >/dev/null
        CUR_EULA=$(get_eula)
    fi
fi
if [ "$CUR_EULA" != "none" ]; then
    EULA_ID=$(sed -n 1p <<<"$CUR_EULA")
    CUR_TEXT=$(sed '1d;$d' <<<"$CUR_EULA")
    CUR_TERRITORIES=$(tail -n 1 <<<"$CUR_EULA")
    if [ "$CUR_TEXT" != "$WANT_EULA" ] || [ "$CUR_TERRITORIES" != "$ALL_TERRITORIES" ]; then
        log "現状: 本文またはテリトリーが定義と異なる (テリトリー数 $(jq 'length' <<<"$CUR_TERRITORIES") / 定義 $(jq 'length' <<<"$ALL_TERRITORIES"))"
        if [ $DRY_RUN -eq 0 ]; then
            api PATCH "/v1/endUserLicenseAgreements/$EULA_ID" "$(jq -n --arg id "$EULA_ID" --arg t "$WANT_EULA" --argjson ts "$ALL_TERRITORIES" \
                '{data:{type:"endUserLicenseAgreements",id:$id,attributes:{agreementText:$t},relationships:{territories:{data:[$ts[] | {type:"territories",id:.}]}}}}')" >/dev/null
            CUR_EULA=$(get_eula)
            CUR_TEXT=$(sed '1d;$d' <<<"$CUR_EULA")
            CUR_TERRITORIES=$(tail -n 1 <<<"$CUR_EULA")
        fi
    else
        log "現状: 定義どおり"
    fi
    [ "$CUR_TEXT" = "$WANT_EULA" ] && [ "$CUR_TERRITORIES" = "$ALL_TERRITORIES" ] && log "[OK] 利用規約 (EULA)" || mark_failed "利用規約 (EULA) が定義と不一致"
else
    mark_failed "利用規約 (EULA) が未設定"
fi

# ---- 4. 年齢制限指定 ----
log "== 年齢制限指定"
WANT_AGE=$(jq -S '.ageRatingDeclaration' "$CONFIG")
# 宣言レコードは appInfo と同じ id とは限らないため、GET で得た自身の id を PATCH に使う
AGE_ID=$(api GET "/v1/appInfos/$APP_INFO_ID/ageRatingDeclaration?fields[ageRatingDeclarations]=kidsAgeBand" | jq -r '.data.id')
get_age() {
    # 定義に含まれるキーだけを比較対象にする (kidsAgeBand / deprecated な ageRatingOverride 等は比較しない)
    api GET "/v1/appInfos/$APP_INFO_ID/ageRatingDeclaration" \
        | jq -S --argjson want "$WANT_AGE" '.data.attributes | with_entries(select(.key as $k | $want | has($k)))'
}
CUR=$(get_age)
if [ "$CUR" != "$WANT_AGE" ]; then
    log "差分 (現状 → 定義):"
    jq -n --argjson cur "$CUR" --argjson want "$WANT_AGE" '$want | to_entries[] | select($cur[.key] != .value) | "  \(.key): \($cur[.key]) → \(.value)"' -r
    if [ $DRY_RUN -eq 0 ]; then
        api PATCH "/v1/ageRatingDeclarations/$AGE_ID" "$(jq -n --arg id "$AGE_ID" --argjson a "$WANT_AGE" \
            '{data:{type:"ageRatingDeclarations",id:$id,attributes:$a}}')" >/dev/null
        CUR=$(get_age)
    fi
else
    log "現状: 定義どおり"
fi
[ "$CUR" = "$WANT_AGE" ] && log "[OK] 年齢制限指定" || mark_failed "年齢制限指定が定義と不一致"

# ---- 5. App Review メモ・連絡先 (PREPARE_FOR_SUBMISSION の各バージョン) ----
log "== App Review メモ"
# documents/app-review-notes.md の最初のコードブロック (英語文面) をメモ本文にする
WANT_NOTES=$(awk '/^```/{ if (inblock) exit; inblock=1; next } inblock' "$NOTES_SOURCE")
[ -n "$WANT_NOTES" ] || { echo "[NG] $NOTES_SOURCE にコードブロックが無い" >&2; exit 2; }
WANT_REVIEW=$(jq -n --arg notes "$WANT_NOTES" \
    --arg fn "${ASC_REVIEW_CONTACT_FIRST_NAME:-}" --arg ln "${ASC_REVIEW_CONTACT_LAST_NAME:-}" \
    --arg em "${ASC_REVIEW_CONTACT_EMAIL:-}" --arg ph "${ASC_REVIEW_CONTACT_PHONE:-}" \
    --argjson demo "$(jq '.reviewDetail.demoAccountRequired' "$CONFIG")" \
    '{notes:$notes, demoAccountRequired:$demo}
     + (if $fn != "" then {contactFirstName:$fn} else {} end)
     + (if $ln != "" then {contactLastName:$ln} else {} end)
     + (if $em != "" then {contactEmail:$em} else {} end)
     + (if $ph != "" then {contactPhone:$ph} else {} end)' | jq -S .)
WANT_KEYS=$(jq -c 'keys' <<<"$WANT_REVIEW")
# ログに連絡先を出さない
mask_contact() { jq -c 'with_entries(if (.key | startswith("contact")) and .value != null then .value = "***" else . end) | .notes |= (if . == null then null else "(\(length) chars)" end)'; }
# 審査で差し戻された (DEVELOPER_REJECTED / REJECTED / METADATA_REJECTED) バージョンもメモを直して再提出するため対象にする
VERSIONS=$(api GET "/v1/apps/$APP_ID/appStoreVersions?filter[appVersionState]=PREPARE_FOR_SUBMISSION,DEVELOPER_REJECTED,REJECTED,METADATA_REJECTED&filter[platform]=IOS&fields[appStoreVersions]=platform,versionString,appStoreReviewDetail&include=appStoreReviewDetail&fields[appStoreReviewDetails]=demoAccountRequired")
get_review() {
    local rd_id="$1"
    api GET "/v1/appStoreReviewDetails/$rd_id?fields[appStoreReviewDetails]=contactFirstName,contactLastName,contactPhone,contactEmail,demoAccountRequired,notes" \
        | jq -S --argjson keys "$WANT_KEYS" '.data.attributes | with_entries(select(.key as $k | $keys | index($k)))'
}
if [ "$(jq '.data | length' <<<"$VERSIONS")" -eq 0 ]; then
    mark_failed "編集可能な (提出準備中または差し戻し) iOS バージョンが無い (App Review メモを設定する対象が無い)"
fi
while read -r ver_id ver rd_id; do
    log "- iOS $ver (version $ver_id)"
    if [ "$rd_id" = "null" ]; then
        log "  現状: 未作成"
        if [ $DRY_RUN -eq 0 ]; then
            rd_id=$(api POST "/v1/appStoreReviewDetails" "$(jq -n --arg v "$ver_id" --argjson a "$WANT_REVIEW" \
                '{data:{type:"appStoreReviewDetails",attributes:$a,relationships:{appStoreVersion:{data:{type:"appStoreVersions",id:$v}}}}}')" | jq -r '.data.id')
        fi
    else
        CUR=$(get_review "$rd_id")
        if [ "$CUR" != "$WANT_REVIEW" ]; then
            log "  現状: $(mask_contact <<<"$CUR")"
            if [ $DRY_RUN -eq 0 ]; then
                api PATCH "/v1/appStoreReviewDetails/$rd_id" "$(jq -n --arg id "$rd_id" --argjson a "$WANT_REVIEW" \
                    '{data:{type:"appStoreReviewDetails",id:$id,attributes:$a}}')" >/dev/null
            fi
        else
            log "  現状: 定義どおり"
        fi
    fi
    if [ -z "$rd_id" ] || [ "$rd_id" = "null" ]; then
        mark_failed "iOS $ver の App Review 情報が未作成"
        continue
    fi
    CUR=$(get_review "$rd_id")
    [ "$CUR" = "$WANT_REVIEW" ] && log "  [OK] iOS $ver App Review メモ" || mark_failed "iOS $ver の App Review メモが定義と不一致: $(mask_contact <<<"$CUR")"
done < <(jq -r '.data[] | "\(.id) \(.attributes.versionString) \(.relationships.appStoreReviewDetail.data.id // "null")"' <<<"$VERSIONS")

log "== 結果"
if [ $FAILED -eq 0 ]; then
    [ $DRY_RUN -eq 1 ] && log "[OK] dry-run: すべて定義どおり (差分なし)" || log "[OK] 5 項目すべて定義どおり (適用・検証済み)"
    exit 0
fi
[ $DRY_RUN -eq 1 ] && log "[WARN] dry-run: 差分あり (--dry-run なしで実行すると適用する)" || log "[NG] 不一致あり"
exit 1
