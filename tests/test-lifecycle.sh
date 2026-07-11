#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
TMP=$(mktemp -d "${TMPDIR:-/tmp}/loop-template-test.XXXXXX")
trap 'rm -rf "$TMP"' EXIT HUP INT TERM

clean_git() {
  env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE -u GIT_PREFIX \
    -u GIT_COMMON_DIR -u GIT_OBJECT_DIRECTORY \
    -u GIT_ALTERNATE_OBJECT_DIRECTORIES git "$@"
}

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_file() {
  test -f "$1" || fail "missing file: $1"
}

REMOTE="$TMP/remote.git"
REPO="$TMP/sample-app"
clean_git init --bare "$REMOTE" >/dev/null
clean_git clone "$REMOTE" "$REPO" >/dev/null 2>&1
clean_git -C "$REPO" switch -c main >/dev/null
clean_git -C "$REPO" config user.name "Loop Test"
clean_git -C "$REPO" config user.email "loop@example.com"
mkdir -p "$REPO/scripts" "$REPO/.loop" "$REPO/tests"
cp -R "$ROOT/scripts/loop" "$REPO/scripts/"
cp -R "$ROOT/.githooks" "$REPO/"
cp "$ROOT/.loop/project.yml" "$ROOT/.loop/project.schema.json" "$REPO/.loop/"
cp "$ROOT/AGENTS.md" "$REPO/"
printf 'sample\n' >"$REPO/README.md"
clean_git -C "$REPO" add .
clean_git -C "$REPO" commit -m "initial" >/dev/null
clean_git -C "$REPO" push -u origin main >/dev/null

if (cd "$REPO" && ./scripts/loop/claim.sh '../2' bad builder-a >/dev/null 2>&1); then
  fail "unsafe Issue claim succeeded"
fi

CLAIM_OUTPUT=$(cd "$REPO" && ./scripts/loop/claim.sh 2 lifecycle builder-a)
WORKTREE=$(printf '%s\n' "$CLAIM_OUTPUT" | sed -n 's/^worktree=//p')
BRANCH=$(printf '%s\n' "$CLAIM_OUTPUT" | sed -n 's/^branch=//p')
test "$BRANCH" = "agent/2-lifecycle" || fail "unexpected branch: $BRANCH"
test -d "$WORKTREE" || fail "claim did not create worktree"
test "$(clean_git -C "$REPO" branch --show-current)" = main || fail "claim switched stable checkout"
if (cd "$REPO" && ./scripts/loop/claim.sh 2 lifecycle builder-b >/dev/null 2>&1); then
  fail "duplicate claim succeeded"
fi

if (cd "$REPO" && ./scripts/loop/policy-check.sh direct-main >/dev/null 2>&1); then
  fail "direct-main guard allowed main"
fi
(cd "$WORKTREE" && "$REPO/scripts/loop/policy-check.sh" direct-main)

printf 'feature\n' >"$WORKTREE/feature.txt"
clean_git -C "$WORKTREE" add feature.txt
clean_git -C "$WORKTREE" commit -m "feat: lifecycle (#2)" >/dev/null
test -z "$(clean_git -C "$REPO" tag --list)" || fail "commit created an automatic tag"
if (cd "$WORKTREE" && LOOP_SKIP_INTEGRATION_TESTS=1 ./scripts/loop/checkpoint.sh 2 lifecycle >/dev/null 2>&1); then
  fail "checkpoint accepted an unpushed commit"
fi
clean_git -C "$WORKTREE" push -u origin "$BRANCH" >/dev/null
printf 'dirty\n' >"$WORKTREE/dirty.txt"
if (cd "$WORKTREE" && LOOP_SKIP_INTEGRATION_TESTS=1 ./scripts/loop/checkpoint.sh 2 lifecycle >/dev/null 2>&1); then
  fail "checkpoint accepted a dirty worktree"
fi
rm "$WORKTREE/dirty.txt"

TAG=$(cd "$WORKTREE" && LOOP_SKIP_INTEGRATION_TESTS=1 ./scripts/loop/checkpoint.sh 2 lifecycle)
test "$(clean_git -C "$WORKTREE" cat-file -t "$TAG")" = tag || fail "checkpoint is not annotated"
clean_git --git-dir="$REMOTE" rev-parse "$TAG^{commit}" >/dev/null

ACTIVE_BEFORE=$(clean_git -C "$REPO" branch --show-current)
RESTORE_OUTPUT=$(cd "$REPO" && ./scripts/loop/restore.sh "$TAG")
RESTORE_WORKTREE=$(printf '%s\n' "$RESTORE_OUTPUT" | sed -n 's/^worktree=//p')
test -d "$RESTORE_WORKTREE" || fail "restore worktree missing"
test "$(clean_git -C "$REPO" branch --show-current)" = "$ACTIVE_BEFORE" || fail "restore switched active worktree"
if (cd "$REPO" && ./scripts/loop/restore.sh HEAD >/dev/null 2>&1); then
  fail "restore accepted a mutable commit"
fi
clean_git -C "$REPO" tag lightweight HEAD
if (cd "$REPO" && ./scripts/loop/restore.sh lightweight >/dev/null 2>&1); then
  fail "restore accepted a lightweight tag"
fi

printf 'SECRET=sk-%s\n' 'abcdefghijklmnopqrstuvwxyz' >"$REPO/.env"
clean_git -C "$REPO" add .env
if (cd "$REPO" && ./scripts/loop/secret-scan.sh >/dev/null 2>&1); then
  fail "secret scan accepted a staged .env"
fi
clean_git -C "$REPO" restore --staged .env
rm "$REPO/.env"

REPORT=$(cd "$REPO" && ./scripts/loop/report-stage.sh alpha "Lifecycle ready")
assert_file "$REPO/$REPORT"

(cd "$REPO" && ./scripts/loop/bootstrap.sh >/dev/null)
test "$(clean_git -C "$REPO" config core.hooksPath)" = .githooks || fail "hooks were not installed"
zero=0000000000000000000000000000000000000000
if printf 'refs/heads/main %s refs/heads/main %s\n' "$zero" "$zero" | \
  (cd "$REPO" && ./.githooks/pre-push origin "$REMOTE" >/dev/null 2>&1); then
  fail "pre-push hook accepted direct main push"
fi

printf 'all lifecycle tests passed\n'
