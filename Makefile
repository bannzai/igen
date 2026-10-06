# 実機 (iPhone) への Release ビルド・インストール・起動。
# Release を使う理由: Debug は既定で Functions エミュレータ (127.0.0.1) に向くため、
# 実機単体で触るには本番 igen-prod に向く Release が必要 (ios/Igen/Shared/API/IgenAPI.swift 参照)。

# `xcrun devicectl list devices` の Identifier。既定は bannzai の iPhone 15 Pro
DEVICE ?= FA761CC3-6F5C-569D-A044-3CFC42E93A35
DERIVED_DATA := ./tmp/DerivedData

.PHONY: device-build device-install device-launch

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

# 引数なしの make で動作確認 (verify) を実行する
.DEFAULT_GOAL := verify

.PHONY: verify
verify:
	xcrun swift-format lint --strict --recursive ios
	npm --prefix backend/functions ci
	npm --prefix backend/functions run lint
	npm --prefix backend/functions run build
	npm --prefix backend/functions test
	xcodebuild test -project ios/Igen.xcodeproj -scheme Igen -destination "platform=iOS Simulator,name=iPhone 17" -derivedDataPath tmp/DerivedData -skip-testing:IgenUITests/AppStoreScreenshot1PageSnapshotUITest -skip-testing:IgenUITests/AppStoreScreenshot2PageSnapshotUITest -skip-testing:IgenUITests/AppStoreScreenshot3PageSnapshotUITest -skip-testing:IgenUITests/AppStoreScreenshot4PageSnapshotUITest -skip-testing:IgenUITests/AppStoreScreenshot5PageSnapshotUITest -skip-testing:IgenUITests/AppStoreScreenshot6PageSnapshotUITest -skipPackagePluginValidation CODE_SIGN_IDENTITY=-
