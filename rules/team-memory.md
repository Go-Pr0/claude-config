# Team memory

Applies when `TEAM_MEMORY_VAULT` is set. Read `$TEAM_MEMORY_VAULT/CONTRACT.md` for surfaces, budgets, promote gate, and never-memorize rules. Write protocol lives in `$TEAM_MEMORY_VAULT/CLAUDE.md`.

Query protocol: read `$TEAM_MEMORY_VAULT/INDEX.md` first; then read at most four vault notes by path when the task needs detail; never dump the whole vault; abstain on git commands, shell-only prompts, and trivial edits.

Cursor: auto-inject of INDEX is unavailable. At session start, read `$TEAM_MEMORY_VAULT/INDEX.md` when the task needs team context.

Durable team facts go to `$TEAM_MEMORY_VAULT/inbox/` for capture, or invoke `/memory-promote` to compile and commit on vault `main`. Never write team facts to Claude Auto Memory.
