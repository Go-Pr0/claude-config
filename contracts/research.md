# Research Contract

Machine-wide shape for cumulative `research.md`. `web-search-researcher` writes to this contract. Planners read its conclusions and cite them in `plan.md` Facts; they never copy the investigation into the plan.

Workspace, edit-in-place, and lifecycle: `~/.claude/contracts/artifacts.md`.

## Shape

```markdown
# <Topic>

## Status
Wave N, <short title>. Last pass: what this wave added or changed.

## Repo findings
What exists today, how it is wired, what is broken, redundant, or scheduled for
removal. Conclusions only.

## External reference
How comparable projects, libraries, or systems handle this. Primary sources preferred.

## Options
| Option | Pros | Cons | Fit |

## Recommended direction
What to do and why, for this project, its stack, and its agents.

## Constraints
Tradeoffs that bind the decision: performance ceilings, tooling limits, framework fit,
licensing, ops cost.

## Cleanup inventory
Dead code, unreferenced assets, redundant modules. Conceptual, not a file tree.

## Open questions
Blocking only.

## Sources
- [Title](url), one-line takeaway
```

## Rules

- Cumulative. Later waves edit and extend the same file. Read every prior research file in the topic dir before writing. Restart only when the dispatch says wave 1 reset.
- Wave 1 is expansive: map the whole territory and the agenda for later waves. Later waves go deep on the assigned slice.
- Split into `research-<slice>.md` only for truly disjoint parallel scopes.
- Conclusions and evidence summaries, never chat logs or raw search dumps.
- Every claim is actionable: it helps a planner choose approach, sequencing, or cleanup scope.
- Cite sources by link or primary name; label weak sources as secondary.
- No implementation code. Short snippets only for a non-obvious external API shape.
- No waves. Sequencing and execution belong in `plan.md`.
- Repo inspection is read-only unless the dispatch assigns a narrow mutating probe.
