#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/common.sh"
root=$(loop_checkout_root)
test -f "$root/.loop/project.yml"
test -f "$root/.loop/project.schema.json"
test -f "$root/AGENTS.md"
command -v git >/dev/null
find "$root/scripts/loop" -type f -name '*.sh' | while IFS= read -r file; do sh -n "$file"; done
printf 'doctor passed for %s\n' "$root"
