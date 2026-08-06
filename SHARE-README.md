# Shared agent config — setup guide

This bundle is a **portable orchestration layer** for Claude Code and OpenAI Codex. It is not a full machine config — personal settings, auth, and runtime data stay on each host.

## What’s in the zip

```text
SHARE-README.md          ← you are here
export-shared-config.sh  ← restore script (included in bundle)
claude/                  ← Claude Code host layer
  agents/ contracts/ rules/*.md hooks/ skills/ CLAUDE.md README.md settings.json
codex/                   ← Codex host layer
  agents/ contracts/ rules/*.md AGENTS.md README.md
```

**Not included (create locally on each machine):**

| Personal / machine-local | Why |
|--------------------------|-----|
| `~/.codex/config.toml` | Model, MCP servers, API keys, plugins, project trust |
| `~/.codex/auth.json` | Credentials |
| `~/.codex/rules/default.rules` | Your shell command allowlist |
| `~/.codex/skills/.system/` | Native Codex skills (installed by OpenAI) |
| `~/.claude/settings.local.json` | Local permission overrides, `TEAM_MEMORY_VAULT` env |
| `gacha-team-memory` clone | Gacha team memory git repo (separate from this zip) |
| `sessions/`, `plugins/`, `cache/`, sqlite | Runtime state |

---

## How the layers fit together

```text
~/.claude/skills/     ← CANONICAL skills (edit here)
~/.claude/            ← Claude host: agents, contracts, hooks, CLAUDE.md, settings.json
~/.codex/             ← Codex host: agents, contracts, AGENTS.md, config.toml (local)

Optional for Codex:
~/.agents/skills/     ← copy of ~/.claude/skills when you want Codex to see them
```

Claude discovers personal skills only under `~/.claude/skills/`.
Codex discovers user skills under `~/.agents/skills/`.

**No symlink.** Edit skills in Claude, copy to Codex when needed (export/restore does this optionally).

---

## Quick install (from zip)

```bash
unzip agent-config-*.zip -d /tmp/agent-config
bash /tmp/agent-config/export-shared-config.sh --restore /tmp/agent-config/agent-config-*.zip
```

Or if you already extracted:

```bash
bash export-shared-config.sh --restore ./agent-config-<timestamp>.zip
```

The restore script backs up your current shareable files, then installs:

1. `claude/*` → `~/.claude/` (including `skills/`)
2. `codex/*` → `~/.codex/`
3. Optionally copies skills into `~/.agents/skills/` for Codex

---

## Team memory vault

Gacha team-memory hooks ship in the workspace repo (`.claude/hooks/team-memory-*.sh` and `.claude/settings.json`). Memory-only onboarding: pull the workspace, clone the vault below, set `TEAM_MEMORY_VAULT` in `settings.local.json`. No export zip required. See `docs/gacha/ONBOARD-MEMORY.md` in the workspace after PR #26 merges.

The export zip below is still required for machine-wide orchestrator skills, RTK hooks, and other `~/.claude` host wiring outside the gacha workspace.

After zip restore (or workspace pull for hooks only), clone the Gacha team vault into the gacha workspace and point hooks at it on this machine:

```bash
git clone git@github.com:ID-Holding/gacha-team-memory.git /path/to/gacha/gacha-team-memory
```

Replaces archived `ID-Holding/team-memory-vault` (`~/team-memory-vault`) for gacha work. Do not clone or use `team-memory-vault`; use `gacha-team-memory` only.

The vault is not PR-gated. Session capture writes to gitignored `inbox/` via `SessionEnd` on Claude Code (once per session; side-effect only). `/memory-promote` compiles notes and pushes directly to `main`.

Hook wiring: project `.claude/settings.json` in the gacha workspace (preferred). Legacy zip installs may still have user-level entries in shareable `settings.json`; remove those when using workspace project hooks to avoid duplicate INDEX inject (Claude merges hook sources).

- `SessionStart` (`matcher`: `startup|resume|compact`) → `team-memory-session.sh` (pull vault, inject `INDEX.md` via `hookSpecificOutput.additionalContext`)
- `SessionEnd` → `team-memory-capture.sh` (append to `inbox/`; no JSON output)

Do not register capture on Claude `Stop` (fires once per turn). Cursor keeps its own `hooks.json` (`sessionEnd` and optionally `stop`).

Create or extend `~/.claude/settings.local.json`:

```json
{
  "env": {
    "TEAM_MEMORY_VAULT": "/path/to/gacha/gacha-team-memory"
  }
}
```

The vault clone path and `settings.local.json` are machine-local (same exclusion list as above). They are not in the export zip.

Teammate checklist (memory only, no zip):

1. Clone or pull `ID-Holding/workspace` and open the gacha workspace.
2. Clone `ID-Holding/gacha-team-memory` into the workspace as `gacha-team-memory/`.
3. Set `env.TEAM_MEMORY_VAULT` in `~/.claude/settings.local.json` to that absolute path.
4. If you have team-memory `SessionStart` / `SessionEnd` in `~/.claude/settings.json` from an old zip, remove them (workspace project hooks replace them).
5. Cursor users: run `~/.cursor/sync-from-claude.sh`.
6. Restart Claude Code or Cursor.
7. Claude: confirm `SessionStart` pulls the vault and the INDEX prefix appears in the session transcript.
8. Claude: end a session and confirm one capture block lands in `inbox/YYYY-MM-DD.md` (not once per turn).

Teammate checklist (full agent stack via zip):

1. Restore the zip (`export-shared-config.sh --restore …`).
2. Clone `ID-Holding/gacha-team-memory` into the gacha workspace as `gacha-team-memory/`.
3. Set `env.TEAM_MEMORY_VAULT` in `~/.claude/settings.local.json` to that absolute path.
4. Remove team-memory `SessionStart` / `SessionEnd` from `~/.claude/settings.json` if present (workspace project hooks replace them).
5. Cursor users: run `~/.cursor/sync-from-claude.sh`.
6. Restart Claude Code or Cursor.
7. Claude: confirm `SessionStart` pulls the vault and the INDEX prefix appears in the session transcript (`jq '.hooks | keys'` on workspace `.claude/settings.json` should list `SessionStart` and `SessionEnd`, not `Stop` for capture).
8. Claude: end a session and confirm one capture block lands in `inbox/YYYY-MM-DD.md` (not once per turn).
9. Cursor: confirm `TEAM_MEMORY_VAULT` is set; read INDEX on demand per `rules/team-memory` when the task needs team context.

Teammate dry-run (recipient machine, full path):

```bash
bash ~/.claude/export-shared-config.sh --restore /path/to/agent-config-*.zip
git clone git@github.com:ID-Holding/gacha-team-memory.git /path/to/gacha/gacha-team-memory
# edit ~/.claude/settings.local.json env.TEAM_MEMORY_VAULT=/path/to/gacha/gacha-team-memory
~/.cursor/sync-from-claude.sh   # Cursor users
# restart Claude Code / Cursor; open gacha workspace
# Claude: jq '.hooks | keys' ~/.claude/settings.json  # expect SessionStart, SessionEnd (no Stop for capture)
# Claude: confirm INDEX prefix in SessionStart transcript; one inbox capture on session end
# Cursor: confirm TEAM_MEMORY_VAULT env set; rule-driven INDEX read when task needs team context
```

---

## Sync with Codex

1. Edit skills in `~/.claude/skills/`.
2. Copy skill dirs to `~/.agents/skills/` when Codex should use them.
3. Mirror host files: Claude `agents/*.md` ↔ Codex `agents/*.toml`; `CLAUDE.md` ↔ `AGENTS.md`.
4. Restart both hosts after global changes.

```bash
# one-shot copy
mkdir -p ~/.agents/skills
for s in orchestrator research workflow prompt handoff explain review audit autonomous-sprint writing-prompts memory-promote instructions; do
  [[ -d ~/.claude/skills/$s ]] && cp -a ~/.claude/skills/$s ~/.agents/skills/
done
```
