# Apple App Template Agent Contract

- Work on one GitHub Issue in one `agent/<issue>-<slug>` branch and worktree.
- Never develop or push feature work directly on `main`.
- Keep the no-account, no-ad core usable and protect user data and rollback.
- Run risk-matched verification and leave concrete evidence before review.
- Builder and Checker identities must be independent.
- Create checkpoints explicitly only for clean, pushed, fully verified commits.
- Restore history into a new worktree. Never use destructive reset commands.
- Local hooks are fast feedback; repository policy and CI remain authoritative.
- Never commit credentials, provisioning profiles, cookies, tokens, or paid assets.
