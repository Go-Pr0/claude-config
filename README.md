# ~/.claude — machine-wide Claude Code layer

Parallel to `~/.codex/`. Skills live in `~/.claude/skills/` (real directory — not a symlink).

**Codex mirror:** `~/.codex/` — `AGENTS.md`, `agents/*.toml`, `config.toml` (local). Copy skills to `~/.agents/skills/` when Codex needs them.

## Directory layout

```text
~/.claude/
├── CLAUDE.md              machine-wide habits
├── settings.json          skillOverrides, hooks, model (shareable template)
├── settings.local.json    permissions (local only — not in zip)
├── skills/                personal skills (canonical — edit here)
├── agents/                web-search-*.md subagents
├── contracts/             research.md / plan.md / artifacts.md shapes
├── rules/                 *.md behavioral guidance
├── hooks/                 rtk-rewrite, biome format (Claude-only)
├── export-config.sh       Claude-only zip
├── export-shared-config.sh  Claude + Codex + skills zip
└── SHARE-README.md        setup guide for zip recipients
```

## What loads each session

```text
1. ~/.claude/CLAUDE.md       machine-wide habits
2. repo/CLAUDE.md            project contract
3. skills metadata           from ~/.claude/skills/
4. settings.json             skillOverrides
```

| Skill | Visibility |
|-------|------------|
| `/orchestrator` | `user-invocable-only` |
| `/research` | `user-invocable-only` |
| `/workflow` | `name-only` globally; re-enabled in agent frontmatter |
| `/prompt` | `user-invocable-only` |
| `/handoff` | `user-invocable-only` |
| `/explain` | `user-invocable-only` |
| `/review` | `user-invocable-only` |
| `/audit` | `user-invocable-only` |

## `settings.json` skillOverrides

| Override | Effect |
|----------|--------|
| `orchestrator` | `user-invocable-only` |
| `research` | `user-invocable-only` |
| `workflow` | `name-only` |
| `prompt` | `user-invocable-only` |
| `handoff` | `user-invocable-only` |
| `explain` | `user-invocable-only` |
| `review` | `user-invocable-only` |
| `audit` | `user-invocable-only` |
| `autonomous-sprint` | `off` |
| `deep-research` | `off` |

Planner, investigator, implementer, plan closer, wave closer, and reviewer re-enable `workflow` in agent frontmatter `skills`.

## Orchestrator (`/orchestrator`)

Intent translator and dispatcher, not implementer. Full rules: `skills/orchestrator/SKILL.md`.

Flow: create `plans/active/<topic>/` → optional research → plan → plan-closer → implementer waves → wave-closer only for ultra-critical waves (~5%) → verification → report.

`/research` — separate user-invoked skill for multi-wave research and sequential planners.

`/audit` — map with `web-search-surface-mapper`, deep-dive with `web-search-auditor`, group into `plan.md`, execute fixes in the same session. User-invoked only.

## `agents/` — nine custom agents

| Agent | Workflow | Output |
|-------|----------|--------|
| `web-search-researcher` | no | `research.md` |
| `web-search-investigator` | yes | `plan.md` |
| `web-search-planner` | yes | `plan.md` |
| `web-search-plan-closer` | yes | edited plan files |
| `web-search-implementer` | yes | code |
| `web-search-wave-closer` | yes | code |
| `web-search-reviewer` | yes | code + chat summary |
| `web-search-surface-mapper` | no | `surfaces.md` (`/audit` only) |
| `web-search-auditor` | no | `surface-*.md` (`/audit` only) |

Definitions: `agents/web-search-*.md` with YAML frontmatter.

## Contracts

| File | Purpose |
|------|---------|
| `contracts/artifacts.md` | Repo workspace `plans/active/<topic>/` (incl. `/research` and `/audit` extended layouts) |
| `contracts/research.md` | `research.md` shape |
| `contracts/plan.md` | `plan.md` shape (wave-centric) |

## Skills

Canonical path: `~/.claude/skills/`. Edit here. For Codex, copy into `~/.agents/skills/` (or run export/restore).

| Skill | Who | How |
|-------|-----|-----|
| `orchestrator` | Main session | `/orchestrator` |
| `research` | User only | `/research` (never model-invoked) |
| `workflow` | Planner, investigator, implementer, closers, reviewer | Agent frontmatter |
| `prompt` | User only | `/prompt [ask] [mode hint]` |
| `handoff` | User only | `/handoff [note]` |
| `explain` | User only | `/explain [topic]` |
| `review` | User only | `/review [scope]` |
| `audit` | User only | `/audit [target] [brief]` |
| `autonomous-sprint` | Disabled (`off`) | — |
| `writing-prompts` | Reference | prompt craft |

Orchestrator, research, prompt, handoff, explain, review, and audit use Claude `disable-model-invocation: true` in frontmatter plus `skillOverrides: user-invocable-only`. Codex mirrors that with `agents/openai.yaml` `allow_implicit_invocation: false`. `workflow` stays model-loadable (`name-only` + no `disable-model-invocation`); its Codex yaml is still `false` so it is not implicitly matched — agents load it via frontmatter. `writing-prompts` stays model-applicable (no disable; Codex `allow_implicit_invocation: true`).

## Export / share

| Script | Output |
|--------|--------|
| `export-shared-config.sh` | Both hosts + `claude/skills/` + `SHARE-README.md` |
| `export-config.sh` | Claude host + skills |

Excluded from zips (personal): `settings.local.json`, `projects/`, `plugins/`, runtime caches.

```bash
~/.claude/export-shared-config.sh              # → ~/Desktop/agent-config-<stamp>.zip
~/.claude/export-shared-config.sh --restore path/to.zip
```

Recipients: read `SHARE-README.md` in the zip.

## Sync with Codex

1. Edit skills in `~/.claude/skills/`.
2. Copy needed skill dirs to `~/.agents/skills/` for Codex (no live symlink).
3. Mirror host files: Claude `agents/*.md` ↔ Codex `agents/*.toml`; `CLAUDE.md` ↔ `AGENTS.md`.
4. Claude: `disable-model-invocation: true` + `skillOverrides`. Codex: `agents/openai.yaml` `allow_implicit_invocation` (`false` for user-only / workflow; `true` for writing-prompts).
5. Restart both hosts after global changes.
