# TestFlight 配布

GitHub Actions の `ios-deploy` workflowで、`main`のReleaseビルドをTestFlightへ配布する。
署名情報はGitHubの`ios-deploy` environment secretsに置き、同environmentからデプロイできるブランチは`main`だけに制限する。
RevenueCatの公開SDKキーは既存のrepository secret `REVENUECAT_PUBLIC_API_KEY_IOS`からビルド時に`ios/Config.local.xcconfig`へ書き出す。値が未登録または空の場合は、課金機能を無効にした配布物を作らずworkflowを失敗させる。

## 配布を起動する

`main`へのマージまたはpushで自動起動する。再配布が必要な場合だけ、次のコマンドで手動起動する。

```sh
gh workflow run ios-deploy.yml --ref main
```

配布は同時に1本だけ実行できる。先行runが未完了の場合、後続runは`Reject concurrent dispatch`で失敗する。先行runの完了後に新しく手動起動する。

最新runは次のコマンドで確認する。

```sh
gh run list --workflow ios-deploy.yml --limit 3
RUN_ID="$(gh run list --workflow ios-deploy.yml --limit 1 --json databaseId --jq '.[0].databaseId')"
gh run watch "$RUN_ID"
```

## ビルド番号

ビルド番号は`github.run_number + BUILD_NUMBER_OFFSET`で決まる。現在のoffsetは`0`。GitHub Actionsからの初回配布前にApp Store Connect上の既存ビルドがなかったため、加算は不要だった。

`Upload to TestFlight`まで進んだ後に失敗したrunはRe-runしない。アップロード済みと同じビルド番号の再送を避けるため、新しく手動起動する。アップロードより前のstepで失敗したrunはRe-runしてよい。

## 署名情報を更新する

Apple Distribution証明書はチーム共通の証明書を再利用する。証明書を更新した場合は、配布対象のapp本体と全extensionのprovisioning profileをセットで再発行し、対応するenvironment secretsをすべて更新する。現在の配布対象はapp本体`com.bannzai.Igen`だけで、profile名は`Igen.AppStore`、secret名は`IOS_PROVISIONING_PROFILE_BASE64`である。

profile名は次の2箇所で一致させる。

- `ios/Igen.xcodeproj/project.pbxproj`のRelease・実機SDK向け`PROVISIONING_PROFILE_SPECIFIER`
- `.github/workflows/ios-deploy.yml`の`ExportOptions.plist`にある`provisioningProfiles`

profileを再発行する場合は、リポジトリルートで次を実行する。証明書IDは、使用するP12と一致する有効な証明書のIDに置き換える。

```sh
mkdir -p ./tmp/signing
signing-assets.sh create-profile \
  --name Igen.AppStore \
  --bundle-id com.bannzai.Igen \
  --certificate-id CERTIFICATE_ID \
  --out ./tmp/signing
```

値を環境変数に読み込んだうえで、全項目が揃っていることをdry-runで確認してから`ios-deploy` environmentへ登録する。コマンドは値を出力しない。

```sh
register-secrets.sh \
  --repo bannzai/igen \
  --env ios-deploy \
  --dry-run \
  --secret ASC_API_KEY_ID="$ASC_API_KEY_ID" \
  --secret ASC_API_KEY_ISSUER_ID="$ASC_API_KEY_ISSUER_ID" \
  --secret ASC_API_KEY_P8_BASE64="$ASC_API_KEY_P8_BASE64" \
  --secret IOS_P12_CERTIFICATE_BASE64="$IOS_P12_CERTIFICATE_BASE64" \
  --secret IOS_P12_PASSWORD="$IOS_P12_PASSWORD" \
  --secret-base64-file IOS_PROVISIONING_PROFILE_BASE64=./tmp/signing/Igen_AppStore.mobileprovision

register-secrets.sh \
  --repo bannzai/igen \
  --env ios-deploy \
  --secret ASC_API_KEY_ID="$ASC_API_KEY_ID" \
  --secret ASC_API_KEY_ISSUER_ID="$ASC_API_KEY_ISSUER_ID" \
  --secret ASC_API_KEY_P8_BASE64="$ASC_API_KEY_P8_BASE64" \
  --secret IOS_P12_CERTIFICATE_BASE64="$IOS_P12_CERTIFICATE_BASE64" \
  --secret IOS_P12_PASSWORD="$IOS_P12_PASSWORD" \
  --secret-base64-file IOS_PROVISIONING_PROFILE_BASE64=./tmp/signing/Igen_AppStore.mobileprovision
```

## TestFlight処理完了を確認する

workflowのアップロード成功後、App Store Connect APIで最新ビルドの`processingState`が`VALID`になるまで確認する。

```sh
asc-api.sh GET \
  '/v1/builds?filter[app]=6806111672&sort=-uploadedDate&limit=5&fields[builds]=version,processingState,uploadedDate'
```

## 実機で最終確認する

TestFlightビルドを実機へインストールし、次を確認してIssue #50へ結果とスクリーンショットをコメントする。不具合は別Issueに起票する。

- マイク許可後、音声入力がSpeech frameworkで文字起こしされる
- Sandbox Apple IDで相談チケット購入、月額サブスクリプション購入、購入の復元が成功する
- push通知を使わない状態で警告やクラッシュがない
- セーフティ画面の窓口カードにある電話番号をタップすると発信確認画面が開く
