#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
apk_path="${1:-}"
expected_file="${2:-$repo_root/android/release-signing.sha256}"

if [[ -z "$apk_path" || ! -f "$apk_path" ]]; then
  echo "Usage: $0 <apk-path> [expected-fingerprint-file]" >&2
  exit 2
fi

if [[ ! -f "$expected_file" ]]; then
  echo "Expected signing fingerprint file not found: $expected_file" >&2
  exit 2
fi

apksigner_bin="${APKSIGNER:-}"
if [[ -z "$apksigner_bin" ]] && command -v apksigner >/dev/null 2>&1; then
  apksigner_bin="$(command -v apksigner)"
fi
if [[ -z "$apksigner_bin" && -n "${ANDROID_HOME:-}" ]]; then
  for candidate in "$ANDROID_HOME"/build-tools/*/apksigner; do
    [[ -x "$candidate" ]] && apksigner_bin="$candidate"
  done
fi
if [[ -z "$apksigner_bin" || ! -x "$apksigner_bin" ]]; then
  echo "apksigner was not found. Set APKSIGNER or install Android build-tools." >&2
  exit 2
fi

expected="$(tr -d '[:space:]:' < "$expected_file" | tr '[:upper:]' '[:lower:]')"
certificate_output="$($apksigner_bin verify --print-certs "$apk_path" 2>&1)"
actual="$(printf '%s\n' "$certificate_output" \
  | sed -nE 's/.*SHA-256 digest:[[:space:]]*([0-9A-Fa-f]{64}).*/\1/p' \
  | head -n 1 \
  | tr '[:upper:]' '[:lower:]')"

if [[ ! "$expected" =~ ^[0-9a-f]{64}$ ]]; then
  echo "Invalid expected SHA-256 fingerprint in $expected_file" >&2
  exit 2
fi
if [[ ! "$actual" =~ ^[0-9a-f]{64}$ ]]; then
  echo "Could not read an APK signing certificate from $apk_path" >&2
  printf '%s\n' "$certificate_output" >&2
  exit 1
fi
if [[ "$actual" != "$expected" ]]; then
  echo "Android signing certificate mismatch." >&2
  echo "Expected: $expected" >&2
  echo "Actual:   $actual" >&2
  exit 1
fi

echo "Android signing certificate verified: $actual"
