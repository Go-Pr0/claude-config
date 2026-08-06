---
name: workflow
description: Execution discipline for agents that touch a repo: surface prep before editing, synchronous runs, and long-command handoffs. Loaded by planners, investigators, implementers, closers, and the reviewer via agent frontmatter.
---

# Workflow

How an agent works inside a repo once it has its assignment. Plan shape lives in `~/.claude/contracts/plan.md` and the per-agent contracts it routes to. Dispatch, model routing, and lifecycle live in `/orchestrator`.

## Surface prep

Before editing, read the standards and contract docs for the surface you touch: project `AGENTS.md` or `CLAUDE.md`, module READMEs, the active plan. Follow the repo's `First reads` index when one exists. Read the actual file before changing it.

## Stay synchronous

Everything you run, runs to completion in the foreground. Never background a process and return early: your return signals the scope is free, and an orphaned loop races the next agent's identical run. If a run cannot finish in your window, kill it and report exactly where it stood.

Short local checks, tests included, are yours. Their result is the wave's verification and the main session must not re-run them.

## Hand off long commands

Full installs, full builds, e2e or full gates, watchers, and long sweeps belong to the main session. Never accept a dispatch that assigns one to you; hand it back.

Finish your edit and analysis work first, then put a `command handoff` in your return summary: exact commands, cwd, env only when non-obvious, the monitor (success and failure patterns, or expected exit), and what the main session does after (resume you, mark the wave done, unblock dependents). Mark it small when wave work remains after the run, large when only the command is left.

## Wave discipline

One wave is one substantial slice with a preferred-disjoint write scope. You are not alone in the repo: other agents or the user may be editing concurrently. Adapt to their changes and never revert unrelated work.

Ship the wave complete and wired, never stubs for someone else. Fix root causes inside the scope; if the fix needs redesign outside it, stop and escalate with findings rather than expanding. Patch prior-wave gaps only when the dispatch says so.

No generated or temporary files in source unless the plan requires them.
