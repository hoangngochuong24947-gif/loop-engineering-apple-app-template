#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/common.sh"
test "$#" -ge 1 || { printf 'Usage: %s STAGE [SUMMARY]\n' "$0" >&2; exit 2; }
stage=$1
summary=${2:-Stage snapshot}
loop_safe_name "$stage" || exit 2
root=$(loop_checkout_root)
utc=$(date -u '+%Y%m%dT%H%M%SZ')
head=$(loop_clean_git -C "$root" rev-parse HEAD)
branch=$(loop_branch "$root")
relative="docs/progress/stages/$utc-$stage.md"
path="$root/$relative"
mkdir -p "$(dirname "$path")"
cat >"$path" <<EOF
# $stage

- Created: $utc
- Branch: $branch
- SHA: $head
- Summary: $summary

## Verification

- Run \`./scripts/loop/verify-full.sh\` before publishing this stage.
EOF
printf '%s\n' "$relative"
