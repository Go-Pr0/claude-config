# Artifacts

Canonical workspace and lifecycle for work artifacts in every repo. Skills and agents point here instead of restating it.

## Location

`plans/active/<topic>/`, one dir per planned task. `<topic>` is a short slug from user intent (`auth-refresh`, `search-index`, `cache-layer`). The main session creates it at task start; invoking an orchestrated skill is explicit permission. Subagents read and write artifact files inside it. The main session does not author `research.md`, `plan.md`, or audit surface-report bodies; `base-prompt.md`, the shared dispatch brief, is its own. Git-track or gitignore per repo policy. No other artifact location: not `docs/`, not `reports/`, not repo root.

## Files

| File | Writer | Contract |
|------|--------|----------|
| `research.md` | `web-search-researcher` | `~/.claude/contracts/research.md` |
| `plan.md` | one planning agent, then `web-search-plan-closer` | `~/.claude/contracts/plan.md` and the per-agent contract its routing table names |

Two files, plus the record below for more than one wave, is the default layout. Extended layouts stay under the same topic dir:

| Layout | Skill | Files |
|--------|-------|-------|
| Research | `/research` | `research-<slice>.md`, `plan-<nn>-<slug>.md` |
| Audit | `/audit` | `base-prompt.md` (main session once), `surfaces.md` (mapper), `surface-<slug>.md` (auditor), then `plan.md` |

`base-prompt.md` is one file, pointed at from thin dispatches, never inlined. Surface report shape is the auditor's call; there is no machine-wide contract for it.

## Progress record

A plan of more than one wave keeps a record beside it. The orchestrator owns it and every worker reads it first, so it says what is true now and nothing else.

| File | Writer | Holds |
|------|--------|-------|
| `base-prompt.md` | main session | The worker brief three or more dispatches share: read list, authority, hard rules, done, return |
| `progress.md` | orchestrator and the pass, only through `~/.claude/bin/progress` | `## Binding`, `## Open`, `## Landed`, one `### ` line per block |
| `progress/<UTC landing time YYYY-MM-DDTHHMMZ>-<slug>.md` | the landing worker | Its entry: what changed, checks with their numbers, deviations. One file per landing, so parallel landings never share one. Corrected in place, never moved |
| `archive.md` | `progress move` only | Moved blocks, byte for byte. Grep a heading, never read it whole |

A block is one line: `### ` plus at most 300 bytes of text. `progress add` takes the text and refuses more. The line says what is true and points at the entry that holds the detail. No story, no file list, no symbol, no number but a miss or a baseline.

- `## Landed`: `### Wave 7: cache layer landed; p99 41 ms against 30, Wave 9 owns it. progress/2026-11-03T1136Z-wave-7-cache-layer.md`. Every missed target and every waived or patched check is on this line.
- `## Binding`: a ruling, baseline, deviation or convention later waves must obey, naming what it binds: `### Waves 9-12: retries stay client-side; the gateway never retries.`
- `## Open`: an unresolved item and its owner: `### Flaky upload test: no owner yet.`

`~/.claude/bin/progress` writes the record: `add DIR binding|open|landed 'TEXT'`, `move FILE 'HEADING TEXT'...` (to `archive.md` beside FILE), `show DIR`, `list FILE`. A landing worker writes its entry and returns its landed line. The orchestrator adds that line and its rulings, and changes a block by `move` then `add`, so a superseded ruling leaves the index and stays on record.

- In a quoted argument, write an apostrophe as `'\''`.
- `HEADING TEXT` is fixed text inside one heading line, and a whole-line match wins: `Wave 1` also hits `Wave 10`, so write `### Wave 1:`.
- The three sections never move, only blocks.
- Never edit `progress.md` by hand: any line that is not a section or `### ` block stops every later `add` with exit 6.
- Read `moved N lines`: an unclosed fence makes a block run to end of file. The bytes stay in the archive, but the rest of the file left with it.
- Never pipe `move` through `head`: the blocks after the closed pipe stay unmoved.
- Exit 4 or 5 can leave the block in both files and a partial tail in the archive. Rerunning the blocks with no `moved` line is safe.

The pass runs when `progress add` says so: one `web-search-implementer`, beside any running wave, acting on no trigger its own `add` prints. It reads `progress.md`, moves every block nothing unlanded needs by that block's own text, and moves landed `### Wave` sections out of `plan.md`. A block stays while an unlanded wave depends on it or names it, an open item cites it, or it binds work not landed; in doubt it stays. A ruling a landed line or entry holds that still binds is added to `## Binding` before the line moves. The worker returns the sizes before and after and each `## Binding` block it moved.

The read list in `base-prompt.md` names the sections a worker needs, never a whole document of another topic, and never a re-read before each edit: Edit matches exact text and refuses a miss.

## Chat first

Chat is the default medium for every result: findings, diagnoses, audits, status, completion reports. A file exists only for content a future agent or session must read, meaning an execution contract, cumulative research, or a shared brief that several dispatch prompts would otherwise repeat. "The user might want this later" is not a consumer; the chat message is the record. Never write completion-report, summary, or root-cause markdown files unless the user asks for the file.

A completion report to the user speaks plain language: what was wrong or missing before, what changed and why, what is true now. Factually exact, never agent jargon, and never a path dump, a check log, or a residual-risk checklist as the whole message. A return to the agent that dispatched you is a different shape: `~/.claude/rules/artifacts.md`.

## Edit in place

Updating an artifact means editing it: refine, extend, correct, delete stale sections. A full redesign rewrites the file in place: same filename, old content deleted, nothing legacy kept. Never version by filename (`plan-v2.md`, `research-final.md`, `plan-updated.md`) and never fork a new file to avoid merging into an existing one. A new file is justified only by a new consumer: the first `plan.md`, a truly disjoint parallel research slice, a shared brief read by three or more dispatch prompts.

## Lifecycle

`active/` means active. When the work is executed, verified, and reported, delete the topic dir in the same turn as the final report; the report and the diff are the record. Keep it only when the user says so or execution is deferred to a later session (held plans stay until executed). Stale topic dirs found at task start: ask once, then delete or resume.

## Dispatch

Every subagent dispatch names: topic dir, exact output file, prior artifact paths to read. Subagents write only their assigned file; everything else returns in the summary, shaped per `~/.claude/rules/artifacts.md`.
