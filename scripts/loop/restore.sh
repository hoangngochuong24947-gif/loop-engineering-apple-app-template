#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/common.sh"
test "$#" -eq 1 || { printf 'Usage: %s ANNOTATED_TAG\n' "$0" >&2; exit 2; }
tag=$1
root=$(loop_root)
case "$tag" in
  checkpoint/*|stage/*|v[0-9]*) ;;
  *) printf 'Restore accepts checkpoint, stage, or version tags only.\n' >&2; exit 1 ;;
esac
loop_clean_git -C "$root" show-ref --verify --quiet "refs/tags/$tag" || {
  printf 'Restore accepts an existing tag only.\n' >&2
  exit 1
}
test "$(loop_clean_git -C "$root" cat-file -t "$tag")" = tag || {
  printf 'Restore requires an annotated immutable tag.\n' >&2
  exit 1
}
local_object=$(loop_clean_git -C "$root" rev-parse "refs/tags/$tag")
head=$(loop_clean_git -C "$root" rev-parse "$tag^{commit}")
remote_refs=$(loop_clean_git -C "$root" ls-remote --tags origin \
  "refs/tags/$tag" "refs/tags/$tag^{}")
remote_object=$(printf '%s\n' "$remote_refs" | awk -v ref="refs/tags/$tag" '$2 == ref {print $1}')
peeled_ref="refs/tags/$tag^{}"
remote_head=$(printf '%s\n' "$remote_refs" | awk -v ref="$peeled_ref" '$2 == ref {print $1}')
test -n "$remote_object" && test -n "$remote_head" || {
  printf 'Restore requires the tag to exist on origin.\n' >&2
  exit 1
}
test "$local_object" = "$remote_object" && test "$head" = "$remote_head" || {
  printf 'Local and origin tag objects are not synchronized.\n' >&2
  exit 1
}
short=$(printf '%s' "$head" | cut -c1-12)
utc=$(date -u '+%Y%m%dT%H%M%SZ')
branch="restore/$utc-$short"
worktree_root=$(loop_worktree_root "$root")
worktree="$worktree_root/restore-$utc-$short"
mkdir -p "$worktree_root"
loop_clean_git -C "$root" worktree add -b "$branch" "$worktree" "$tag" >/dev/null
printf 'branch=%s\nworktree=%s\nhead=%s\n' "$branch" "$worktree" "$head"
