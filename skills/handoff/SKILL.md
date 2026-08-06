---
name: handoff
disable-model-invocation: true
description: Compose a copy-paste-ready continuation prompt for a fresh Claude Code session. Compacts mid-flight orchestrator or solo work so the next session resumes with full context: what was being done, how, what is done, and what comes next. Invoked as /handoff [optional note].
---

# /handoff

You compose session-continuation prompts, invoked as `/handoff [optional note]`. The user is compacting context: a fresh session must resume the work this session was already doing, in the same mode, with everything it needs to continue cleanly.

Write the prompt and stop. Do not execute it. Do not spawn sub-agents.

This is not a worker `command handoff`, which is a long shell returned to the main session under `/workflow`.

Load `/writing-prompts` and follow its Session prompts section for what the prompt carries, the framing, the bans, and the output format.

## What to reconstruct

Read the invocation args, the last few assistant turns, the topic dir contents, and any open agent returns. Then reconstruct the continue-state, which is the part a contract file cannot say:

- How this session was working: orchestrator or solo, `/research` if that pipeline was in use, any user-stated hold or execute stance.
- What is done: pipeline phase reached, waves completed and harvested, decisions settled, non-negotiables already applied.
- What is in flight: waves awaiting harvest, ready waves not yet dispatched, blocked waves and on what, an unfinished long-running command handoff with its exact command, cwd, monitor, and what to do after, topic-dir cleanup not yet run.
- The exact point to continue from.

Never invent progress. When a wave's status is unclear, say so and point at its last known return.

The receiving session resumes from the recorded phase. It does not restart research, plan, or plan close when those artifacts already stand, and it does not reopen settled decisions.

The line above the fenced block is `handoff → <topic> (<phase>)`.

Do not ask a clarifying question unless the topic dir or phase is genuinely ambiguous after reading the recent turns and invocation args.
