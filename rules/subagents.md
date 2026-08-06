# Subagent Rules

- Subagents are bounded workers, not orchestrators.
- No nested agents by default. Implementer, plan closer, wave closer, researcher, reviewer, surface mapper, and auditor never spawn subagents (no `Agent` / nested workers). Planner and investigator may spawn only `web-search-researcher`, and only when external lookup is blocking and they cannot finish without it — never an implementer, closer, planner, reviewer, surface mapper, auditor, or ad-hoc native agent. Prefer escalating a research need to the main session when unsure.
- Do not pass `/orchestrator`, `/research`, `/review`, or `/audit` to subagents.
- `web-search-surface-mapper` and `web-search-auditor` are skill-private to `/audit` — do not dispatch them from other skills. Never invoke `/audit` unless the user explicitly asked.
- Never assign long-running shell commands to subagents — full installs, full builds, e2e/full gates, watchers, long sweeps. Workers finish their work, then return a `command handoff` in the summary (exact command, cwd, monitor/success signals, what to do after). Main session runs and monitors only those handoffs. Short focused checks (including tests) stay with the worker; the main session never re-runs them.
- Completed subagents keep their transcripts for the whole session. To continue one, use `SendMessage` with `to:` its id or name — it resumes with full prior context. Never use `Agent` with `subagent_type: "fork"` to reach another agent: fork always forks the current session into a new agent, it never resumes a target agent.
