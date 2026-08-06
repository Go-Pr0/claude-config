---
name: handoff
disable-model-invocation: true
description: Compose a copy-paste-ready continuation prompt for a fresh Claude Code session. Compacts mid-flight orchestrator or solo work so the next session resumes with full context — what was being done, how, what is done, and what comes next. Invoked as /handoff [optional note].
---

# /handoff

You compose session-continuation prompts. Invoked as `/handoff [optional note]`. The user is compacting context: a fresh session must resume the same work this session was already doing — usually as orchestrator — with every piece of context it needs to continue cleanly.

You write the prompt and stop. Do not execute it. Do not spawn sub-agents.

This skill hands the main session to the next chat. It is not a worker `command handoff` (a long shell returned to the main session under `/orchestrator` / `/workflow`).

## Role

The generated prompt must make the receiving session continue as this session was operating — orchestrate and dispatch per `/orchestrator` and `~/.claude/agents/`, or solo if that was the mode — instead of restarting, re-planning, or doing the work differently. Continuations that omit how the work was being done get re-derived from scratch; carrying mode, progress, and next action is the fix.

Two modes. Orchestrator (default): the new session continues orchestrating and dispatching. Solo: everything inline in one transcript, no sub-agents. Match the mode this session was using. Detect solo from the current session or hints like solo, inline, no workers, no agents, single session.

## How to write it

Reconstruct the full continue-state. Read the invocation args, the last few assistant turns, topic dir contents, and any open agent returns. Inventory every file the user provided this session — screenshots, logs, exports, repro cases — and every artifact the receiving session must read. Lift the user's intent verbatim if they stated it.

The prompt must be self-contained: the receiving session continues cleanly with zero bolt-ons from the user. Carry forward by path the topic dir, `plan.md`, `research.md` if present, each evidence file with one line on what it shows (sub-agent briefs pass these paths through unmodified — specialists read the raw evidence, not a summary), and any other artifact to read.

Also carry what the contract alone cannot say:

- How this session was working — orchestrator or solo; `/research` if that pipeline was in use; any user-stated hold or execute stance.
- What is already done — pipeline phase reached; waves completed; waves harvested; decisions settled; non-negotiables already applied.
- What is in flight or pending — waves awaiting harvest, ready waves not yet dispatched, blocked waves and on what, unfinished long-running `command handoff` shells (exact command, cwd, monitor, what to do after), topic-dir cleanup not yet run.
- The exact point to continue from — the next concrete action in plain language.

Do not invent progress. If a wave's status is unclear, say so and point at the last known return.

Write tight prose. Open by declaring the receiving session's role — orchestrator continuing `<topic>`, or solo continuing. Point at artifact paths; do not inline their contents. Tell the session that sub-agent briefs reference those same paths instead of restating the plan. Quote the user's intent verbatim if they stated it.

Describe sub-agent management in your own prose, in intent terms, not as a checklist of XML blocks — same posture this session used. State the contract's scope as binding both ways: deliver it completely, build none of its non-goals. Carry the clean-split rule: anything refactored is replaced outright — old code deleted, never shimmed or wrapped for backward compat. Name any other real, user-stated non-negotiables.

Keep it short. The contract files carry design detail. The continuation prompt carries framing, progress, and the next action.

Post the prompt in chat as a single fenced code block the user can copy. One line above the block: `handoff → <topic> (<phase>)`. Nothing after.

## Orchestrator framing

Convey in a few short prose paragraphs: orchestrator continuing this topic; `plans/active/<topic>/`; resume from the recorded phase — do not restart research, plan, or plan-close when those artifacts already stand; optional researcher when external lookup is still central and not yet done → planner → plan-closer → implementers as the graph requires from here; wave-closer only for ultra-critical waves (~5%); set `model` and `effort` per `/orchestrator` Model routing; follow `/orchestrator` and `~/.claude/agents/`. If this session was on `/research`, say so — load it and continue that pipeline.

The receiving session does not need twenty imperatives — it needs its role, where the contracts live, how this run was being managed, what is already done, and what to do next.

For solo mode: solo, no sub-agents. Read, edit, run, verify in this session directly. Follow the contract file from the recorded point.

## Boundaries

Do not put inline plan contents, file enumerations, line ranges, or exact change lists in the generated prompt — the receiving session reads the contracts.

Do not dump the chat transcript, agent transcripts, or wave-by-wave narration.

Do not restart research, plan, or plan-close when those artifacts already exist and were accepted this session — continue from the recorded phase.

Do not re-open settled decisions or invent new scope.

Do not include verification commands or test invocations. The receiving session knows project gates.

Do not add a report-back skeleton with specific section names. Do not use XML tags in the generated prompt body.

Do not lecture the session on how Claude Code works or restate `~/.claude/CLAUDE.md`; point at the rules files.

Do not paste a long contract block verbatim. A few prose lines of orchestrator framing, progress, and the next action plus the artifact paths are enough.

Do not write a handoff file into the topic dir unless the user explicitly asks for a file; the copy-paste prompt is the handoff.

Do not write the prompt for the user in chat prose — you are writing the session-continuation for a fresh Claude Code session.

Do not ask clarifying questions unless topic dir or phase is genuinely ambiguous after reading the recent turns and invocation args.
