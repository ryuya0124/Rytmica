#!/usr/bin/env bash

set -euo pipefail

readonly SIGNING_IDENTITY="${SIGNING_IDENTITY:-Developer ID Application: ryuya watanabe (FZ35ZF3CZV)}"
readonly APPLE_TEAM_ID="${APPLE_TEAM_ID:-FZ35ZF3CZV}"
readonly ASC_KEY_PATH="${ASC_KEY_PATH:?Set ASC_KEY_PATH to the App Store Connect API private key}"
readonly ASC_KEY_ID="${ASC_KEY_ID:?Set ASC_KEY_ID to the App Store Connect API key ID}"
readonly ASC_ISSUER_ID="${ASC_ISSUER_ID:?Set ASC_ISSUER_ID to the App Store Connect issuer ID}"

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

version="$(awk '/^version:/ { split($2, parts, "+"); print parts[1]; exit }' pubspec.yaml)"
readonly version
readonly app_path="$project_root/build/macos/Build/Products/Release/Rytmica.app"
readonly output_dir="${OUTPUT_DIR:-$project_root/release-assets}"
readonly submission_zip="$output_dir/Rytmica-macOS-$version-notarization.zip"
readonly distribution_zip="$output_dir/Rytmica-macOS-$version.zip"
readonly distribution_dmg="$output_dir/Rytmica-macOS-$version.dmg"

mkdir -p "$output_dir"
rm -f "$submission_zip" "$distribution_zip" "$distribution_dmg"

flutter build macos --release

while IFS= read -r framework; do
  codesign \
    --force \
    --options runtime \
    --timestamp \
    --sign "$SIGNING_IDENTITY" \
    "$framework"
done < <(find "$app_path/Contents/Frameworks" -mindepth 1 -maxdepth 1 -type d -name '*.framework' -print | sort)

codesign \
  --force \
  --options runtime \
  --timestamp \
  --entitlements macos/Runner/Release.entitlements \
  --sign "$SIGNING_IDENTITY" \
  "$app_path"

codesign --verify --deep --strict --verbose=2 "$app_path"
ditto -c -k --keepParent "$app_path" "$submission_zip"

xcrun notarytool submit "$submission_zip" \
  --key "$ASC_KEY_PATH" \
  --key-id "$ASC_KEY_ID" \
  --issuer "$ASC_ISSUER_ID" \
  --team-id "$APPLE_TEAM_ID" \
  --wait

xcrun stapler staple "$app_path"
xcrun stapler validate "$app_path"
spctl --assess --type execute --verbose=2 "$app_path"

ditto -c -k --keepParent "$app_path" "$distribution_zip"
diskutil image create from \
  --volumeName Rytmica \
  --format UDZO \
  "$app_path" \
  "$distribution_dmg"

codesign --force --timestamp --sign "$SIGNING_IDENTITY" "$distribution_dmg"
xcrun notarytool submit "$distribution_dmg" \
  --key "$ASC_KEY_PATH" \
  --key-id "$ASC_KEY_ID" \
  --issuer "$ASC_ISSUER_ID" \
  --team-id "$APPLE_TEAM_ID" \
  --wait

xcrun stapler staple "$distribution_dmg"
xcrun stapler validate "$distribution_dmg"
spctl --assess --type open --context context:primary-signature --verbose=2 "$distribution_dmg"

rm -f "$submission_zip"
printf 'Created %s and %s\n' "$distribution_zip" "$distribution_dmg"
