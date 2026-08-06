---
name: memory-promote
disable-model-invocation: true
description: Promote an inbox capture or session extract into a compiled vault note on main. User-invocable only. Follows vault CLAUDE.md and CONTRACT.md for note prose and surfaces.
---

# /memory-promote

Promote an `inbox/` entry or session extract into a compiled vault note, commit on `main`, and push. Read `$TEAM_MEMORY_VAULT/CONTRACT.md` for the promote gate and link-integrity rules. Read `$TEAM_MEMORY_VAULT/CLAUDE.md` before writing note prose.

Work from the vault clone at `$TEAM_MEMORY_VAULT`. Pull `main` first. Compile the capture into the correct vault path (`team/`, `projects/`, `wiki/concepts/`, etc.). Update `INDEX.md` only when the new note needs a table-of-contents row.

Commit and push to `main`. No feature branch. No PR.

Never auto-promote from the capture hook. Never duplicate `gacha-functional` decision bodies; use pointer rows only.

Return the commit SHA and push result when done.
