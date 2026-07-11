#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
. "$SCRIPT_DIR/common.sh"

test "$#" -eq 3 || { printf 'Usage: %s ISSUE SLUG BUILDER\n' "$0" >&2; exit 2; }
issue=$1
slug=$2
builder=$3
loop_safe_name "$issue" && loop_safe_name "$slug" && loop_safe_name "$builder" || {
  printf 'Issue, slug, and Builder must use safe names.\n' >&2
  exit 2
}

root=$(loop_root)
default=$(loop_default_branch "$root")
branch="agent/$issue-$slug"
worktree_root=$(loop_worktree_root "$root")
worktree="$worktree_root/$issue-$slug"
claim_dir="$root/.loop/runs/claims/$issue"

test ! -e "$claim_dir" || { printf 'Issue %s is already claimed.\n' "$issue" >&2; exit 1; }
loop_clean_git -C "$root" show-ref --verify --quiet "refs/heads/$branch" && {
  printf 'Branch already exists: %s\n' "$branch" >&2
  exit 1
}
test ! -e "$worktree" || { printf 'Worktree already exists: %s\n' "$worktree" >&2; exit 1; }

base="$default"
if loop_clean_git -C "$root" rev-parse --verify --quiet "origin/$default^{commit}" >/dev/null; then
  base="origin/$default"
fi
base_sha=$(loop_clean_git -C "$root" rev-parse "$base^{commit}")
mkdir -p "$(dirname "$claim_dir")" "$worktree_root"
mkdir "$claim_dir" || { printf 'Issue %s was claimed concurrently.\n' "$issue" >&2; exit 1; }
if ! loop_clean_git -C "$root" worktree add -b "$branch" "$worktree" "$base_sha" >/dev/null; then
  rmdir "$claim_dir"
  exit 1
fi
cat >"$claim_dir/claim.env" <<EOF
issue=$issue
slug=$slug
builder=$builder
branch=$branch
worktree=$worktree
base_sha=$base_sha
EOF

printf 'issue=%s\nbranch=%s\nworktree=%s\nbase_sha=%s\n' \
  "$issue" "$branch" "$worktree" "$base_sha"
