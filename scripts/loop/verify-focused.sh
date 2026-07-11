#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/common.sh"
root=$(loop_checkout_root)
"$root/scripts/loop/verify-fast.sh"
if test "${LOOP_SKIP_INTEGRATION_TESTS:-0}" != 1 && test -x "$root/tests/run.sh"; then
  "$root/tests/run.sh"
fi
printf 'focused verification passed\n'
