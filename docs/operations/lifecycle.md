# Local Lifecycle

1. Bootstrap hooks once per clone.
2. Claim one Issue with `claim.sh`; duplicate Issues, branches, and paths fail.
3. Work only in the returned `agent/<issue>-<slug>` worktree.
4. Run fast, focused, or full verification according to risk.
5. Push the branch before creating an explicit annotated checkpoint.
6. Restore only an immutable annotated tag into a new worktree.
7. Use `report-stage.sh` for user-testable milestones.

No lifecycle script force-resets, rewrites shared history, switches the stable
checkout, deletes branches automatically, or creates a tag for every commit.
