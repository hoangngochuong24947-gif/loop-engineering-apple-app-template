#!/bin/sh

loop_clean_git() {
  env -u GIT_DIR -u GIT_WORK_TREE -u GIT_INDEX_FILE -u GIT_PREFIX \
    -u GIT_COMMON_DIR -u GIT_OBJECT_DIRECTORY \
    -u GIT_ALTERNATE_OBJECT_DIRECTORIES git "$@"
}

loop_root() {
  common=$(loop_clean_git rev-parse --git-common-dir 2>/dev/null) || {
    printf 'Not inside a Git repository.\n' >&2
    return 1
  }
  case "$common" in
    /*) ;;
    *) common="$(pwd)/$common" ;;
  esac
  common=$(CDPATH= cd -- "$(dirname "$common")" && pwd)/$(basename "$common")
  if test "$(basename "$common")" = .git; then
    dirname "$common"
  else
    loop_clean_git rev-parse --show-toplevel
  fi
}

loop_checkout_root() {
  loop_clean_git rev-parse --show-toplevel
}

loop_default_branch() {
  root=$1
  value=$(sed -n 's/^  default_branch:[[:space:]]*//p' "$root/.loop/project.yml" | head -1)
  printf '%s\n' "${value:-main}"
}

loop_safe_name() {
  value=$1
  case "$value" in
    ''|[!A-Za-z0-9]*|*[!A-Za-z0-9._-]*) return 1 ;;
    *) return 0 ;;
  esac
}

loop_repo_name() {
  basename "$1"
}

loop_worktree_root() {
  root=$1
  repo=$(loop_repo_name "$root")
  parent=$(CDPATH= cd -- "$root/.." && pwd)
  printf '%s/.worktrees/%s\n' "$parent" "$repo"
}

loop_require_clean() {
  root=$1
  test -z "$(loop_clean_git -C "$root" status --porcelain=v1)" || {
    printf 'Working tree must be clean.\n' >&2
    return 1
  }
}

loop_branch() {
  loop_clean_git -C "$1" branch --show-current
}
