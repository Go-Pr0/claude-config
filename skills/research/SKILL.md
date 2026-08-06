---
name: research
disable-model-invocation: true
description: Multi-wave research pipeline: expansive early waves, cumulative research.md, sequential plan agents, plan closer. User-invoked only (/research). Default hold execution until the user asks to implement.
---

# /research

User-invoked only, as `/research`. This replaces the orchestrator's single research pass with multi-wave research and sequential planning. Everything else in `/orchestrator` still applies: role, autonomy, model routing, escalation, dispatch prompts, shells, and report.

Default: hold execution until the user explicitly asks to implement.

## Files

One dir per task: `plans/active/<topic>/`, created at invocation. Base layout and lifecycle: `~/.claude/contracts/artifacts.md`. The named slices and sequential plan files below are this skill's extension of it; do not multiply files beyond truly disjoint scopes.

| File | Writer |
|------|--------|
| `research.md` | `web-search-researcher`, one wave at a time, cumulative |
| `research-<slice>.md` | parallel researchers, disjoint scopes only |
| `plan.md` or `plan-<nn>-<slug>.md` | `web-search-planner` or `web-search-redesign-planner`, one per surface |

## Phase 1, research waves

Dispatch `web-search-researcher` with the topic dir, output file, wave number and title, prior files to read, repo scope, and done-when. Repo inspection is read-only.

Wave 1 is expansive: it maps the whole territory, repo state, comparables, every area to cover, open questions, and the agenda for later waves. Later waves go deep on one assigned slice and edit the same file. Run waves sequentially, at most two researchers in parallel and only on disjoint scopes, and never start wave N+1 while wave N is running.

Research is done when `Recommended direction` is stable, blocking open questions are listed, and a planner has enough to plan.

## Phase 2, plan waves

One planner per surface, chosen per the `/orchestrator` Pipeline table. Pass all research paths, all prior plan paths, the output path, and the surface it owns. Sequential: each planner extends, depends on, or supersedes the prior ones, never contradicts them. The planner decides bundling; a cleanup then greenfield then polish split is a suggestion, not a template.

## Phase 3, plan close

`web-search-plan-closer` over all plan paths plus all research files.

## Phase 4, report

Report the topic dir, a synthesis pointing at the files, the plan paths and their order, the decisions, and the open questions. Stop there unless the user asks to implement, then continue at `/orchestrator` Execution step 6. Held plans stay in `plans/active/` until executed.

Re-plan when research changes scope or the closer cannot reconcile the plans: re-dispatch the same agent type with the findings, close again, resume.
