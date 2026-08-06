# Plan Contract

Machine-wide spine for `plan.md`: the blocks every plan shares and the rules that govern them. Each planning agent reads its own contract for the sections it writes, then this file for what those sections mean.

| Agent | Contract |
|-------|----------|
| `web-search-planner` | `~/.claude/contracts/plan-planner.md` |
| `web-search-redesign-planner` | `~/.claude/contracts/plan-redesign-planner.md` |
| `web-search-investigator` | `~/.claude/contracts/plan-investigator.md` |
| `web-search-redesign-investigator` | `~/.claude/contracts/plan-redesign-investigator.md` |
| `web-search-plan-closer` | `~/.claude/contracts/plan-closer.md` |

Workspace, edit-in-place, and lifecycle: `~/.claude/contracts/artifacts.md`.

## What a plan says

A plan is the handoff between an agent that read the code and an agent that will change it. It says three kinds of thing, and they fail differently. Kept apart, a plan can be checked.

| Kind | What it is | How it fails | Where it lives |
|------|------------|--------------|----------------|
| Fact | The system as it is now | Wrong, or true when written and rotted since | `## Facts`, cited |
| Decision | What to build and what not to | Not wrong, only ill judged | the head sections your contract names |
| Instruction | What an implementer does | Incomplete: leaves a choice unmade | `## Waves` |

A fact stated inside an instruction is invisible and unfalsifiable. That is the most common way a well-formed plan is wrong.

Density is choices removed per token, not tokens spent. A long plan that leaves nothing to invent is dense. A short plan that leaves five choices open is deferred cost. Length is never the fault; an uncited claim or a repeated line is.

## Facts

Load-bearing claims about the current system. One line each, each ending in where it was read this session (`path`, or `path:symbol`). Research pointers live here too.

A claim earns a line only when a wave would be built wrong without it. These four are the ones missed most:

- The existing owner of a job the plan is about to specify a second time: timer, store, component, helper, string.
- The trigger path of any surface, state, or control the plan adds: what shows it, what hides it, what already shows the same fact. If the trace fails, the feature is wrong, not the trace.
- The repo invariants the plan's own Spec content must obey: data rules, copy rules, documented type contracts.
- The gates the touched surface crosses, including cross-cutting sweeps that live outside it.

Writing the citation is the check: you cannot write down where a mechanism already lives and then specify a second one.

Never write a remembered specific. A symbol, path, token, channel, or gate you did not read is delegated, not guessed: state the invariant and hand the mechanism to the implementer ("mechanism yours: no section renders an orphan label"). An honest delegation costs less than a plausible wrong specific and is the only thing that catches it.

## Spec

Optional. Subsections the planner names after the domain: layout, copy deck, state matrix, data derivations, wire shapes, schema deltas, rollout order, compatibility matrix, file inventory (keep / rewrite / new / delete).

A subsection earns its place when two waves reference it, or when it removes a choice an implementer would otherwise make. A file inventory here is the authoritative touch list; waves point into it instead of re-listing paths.

Shape only: tables, matrices, exact strings, orderings, geometry, short type sketches. No facts, they are cited above. No reasoning, it is decided in the head sections. A subsection of prose paragraphs is an essay and belongs in a head section as one line.

Omit the section entirely when the waves carry everything.

## Conceptual reading

Redesign plans only, placed before `## Waves`. The target model, never the current codebase:

- Entities, states, transitions, boundaries, invariants.
- What the current design must not keep.
- What transfers from alternatives and what you refuse.
- Deletion and replace stance.

Dense bullets, at most 40. No file paths, no current-code inventory, no bolt-on steps layered on today's shape. Long evidence stays in `research.md`. Every wave traces to a bullet here.

## Waves

Graph nodes. `Depends on` lines are the edges.

```markdown
### Wave N: <title>
- Goal:
- Touches: the write surface, precise enough that two waves can be compared for conflict. Paths allowed, edit scripts not.
- Depends on: none | Wave N
- Do: what changes. Name the mechanism wherever the outcome has more than one plausible shape and the choice touches a hot path, a shared invariant, or a gate; otherwise name the outcome and stop. Point into Spec rather than restating it. A bullet that states its outcome twice is missing its mechanism.
- Avoid: the specific wrong turns available in this scope. Each line is a defect that does not happen.
- Done when: observable from outside the wave.
- Verify: one fast local check drawn from the gates cited in Facts. The wave worker runs it.
- Close: yes | no.
```

- Few, large waves. One wave is one implementer and one dispatchable slice with a preferred-disjoint write scope. Merge anything that would always ship together.
- Flat only. No sub-waves, no nested IDs (1.1, 1.2), no wave that implies a second agent.
- Real edges only: producer to consumer, or a hard write conflict. Indirect or read-only overlap is not an edge. Anything not downstream of an unfinished wave dispatches at once. A false `Depends on` costs more than a merged wave.
- `Close: yes` means a landing gap here would poison a dependent wave. Whether a flag dispatches a closer is the consumer's policy, not the plan's.
- Full installs, full builds, e2e or full gates, watchers, and long sweeps are never a `Verify` line. They are a `command handoff` to the main session.

## Deferred

Everything deliberately not here, one line each with its reason: rejected options, out-of-scope surfaces, hypotheses ruled out and the evidence that ruled them out. A question that blocks the work is marked blocking.

## Never in a plan

- A remembered specific. Cite it or delegate it.
- An executive summary. The waves are the summary.
- Investigation transcript, evidence tables, provenance front matter. That is `research.md`.
- Full implementations, per-line edit scripts, tool step-by-step.
- Superseded content. A revision rewrites this file in place: no legacy waves, no changelog, no "previously".
- A rule another contract or a file in `~/.claude/rules/` already owns. Point at it, or leave it out.
