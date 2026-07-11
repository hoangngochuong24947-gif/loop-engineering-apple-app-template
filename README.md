# Loop Engineering Apple App Template

This public template combines a useful iOS 18+ local QuickNote app with lean
Loop Engineering governance. The app captures, lists, completes, and
soft-deletes notes with Undo and JSON persistence. Its App Shortcut can capture
a note without opening the app. The core has no account, ads, analytics,
network dependency, or collected data.

Generate and verify the Apple project:

```sh
xcodegen generate
xcodebuild test -project QuickNote.xcodeproj -scheme QuickNote \
  -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO
```

The lifecycle keeps `main` stable, gives each Builder one Issue worktree,
records explicit verified checkpoints, and restores immutable tags without
changing the active checkout:

```bash
./scripts/loop/bootstrap.sh
./scripts/loop/claim.sh 123 planner-preview builder-a
./scripts/loop/verify-focused.sh
./scripts/loop/checkpoint.sh 123 planner-preview
./scripts/loop/restore.sh checkpoint/123-planner-preview/UTC-SHA
```

Local hooks are fast feedback. There is deliberately no post-commit hook and no
automatic tagging. Checkpoints require a clean, pushed feature SHA and full
verification. Restore accepts annotated tags only and creates a separate
`restore/...` worktree.

Run the shell integration suite with `./tests/run.sh`.
