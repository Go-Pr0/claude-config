---
name: audit
disable-model-invocation: true
description: Orchestrated codebase audit. Maps surfaces, deep-dives each surface, groups findings into a coarse plan.md, then refactors and fixes in the same session. User-invoked only (/audit). Never model-invoked. Invoked as /audit [target] [brief].
---

# /audit

User-invoked only, as `/audit [target] [brief]`. Never invoke this skill yourself and never let a subagent invoke it. Target is the repo, subsystem, pipeline, or scope the user named. Brief is optional intent, exclusions, and priors; reconstruct it from recent turns and the repo contract when absent.

You are the orchestrator for this pipeline. Everything in `/orchestrator` applies: role, autonomy, model routing, escalation, dispatch prompts, shells, and report. This file holds only what is specific to an audit. Do not author surface reports or `plan.md` bodies; workers write those.

Default: execute the fixes after plan close, in this same session. Hold only when the user asks for audit or plan only.

## Files

One dir per audit: `plans/active/<topic>/`, created at invocation. Layout and lifecycle: `~/.claude/contracts/artifacts.md`.

| Phase | Writer | File |
|-------|--------|------|
| Brief | main session, once | `base-prompt.md` |
| Map | `web-search-surface-mapper` | `surfaces.md` |
| Surface dive | one `web-search-auditor` per surface | `surface-<slug>.md` |
| Plan | `web-search-planner` | `plan.md` |
| Plan close | `web-search-plan-closer` | edited `plan.md` |
| Execute | `web-search-implementer` per wave | code |

`web-search-surface-mapper` and `web-search-auditor` are private to this skill.

## Base prompt

Write `base-prompt.md` once, before the surface dives. It is the shared stance every auditor applies, so each dispatch stays thin: point at this file, name the surface, give the output path. Never paste it into a brief.

Cover, in prose rather than an output skeleton: likely original intent versus observed behavior; whether the surface achieves what it is trying to do; layer and boundary fit; correctness; performance; security; efficiency. Findings only, no fixes during the audit phases. Point auditors at `~/.claude/rules/code.md` and `~/.claude/rules/deps.md` by path.

## Phases

1. Map. One `web-search-surface-mapper` on the target scope, done-when the conceptual surfaces are named. Surfaces are domains, subsystems, and layers, not a file tree. Re-dispatch once to merge if the map shatters into dozens of micro-surfaces. Wait.
2. Surface dives. One `web-search-auditor` per surface, in parallel since each owns its own `surface-<slug>.md`. Every brief: user intent quoted, path to `base-prompt.md`, surface name and scope from the map, exact output path, boundaries. Do not prescribe report shape. Wait for the ready set.
3. Plan. `web-search-planner` reads every `surface-*.md` and `surfaces.md` and groups findings by theme into `plan.md`. Batch hard: a handful of substantial waves that a few implementers can own, never thirty micro-waves. Wait.
4. Plan close. `web-search-plan-closer` on `plan.md`, with the surface reports as prior context. Wait.
5. Execute. Implementer waves greedy over the graph, per `/orchestrator` Execution step 6.
6. Report in chat and delete the topic dir, unless held or the user says keep.
