---
name: audit
disable-model-invocation: true
description: Orchestrated codebase audit — map surfaces, deep-dive each surface, group findings into a coarse plan.md, then refactor/fix in the same session. User-invoked only (/audit). Never model-invoked. Invoked as /audit [target] [brief].
---

# /audit

User-invoked only. Never invoke this skill yourself and never let a subagent invoke it. Invoked as `/audit [target] [brief]`. Target: repo, subsystem, pipeline, or scope the user named. Brief: optional intent, exclusions, priors — reconstruct from recent turns and the repo contract when absent.

You are the orchestrator for this pipeline — intent translator and dispatcher, not implementer. Do not spawn an orchestrator subagent. Do not pass this skill to subagents. Do not edit application source in the main session. Do not author surface reports or `plan.md` bodies — workers write those.

Default: execute after plan close in this same session. Hold only when the user explicitly asks audit/plan only.

## Topic workspace

Every audit uses one dir in the repo:

`plans/active/<topic>/`

Create it at the start — invoking `/audit` is explicit permission. Layout, edit-in-place, and lifecycle: machine-wide `artifacts.md` at `~/.claude/contracts/` or `~/.codex/contracts/` (keep in sync). This skill's extended files:

| File | Writer | Purpose |
|------|--------|---------|
| `base-prompt.md` | Main session (once) | Shared audit brief for every surface dive |
| `surfaces.md` | `web-search-surface-mapper` | Conceptual surface inventory |
| `surface-<slug>.md` | `web-search-auditor` (one per surface) | Findings for that surface |
| `plan.md` | `web-search-planner` | Execution graph after grouping reports |

Main session writes only `base-prompt.md`. Everything else is a worker output. Chat carries the final report; delete the topic dir when execution finishes unless the user says keep or held the run.

## Base prompt

Write `base-prompt.md` once before surface dives. It is the shared brief — stance, lenses, and constraints every surface auditor must apply — so each dispatch stays thin: point at this file, name the surface, give the output path. Do not paste the base prompt into every brief.

Cover in the base prompt (prose, not an output skeleton): likely original intent vs observed behavior; whether the surface achieves what it is trying to do; layer and boundary fit (does this logic belong here); correctness; performance; security; efficiency. Findings only — no fixes in audit phases. Point auditors at `~/.claude/rules/code.md` and `~/.claude/rules/deps.md` by path; do not restate them.

## Pipeline

```text
1. MAP → web-search-surface-mapper → surfaces.md
2. SURFACE DIVES → one web-search-auditor per surface → surface-<slug>.md
3. PLAN → web-search-planner groups themes → plan.md (few large waves)
4. PLAN CLOSE → web-search-plan-closer
5. EXECUTE → web-search-implementer waves (greedy graph)
6. VERIFY + REPORT → delete topic dir
```

## Phase 1 — Map

Dispatch one `web-search-surface-mapper` with topic dir, output path `surfaces.md`, target/scope, done-when = conceptual surfaces named. Set `opus` + `high`. Wait.

Surfaces are domains/subsystems/layers — not a file tree. If the map is too fine (dozens of micro-surfaces), re-dispatch once to merge before diving.

## Phase 2 — Surface dives

Write `base-prompt.md` if not already written. Dispatch one `web-search-auditor` per surface from `surfaces.md`. Parallel when write scopes are disjoint (each owns its own `surface-<slug>.md`). Every brief: user intent quoted; path to `base-prompt.md`; surface name and scope from the map; exact output path; boundaries; done-when = findings written. Set `model` and `effort` per Model routing below. Wait for the ready set.

Do not prescribe report shape. Do not pre-read or summarize evidence files — pass paths through.

## Phase 3 — Plan

Dispatch `web-search-planner` with topic dir, all `surface-*.md` paths, `surfaces.md`, output `plan.md`. Brief: read every surface report; group findings by section or theme; write a wave-centric `plan.md` per `~/.claude/contracts/plan.md` (or Codex twin). Batch hard — few large waves that a handful of implementers can own (merge same theme/section; never emit a fine graph of ~30 micro-waves when ~7 substantial slices would suffice). Maximize parallelism only for real independence; `Depends on` only for producer→consumer or hard write conflicts. Set `model` and `effort` per `/orchestrator` Model routing. Wait.

Planner returns findings instead of `plan.md` only when the brief cannot be planned honestly. Stop, re-dispatch the same type with findings (or switch type only per `/orchestrator` Plan routing), then closer.

## Phase 4 — Plan close

`web-search-plan-closer` on `plan.md` (and surface reports as prior context to read). Default `opus` + `high`; `opus` + `xhigh` when cross-module or high-blast. Wait. Escalate if irreconcilable.

## Phase 5 — Execute

Treat closed `plan.md` as the execution contract. Run implementer waves like `/orchestrator` Execution step 6: greedy over `Depends on`, one `web-search-implementer` per wave, dispatch the entire ready set together, harvest command handoffs in the main session, resume once for a small appendix or fresh fixup otherwise. `web-search-wave-closer` only for ultra-critical `Close:` yes waves (~5%). Model and effort per `/orchestrator` Model routing.

## Phase 6 — Report

No orchestrator verification pass. Trust worker Verify; run only returned long-running command handoffs. Final chat report per `/orchestrator` Report. Delete the topic dir with the final report unless held or the user says keep.

Commit, stage, or push only when the user explicitly asks.

## Model routing

Always set `model` and `effort` explicitly.

| Agent | Model | Effort | Use |
|-------|-------|--------|-----|
| `web-search-surface-mapper` | `opus` | `high` | Default map |
| `web-search-auditor` | `opus` | `high` | Default per surface |
| `web-search-auditor` | `opus` | `xhigh` | Extreme cross-cutting or high-blast surface after high under-reasoned |

Planner, plan closer, implementer, wave closer: follow `/orchestrator` Model routing.

## Escalation

Stop implementers on a bad plan. Re-dispatch the same planning agent with findings quoted verbatim (switch type only per `/orchestrator` Plan routing) → plan closer → implement only after closer passes. Tell the user when scope materially changes.

## Dispatch prompts

Intent quoted; topic dir; prior artifact paths to read; exact output path; boundaries; done-when; `model` and `effort` set. Surface dives point at `base-prompt.md` — do not inline it. Expected return: artifact path for writers, changed paths for implementers/closers, findings on escalation.

Never suggest implementation steps to mappers, auditors, or the planner. Never assign long-running shell commands to workers — command handoff only. Do not pass `/audit`, `/orchestrator`, `/research`, or `/review` to subagents. Trust summaries; re-read artifacts only on conflict or high-risk claims.

## Agents

| Phase | Agent | Output |
|-------|--------|--------|
| Map | `web-search-surface-mapper` | `surfaces.md` |
| Surface | `web-search-auditor` | `surface-<slug>.md` |
| Plan | `web-search-planner` | `plan.md` |
| Plan close | `web-search-plan-closer` | edited `plan.md` |
| Execute | `web-search-implementer` | code |
| Wave close | `web-search-wave-closer` | code |

`web-search-surface-mapper` and `web-search-auditor` are skill-private — only this skill dispatches them.
