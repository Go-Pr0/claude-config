# Artifacts

Canonical workspace and lifecycle for work artifacts in every repo. Skills and agents point here instead of restating it.

## Location

`plans/active/<topic>/`, one dir per task. `<topic>` is a short slug from user intent (`auth-refresh`, `search-index`, `cache-layer`). The main session creates it at task start; invoking an orchestrated skill is explicit permission. Subagents read and write artifact files inside it. The main session does not author `research.md`, `plan.md`, or audit surface-report bodies, with one exception: `/audit` writes `base-prompt.md` once as the shared dispatch brief. Git-track or gitignore per repo policy. No other artifact location: not `docs/`, not `reports/`, not repo root.

## Files

| File | Writer | Contract |
|------|--------|----------|
| `research.md` | `web-search-researcher` | `~/.claude/contracts/research.md` |
| `plan.md` | one planning agent, then `web-search-plan-closer` | `~/.claude/contracts/plan.md` and the per-agent contract its routing table names |

Two files is the whole default layout. Extended layouts stay under the same topic dir:

| Layout | Skill | Files |
|--------|-------|-------|
| Research | `/research` | `research-<slice>.md`, `plan-<nn>-<slug>.md` |
| Audit | `/audit` | `base-prompt.md` (main session once), `surfaces.md` (mapper), `surface-<slug>.md` (auditor), then `plan.md` |

`base-prompt.md` is the shared brief for parallel surface auditors: one file, pointed at from thin dispatches, never inlined. Surface report shape is the auditor's call; there is no machine-wide contract for it.

## Chat first

Chat is the default medium for every result: findings, diagnoses, audits, status, completion reports. A file exists only for content a future agent or session must read, meaning an execution contract, cumulative research, or a shared brief that several dispatch prompts would otherwise repeat. "The user might want this later" is not a consumer; the chat message is the record. Never write completion-report, summary, or root-cause markdown files unless the user asks for the file.

Completion reports speak plain language: what was wrong or missing before, what changed and why, what is true now. Factually exact, never agent jargon, and never a path dump, a check log, or a residual-risk checklist as the whole message.

## Edit in place

Updating an artifact means editing it: refine, extend, correct, delete stale sections. A full redesign rewrites the file in place: same filename, old content deleted, nothing legacy kept. Never version by filename (`plan-v2.md`, `research-final.md`, `plan-updated.md`) and never fork a new file to avoid merging into an existing one. A new file is justified only by a new consumer: the first `plan.md`, a truly disjoint parallel research slice, a shared brief read by three or more dispatch prompts.

## Lifecycle

`active/` means active. When the work is executed, verified, and reported, delete the topic dir in the same turn as the final report; the report and the diff are the record. Keep it only when the user says so or execution is deferred to a later session (held plans stay until executed). Stale topic dirs found at task start: ask once, then delete or resume.

## Dispatch

Every subagent dispatch names: topic dir, exact output file, prior artifact paths to read. Subagents write only their assigned file; everything else returns in the summary.
