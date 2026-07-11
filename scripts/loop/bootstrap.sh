#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/common.sh"
root=$(loop_checkout_root)
chmod +x "$root"/scripts/loop/*.sh "$root"/.githooks/* 2>/dev/null || true
loop_clean_git -C "$root" config core.hooksPath .githooks
"$root/scripts/loop/doctor.sh"
printf 'Loop Engineering hooks installed.\n'
