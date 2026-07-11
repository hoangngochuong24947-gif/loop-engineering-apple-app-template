#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/common.sh"
root=$(loop_checkout_root)

files=$(loop_clean_git -C "$root" diff --cached --name-only --diff-filter=ACMR)
printf '%s\n' "$files" | grep -E '(^|/)(\.env($|\.)|.*\.(p12|mobileprovision|cer|key)$)' >/dev/null 2>&1 && {
  printf 'Staged secret-bearing filename detected.\n' >&2
  exit 1
} || true

loop_clean_git -C "$root" diff --cached --no-ext-diff -U0 | \
  grep -E '^\+.*(BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY|AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9]{20,})' >/dev/null 2>&1 && {
    printf 'Possible staged secret detected.\n' >&2
    exit 1
  } || true
