#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/common.sh"
test "$#" -eq 2 || { printf 'Usage: %s ISSUE SLUG\n' "$0" >&2; exit 2; }
issue=$1
slug=$2
loop_safe_name "$issue" && loop_safe_name "$slug" || exit 2

root=$(loop_checkout_root)
default=$(loop_default_branch "$root")
branch=$(loop_branch "$root")
test "$branch" != "$default" || { printf 'Checkpoint refused on %s.\n' "$default" >&2; exit 1; }
loop_require_clean "$root"
upstream=$(loop_clean_git -C "$root" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null) || {
  printf 'Push the branch and configure its upstream first.\n' >&2
  exit 1
}
head=$(loop_clean_git -C "$root" rev-parse HEAD)
remote_head=$(loop_clean_git -C "$root" rev-parse "$upstream")
test "$head" = "$remote_head" || { printf 'Current HEAD is not pushed.\n' >&2; exit 1; }
env -u LOOP_SKIP_INTEGRATION_TESTS -u LOOP_SKIP_TESTS -u SKIP_TESTS \
  -u NO_TESTS -u CI_SKIP_TESTS -u LOOP_VERIFY_SKIP_TESTS \
  "$root/scripts/loop/verify-full.sh" >&2

utc=$(date -u '+%Y%m%dT%H%M%SZ')
short=$(loop_clean_git -C "$root" rev-parse --short HEAD)
tag="checkpoint/$issue-$slug/$utc-$short"
loop_clean_git -C "$root" show-ref --verify --quiet "refs/tags/$tag" && {
  printf 'Checkpoint already exists: %s\n' "$tag" >&2
  exit 1
}
loop_clean_git -C "$root" tag -a "$tag" -m "Verified checkpoint for Issue $issue" "$head"
if ! loop_clean_git -C "$root" push origin "refs/tags/$tag" >/dev/null; then
  loop_clean_git -C "$root" tag -d "$tag" >/dev/null
  exit 1
fi
printf '%s\n' "$tag"
