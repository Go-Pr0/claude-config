---
name: instructions
description: Author and refactor model-facing instructions and team-memory vault notes in the lean house style. Use when creating, editing, cleaning, or reviewing skills, rules, agents, contracts, modules, CLAUDE.md surfaces, or any compiled note under $TEAM_MEMORY_VAULT (promote, direct write, or CONTRACT edits).
---

# Instructions

Write and refactor model-facing instruction text and team-memory vault notes. Skills, rules, agents, contracts, modules, CLAUDE.md surfaces, and compiled notes under `$TEAM_MEMORY_VAULT`. Same style whether authoring new or cleaning existing.

When writing or promoting vault memory, read `$TEAM_MEMORY_VAULT/CONTRACT.md` for surfaces, AI-first note rules, and the promote gate. This skill owns prose style only.

## Surfaces first

Before writing a line, map what lives where. One fact, one home. Everything else points by path.

| Layer | Holds | Does not hold |
|-------|-------|---------------|
| Habits / CLAUDE.md | Always-on scope, tiny session defaults | Workflows, role bodies, artifact shapes |
| Rules | Broad behavioral constraints | Pipelines, per-task routing, file contracts |
| Contracts | Shape of a shared artifact a worker must write | Who dispatches whom, when to invoke |
| Skills | Invoked workflow, on-demand reference, phase ownership | Restated rule text, restated contract bodies |
| Agents | Role, job, return, real never-dos | Orchestrator pipelines, contract prose inlined |
| Commands | Thin project binding that invokes a skill or flow | The flow itself |

If two files would say the same thing, delete one and point. Pointing is the join, not paraphrase.

## Style

- Dense. Every sentence earns its place. Cut padding, throat-clearing, and restated Intent.
- Concrete. Name paths, agent names, artifact filenames. Abstractions only when the surface is conceptual by design.
- Opinionated. State the rule. No "consider", "try to", "prefer", "you might".
- Imperative. "Never X". "Only Y". "Always Z".
- Headers for structure. Regular text and backticks for paths, commands, names. No bold. No italic. No underline.
- No em dash or en dash as punctuation. Comma, colon, full stop, parentheses, or hyphen for ranges.
- No XML tags in bodies. No prescribed output skeletons unless a machine contract requires a fixed shape.
- Trust the reader. Define role, work, what to read, real constraints. Do not script their reasoning order or section labels for prose output.

## Shape

Open with stance: what this file is, when it applies, who runs it.

Then ownership and routing before detail: tables for who writes what, which phase owns which file, which agent returns which artifact. Conceptual surfaces before procedural steps.

Then the work: phases, actions, done-when. Steps are actions only, never a reasoning script.

Then Boundaries: real don'ts with real reasons. Skip hypothetical violations.

Frontmatter earns its fields. Skills: `name`, `description` (what + when, third person). Add `disable-model-invocation: true` only for user-invoked workflows. Agents: `name`, `description`, model/effort defaults, tool bans, which skills they load. Body stays prose.

## Authoring

1. Name the layer and the consumer (always-on rule vs invoked skill vs one-shot agent).
2. List the facts that must live here. Move anything that already has a home out; leave a path.
3. Write stance, then surface map / ownership, then work, then boundaries.
4. Re-read once for duplication, hedges, emphasis markup, and sentences that restate a neighbor section.
5. Stop when removing a sentence loses no constraint.

## Refactor

Read the whole file and its neighbors before editing. Inventory duplication across the layer set.

- Merge sections that share one job.
- Delete restated contract or rule prose; replace with a path.
- Collapse hedges into imperatives, or delete the line if it cannot be made firm.
- Strip bold, italic, em dashes, and decorative emphasis.
- Rewrite in place. Same path. No `*-v2`, no parallel "clean" copy beside the live file.
- Preserve load-bearing constraints. Tightening style is not a license to soften or drop a real boundary.

When the user points at a set of files, treat them as one surface: fix cross-file duplication, not each file in isolation.

## Anti-patterns

- Fact living in two layers ("also see" paraphrase of a rule inside a skill)
- Output templates for prose the agent should organize itself
- Numbered reasoning scripts ("first analyze, then consider, then decide")
- Soft alternatives stacked where one rule should stand
- Inventories of files or line ranges that belong in the repo, not in the instruction
- Provenance and changelog in operative text (history belongs in commits and reports)
- Padding that restates the section above it
- Emphasis markup doing the job of a header or a stronger sentence

## Boundaries

Do not invent a new layer when an existing one fits.

Do not expand scope into product code, plans, or research artifacts unless the user asked for those files.

Do not ask clarifying questions when the target path and intent are clear from the invocation and recent turns. Decide and write.

Chat carries the summary of what changed. The instruction files are the deliverable.
