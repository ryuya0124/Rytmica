# F-Droid ビルド

ソースは GitHub で管理し、公式掲載のビルド定義は
[fdroiddata](https://gitlab.com/fdroid/fdroiddata) へ提出する。
Android application ID は `net.ryuya_dev.mnc`。

2026-10-25 に [掲載申請 MR !54059](https://gitlab.com/fdroid/fdroiddata/-/merge_requests/54059)
をドラフトで作成した。フォークの CI は GitLab の追加本人確認で実行されず、
MR に運営側ランナーの実行依頼を記載している。F-Droid でのビルド・スキャン、
署名方式と再現ビルド、ABI 分割、対応するリリースタグは掲載前の確認事項。

署名なしのリリース APK は、JDK 21、Flutter 3.47.8、Android SDK 37.0、
NDK r28c を用意し、以下で生成する。Android のビルドツールは
AGP 9.2.1 / Gradle 9.4.1 / Kotlin 2.4.21 を使用する。
AGP 9.1.0 は現在配布されている SDK 37.0 をクリーン環境で解決できない。

```sh
flutter pub get --enforce-lockfile
ORG_GRADLE_PROJECT_fdroid=true flutter build apk --release
# 例: ARM64 だけの APK（Android versionCode 362）
ORG_GRADLE_PROJECT_fdroid=true flutter build apk --release --split-per-abi --target-platform=android-arm64 -PrytmicaAbi=arm64-v8a
```

`ANDROID_KEYSTORE_PATH` など通常の署名用環境変数は設定しない。
F-Droid モードと署名情報を併用するとビルドは停止する。
このオプションを指定しない通常のリリースでは、本番署名情報が必須となる。

GitHub Actions の `Flutter Android Build` で `distribution: fdroid` と `abi` を指定しても
同じビルドを確認できる。初回の [CI ビルド](https://github.com/ryuya0124/Rytmica/actions/runs/40151821117)
は成功し、パッケージ ID・2.5.1（36）・署名が付いていないことを検証済み。
これは F-Droid 自身のスキャナーやビルド環境での成功を保証するものではない。

日英の紹介文・アイコン・変更履歴は `fastlane/metadata/android/` に置く。
`images/phoneScreenshots/` は Android 17（API 37）のエミュレーターで撮影した
1080×2400px の画像を各言語 5 枚収録している。
初回申請は完全なコミット SHA に固定し、将来の更新はタグと `pubspec.yaml` から取得する。

2.5.1 以降は Android の versionCode を `pubspec のビルド番号 × 10 + ABI 番号` に揃える。
通常版は 360、ARM32 は 361、ARM64 は 362、x86_64 は 363。
次回の通常版 370 はこれらすべてを更新できる。自動更新側も同じ `VercodeOperation` を使う。
詳細は [Android signing](ANDROID_SIGNING.md) を参照。

F-Droid 独自署名と GitHub の本番署名は異なるため、そのままでは相互に更新できない。
既存の本番署名を使うには [再現ビルド](https://f-droid.org/docs/Reproducible_Builds/) の検証と
公開済み APK の指定が必要となる。申請レビューでこの方式を確定してから掲載する。
本番の秘密鍵・パスワードを fdroiddata に渡さない。
