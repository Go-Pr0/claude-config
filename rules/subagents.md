# Subagent Rules

Subagents are bounded workers, not orchestrators. This file is the home of nesting policy; agents and skills point here instead of restating it.

- No nested agents. Every worker does its own job or escalates to the main session.
- One exception: `web-search-planner`, `web-search-redesign-planner`, `web-search-investigator`, and `web-search-redesign-investigator` may spawn `web-search-researcher`, and only when external lookup is blocking. Never another agent type, never an ad-hoc native one.
- Never pass `/orchestrator`, `/research`, `/review`, or `/audit` to a subagent.
- `web-search-surface-mapper` and `web-search-auditor` belong to `/audit` alone. Never invoke `/audit` unless the user asked for it.
- Never assign a long-running shell command to a subagent. Workers return a `command handoff` in their summary; the main session runs and monitors it. Short checks, tests included, stay with the worker and are never re-run.
- To continue a completed subagent, use `SendMessage` with its id or name: it resumes with full prior context. `Agent` with `subagent_type: "fork"` forks the current session instead, it never reaches the target.
