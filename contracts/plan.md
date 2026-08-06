# Plan Contract

Machine-wide shape for `plan.md`. Planners and investigators write to this contract. The orchestrator treats `plan.md` as the execution contract: a dependency graph of waves, one `web-search-implementer` per wave, dispatched greedily as dependencies land; `web-search-wave-closer` only for ultra-critical waves (~5%) per `/orchestrator`.

## Shape

- Wave-centric. The `## Waves` section is the body of the plan.
- Waves are graph nodes. `Depends on` lines are the edges — real producer→consumer dependencies only (B cannot start until A's outputs exist). False edges serialize the graph; anything not downstream of an unfinished wave dispatches in parallel.
- Maximize parallelism. Do not add `Depends on` to avoid indirect or read-only overlap — that overlap is fine. Serialize only for hard write conflicts or true data dependencies.
- Few, large waves. A wave is one implementer's substantial logical chunk — a domain/surface slice with real work, not a step or checklist item. Prefer fewer, larger waves over a fine graph. Merge anything that would always ship together; split only on a hard write conflict or a true dependency.
- Flat graph only. No sub-waves, no nested numbering (1.1 / 1.2), no wave that spawns further agents. One wave = one implementer.
- Current design only. The plan holds what is being, about to be, or has been implemented — nothing legacy. A redesign rewrites `plan.md` in place: same filename, old content deleted, no superseded waves, no changelog, no "previously" sections.
- Scope is domain/surface first — not a file tree or path inventory. Landmark modules or paths are allowed when naming them prevents the wrong surface; do not enumerate every touch point.
- Dense and complete — as long as needed to cover the surface; no padding, no transcript. Extra tokens are for hard constraints, not restating Intent or padding `Do`.
- Carry enough conceptual how that a strong implementer does not re-derive the approach. Prefer precise invariants, ordering, failure modes, and key shapes over soft prose. Short snippets only when they beat a longer explanation (API/type/protocol shape, state transition, non-obvious invariant) — never full implementations or per-file edit scripts. Implementers still read the repo for exact files and wiring.
- No investigation transcript — conclusions and decisions only. Discovery stays in the agent read phase or in `research.md`.
- One wave = one dispatchable slice with a preferred-disjoint write scope (hard write conflicts force a split or edge; indirect overlap does not).

## Feature plan shape

```markdown
# <Topic>

## Intent
What we are doing, why, and how we know it is done.

## Context
Pointers only: `research.md`, relevant subsystems, constraints.

## Decision
Chosen approach and what we ruled out.

## Waves

### Wave 1: <title>
- Goal:
- Scope: domain/surface — optional landmark modules/paths when ambiguity would cost the wrong surface; never a file inventory
- Depends on: none | Wave N
- Do: dense bullets — what to change and how (approach, invariants, ordering, key shapes). Spend length on constraints the implementer must not reinvent; skip restating Goal/Intent
- Avoid:
- Done when:
- Verify: named check or command — focused and fast, local to the wave; the wave worker runs it. Full installs, full builds, e2e/full gates, watchers, long sweeps → `command handoff` to the main session. Short tests are never a handoff and are never re-run by the orchestrator.
- Close: yes | no — marks integration-heavy waves where landing gaps are costly. Does not auto-dispatch wave closer; default landing is the next implementer or a fixup. Wave closer only when ultra-critical per `/orchestrator`.
  Optional group form `Close: yes (group: <slug>)` — waves sharing a slug are closed together by ONE wave closer covering the whole group, dispatched once every wave in it has returned; a consumer that ignores groups reads it as plain `Close: yes`.
  Whether a `Close:` flag dispatches a closer at all stays consumer policy — `/orchestrator` remains sparse; another consumer may mandate one per flag.

### Wave 2: ...

## Open questions
Blocking only.

## Out of scope
```

## Investigation plan shape

Same `## Waves` block. Replace Intent/Context/Decision with:

```markdown
## Symptoms
## Leading theory
## Hypotheses ruled out
## Waves
```

## Anti-patterns

- Architecture essays before waves
- Executive summaries restating the waves — the waves are the summary
- Long "current system" dumps, evidence tables, or API-verification transcripts that belong in `research.md` — a pointer, not a copy
- Provenance front-matter (commit SHAs, clone paths, investigation dates)
- Long code dumps or full-function implementations (short shape/invariant snippets are fine)
- Per-file edit instructions or touch-list inventories across the repo
- Soft essay `Do` that restates Intent without adding constraints
- Tool/editor step-by-step scripts (name constraints in `Avoid` if needed)
- Versioned filenames — revisions edit `plan.md` in place per `~/.claude/contracts/artifacts.md`
- Superseded or legacy content kept for history — a redesign wholly replaces the file
- Step-sized or undersized waves; chains of `Depends on` that are really one slice
- Sub-waves, nested IDs (1.1, 1.2), or one wave that implies a second agent
- `Depends on` added only to avoid indirect or read-only overlap
- Waves adding unrequested safety modes or fallback scaffolding (paper/dry-run/mock modules) — per `~/.claude/rules/code.md` Defensive code
- Waves that bump dependency or runtime versions unless the user asked — per `~/.claude/rules/deps.md`

## Routing

Workspace: `plans/active/<topic>/plan.md` per `~/.claude/contracts/artifacts.md`.

Malformed plans after plan closer (missing `## Waves`, waves without disjoint scope or done-when) → re-dispatch planner/investigator.

Root-redesign escalation → fresh planner with findings → plan closer → implement.
