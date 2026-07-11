#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
repo=${1:-${GITHUB_REPOSITORY:-}}

if [ -z "$repo" ]; then
  repo=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')
fi
case "$repo" in
  */*) ;;
  *)
    echo "Repository must be OWNER/REPO: $repo" >&2
    exit 2
    ;;
esac

for definition in "$root/.github/rulesets/main.json" "$root/.github/rulesets/tags-v.json"; do
  name=$(jq -r '.name' "$definition")
  ruleset_id=$(
    gh api "repos/$repo/rulesets" |
      jq -r --arg name "$name" '.[] | select(.name == $name) | .id' |
      head -n 1
  )
  if [ -n "$ruleset_id" ]; then
    echo "Updating ruleset $name ($ruleset_id) on $repo"
    gh api \
      --method PUT \
      "repos/$repo/rulesets/$ruleset_id" \
      --input "$definition" >/dev/null
  else
    echo "Creating ruleset $name on $repo"
    gh api \
      --method POST \
      "repos/$repo/rulesets" \
      --input "$definition" >/dev/null
  fi
done

gh api "repos/$repo/rulesets" \
  --jq '.[] | {id, name, target, enforcement}'
