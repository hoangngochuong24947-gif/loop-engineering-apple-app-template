#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/common.sh"
root=$(loop_checkout_root)

find "$root/scripts/loop" "$root/tests" -type f -name '*.sh' 2>/dev/null | while IFS= read -r file; do
  sh -n "$file"
done
find "$root/.githooks" -type f 2>/dev/null | while IFS= read -r file; do
  sh -n "$file"
done
"$root/scripts/loop/secret-scan.sh"
printf 'fast verification passed\n'
