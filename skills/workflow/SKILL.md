---
name: workflow
description: Execution discipline for agents that touch a repo: surface prep before editing, synchronous runs, and command handoffs. Loaded by planners, investigators, implementers, closers, and the reviewer via agent frontmatter.
---

# Workflow

How an agent works inside a repo once it has its assignment. Plan shape lives in `~/.claude/contracts/plan.md` and the per-agent contracts it routes to. Dispatch, model routing, and lifecycle live in `/orchestrator`.

## Surface prep

Before editing, read the standards and contract docs for the surface you touch: project `AGENTS.md` or `CLAUDE.md`, module READMEs, the active plan. Follow the repo's `First reads` index when one exists. Read the actual file before changing it.

## Stay synchronous

Everything you run, runs to completion before you return. Never background a process and return early: your return signals the scope is free, and an orphaned loop races the next agent's identical run. If a run cannot finish in your window, kill it and report exactly where it stood.

Wait as `~/.claude/rules/subagents.md` says, on locks, runs and files alike. Never attach a second wait to a run already watched.

## Hand off what you cannot finish

What must outlive you (a watcher, a server) or must not run twice at once with no lock in the repo (a full install) goes in your return as a `command handoff`: exact commands, cwd, env only when non-obvious, the monitor (success and failure patterns, or expected exit), and what the main session does after.

## Wave discipline

One wave is one substantial slice with a preferred-disjoint write scope. You are not alone in the repo: other agents or the user may be editing concurrently. Adapt to their changes and never revert unrelated work.

A measurement contradicting a premise of your brief returns at once.

With a `progress.md` beside your plan, read it first, then only the entries your wave builds on, and never edit it. On landing, write your entry as `progress/<UTC YYYY-MM-DDTHHMMZ>-<slug>.md` beside it (what changed, checks with their numbers, deviations) and return its landed line, at most 300 bytes: the outcome, every miss and waiver, that path.

Ship the wave complete and wired, never stubs for someone else. Fix root causes inside the scope; if the fix needs redesign outside it, stop and escalate with findings rather than expanding. Patch prior-wave gaps only when the dispatch says so.

No generated or temporary files in source unless the plan requires them.
