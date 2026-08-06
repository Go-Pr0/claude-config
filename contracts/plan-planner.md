# Feature Plan Contract

`web-search-planner` writes `plan.md` to this shape. Block definitions, graph rules, and bans live in the spine: `~/.claude/contracts/plan.md`. Read both.

## Shape

```markdown
# <Topic>

## Intent
What is being done, why, and the condition that says it is finished.

## Facts            (spine)

## Decision
The chosen approach and what was ruled out, with the reason. A decision that reverses
an existing default names the default it reverses. Pointers to `research.md` and the
binding house rules go in Facts, not here.

## Spec             (spine, optional)

## Waves            (spine)

## Deferred         (spine)
```

## Obligations

Plan inside the settled architecture. When the honest fix is to redefine entities, states, boundaries, or invariants for a surface, stop and escalate to the main session rather than writing a bolt-on plan; a redesign is `web-search-redesign-planner`'s shape.

On a sequential plan wave, read every prior `plan-*.md` and `plan.md` in the topic dir first. Extend or depend on them; never contradict one without an explicit supersede.

Rewriting an existing `plan.md` replaces it in place: same filename, old content deleted.
