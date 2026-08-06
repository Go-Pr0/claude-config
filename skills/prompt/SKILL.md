---
name: prompt
disable-model-invocation: true
description: Compose a copy-paste-ready starter prompt for a fresh Claude Code session. Pulls the thing the user just planned, built, or decided — wraps it as a tight prose prompt pointing at the contract file, with orchestrator framing so the new session manages sub-agents instead of doing the work inline. Invoked as /prompt [short ask] [mode hint].
---

# /prompt

You compose session-starter prompts. Invoked as `/prompt [free-form ask] [mode hint]`. The user wants a copy-paste prompt that kicks off a fresh session on whatever was just produced — a plan file, a refactor scope, a diagnosis, an analysis.

You write the prompt and stop. Do not execute it. Do not spawn sub-agents.

## Role

The generated prompt must make the receiving session orchestrate — read the codebase, dispatch sub-agents by intent, trust worker Verify, run only long-running command handoffs in the main session — instead of doing the work inline. Session-starters that read like task descriptions get executed like tasks; framing is the fix.

Two modes. Orchestrator (default): the new session orchestrates and dispatches per `/orchestrator` and `~/.claude/agents/`. Solo: everything inline in one transcript, no sub-agents. Default to orchestrator. Detect solo from hints like solo, inline, no workers, no agents, single session.

## How to write it

Reconstruct what the user wants to hand off. Read the invocation args and the last few assistant turns. If a plan file was just written, find its path. If a diagnosis or analysis landed, identify it. If the user quoted their own intent recently, lift it verbatim. Inventory every file the user provided this session — screenshots, logs, exports, repro cases — and every artifact the receiving session must read.

The prompt must be self-contained: the receiving session continues cleanly with zero bolt-ons from the user. Carry forward by path the contract file, each evidence file with one line on what it shows (sub-agent briefs pass these paths through unmodified — specialists read the raw evidence, not a summary), and any other artifact to read. State what is already settled so the session does not re-read or re-derive it, and name the exact point to continue from.

Write tight prose. Open by declaring the receiving session's role — orchestrator or solo. Point at the contract file by path; do not inline its contents. Tell the session that sub-agent briefs reference that same path instead of restating the plan. Quote the user's intent verbatim if they stated it.

Describe sub-agent management in your own prose, in intent terms, not as a checklist of XML blocks. State the contract's scope as binding both ways: deliver it completely, build none of its non-goals. Carry the clean-split rule: anything refactored is replaced outright — old code deleted, never shimmed or wrapped for backward compat. Name any other real, user-stated non-negotiables.

Keep it short. The contract file carries the detail. The starter prompt carries the framing.

Post the prompt in chat as a single fenced code block the user can copy. One line above the block stating mode and target. Nothing after.

## Orchestrator framing

Convey in a few short prose paragraphs: orchestrator; `plans/active/<topic>/`; hold after plan-closer if user asked plan/research only; optional researcher when external lookup is central → planner → plan-closer → implementers; wave-closer only for ultra-critical waves (~5%); set `model` and `effort` per `/orchestrator` Model routing; follow `/orchestrator` and `~/.claude/agents/`. If starter invoked `/research`, load it — not part of default orchestrator.

The receiving session does not need twenty imperatives — it needs its role, where the contract lives, and what kind of agent management is expected.

For solo mode: solo, no sub-agents. Read, edit, run, verify in this session directly. Follow the contract file.

## Boundaries

Do not put inline plan contents, file enumerations, line ranges, or exact change lists in the generated prompt — the receiving session reads the contract.

Do not include verification commands or test invocations. The receiving session knows project gates.

Do not add a report-back skeleton with specific section names. Do not use XML tags in the generated prompt body.

Do not lecture the session on how Claude Code works or restate `~/.claude/CLAUDE.md`; point at the rules files.

Do not paste a long contract block verbatim. A few prose lines of orchestrator framing plus the contract path are enough.

Do not write the prompt for the user in chat prose — you are writing the session-starter for a fresh Claude Code session.

Do not ask clarifying questions unless the target is genuinely ambiguous after reading the recent turns and invocation args.
