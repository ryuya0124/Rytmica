# Android release signing

Android updates are accepted only when the new APK is signed by the same
certificate as the installed app. Rytmica uses the signing identity established
by the GitHub release `2.4.0` as its permanent direct-distribution identity.

## Canonical certificate

- Subject: `CN=Rytmica, OU=ryuya-dev, O=ryuya-dev, L=Tokyo, ST=Tokyo, C=JP`
- SHA-256: `E6:EB:4D:AD:8C:4D:B1:64:9C:9B:75:A8:F5:A3:74:E2:B7:68:24:28:D1:48:F9:61:ED:63:27:C2:2C:5B:BD:78`
- Machine-readable value: [`android/release-signing.sha256`](../android/release-signing.sha256)

The certificate fingerprint is public information. The keystore and its
passwords must never be committed.

## GitHub Actions secrets

The release workflow requires all four values:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

`ANDROID_KEYSTORE_BASE64` must always contain the same original Rytmica
keystore. The Gradle configuration deliberately fails release tasks if any
value is missing; it never falls back to a debug key. CI also verifies the APK
certificate before uploading release assets.

## Local release build

Set the same four values in the environment. `ANDROID_KEYSTORE_PATH` is
resolved from the `android` directory, so `app/rytmica-release.jks` is the
expected local path. Then run:

```sh
flutter build apk --release
flutter build appbundle --release
scripts/verify_android_signature.sh build/app/outputs/flutter-apk/app-release.apk
```

Never place passwords in shell history, source files, Gradle files, or CI logs.

Debug builds use the separate application ID `net.ryuya_dev.mnc.debug` and the
launcher name `Rytmica Dev`. This lets wireless-debugging installs coexist with
the release-signed GitHub build without replacing it or risking its app data.

## Backup and recovery

Keep at least two encrypted, offline backups of the keystore and the four
values above, in separate locations. Test recovery periodically by building an
APK and verifying the fingerprint. Losing this private key permanently prevents
updates to direct-distribution installs made from 2.4.0 onward.

Google Play App Signing is separate: Google signs store-delivered APKs with the
Play app-signing key, while the uploaded AAB uses an upload key. Record both Play
fingerprints in the release runbook if Play distribution is enabled; do not
replace this direct-distribution key unless a planned migration supports it.

## Historical note

The GitHub APKs from `2.2.28` and earlier were signed with different Android
debug certificates. Android cannot update those installations in place to
`2.4.0` or later; users of those builds must uninstall the old app once before
installing the permanent-signing line. Releases from `2.4.0` onward must keep
the canonical certificate above.
