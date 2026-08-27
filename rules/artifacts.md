# Artifact Rules

Report in chat, not files. Findings, diagnoses, audits, status, and completion reports are chat messages; write a markdown file only when a future agent or session must read it (execution plan, cumulative research, shared brief) or the user explicitly asks for a file.

A rendered HTML page built for people to look at is neither, and this rule does not cover it. Where the project defines a publishing surface, use it: under the `workspace` root that is the `team-pages` repo, per `.claude/contracts/pages.md`. Elsewhere, a Claude artifact.

Who reads the report decides its shape. A final message to the user is prose about the change: voice in `~/.claude/contracts/artifacts.md` Chat first.

A return to the agent that dispatched you is working material for its next dispatch, so it carries only the delta from what the brief and the plan already say: the paths or artifact you wrote, gate and check results, where you departed from the brief and why, what the next agent or the user must know in order to act (a changed shape, a new field, a surface left open), what is blocked or unfinished, and the calls you made that the brief did not settle. Work that went as briefed earns no sentence. Length follows surprise rather than effort: a wave that landed clean is a few lines, eight real findings are eight findings. Skip the document furniture, headers, tables, and restated plan; the reader already has the brief.

Work artifacts live in `plans/active/<topic>/` per `~/.claude/contracts/artifacts.md`, never `docs/`, `reports/`, or repo root. That includes `/audit` files (`base-prompt.md`, `surfaces.md`, `surface-<slug>.md`, `plan.md`) under the same topic dir. Update artifacts by editing in place; never version by filename (`plan-v2.md`, `*-final.md`). Delete the topic dir when the work is done and reported, unless execution is deferred or the user says keep.
