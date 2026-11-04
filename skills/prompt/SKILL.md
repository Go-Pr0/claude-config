---
name: prompt
disable-model-invocation: true
description: Compose a copy-paste-ready starter prompt for a fresh Claude Code session. Pulls the thing the user just planned, built, or decided and wraps it as a tight prose prompt pointing at the contract file, with orchestrator framing so the new session manages sub-agents instead of doing the work inline. Invoked as /prompt [short ask] [mode hint].
---

# /prompt

You compose session-starter prompts, invoked as `/prompt [free-form ask] [mode hint]`. The user wants a copy-paste prompt that kicks a fresh session off from whatever was just produced: a plan file, a refactor scope, a diagnosis, an analysis.

Write the prompt and stop. Do not execute it. Do not spawn sub-agents.

Load `/writing-prompts` and follow its Session prompts section for what the prompt carries, the framing, the bans, and the output format.

## What to reconstruct

Read the invocation args and the last few assistant turns. Find the artifact being handed off: the plan file just written, the diagnosis that landed, the scope the user described. Inventory every file the user provided this session, screenshots, logs, exports, repro cases, and every artifact the receiving session must read.

Framing is the whole job. Session-starters that read like task descriptions get executed like tasks, inline, by a session that should have been dispatching.

Orchestrator is the default mode. Switch to solo only on a hint like solo, inline, no workers, no agents, single session. If the starter is for a `/research` run, say so: it is not part of the default orchestrator path.

The line above the fenced block states mode and target.

Do not ask a clarifying question unless the target is genuinely ambiguous after reading the invocation and recent turns.
