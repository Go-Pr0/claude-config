# Shared agent config: setup guide

This bundle is a portable orchestration layer for Claude Code and OpenAI Codex. It is not a full machine config: personal settings, auth, and runtime data stay on each host.

## What's in the zip

```text
SHARE-README.md          you are here
export-shared-config.sh  restore script (included in bundle)
claude/                  Claude Code host layer
  agents/ bin/ contracts/ rules/*.md hooks/ skills/ CLAUDE.md README.md RTK.md settings.json statusline-command.sh
codex/                   Codex host layer
  agents/ contracts/ rules/*.md AGENTS.md README.md
```

Not included (create locally on each machine):

| Personal / machine-local | Why |
|--------------------------|-----|
| `~/.codex/config.toml` | Model, MCP servers, API keys, plugins, project trust |
| `~/.codex/auth.json` | Credentials |
| `~/.codex/rules/default.rules` | Your shell command allowlist |
| `~/.codex/skills/.system/` | Native Codex skills (installed by OpenAI) |
| `~/.claude/settings.local.json` | Read only by sessions started from `~`; permission rules for every project belong in `settings.json` |
| `~/.claude/rules/machines.md` | Host addresses and logins |
| `sessions/`, `plugins/`, `cache/`, sqlite | Runtime state |

---

## How the layers fit together

```text
~/.claude/skills/     CANONICAL skills (edit here)
~/.claude/            Claude host: agents, contracts, hooks, CLAUDE.md, settings.json
~/.codex/             Codex host: agents, contracts, AGENTS.md, config.toml (local)
~/.agents/skills/     copy of ~/.claude/skills, for Codex
```

Claude discovers personal skills only under `~/.claude/skills/`.
Codex discovers user skills under `~/.agents/skills/`.

No symlink. Edit skills in Claude; restore copies them to Codex, and "Sync with Codex" below copies them after that.

---

## Quick install (from zip)

Run from the directory that holds the zip:

```bash
unzip agent-config-*.zip -d /tmp/agent-config
bash /tmp/agent-config/export-shared-config.sh --restore agent-config-*.zip
```

The restore script backs up your current shareable files under `~/.claude/_shared_restore_backup_<stamp>/`, then installs:

1. `claude/*` into `~/.claude/`, replacing `settings.json` and every skill of the same name
2. `codex/*` into `~/.codex/`
3. The skills into `~/.agents/skills/`, for Codex

Add machine-specific hooks and settings to `~/.claude/settings.json` afterwards. The hooks in the bundled copy use `~/.claude/` paths and need `jq`, and `rtk` for the Bash rewrite.

---

## Team memory (optional)

`rules/team-memory.md`, `hooks/team-memory-*.sh` and `/memory-promote` work against a git vault holding `INDEX.md`, `CONTRACT.md` and `CLAUDE.md`. They do nothing until you point them at a clone.

Set `env.TEAM_MEMORY_VAULT` in `~/.claude/settings.json` to the clone's absolute path, then register the hooks there:

- `SessionStart` (`matcher`: `startup|resume|compact`): `team-memory-session.sh` pulls the vault and injects `INDEX.md` through `hookSpecificOutput.additionalContext`. It fails when the vault is unset or missing, so register it only on a machine with a clone.
- `SessionEnd`: `team-memory-capture.sh` appends to `inbox/`, with no JSON output.

Do not register capture on `Stop`, which fires once per turn.

---

## Sync with Codex

1. Edit skills in `~/.claude/skills/`.
2. Copy skill dirs to `~/.agents/skills/` when Codex should use them.
3. Mirror host files: Claude `agents/*.md` and Codex `agents/*.toml`; `CLAUDE.md` and `AGENTS.md`.
4. Restart both hosts after global changes.

```bash
# one-shot copy
mkdir -p ~/.agents/skills
for s in orchestrator research workflow prompt handoff explain review audit autonomous-sprint writing-prompts memory-promote instructions; do
  [[ -d ~/.claude/skills/$s ]] && cp -a ~/.claude/skills/$s ~/.agents/skills/
done
```
