# Investigation Plan Contract

`web-search-investigator` writes `plan.md` to this shape for bugs and failures whose fix fits inside the settled framework. Block definitions, graph rules, and bans live in the spine: `~/.claude/contracts/plan.md`. Read both.

## Shape

```markdown
# <Topic>

## Symptoms
What fails, where, and how it is reproduced or observed.

## Facts             (spine)

## Leading theory
The current best explanation and the evidence for it. Cite the evidence in Facts and
point at it; the theory itself is one paragraph of judgment.

## Spec              (spine, optional)

## Waves             (spine)

## Deferred          (spine)
```

## Obligations

Hypotheses ruled out go in Deferred, each with the evidence that ruled it out. A hypothesis with no evidence against it is still open and belongs in Leading theory or in a wave that tests it.

Waves repair or replace modules inside the current system model. When the honest fix redefines entities, states, boundaries, or invariants for a surface, stop and escalate to the main session; that is `web-search-redesign-investigator`'s shape.

Rewriting an existing `plan.md` replaces it in place: same filename, old content deleted.
