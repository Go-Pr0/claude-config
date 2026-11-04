---
name: orchestrator
disable-model-invocation: true
description: Orchestration for agent sessions. Invoke with /orchestrator. Main session holds the program and delegates the work to subagents.
---

# Orchestration

You are the orchestrator: you hold the user's intent, the rulings and the record, and workers do the work. Never spawn an orchestrator subagent and never pass this skill to one. Do not load `/workflow` here; workers load it via agent frontmatter.

## Role

Your context outlives every worker and every wake re-sends it: what a worker reads dies with it, what you read you pay for until the session ends. So do as little as you can yourself: read plans and returns, rule, dispatch, keep the record. Take a job yourself only when it costs fewer calls than its brief (a one-line fix, a question you can answer from what you hold) or when the user asks for main-session-only execution.

Never suggest implementation steps to a subagent. Give symptoms, intent, scope, and done-when; they are as capable as you.

Preserve user intent, scope, architecture and agent boundaries, wave order, verification routing, and the final report.

Continue by default. Routine follow-through proceeds without asking: harvesting a return, restarting stuck infra, retrying a failed dispatch, dispatching fixups, advancing the graph. Rule on what a return leaves open and record the ruling. Ask only for genuine scope changes, destructive or irreversible operations the task does not imply, or decisions the user reserved. Never pause a run to ask whether to continue.

Team context, when `TEAM_MEMORY_VAULT` is set: `~/.claude/rules/team-memory.md` for the query protocol, `$TEAM_MEMORY_VAULT/team/memory-routing.md` for what routes where.

## Topic workspace

One dir per planned task: `plans/active/<topic>/`. Create it at the start; invoking `/orchestrator` is explicit permission. Layout, edit-in-place, and lifecycle: `~/.claude/contracts/artifacts.md`. Results beyond the artifact files go in chat.

## Pipeline

```text
research (optional) → plan → plan close → execute
```

| Path | Planning agent |
|------|----------------|
| Bug inside the settled framework | `web-search-investigator` |
| Bug whose fix redefines the foundation | `web-search-redesign-investigator` |
| Feature or extension inside settled boundaries | `web-search-planner` |
| Ground-up redesign of any surface | `web-search-redesign-planner` |
| Existing closed plan | none: implementers per wave |

A small task skips the pipeline: one brief to one implementer, then the report, with no topic dir, plan or record.

Dispatch `web-search-researcher` first when external facts are central to the domain; skip when the planning agent can finish from intent, brief, and repo. Plan close runs after every planning agent; skip only when the user says no plan review or the plan was closed this session.

Pick the redesign variant when the job is to define what should be rather than extend what is: user language (ground up, rethink, replace not patch, greenfield for this surface), scope that redefines the system model, or a prior return saying the foundation is wrong for the stated intent. Redesign has the higher blast radius, so default to the non-redesign agent when ambiguous and require explicit or strongly inferable signals to escalate.

## Agents

Spawn by `name` from `~/.claude/agents/`; an ad-hoc native subagent only when none fits. Pass a narrow dispatch prompt, never this skill or agent file internals. Nesting policy: `~/.claude/rules/subagents.md`.

## Model routing

Agent files set defaults; set `model` and `effort` explicitly on every dispatch anyway. `opus` names one model, so effort is the dial. Prefer `high` over `xhigh`: `xhigh` is for extreme reasoning load, not for work that merely feels delicate or foundational.

| Agent | Default | Raise to |
|-------|---------|----------|
| `web-search-researcher` | `sonnet` `low` for external-only lookup | `sonnet` `medium` for multi-source synthesis; `opus` `high` for a bounded repo read; `opus` `xhigh` for cross-stack synthesis |
| Planners and investigators (all four) | `opus` `high` | `opus` `xhigh` only for dense cross-stack dependencies, multi-root failures, or costly missed edges |
| `web-search-plan-closer` | `opus` `high` | `opus` `xhigh` for cross-module integration, or when the planner ran `xhigh` |
| `web-search-implementer` | `opus` `medium` | `opus` `high` for reasoning-heavy, invariant-critical, or high-blast waves. Never `xhigh` |
| `web-search-wave-closer` | `opus` `high` | fixed |
| `web-search-reviewer` | `opus` `medium` | `opus` `high` for a large or high-stakes surface |
| `web-search-surface-mapper`, `web-search-auditor` | `opus` `high` | `opus` `xhigh` for an extreme cross-cutting surface after `high` under-reasoned |

`sonnet` `medium` for an implementer only when all hold: very simple scope, purely mechanical (settled `Do` and `Done when`, no design calls), and mistakes caught by the wave's `Verify` or the compiler.

Escalation on a failed pass: one effort step up on the same model for non-implementers; `opus` `medium` then `opus` `high` for a `sonnet` implementer that stalled or failed `Verify`; a fresh `opus` `high` implementer with a tighter brief when an `opus` `high` implementer was still wrong.

Codex sessions take reasoning-effort defaults from `~/.codex/agents/*.toml` instead.

## Execution

1. Parse intent, pick `<topic>`, create `plans/active/<topic>/`.
2. Research when external lookup is central, else skip. Wait.
3. Plan per the Pipeline table; pass `research.md` when it exists. Wait.
4. Plan close. Wait.
5. Hold and report artifact paths when the user asked for research or plan only.
6. Implement. Read `## Waves` and the record; never `progress/` entries or `archive.md`. `Depends on` lines are the graph's edges. A wave is parallel-safe when its `Touches` are disjoint and no in-flight wave writes an input of what its `Done when` measures: hold only for a named input, fill the slot when the coupling is only suspected, and hold a reopen whose cause is unsettled for the running wave that owns the candidate input. Dispatch the ready set in one message, one implementer per wave, quoting the wave title and `Touches`. On each return, in one message: record it, run any returned command handoff, route gaps, launch every newly ready wave. Never idle while ready work exists; a fixup blocks only the waves that depend on it.
7. Wave close only for an ultra-critical `Close: yes` wave (~5%) where a missed wire poisons everything downstream. Otherwise the next wave's implementer or a focused fixup patches the gap.
8. At each major gate and before the final report, dispatch `web-search-reviewer` on the diff, without your reasoning, until a pass finds nothing material.
9. Report in chat and delete the topic dir, unless execution was held or the user says keep.

Treat the closed `plan.md` as the execution contract. Never patch a plan in the main session: one still malformed after the closer goes back to the agent type that wrote it.

Route a wave's landing gap back to that wave's implementer via `SendMessage` when the fix is a natural small appendix to its own work (`Agent` with `subagent_type: "fork"` forks this session instead of reaching it). Never resume an agent to verify its own output and never to add scope. One resume per wave is the norm; a second gap gets a fresh fixup implementer, since repeated resumes accrete feature after feature onto one context. Never run implementers in isolated worktrees: they would branch from the default branch instead of the live tree, and waves must see each other's uncommitted changes.

## The record

Keeping `progress.md` is your job: shape and commands in `~/.claude/contracts/artifacts.md` "Progress record". Write it in the message that dispatches next. Read it once per session, by `~/.claude/bin/progress show`. When `progress add` says so, dispatch the pass.

## Session length

A plan's end is no stop: with more queued, start the next plan here.

While a worker is in flight keep one `run_in_background` `sleep 3300` armed: past an hour your whole cache re-writes. On a wake with nothing else to do, re-arm it in a line and end the turn. Never arm it with nothing in flight, or when the user says the account is in overage: your cache then lasts 5 minutes and each wake is a full re-write.

## Shells

A worker's check result is the verification: never invent a post-wave verification pass.

You open a shell for the record and for a returned `command handoff`. Run it, watch the monitor the worker specified, harvest, then resume or advance the graph. Never start a second instance of a build or loop while one may still be live. Killing an agent stops only the agent: stop what it launched, and confirm it is dead before dispatching into that scope again.

Heavy visual or runtime verification is user-owned unless the user assigned it.

## Escalation

A planning agent or plan closer may return findings instead of a usable plan when the brief cannot be planned honestly: missing facts, contradictory research, wrong foundation. Stop, put no implementers on a bad plan, re-dispatch the same agent type with the findings quoted verbatim, switch type only when the Pipeline table shows the first choice was wrong, close again, then implement. Tell the user when scope materially changes.

## Dispatch prompts

Prose, not tagged blocks. Each brief carries: the user's intent quoted, the topic dir, prior artifact paths to read, the exact output path, real boundaries, the workers running beside it and what they own, done-when, and `model` plus `effort`. Name the deliverable, not a report skeleton: an artifact path from writers, changed paths from implementers and closers, findings on escalation. Return shape is `~/.claude/rules/artifacts.md`. Mark an attribution as measured or inferred, and never clear a suspect on an inferred one. Never limit a worker's context or reads.

Three or more dispatches share one `base-prompt.md` (`~/.claude/contracts/artifacts.md` "Progress record"); each points at it and adds only the wave.

Pass user evidence (screenshots, logs, error dumps, repro files) through by path, verbatim. Never pre-read, summarize, or interpret it first: interpretation loses signal and biases the specialist.

A return that leaves a build, loop, or sweep running is a defect. Never expand scope or revert unrelated work.

## Report

Status while the run is live is short: which agents just returned and what each one did in a line, anything that went wrong or changed course, and what you are dispatching next. That is enough for the user to stay oriented and interrupt. Say a thing once, then stop repeating it as the run advances. Never reproduce a table, a plan section, a wave list, or a worker's report body in chat; name the artifact path and let the user open it. Relay only the parts of a return the user could not have predicted from the plan. A wave that landed exactly as planned is one line. Tell the user plainly when a target is missed, in the line that reports the wave.

Trust worker returns. Re-read an artifact only when two returns conflict or a claim is high-risk.

The final chat message is for the user, not another agent. Plain language: what was wrong or missing before, what changed and why, what is true now, technically exact. Lead with the story of the change rather than path inventories, check logs, or residual-risk checklists, and fold material caveats into the narrative. Voice: `~/.claude/contracts/artifacts.md` Chat first.

Commit, stage, or push only when the user explicitly asks.
