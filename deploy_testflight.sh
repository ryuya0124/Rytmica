#!/bin/bash
# ============================================================
# iOS TestFlightアップロードスクリプト
# 使い方: ./deploy_testflight.sh
# ============================================================

set -e

# 色付きメッセージ
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# プロジェクトルートに移動
cd "$(dirname "$0")"

# pubspec.yamlからバージョン情報を取得
VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //')
VERSION_NAME=$(echo "$VERSION" | cut -d'+' -f1)
BUILD_NUMBER=$(echo "$VERSION" | cut -d'+' -f2)

echo -e "${YELLOW}📦 pubspec.yaml から取得: バージョン ${VERSION_NAME}, ビルド番号 ${BUILD_NUMBER}${NC}"

# 最初に証明書を同期
echo -e "${YELLOW}🔐 証明書を同期中...${NC}"
cd ios
bundle exec fastlane sync_certificates
cd ..

# Info.plistを直接書き換え（Xcodeの自動インクリメントを回避）
echo -e "${YELLOW}🔧 Info.plistのビルド番号を直接設定中...${NC}"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${BUILD_NUMBER}" ios/Runner/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${VERSION_NAME}" ios/Runner/Info.plist

# ビルドキャッシュをクリーン
echo -e "${YELLOW}🧹 ビルドキャッシュをクリーン中...${NC}"
flutter clean
flutter pub get

# Flutter でIPAをビルド（pubspec.yamlのビルド番号を使用）
echo -e "${YELLOW}🔨 Flutter IPAをビルド中...${NC}"
flutter build ipa --release --build-number="${BUILD_NUMBER}" --build-name="${VERSION_NAME}" --export-options-plist=ios/ExportOptions.plist

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ ビルドに失敗しました${NC}"
    exit 1
fi

echo -e "${GREEN}✅ ビルド完了${NC}"

# ビルドされたIPAのビルド番号を確認
echo -e "${YELLOW}🔍 IPAのビルド番号を確認中...${NC}"
IPA_BUILD_NUMBER=$(unzip -p build/ios/ipa/*.ipa Payload/Runner.app/Info.plist | plutil -p - | grep CFBundleVersion | sed 's/.*=> "//' | sed 's/"//')
echo -e "   IPAのビルド番号: ${IPA_BUILD_NUMBER}"

if [ "$IPA_BUILD_NUMBER" != "$BUILD_NUMBER" ]; then
    echo -e "${RED}❌ エラー: IPAのビルド番号(${IPA_BUILD_NUMBER})がpubspec.yaml(${BUILD_NUMBER})と異なります！${NC}"
    echo -e "${YELLOW}   ビルドを中止します。${NC}"
    exit 1
fi

# fastlaneでTestFlightにアップロード
echo -e "${YELLOW}🚀 TestFlightにアップロード中...${NC}"
cd ios

OUTPUT=$(bundle exec fastlane upload_local 2>&1) || {
    EXIT_CODE=$?
    
    # ビルド番号重複エラーチェック
    if echo "$OUTPUT" | grep -qE "(redundant binary upload|already exists|This build already exists|has already been uploaded|must be higher than|DUPLICATE|has already been used)"; then
        echo ""
        echo -e "${RED}❌ ビルド番号 ${BUILD_NUMBER} は既にTestFlightにアップロード済みです！${NC}"
        echo ""
        echo -e "${YELLOW}📝 解決方法: pubspec.yaml の version を更新してください。${NC}"
        echo -e "   現在: version: ${VERSION_NAME}+${BUILD_NUMBER}"
        echo -e "   変更例: version: ${VERSION_NAME}+$((BUILD_NUMBER + 1))"
        exit 1
    else
        echo "$OUTPUT"
        exit $EXIT_CODE
    fi
}

echo "$OUTPUT"
echo ""
echo -e "${GREEN}✅ TestFlightへのアップロード完了！${NC}"
