# Research Contract

Machine-wide shape for cumulative `research.md`. Workspace: `plans/active/<topic>/` per `~/.claude/contracts/artifacts.md`. Research agents write to this contract. Planners read conclusions; they do not duplicate investigation transcripts in `plan.md`.

## Shape

- Cumulative — later waves edit and extend the same file(s); do not spawn parallel disconnected reports unless scopes are truly disjoint (then use named files, e.g. `research-texturing.md`).
- Conclusions and evidence summaries — not chat logs, not raw search dumps.
- Dense and complete — as long as needed to ground planners; no padding, no transcript.
- Actionable for this project — every section should help planners choose approach, sequencing, and cleanup scope.
- Cited sources — links or named primary sources; label weak sources as secondary.
- No implementation code — short snippets only for non-obvious external API shapes (optional).
- No plan waves — sequencing and execution belong in `plan.md`, not here.

## research.md shape

```markdown
# <Topic>

## Status
Wave N — <short title>. Last pass: <what this wave added or changed>.

## Repo findings
What exists today, how it is wired, what is broken, redundant, or scheduled for removal. Conclusions only.

## External reference
How comparable games, engines, or frameworks handle this. Primary sources preferred.

## Options
| Option | Pros | Cons | Fit |
Brief comparison table or dense bullets.

## Recommended direction
What we should do and why — for this project, its stack, and its agents.

## Performance and constraints
Tradeoffs that affect the decision (performance ceilings, tooling limits, framework fit, etc.).

## Cleanup inventory
Dead code, unreferenced assets, redundant modules — conceptual, not file trees.

## Open questions
Blocking only. Non-blocking gaps go in planner assumptions.

## Sources
- [Title](url) — one-line takeaway
```

## Research agent rules

- Read all prior research files in the topic dir before writing.
- Early waves are expansive — map full coverage and the research agenda; later waves go deep on assigned slices.
- Edit in place: refine, extend, correct — do not restart from scratch unless orchestrator says wave 1 reset.
- Repo inspection is `read-only` during research unless orchestrator explicitly assigns a narrow mutating probe.
- Date-stamp web-search queries with the current month and year.
- End with a short return summary: what changed in the file, what is still open, what the next wave should tackle.

## Validation

Malformed research (missing `Recommended direction`, no `Repo findings` after wave 1) → re-dispatch researcher with gap list; do not patch in the main session.
