---
name: writing-prompts
description: Reference for writing effective agent prompts, sub-agent dispatch prompts, session-starter prompts, and session-continuation prompts. Apply when writing, reviewing, or improving any prompt, agent definition, or instruction.
---

# /writing-prompts

Apply these principles to whatever prompt, agent definition, or instruction is being written or improved. `/prompt` and `/handoff` load this file for the craft; they carry only what is specific to their invocation.

## Core stance

A prompt is intent and constraints. It is not a checklist of steps, an output template, or a list of categories the receiving agent uses as scaffolding. Over-controlled prompts make reasoning worse: they push the model into producing the shape you sketched instead of the answer the work demands.

State the role, the work, what to read, what is already known, and the real constraints. Then trust the agent. If you are prescribing how the output should be organized, which sections, labels, categories, or table columns, strip it out.

The signs of over-control: bullet lists of categories the output must contain, prescribed skeletons with section headers, numbered workflows that read like a procedure, instructions about how to reason ("first analyze X, then consider Y"), and restating contract content the agent can read itself.

## Sub-agent dispatch prompts

Prose, not tagged blocks. The receiving agent gets:

- The user's verbatim intent. Quote, never paraphrase.
- Context it cannot easily derive: decisions already made, invariants, what was ruled out. Tell it what to read, not what the file contains.
- Its scope. Tight when the work really is one file or one symbol; goal-shaped (a domain or surface) for anything spanning more than two files.
- The outcome. For tight scope, the concrete change. For goal-shaped work, what success looks like, not the steps.
- Real boundaries, the ones that exist for actual reasons. Never enumerate hypothetical violations.

## Session prompts

A session prompt hands work to a fresh Claude Code session. Two kinds: a starter, which begins from a finished artifact, and a continuation, which resumes mid-flight work. Both obey the same craft.

Declare the receiving session's role in the first sentence: orchestrator, or solo. Then carry, in tight prose:

- Every artifact by path: the contract or plan file, `research.md`, and each piece of user evidence with one line on what it shows. Never inline their contents; the session reads them. Say that sub-agent briefs pass those same paths through unmodified, because specialists read raw evidence rather than a summary.
- The user's intent, quoted verbatim when they stated it.
- What is already settled, so nothing gets re-derived or re-litigated.
- The exact next action, in plain language.
- Real non-negotiables in plain prose ("zero backward compat", "do not touch the QA agents"). Carry the clean-split rule when a refactor is in play: what is replaced is deleted, never shimmed for compatibility. State the contract's scope as binding both ways: deliver it completely, build none of its non-goals.

The prompt must be self-contained: the session continues cleanly with zero bolt-ons from the user.

Orchestrator framing is a few short paragraphs, not twenty imperatives: orchestrator on `plans/active/<topic>/`, following `/orchestrator` and `~/.claude/agents/`, dispatching by intent with `model` and `effort` per `/orchestrator` Model routing, trusting worker `Verify`, running only long-running command handoffs in the main session. Solo framing is one line: solo, no sub-agents, read and edit and verify inline.

Never include: file enumerations, line ranges, verification commands, report-back skeletons, XML tags, chat transcripts, or a lecture on how Claude Code works.

Post the prompt as a single fenced code block the user can copy, with one identifying line above it and nothing after.

## Agent definition files

Frontmatter carries `name`, `description`, model and effort defaults, tool bans, and the skills the agent loads. Body is plain markdown.

Cover, in any order that suits the agent: a short role line; what it does, who spawns it, what it returns; the work itself, as actions rather than a reasoning script; and its real boundaries. Skip output templates unless a machine-readable shape is required.

## Style

- Dense, not padded. Every sentence earns its place.
- Concrete, not abstract. Name files and schemas. "The queue at `kore/project/queue.py`" beats "the queue module".
- Opinionated, not hedged. "Cut the nine source types to four" beats "consider whether they could be simplified".
- Plain imperatives: Never X, Only Y, Always Z. No "try to" or "prefer".
- Headers, regular text, and backticks for paths and commands. No XML, no bold, no italic.
- Define the work and trust the agent. No control overhead.
