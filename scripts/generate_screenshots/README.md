# App Store Screenshot Generator

App Store のスクリーンショットを SwiftUI + UITest で生成するスクリプト群。

## 概要

`ios/Igen/AppStoreScreenshots/` の SwiftUI で組んだスクショ画面を、
`ios/IgenUITests/AppStoreScreenshots/` の UITest がシミュレータ上で表示して撮影し、
`fastlane/screenshots/{ja,en-US}/` に App Store Connect が読める形式で配置する。

撮影の入口は起動引数 `--isSnapshotUITest`。この引数が付くと `IgenApp` が `HomePage` の代わりに
`AppStoreScreenshotsRootPage` を表示し、UITest が各スクショ画面のボタンをタップして撮影する。

## スクリプト一覧

| スクリプト | 役割 |
|-----------|------|
| `appstore_screenshot_env.sh` | 環境変数・共通関数の定義 (他スクリプトから source する) |
| `build_appstore_screenshot.sh` | UITest のビルド (`xcodebuild build-for-testing`) |
| `run_appstore_screenshot.sh` | 個別テストの実行 (`xcodebuild test-without-building`) |
| `organize_appstore_screenshots.sh` | xcresult から書き出した PNG を fastlane 形式に配置 |
| `generate_appstore_screenshots.sh` | メインオーケストレーション (ビルド → 撮影 → 配置 → 検査) |

通常は `generate_appstore_screenshots.sh` だけを使う。

## 使い方

### 全言語・全番号で生成

```bash
./scripts/generate_screenshots/generate_appstore_screenshots.sh
```

### 1 枚だけ生成する (動作確認用)

```bash
./scripts/generate_screenshots/generate_appstore_screenshots.sh -n "1" -l "ja"
```

### 言語を指定して生成

```bash
./scripts/generate_screenshots/generate_appstore_screenshots.sh -l "ja"
./scripts/generate_screenshots/generate_appstore_screenshots.sh -l "ja,en"
```

### 番号を指定して生成 (カンマ区切りと範囲の混在に対応)

```bash
./scripts/generate_screenshots/generate_appstore_screenshots.sh -n "1-3"
./scripts/generate_screenshots/generate_appstore_screenshots.sh -n "1,3,6"
```

### ビルドをスキップして再撮影

一度ビルドした後、スクショ画面の変更がない状態で撮り直す場合に使う。

```bash
./scripts/generate_screenshots/generate_appstore_screenshots.sh --skip-build
```

### オプション一覧

| オプション | 説明 | デフォルト |
|-----------|------|----------|
| `-l LANGS` | 撮影する言語をカンマ区切りで指定 | `ja,en` (全言語) |
| `-n NUMS` | 撮影するスクリーンショット番号 (カンマ区切り / 範囲指定) | 全番号 (1-6) |
| `--skip-build` | `build-for-testing` をスキップ | - |
| `-h, --help` | ヘルプメッセージを表示 | - |

## 出力先

```
fastlane/screenshots/
├── ja/
│   ├── 1_APP_IPHONE_69_1.png
│   ├── ...
│   └── 6_APP_IPHONE_69_6.png
└── en-US/
    ├── 1_APP_IPHONE_69_1.png
    ├── ...
    └── 6_APP_IPHONE_69_6.png
```

`APP_IPHONE_69` は App Store Connect の 6.9 インチ (1320x2868 px) 枠を指す。
生成後に `sips` で全 PNG の寸法と alpha を検査し、
1320x2868 でない・alpha を持つ PNG があればスクリプトが非ゼロ終了する。

実行ログは `tmp/generate_appstore_screenshots.<datetime>.logs.txt` に出力される。
ビルド成果物と xcresult は `tmp/appstore_screenshots/` 配下に置かれる (`tmp/` は gitignore 済み)。

## 環境変数

| 環境変数 | 説明 | デフォルト |
|---------|------|----------|
| `DESTINATION_SIM_NAME` | 使用するシミュレータ名 | `igen-appstore-screenshots` |
| `DESTINATION_SIM_DEVICE_TYPE` | シミュレータのデバイスタイプ | `iPhone 17 Pro Max` |

シミュレータは `sim-boot` で冪等に作成・起動し、名前から引いた UDID を
`-destination "platform=iOS Simulator,id=<UDID>"` に渡す (OS バージョンは固定しない)。
既に起動済みのシミュレータを使いたい場合はその名前を `DESTINATION_SIM_NAME` に渡す。

```bash
DESTINATION_SIM_NAME=igen-issue-44-45-46-iOS26.5 \
  ./scripts/generate_screenshots/generate_appstore_screenshots.sh
```

デバイスタイプは 6.9 インチのスクリーンショットが撮れるものにする
(`iPhone 17 Pro Max` の 1320x2868 px)。別のデバイスタイプにすると寸法検査で落ちる。

## 撮影対象を増やす場合

1. `ios/Igen/AppStoreScreenshots/AppStoreScreenshot{N}Page.swift` を追加する
2. `ios/Igen/AppStoreScreenshots/AppStoreScreenshotsRootPage.swift` に `SnapshotUITest<AppStoreScreenshot{N}Page_Previews>()` を追加する
3. `ios/IgenUITests/AppStoreScreenshots/AppStoreScreenshot{N}PageSnapshotUITest.swift` を追加する
4. 本 README の出力先の例を更新する

言語を増やす場合は `ios/IgenUITests/AppStoreScreenshots/Languages.swift` の
`languageCodeAndLanguageWithRegion`、`appstore_screenshot_env.sh` の `map_language_to_fastlane`、
`generate_appstore_screenshots.sh` の `ALL_LANGUAGES` の 3 箇所を揃えて更新する。

## 必要なツール

- Xcode (`xcodebuild` / `xcrun xcresulttool` / `sips`)
- `jq` (manifest.json の解析)
- `sim-boot` (bannzai/.bin。シミュレータの冪等な作成・起動)
