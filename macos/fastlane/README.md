fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Mac

### mac upload_store_listing

```sh
[bundle exec] fastlane mac upload_store_listing
```

2.5.0のリリースノートとスクリーンショットをApp Store Connectへ反映

### mac update_testflight_notes

```sh
[bundle exec] fastlane mac update_testflight_notes
```

2.5.0 (34) のTestFlightテスト内容を日本語・英語で更新

### mac sync_certificates

```sh
[bundle exec] fastlane mac sync_certificates
```

証明書とプロビジョニングプロファイルを同期

### mac build_signed

```sh
[bundle exec] fastlane mac build_signed
```

署名ありAppをビルド

### mac upload_testflight

```sh
[bundle exec] fastlane mac upload_testflight
```

ビルド済みAppをTestFlightにアップロード

### mac upload_local

```sh
[bundle exec] fastlane mac upload_local
```

ローカルからビルド済みAppをTestFlightにアップロード

### mac beta

```sh
[bundle exec] fastlane mac beta
```

TestFlightにビルドをアップロード

### mac local_testflight

```sh
[bundle exec] fastlane mac local_testflight
```

ローカルからTestFlightにビルドをアップロード

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
