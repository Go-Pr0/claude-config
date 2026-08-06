# Redesign Plan Contract

`web-search-redesign-planner` writes `plan.md` to this shape for any ground-up redesign: architecture, pipeline, protocol, data model, API, infra, UX, or other. Block definitions, graph rules, and bans live in the spine: `~/.claude/contracts/plan.md`. Read both.

## Shape

```markdown
# <Topic>

## Intent
What is being redesigned, why, and the condition that says the new shape is done.

## Conceptual reading    (spine)

## Facts                 (spine)

## Decision
The chosen target model and what was ruled out, including the bolt-on and
extend-current options and why they fail.

## Spec                  (spine, optional)

## Waves                 (spine)

## Deferred              (spine)
```

## Obligations

State the target model from user intent before inspecting the codebase for constraints. Facts and Spec then ground it in this repo. Order matters: reading the current shape first is how a redesign turns into an extension.

Every wave Goal or Do traces to a `## Conceptual reading` bullet, never to "extend existing X".

Coherence is proven when Conceptual reading, Decision, and Waves tell one story: what should be, then how this codebase gets there.

Rewriting an existing `plan.md` replaces it in place: same filename, old content deleted, no legacy waves.
