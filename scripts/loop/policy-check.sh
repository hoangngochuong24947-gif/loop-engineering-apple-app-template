#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/common.sh"

mode=${1:-all}
root=$(loop_checkout_root)
default=$(loop_default_branch "$root")
branch=$(loop_branch "$root")

case "$mode" in
  direct-main|all)
    test "$branch" != "$default" || {
      printf 'Direct feature work on %s is forbidden.\n' "$default" >&2
      exit 1
    }
    ;;
  *) printf 'Unknown policy mode: %s\n' "$mode" >&2; exit 2 ;;
esac
