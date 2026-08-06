---
name: writing-prompts
description: Reference for writing effective agent prompts, sub-agent dispatch prompts, session-starter prompts, and session-continuation prompts. Apply when writing, reviewing, or improving any prompt, agent definition, or instruction.
---

# /writing-prompts

Apply these principles to whatever prompt, agent definition, or instruction the user wants to write or improve.

## Core stance

A prompt is intent and constraints. It's not a checklist of steps, an output template, or a list of categories the receiving agent is supposed to use as scaffolding. Over-controlled prompts make reasoning worse — they push the model into producing the shape you sketched instead of the answer the work demands.

State the role, the work, what to read, what's already known, and the real constraints. Then trust the agent. If you find yourself prescribing how the output should be organized (which sections, which labels, which categories, which tables), strip it out. The agent will organize it.

The signs you're over-controlling: bullet lists of categories the agent's output must contain ("CUT / MERGE / ADD"), prescribed output skeletons with section headers and table columns, numbered workflows that read like a procedure, instructions about how the agent should reason ("first analyze X, then consider Y, then decide Z"), repeated reiterations of the contract content when the agent can read the file itself.

## Sub-agent dispatch prompts

Write them as prose, not as tagged blocks. The receiving agent gets:

- The user's verbatim intent. Quote, never paraphrase.
- A short brief of context the agent needs and can't easily derive — decisions already made, invariants, what's been ruled out. Tell it what to read, not what the file contains.
- The scope it's working in. Tight when it really is one file or one symbol; goal-shaped (a domain or surface) for anything wider. Default to goal-shaped for anything spanning more than two files.
- The outcome you want. For tight scope, the concrete change. For goal-shaped work, what success looks like — not the steps to get there.
- Real boundaries. "Don't run the full test suite." "Don't touch X." Boundaries that exist for actual reasons. Don't enumerate hypothetical violations.

That's it. No XML tags, no [BLOCK_NAME] headers, no output skeleton, no prescribed reasoning order.

## Session-starter prompts

For a fresh Claude Code session starting from a finished artifact (plan, diagnosis, scope):

- Declare the role in the first sentence — "You are the orchestrator," or "Solo mode."
- Point at the contract file by path. Don't inline it. The receiving session reads it.
- Quote the user's verbatim intent if they stated it.
- A few prose lines on how to manage sub-agents (parallel implementer dispatch by intent, model and effort per `/orchestrator` Model routing, gates once at the end). Don't paste a long boilerplate contract — point at `/orchestrator` and `~/.claude/agents/`.
- Real non-negotiables in plain prose ("zero backward compat", "don't touch the QA agents").

Don't include: file enumerations, line ranges, verification commands, report-back templates, lectures on how Claude Code works.

## Session-continuation prompts

For a fresh Claude Code session resuming mid-flight work:

- Declare continuing role and topic (`orchestrator continuing <topic>`).
- Point at existing artifact paths; do not inline them.
- State pipeline phase and graph progress (done / in flight / ready / blocked).
- Name the exact next action; carry pending main-session `command handoff` shells if any.
- Carry settled decisions; do not reopen them or restart research/plan when those artifacts already stand.

Don't dump transcripts. Don't restart from wave 1.

## Agent definition files

YAML frontmatter (required): `name`, `description`, `tools`, `model`. Body in plain markdown — no XML wrapper.

Sections (in any order that suits the agent):

- A short role line. Noun phrase.
- A paragraph on what the agent does — its job, who spawns it, what it returns, what it never does.
- A short section on what to do — prose or numbered steps, but only steps that are actions, not reasoning.
- A short don't list — real boundaries.

Skip output templates unless the agent's contract requires a specific machine-readable shape (e.g. `[FILES_CHANGED]` from an implementer). For prose output, let the agent organize.

## Style

- Dense, not padded. Every sentence earns its place.
- Concrete, not abstract. Name files. Name schemas. "The queue at kore/project/queue.py" beats "the queue module."
- Opinionated, not hedged. "Cut the 9 source types to 4" beats "consider whether they could be simplified."
- Plain imperatives. "Never X", "Only Y", "Always Z". No "try to" or "prefer".
- No XML in prompt bodies. Markdown headers and prose.
- No control overhead. Define the work; trust the agent.
- No bold or italic. Headers, regular text, and backticks for commands and paths only.
