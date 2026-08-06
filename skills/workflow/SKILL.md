---
name: workflow
description: Execution checklists for planner, investigator, implementer, plan closer, and wave closer — surface prep, orchestrator boundaries, wave-close heuristics, and wave discipline. Loaded by those agents via agent frontmatter.
---

# Workflow

Execution guidance for planner, investigator, implementer, plan closer, wave closer, and orchestrator boundaries. Project contracts and standards live in the repo (and `~/.claude/contracts/` when present) — ports, invariants, gates, and First-reads indexes. This skill holds execution checklists beyond that.

## Surface prep

Before editing, read the relevant standards and contract docs for the surface you touch (project `AGENTS.md`, module READMEs, active plan docs, etc.). Follow the repo's `First reads` index when one exists.

## Orchestrator boundaries

The orchestrator manages lifecycle and dispatch; source and asset mutations stay in implementer and closer waves. The repo contract owns project-specific commands.

Assign visual, runtime, or integration verification only when explicitly needed; default is user-owned at task end.

## Nested agents

Do not spawn subagents. Exception — planner and investigator only: may spawn `web-search-researcher` when external facts are blocking and you cannot finish without them. Never spawn implementers, closers, planners, reviewers, or ad-hoc natives. Implementer, plan closer, wave closer, researcher, and reviewer: never spawn anyone (researcher included — no researcher→researcher) — do the work yourself or escalate to the main session.

## Wave Close heuristics

Set `Close:` yes on waves that cross modules, wire integration surfaces, or span multiple stacks — anywhere landing gaps would poison the next wave. Default no on isolated edits. `Close:` marks integration risk.

Whether a closer runs is consumer policy, not this skill: personal `/orchestrator` keeps closers sparse (~5%); the board ticket engine (`.claude/boards/engine/control-plane.md`) dispatches one closer per every `Close: yes` group. Workers do not second-guess the dispatch.

## Wave discipline

- Stay synchronous. Everything you run, runs to completion in the foreground. Never background a process and return early — your return signals the scope is free, and an orphaned loop races the next agent's identical run. If a run cannot finish in your window, kill it and report exactly where it stood.
- Long shell commands — hand off, never run. Full installs, full builds, e2e/full gates, watchers, long sweeps stay with the main session. Finish your edit/analysis work first. Put a `command handoff` in your return summary — small if more wave work remains after the run, large if the wave is otherwise done and only the command remains. Include: exact command(s); cwd; env only if non-obvious; monitor (success/fail output patterns or exit expectations); what the main session should do after (resume you / mark wave done / unblock dependents). Never accept a dispatch that assigns the long run to you — refuse and hand it back. Short local checks you can finish quickly (including tests) stay yours and run synchronously in the foreground — those results are the wave's verification; the main session must not re-run them.
- One plan wave = one substantial slice; preferred-disjoint write scope. Never revert unrelated work.
- Small, reviewable changes. No generated/temp files in source unless the plan requires them.
- Implementer ships the wave slice; patch prior-wave gaps when the dispatch says so. Wave closer only when the orchestrator dispatches one.

## Plan graph (planner / investigator / plan closer)

Maximize parallelism: few large flat waves, no sub-waves or nested IDs. `Depends on` only for true producer→consumer or hard write conflicts — never to dodge indirect overlap. Merge undersized or always-together waves; cut false edges.
