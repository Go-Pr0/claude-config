---
name: research
disable-model-invocation: true
description: Multi-wave research pipeline — expansive early waves, cumulative research.md, sequential plan agents, plan closer. User-invoked only (/research). Default hold execution until the user asks to implement.
---

# Research workflow

User-invoked only. Run when the user explicitly invoked `/research`. Orchestrator handles the default single-pass path; this skill replaces it with multi-wave research and sequential planning.

Default: `hold execution` until the user explicitly asks to implement.

Do not combine with autonomous sprint unless the user explicitly wants research plus implementation in one run.

## Topic workspace

Every task uses one dir in the repo:

`plans/active/<topic>/`

Create at start. Subagents read and write artifact files there. The main session does not author artifact bodies.

| File | Writer | Purpose |
|------|--------|---------|
| `research.md` | `web-search-researcher` waves | Cumulative research; each wave edits prior content |
| `research-<slice>.md` | researcher (parallel only) | Disjoint slice when scopes do not overlap |
| `plan.md` / `plan-<nn>-<slug>.md` | `web-search-planner` | Execution contract(s); sequential planners read prior plan(s) |

Base layout, edit-in-place, and lifecycle: machine-wide `artifacts.md` at `~/.claude/contracts/` or `~/.codex/contracts/` (keep in sync). Named slices and sequential plan files are this skill's extended layout — still one topic dir, still edit-in-place per file; do not multiply files beyond truly disjoint scopes.

Shapes: machine-wide `research.md` at `~/.claude/contracts/` or `~/.codex/contracts/` (keep in sync), machine-wide `plan.md` at `~/.claude/contracts/` or `~/.codex/contracts/` (keep in sync).

## Pipeline

```text
1. RESEARCH WAVES (sequential; ≤2 parallel researchers per wave if disjoint)
2. PLAN WAVES (sequential planners; each owns a full surface)
3. PLAN CLOSE → web-search-plan-closer
4. REPORT
5. EXECUTION (when user asks) → orchestrator implementer waves from closed plan(s)
```

## Phase 1 — Research waves

Dispatch `web-search-researcher` with topic dir, output file, wave number/title, prior files to read, repo scope, done-when. Set `model` and `effort` per `/orchestrator` Model routing.

Repo inspection `read-only` by default. Date-stamp web-search queries.

Early waves are expansive. Wave 1 maps full territory — repo state, comparables, every area to cover, open questions, research agenda for later waves. Later waves go deep on assigned slices.

| Pattern | Rule |
|---------|------|
| Sequential (default) | Wave N+1 edits `research.md` from wave N |
| Parallel (≤2) | Disjoint scopes only |
| Repo audit | Redundant assets/modules, cleanup constraints, maintainability gaps |

Wait between waves. Research done when `Recommended direction` is stable, blocking `Open questions` listed, planners have enough to plan.

## Phase 2 — Plan waves

Dispatch `web-search-planner` per surface — all research paths, prior plan paths, output path, surface ownership. Set `model` and `effort` per `/orchestrator` Model routing. Follow machine-wide `plan.md` at `~/.claude/contracts/` or `~/.codex/contracts/` (keep in sync).

Sequential — extend, depend, or supersede; no conflicts. Planner decides bundling when user allows. Clean splits (cleanup → greenfield → polish) are a recommendation, not a template.

Planner escalates with findings instead of `plan.md` when root redesign is required.

## Phase 3 — Plan close

`web-search-plan-closer` — all plan paths + all research files → wait. Set `opus` + `high` by default; `opus` + `xhigh` when integration-heavy. Escalate if irreconcilable.

## Phase 4 — Report

Topic dir, synthesis pointing at files, plan paths and order, decisions, open questions. Stop here unless user asks to implement (orchestrator step 6+). Held plans stay in `plans/active/` until executed; after execution and verification the topic dir is deleted per artifacts lifecycle.

## Phase 5 — Execution

Orchestrator implementer waves from closed plan file(s). Do not pass `/research` to subagents.

## Escalation

Stop and re-plan when research changes scope, a planner escalates, or plan closer cannot reconcile plans without redesign. Fresh planner with findings → plan closer → resume.

## Boundaries

- No dependent wave N+1 while wave N runs.
- No implementation during research-only runs.
- Parallel researchers must not edit the same sections concurrently.

## Agents

| Phase | Agent | Output |
|-------|--------|--------|
| Research | `web-search-researcher` | `research.md` |
| Plan | `web-search-planner` | `plan.md` / `plan-<nn>-<slug>.md` |
| Plan close | `web-search-plan-closer` | edited plans |
| Execute | `web-search-implementer` | code |
| Wave close | `web-search-wave-closer` | code |
