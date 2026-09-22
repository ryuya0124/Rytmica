# App Store Connect assets

Rytmica 2.5.0 の App Store Connect 用メタデータとスクリーンショットです。

- iOS/iPadOS: `fastlane/app-store/ios`
- macOS: `fastlane/app-store/macos`
- スクリーンショット内の BPM は 120 に統一します。
- 日本語と英語のリリースノートを管理します。

ローカルの App Store Connect API キーが利用できる環境では、次のコマンドで編集可能なストア情報へ反映できます。審査提出は行いません。

```sh
(cd ios && fastlane ios upload_store_listing)
(cd macos && fastlane mac upload_store_listing)
```

撮影専用の初期画面・BPM・餡蜜チェッカー表示は、製品ビルドへ影響しない `--dart-define` で指定します。

```sh
flutter run -d <device> \
  --dart-define=RYTMICA_SCREENSHOT_PAGE=3 \
  --dart-define=RYTMICA_SCREENSHOT_BPM=120 \
  --dart-define=RYTMICA_SCREENSHOT_ANMITSU_VIEW=1 \
  --dart-define=RYTMICA_SCREENSHOT_SCROLL_RESULT=true
```
