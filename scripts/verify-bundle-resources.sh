#!/bin/sh
set -eu

app_path="${1:-}"

if [ -z "$app_path" ] || [ ! -d "$app_path" ]; then
  echo "usage: $0 /path/to/QuickNote.app" >&2
  exit 2
fi

test -f "$app_path/PrivacyInfo.xcprivacy" || {
  echo "missing PrivacyInfo.xcprivacy in built app" >&2
  exit 1
}

test -f "$app_path/Assets.car" || {
  echo "missing compiled asset catalog in built app" >&2
  exit 1
}

echo "Verified bundled privacy manifest and compiled asset catalog."
