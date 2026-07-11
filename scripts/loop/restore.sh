#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/common.sh"
test "$#" -eq 1 || { printf 'Usage: %s ANNOTATED_TAG\n' "$0" >&2; exit 2; }
tag=$1
root=$(loop_root)
loop_clean_git -C "$root" show-ref --verify --quiet "refs/tags/$tag" || {
  printf 'Restore accepts an existing tag only.\n' >&2
  exit 1
}
test "$(loop_clean_git -C "$root" cat-file -t "$tag")" = tag || {
  printf 'Restore requires an annotated immutable tag.\n' >&2
  exit 1
}
head=$(loop_clean_git -C "$root" rev-parse "$tag^{commit}")
short=$(printf '%s' "$head" | cut -c1-12)
utc=$(date -u '+%Y%m%dT%H%M%SZ')
branch="restore/$utc-$short"
worktree_root=$(loop_worktree_root "$root")
worktree="$worktree_root/restore-$utc-$short"
mkdir -p "$worktree_root"
loop_clean_git -C "$root" worktree add -b "$branch" "$worktree" "$tag" >/dev/null
printf 'branch=%s\nworktree=%s\nhead=%s\n' "$branch" "$worktree" "$head"
