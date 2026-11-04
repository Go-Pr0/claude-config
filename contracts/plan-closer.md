# Plan Close Contract

`web-search-plan-closer` edits `plan.md` until it satisfies this file. Block definitions, graph rules, and bans live in the spine: `~/.claude/contracts/plan.md`; the head sections come from the contract of whichever agent wrote the plan, named in the spine's routing table. Read the spine, that agent's contract, the plan, and the linked `research.md`.

## Check the facts first

`## Facts` is the falsifiable surface and the cheapest place to catch a defect. Open every citation and confirm the claim. Then sweep the rest of the plan for claims that never reached Facts:

- A named symbol, path, token, channel, or gate that appears only in `Do` or `Spec`. Verify it and move it to Facts, or convert it to a delegated invariant.
- A new mechanism specified where one already exists. Cite the owner and reuse it.
- An added surface, state, or control with no traced trigger. Trace it; a surface nothing reaches is a wave to delete, not a line to reword.
- Spec content that breaches a documented repo invariant: copy decks, shape snippets, and layout values are checked like code.
- A `Verify` line naming a gate the repo does not have, or omitting a cross-cutting sweep the wave's `Touches` would trip.

An uncited load-bearing claim is a defect even when it turns out to be true.

## Then the judgment

- Graph: cut false `Depends on`, merge undersized or always-together waves, flatten sub-waves and nested IDs.
- `Do`: an outcome with more than one plausible shape, touching a hot path, a shared invariant, or a gate, owes a mechanism. Add it.
- `Touches`: precise enough to compare two waves for write conflict.
- `Done when`: observable from outside the wave. `Close:` set on waves whose landing gap would poison a dependent wave.
- `Deferred`: every line carries its reason; blocking questions marked.
- Coherence across sequential plan files: no contradictions, nothing material missing, waves attack root causes.
- Strip legacy content, restated rules, and executive summaries.

Do not re-litigate decisions already grounded in research unless you find a concrete error. Do not expand scope beyond user intent.

## Escalate instead of closing

When honest planning needs a root redesign beyond editing these files, wrong foundation at subsystem level, stop editing and return findings with what must change. The main session dispatches a fresh planner. Never patch forward.
