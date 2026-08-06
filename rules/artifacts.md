# Artifact Rules

Report in chat, not files. Findings, diagnoses, audits, status, and completion reports are chat messages; write a markdown file only when a future agent or session must read it (execution plan, cumulative research, shared brief) or the user explicitly asks for a file. Completion-report voice: `~/.claude/contracts/artifacts.md` Chat first.

Work artifacts live in `plans/active/<topic>/` per `~/.claude/contracts/artifacts.md` — never `docs/`, `reports/`, or repo root. That includes `/audit` files (`base-prompt.md`, `surfaces.md`, `surface-<slug>.md`, `plan.md`) under the same topic dir. Update artifacts by editing in place; never version by filename (`plan-v2.md`, `*-final.md`). Delete the topic dir when the work is done and reported, unless execution is deferred or the user says keep.
