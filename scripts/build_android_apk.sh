#!/usr/bin/env bash
set -euo pipefail

abi=${1:-universal}
output_dir=${2:-release-assets}
version=$(sed -nE 's/^version: ([0-9]+\.[0-9]+\.[0-9]+)\+.*/\1/p' pubspec.yaml)
base_code=$(sed -nE 's/^version: .*\+([0-9]+).*/\1/p' pubspec.yaml)
test -n "$version" && test -n "$base_code"
sdk_root=${ANDROID_HOME:-${ANDROID_SDK_ROOT:?Android SDK is required}}
export APKSIGNER="$sdk_root/build-tools/36.1.0/apksigner"
args=(--release)
case "$abi" in
  universal) suffix=0; filename=app-release.apk; asset="Rytmica-Android-$version.apk" ;;
  armeabi-v7a) suffix=1; platform=android-arm ;;
  arm64-v8a) suffix=2; platform=android-arm64 ;;
  x86_64) suffix=3; platform=android-x64 ;;
  *) echo "Unsupported ABI: $abi" >&2; exit 1 ;;
esac
if [[ "$abi" != universal ]]; then
  args+=(--split-per-abi --target-platform="$platform" "-PrytmicaAbi=$abi")
  filename="app-$abi-release.apk"
  asset="Rytmica-Android-$abi-$version.apk"
fi
flutter build apk "${args[@]}"
apk="build/app/outputs/flutter-apk/$filename"
badging=$("$sdk_root/build-tools/36.1.0/aapt" dump badging "$apk")
grep -q "package: name='net.ryuya_dev.mnc' versionCode='$((base_code * 10 + suffix))' versionName='$version'" <<< "$badging"
if [[ "$abi" != universal ]]; then
  grep -qx "native-code: '$abi'" <<< "$badging"
fi
if [[ "${ORG_GRADLE_PROJECT_fdroid:-false}" == true ]]; then
  if "$APKSIGNER" verify "$apk"; then
    echo 'F-Droid APK must be unsigned' >&2
    exit 1
  fi
else
  scripts/verify_android_signature.sh "$apk"
fi
mkdir -p "$output_dir"
cp "$apk" "$output_dir/$asset"
printf '%s\n' "$badging" | head -1
