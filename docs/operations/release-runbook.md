# Source Prerelease Runbook

This repository publishes a compact, source-only GitHub prerelease from an
annotated `v*` tag. The workflow uses free public GitHub runners and the
repository-scoped `GITHUB_TOKEN`. It does not require Apple credentials, paid
signing, TestFlight, notarization, or third-party release secrets.

## Release gate

Release only after all of the following are true:

1. The release commit is merged to `main` through a PR.
2. CI and Repository Policy are green at that commit.
3. An independent Checker has verified the latest PR SHA.
4. Known limitations and runtime evidence are recorded in the stage report or
   optional `docs/releases/<tag>.md` notes.
5. The rollback commit and last known good tag are known.

## Create the tag

Use an annotated, immutable semantic-style tag. Never reuse or move a published
tag.

```bash
git switch main
git pull --ff-only
git tag -a v0.1.0-alpha.1 -m "v0.1.0-alpha.1"
git push origin v0.1.0-alpha.1
```

Only `v*` tag pushes start `.github/workflows/release.yml`. The workflow rejects
lightweight tags, commits not reachable from `origin/main`, and tags that already
have a GitHub Release.

## Optional custom notes

Before tagging, add `docs/releases/<tag>.md` when the generic notes are not
enough. Keep it concise:

```markdown
# v0.1.0-alpha.1

## User-Testable Outcome

## Verification

## Known Limitations

## Runtime Evidence
```

The workflow appends immutable source, known-limitation, and rollback metadata.

## Published assets

- `<repository>-<tag>-source.zip`: archive made with `git archive` from the tag
  commit, without local or generated state.
- `RELEASE_NOTES.md`: custom or generic notes plus source and rollback evidence.
- `SHA256SUMS`: SHA-256 for the source archive and notes.

This slice intentionally does not publish a signed `.ipa`, notarized macOS app,
or TestFlight build. Add those only when a product has a real distribution need
and the user explicitly approves the account or payment boundary.

## Verify the release

```bash
gh release view v0.1.0-alpha.1
gh release download v0.1.0-alpha.1 --dir /tmp/template-release
cd /tmp/template-release
shasum -a 256 -c SHA256SUMS
```

## Rollback

Published tags and releases are immutable. Do not delete and recreate them to
hide a defect.

- Revert a shared bad commit with `git revert <sha>` and release a new tag.
- Inspect an old release with `git switch -c restore/<tag> <tag>`.
- Document the bad tag, replacement tag, affected behavior, and recovery steps
  in the next release notes and stage report.
