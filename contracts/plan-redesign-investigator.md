# Redesign Investigation Plan Contract

`web-search-redesign-investigator` writes `plan.md` to this shape when bug or failure diagnosis requires redefining the broken foundation rather than patching today's shape. Block definitions, graph rules, and bans live in the spine: `~/.claude/contracts/plan.md`. Read both.

## Shape

```markdown
# <Topic>

## Symptoms
What fails, where, and how it is reproduced or observed.

## Facts                 (spine)

## Leading theory
Why the current model produces this failure, not only where the failure surfaces.

## Conceptual reading    (spine)

## Spec                  (spine, optional)

## Waves                 (spine)

## Deferred              (spine)
```

## Obligations

Hypotheses ruled out go in Deferred with the evidence that ruled them out.

Every wave Goal or Do traces to a `## Conceptual reading` bullet, never to "patch existing X".

Coherence is proven when Symptoms, Leading theory, Conceptual reading, and Waves tell one story: what is broken, what should replace it, then how this codebase gets there.

Rewriting an existing `plan.md` replaces it in place: same filename, old content deleted, no legacy waves.
