# ~/.claude, the machine-wide Claude Code layer

Parallel to `~/.codex/`, which holds `AGENTS.md`, `agents/*.toml`, and a local `config.toml`. Skills are canonical here in `~/.claude/skills/` (a real directory, not a symlink); copy them to `~/.agents/skills/` when Codex needs them.

## Directory layout

```text
~/.claude/
├── CLAUDE.md              machine-wide habits
├── settings.json          skillOverrides, hooks, model (published through bin/public-settings)
├── settings.local.json    read only by sessions started from ~, not published
├── skills/                personal skills (canonical, edit here)
├── agents/                web-search-*.md subagents
├── contracts/             artifact shapes: plan, research, workspace
├── rules/                 always-on behavioral guidance
├── hooks/                 rtk-rewrite, context-headsup, biome format (Claude only)
├── bin/                   progress (the program record's one writer), public-settings
├── export-config.sh       Claude-only zip
├── export-shared-config.sh  Claude + Codex + skills zip
└── SHARE-README.md        setup guide for zip recipients
```

Session load order: `~/.claude/CLAUDE.md`, then the repo's `CLAUDE.md`, then skill metadata from `~/.claude/skills/`, then `settings.json` overrides.

## Skills

| Skill | Visibility | Who loads it |
|-------|-----------|--------------|
| `orchestrator` | `user-invocable-only` | main session, `/orchestrator` |
| `research` | `user-invocable-only` | main session, `/research` |
| `audit` | `user-invocable-only` | main session, `/audit [target] [brief]` |
| `review` | `user-invocable-only` | main session, `/review [scope]` |
| `prompt` | `user-invocable-only` | main session, `/prompt [ask] [mode hint]` |
| `handoff` | `user-invocable-only` | main session, `/handoff [note]` |
| `explain` | `user-invocable-only` | main session, `/explain [topic]` |
| `memory-promote` | `user-invocable-only` | main session, `/memory-promote` |
| `workflow` | `name-only` | planners, investigators, implementer, closers, reviewer, via agent frontmatter |
| `writing-prompts` | model-applicable | any agent writing a prompt, agent file, or instruction |
| `instructions` | model-applicable | any agent authoring or refactoring instruction text |
| `autonomous-sprint`, `deep-research` | `off` | nobody |

User-invocable skills carry `disable-model-invocation: true` in frontmatter plus the matching `skillOverrides` entry in `settings.json`. `workflow` stays model-loadable so agent frontmatter can pull it in. Codex mirrors visibility through `agents/openai.yaml` `allow_implicit_invocation`.

## Agents

Eleven subagents, defined in `agents/web-search-*.md` with YAML frontmatter.

| Agent | Loads workflow | Output |
|-------|----------------|--------|
| `web-search-researcher` | no | `research.md` |
| `web-search-planner` | yes | `plan.md` |
| `web-search-redesign-planner` | yes | `plan.md` |
| `web-search-investigator` | yes | `plan.md` |
| `web-search-redesign-investigator` | yes | `plan.md` |
| `web-search-plan-closer` | yes | edited plan files |
| `web-search-implementer` | yes | code |
| `web-search-wave-closer` | yes | code |
| `web-search-reviewer` | yes | code plus a chat summary |
| `web-search-surface-mapper` | no | `surfaces.md`, `/audit` only |
| `web-search-auditor` | no | `surface-*.md`, `/audit` only |

Orchestration flow: create `plans/active/<topic>/`, optional research, plan, plan close, implementer waves, the record, a reviewer at gates, wave close only for ultra-critical waves (~5%), report. Full rules in `skills/orchestrator/SKILL.md`.

## Contracts

One contract per writer. Every plan contract links the spine.

| File | Governs |
|------|---------|
| `contracts/artifacts.md` | the `plans/active/<topic>/` workspace, the progress record, edit-in-place, lifecycle |
| `contracts/research.md` | `research.md` shape, written by `web-search-researcher` |
| `contracts/plan.md` | the plan spine: Facts, Spec, Conceptual reading, Waves, Deferred, graph rules, bans |
| `contracts/plan-planner.md` | `web-search-planner` |
| `contracts/plan-redesign-planner.md` | `web-search-redesign-planner` |
| `contracts/plan-investigator.md` | `web-search-investigator` |
| `contracts/plan-redesign-investigator.md` | `web-search-redesign-investigator` |
| `contracts/plan-closer.md` | `web-search-plan-closer` |

## Export and share

| Script | Output |
|--------|--------|
| `export-shared-config.sh` | both hosts, plus `claude/skills/` and `SHARE-README.md` |
| `export-config.sh` | Claude host plus skills |

```bash
~/.claude/export-shared-config.sh              # writes ~/Desktop/agent-config-<stamp>.zip
~/.claude/export-shared-config.sh --restore path/to.zip
```

Excluded as personal: `settings.local.json`, `rules/machines.md`, `projects/`, `plugins/`, runtime caches, and the parts of `settings.json` that `bin/public-settings` strips. An export refuses to write a zip that holds a home path. Recipients read `SHARE-README.md` in the zip.

## Publishing

This repo has a public remote, and Claude Code writes credentials and transcripts into this directory.

`.gitignore` allows only what is published, at the root and in `skills/`. A new top-level file or a new skill stays local until it gets a `!` line there; `git status` does not list it until then.

`settings.json` is published through a clean filter: `bin/public-settings` strips the dangerous-mode skip, `env`, `apiKeyHelper` and any hook command naming a home path or tokentracker, then fails if a home path remains anywhere. Those parts keep running from the working copy and never reach the index, so `git diff` shows only what a commit would publish. A ` M settings.json` with an empty `git diff` means only unpublished parts or formatting changed; `git add settings.json` clears it and stages nothing.

Keep every personal part in `settings.personal.json` as well (git-ignored, same shape as `settings.json`). A checkout, pull, stash or reset that rewrites `settings.json` writes the published form, and the smudge filter merges that file back over it. A personal part missing from it is lost on the next rewrite. A local `git archive` runs the same filter and holds the personal parts: share through the export scripts.

The filter config lives in `.git/config`, which a clone does not copy. Without it `settings.json` is a plain file and a personal hook in it publishes, so run this after cloning:

```bash
git config filter.public-settings.clean bin/public-settings
git config filter.public-settings.smudge 'in=$(cat); if [ -f settings.personal.json ] && printf "%s\n" "$in" | jq -e . >/dev/null 2>&1; then printf "%s\n" "$in" | jq -s ".[0] * .[1]" - settings.personal.json; else printf "%s\n" "$in"; fi'
git config filter.public-settings.required true
```

## Sync with Codex

1. Edit skills in `~/.claude/skills/`, then copy the dirs Codex needs into `~/.agents/skills/`. There is no live symlink.
2. Mirror host files: Claude `agents/*.md` against Codex `agents/*.toml`, `CLAUDE.md` against `AGENTS.md`, and `contracts/` against `~/.codex/contracts/` with the `~/.claude/` paths rewritten to `~/.codex/`.
3. Set visibility on both sides: Claude via `disable-model-invocation` plus `skillOverrides`, Codex via `agents/openai.yaml` `allow_implicit_invocation`.
4. Restart both hosts after global changes.
