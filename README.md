# Loop Engineering Apple App Template

Lean local governance for one Apple app repository. It keeps `main` stable,
gives each Builder one Issue worktree, records explicit verified checkpoints,
and restores immutable tags without changing the active checkout.

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
