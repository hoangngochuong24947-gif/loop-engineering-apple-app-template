#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/common.sh"
root=$(loop_checkout_root)
"$root/scripts/loop/verify-focused.sh"
project=$(find "$root" -maxdepth 2 -name '*.xcodeproj' -print -quit 2>/dev/null || true)
if test -n "$project" && command -v xcodebuild >/dev/null 2>&1; then
  xcodebuild -list -project "$project" >/dev/null
fi
printf 'full verification passed\n'
