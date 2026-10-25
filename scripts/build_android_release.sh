#!/usr/bin/env bash
set -euo pipefail

output_dir=${1:-release-assets}
version=$(sed -nE 's/^version: ([0-9]+\.[0-9]+\.[0-9]+)\+.*/\1/p' pubspec.yaml)
test -n "$version"
mkdir -p "$output_dir"
for abi in universal armeabi-v7a arm64-v8a x86_64; do
  bash scripts/build_android_apk.sh "$abi" "$output_dir"
  if [[ "$abi" != universal ]]; then
    cp "$output_dir/Rytmica-Android-$abi-$version.apk" "$output_dir/Rytmica-FDroid-Android-$abi-$version.apk"
  fi
done

flutter build appbundle --release
cp build/app/outputs/bundle/release/app-release.aab "$output_dir/Rytmica-Android-$version.aab"
