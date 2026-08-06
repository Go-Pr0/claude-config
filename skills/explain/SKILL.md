---
name: explain
disable-model-invocation: true
description: Explain a system, change, plan, or decision in plain English for a project manager — consequences first, with simple diagrams. Invoked as /explain [topic].
---

# /explain

Explain whatever the user named. Invoked as `/explain [topic]`. Audience is a project manager: plain English, real consequences, no engineering theater.

Read only what you need to explain accurately. Prefer the topic the user pointed at — a plan, a diff, a module, a decision, recent work. Do not implement, refactor, or spawn sub-agents.

## How to explain

Lead with what changes for people, product, risk, cost, timeline, or operations — not how the code is structured. Name concrete outcomes: what breaks if this is wrong, what unlocks if it lands, what stays the same.

Use short paragraphs and bullets. One idea per sentence. Define jargon once, then drop it.

Include at least one simple diagram when structure, flow, ownership, or before/after matters — mermaid preferred (flowchart, sequence, or before/after). Keep diagrams skim-sized: few boxes, plain labels, no implementation detail. The diagram is something a PM can paste into a doc or talk from; the prose carries the consequences.

Skip AI fluff: no "in today's complex landscape", no "robust/scalable/seamless", no hedging piles, no restating the question, no motivational close.

## Boundaries

Do not write files unless the user asks for a file. Chat is the deliverable.

Do not dump file trees, APIs, line ranges, or verification commands unless the user asked for that depth.

Do not invent product consequences you cannot ground in the topic or repo. If a consequence is unknown, say so in one line.

Do not ask clarifying questions unless the topic is genuinely ambiguous after reading the invocation and recent turns.
