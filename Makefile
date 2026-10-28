# 実機 (iPhone) への Release ビルド・インストール・起動。
# Release を使う理由: Debug は既定で Functions エミュレータ (127.0.0.1) に向くため、
# 実機単体で触るには本番 igen-prod に向く Release が必要 (ios/Igen/Shared/API/IgenAPI.swift 参照)。

# `xcrun devicectl list devices` の Identifier。既定は bannzai の iPhone 15 Pro
DEVICE ?= FA761CC3-6F5C-569D-A044-3CFC42E93A35
DERIVED_DATA := ./tmp/DerivedData
BUNDLE_ID := com.bannzai.Igen

# 既定を Debug にする理由: 手元の動作確認は Functions エミュレータに向く構成で行うため
# (Release は本番 igen-prod に向く。ios/Igen/Shared/API/IgenAPI.swift 参照)。
# simulator は sim-boot で用意したプロジェクト固有のものを使う (sim-manager skill 参照)
CONFIGURATION ?= Debug
SIMULATOR_APP := $(DERIVED_DATA)/Build/Products/$(CONFIGURATION)-iphonesimulator/Igen.app
SIMULATOR_UDID ?= $(shell SCRIPT_QUIET=1 sim-boot | sed -n 's/^DEVICE_UDID=//p' | tail -n 1)

.PHONY: build-ios ios device-build device-install device-launch

# Simulator 向けビルド。generic destination なら simulator の起動なしでビルドできる。
# -skipPackagePluginValidation: LicenseList の build tool plugin は GUI で一度許可するまで CLI から実行できない。
# CODE_SIGN_IDENTITY=-: 無署名 (CODE_SIGNING_ALLOWED=NO) にすると Simulator の Keychain が使えず Firebase Auth が失敗する (PR #53)
build-ios:
	xcodebuild build \
	  -project ios/Igen.xcodeproj \
	  -scheme Igen \
	  -configuration $(CONFIGURATION) \
	  -destination 'generic/platform=iOS Simulator' \
	  -derivedDataPath $(DERIVED_DATA) \
	  -skipPackagePluginValidation \
	  CODE_SIGN_IDENTITY=-

# Simulator 向けビルドを sim-boot で起動した simulator にインストールして起動する
ios: build-ios
	@set -e; \
	simulator_udid="$(SIMULATOR_UDID)"; \
	[ -n "$$simulator_udid" ] || { echo "Error: sim-boot で Simulator を解決できません (sim-boot が PATH にあるか確認するか、SIMULATOR_UDID=<UDID> を指定してください)" >&2; exit 1; }; \
	xcrun simctl install "$$simulator_udid" $(SIMULATOR_APP); \
	xcrun simctl launch "$$simulator_udid" $(BUNDLE_ID)

# 実機向け Release ビルド
device-build:
	xcodebuild build \
	  -project ios/Igen.xcodeproj \
	  -scheme Igen \
	  -configuration Release \
	  -destination 'generic/platform=iOS' \
	  -derivedDataPath $(DERIVED_DATA) \
	  -allowProvisioningUpdates \
	  -allowProvisioningDeviceRegistration \
	  -skipPackagePluginValidation

# ビルドして実機にインストール
device-install: device-build
	xcrun devicectl device install app --device $(DEVICE) \
	  $(DERIVED_DATA)/Build/Products/Release-iphoneos/Igen.app

# 実機でアプリを起動 (実機のロック解除が必要)
device-launch:
	xcrun devicectl device process launch --device $(DEVICE) com.bannzai.Igen

# 引数なしの make で ios を実行する (人が手で動作確認するための入口。検査・テストは CI が行う)
.DEFAULT_GOAL := ios

.PHONY: verify
verify:
	xcrun swift-format lint --strict --recursive ios
	npm --prefix backend/functions ci
	npm --prefix backend/functions run lint
	npm --prefix backend/functions run build
	npm --prefix backend/functions test
	xcodebuild test -project ios/Igen.xcodeproj -scheme Igen -destination "platform=iOS Simulator,name=iPhone 17" -derivedDataPath tmp/DerivedData -skip-testing:IgenUITests/AppStoreScreenshot1PageSnapshotUITest -skip-testing:IgenUITests/AppStoreScreenshot2PageSnapshotUITest -skip-testing:IgenUITests/AppStoreScreenshot3PageSnapshotUITest -skip-testing:IgenUITests/AppStoreScreenshot4PageSnapshotUITest -skip-testing:IgenUITests/AppStoreScreenshot5PageSnapshotUITest -skip-testing:IgenUITests/AppStoreScreenshot6PageSnapshotUITest -skipPackagePluginValidation CODE_SIGN_IDENTITY=-
