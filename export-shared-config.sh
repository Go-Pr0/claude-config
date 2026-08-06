#!/usr/bin/env bash
# Bundle shareable Claude Code + Codex machine config into one zip.
#
# Usage:
#   export-shared-config.sh              # ~/Desktop/agent-config-<timestamp>.zip
#   export-shared-config.sh /path/out
#   export-shared-config.sh --restore path/to/archive.zip
#
# Skills: ~/.claude/skills/ (canonical). Optional Codex copy: ~/.agents/skills/
# Claude host: agents, contracts, rules/*.md, hooks, CLAUDE.md, README.md, settings.json
# Codex host: agents, contracts, rules/*.md, AGENTS.md, README.md
#
# Excluded (personal / machine-local):
#   config.toml, auth.json, settings.local.json, rules/default.rules,
#   sessions/, plugins/, cache/, skills/.system/, RTK/statusline hooks, etc.

set -euo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
CODEX_DIR="${CODEX_DIR:-$HOME/.codex}"
CLAUDE_SKILLS_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
CODEX_SKILLS_DIR="${CODEX_SKILLS_DIR:-$HOME/.agents/skills}"  # optional Codex copy target

CUSTOM_SKILLS=(
  orchestrator
  research
  workflow
  prompt
  handoff
  explain
  review
  audit
  autonomous-sprint
  writing-prompts
  memory-promote
  instructions
)

CLAUDE_SHARE_PATHS=(
  agents
  contracts
  hooks
  CLAUDE.md
  README.md
  settings.json
)

CODEX_SHARE_PATHS=(
  agents
  contracts
  AGENTS.md
  README.md
)

usage() {
  cat <<'EOF'
Usage:
  export-shared-config.sh [output-dir]     Create a timestamped zip (default: ~/Desktop)
  export-shared-config.sh --restore <zip>  Restore archive (backs up first)

Environment:
  CLAUDE_DIR         Claude host root (default: ~/.claude)
  CODEX_DIR          Codex host root (default: ~/.codex)
  CLAUDE_SKILLS_DIR  Claude skills root (default: ~/.claude/skills)
  CODEX_SKILLS_DIR   Optional Codex skills copy (default: ~/.agents/skills)
EOF
}

copy_rules_md() {
  local src_dir="$1" dest_dir="$2"
  mkdir -p "$dest_dir"
  shopt -s nullglob
  for f in "$src_dir"/*.md; do
    cp -a "$f" "$dest_dir/"
  done
  shopt -u nullglob
}

restore_rules_md() {
  local src_dir="$1" dest_dir="$2"
  mkdir -p "$dest_dir"
  shopt -s nullglob
  for f in "$src_dir"/*.md; do
    cp -a "$f" "$dest_dir/"
  done
  shopt -u nullglob
}

restore() {
  local archive="$1"
  local stamp backup_dir staging

  [[ -f "$archive" ]] || { echo "archive not found: $archive" >&2; exit 1; }

  stamp="$(date +%Y%m%d-%H%M%S)"
  backup_dir="${CLAUDE_DIR}/_shared_restore_backup_${stamp}"
  staging="$(mktemp -d)"

  echo "Backing up current shareable config to ${backup_dir}"
  mkdir -p "$backup_dir/claude" "$backup_dir/codex" "$backup_dir/claude/skills"
  for path in "${CLAUDE_SHARE_PATHS[@]}"; do
    [[ -e "${CLAUDE_DIR}/${path}" ]] && cp -a "${CLAUDE_DIR}/${path}" "${backup_dir}/claude/${path}"
  done
  copy_rules_md "${CLAUDE_DIR}/rules" "${backup_dir}/claude/rules"
  for path in "${CODEX_SHARE_PATHS[@]}"; do
    [[ -e "${CODEX_DIR}/${path}" ]] && cp -a "${CODEX_DIR}/${path}" "${backup_dir}/codex/${path}"
  done
  copy_rules_md "${CODEX_DIR}/rules" "${backup_dir}/codex/rules"
  for skill in "${CUSTOM_SKILLS[@]}"; do
    [[ -d "${CLAUDE_SKILLS_DIR}/${skill}" ]] && cp -a "${CLAUDE_SKILLS_DIR}/${skill}" "${backup_dir}/claude/skills/"
  done

  echo "Restoring from ${archive}"
  unzip -q -o "$archive" -d "$staging"

  mkdir -p "$CLAUDE_DIR" "$CODEX_DIR" "$CLAUDE_SKILLS_DIR"

  for path in "${CLAUDE_SHARE_PATHS[@]}"; do
    [[ -e "${staging}/claude/${path}" ]] && cp -a "${staging}/claude/${path}" "${CLAUDE_DIR}/${path}"
  done
  restore_rules_md "${staging}/claude/rules" "${CLAUDE_DIR}/rules"

  for path in "${CODEX_SHARE_PATHS[@]}"; do
    [[ -e "${staging}/codex/${path}" ]] && cp -a "${staging}/codex/${path}" "${CODEX_DIR}/${path}"
  done
  restore_rules_md "${staging}/codex/rules" "${CODEX_DIR}/rules"

  mkdir -p "${CLAUDE_DIR}/skills"
  for skill in "${CUSTOM_SKILLS[@]}"; do
    if [[ -d "${staging}/claude/skills/${skill}" ]]; then
      rm -rf "${CLAUDE_DIR}/skills/${skill}"
      cp -a "${staging}/claude/skills/${skill}" "${CLAUDE_DIR}/skills/${skill}"
    elif [[ -d "${staging}/.agents/skills/${skill}" ]]; then
      # legacy zip layout
      rm -rf "${CLAUDE_DIR}/skills/${skill}"
      cp -a "${staging}/.agents/skills/${skill}" "${CLAUDE_DIR}/skills/${skill}"
    fi
  done

  # Optional Codex copy (no symlink)
  if [[ -n "${CODEX_SKILLS_DIR:-}" ]]; then
    mkdir -p "$CODEX_SKILLS_DIR"
    for skill in "${CUSTOM_SKILLS[@]}"; do
      [[ -d "${CLAUDE_DIR}/skills/${skill}" ]] && cp -a "${CLAUDE_DIR}/skills/${skill}" "${CODEX_SKILLS_DIR}/${skill}"
    done
  fi

  cp -a "${staging}/export-shared-config.sh" "${CLAUDE_DIR}/export-shared-config.sh" 2>/dev/null || true
  cp -a "${staging}/export-shared-config.sh" "${CODEX_DIR}/export-shared-config.sh" 2>/dev/null || true
  chmod +x "${CLAUDE_DIR}/export-shared-config.sh" "${CODEX_DIR}/export-shared-config.sh" 2>/dev/null || true
  chmod +x "${CLAUDE_DIR}/hooks/"*.sh 2>/dev/null || true

  rm -rf "$staging"

  cat <<EOF

Restored shared agent config.

Review machine-local settings separately:
  Claude: settings.local.json, enabledPlugins, projects/, plugins/, runtime caches
  Codex:  config.toml, auth.json, rules/default.rules, skills/.system/, sessions/, plugins/

Previous config backed up at: ${backup_dir}
EOF
}

export_config() {
  local output_dir="${1:-$HOME/Desktop}"
  local stamp zip_path staging manifest missing=0

  stamp="$(date +%Y%m%d-%H%M%S)"
  zip_path="${output_dir%/}/agent-config-${stamp}.zip"
  staging="$(mktemp -d)"

  mkdir -p "$output_dir"
  mkdir -p "${staging}/claude" "${staging}/codex" "${staging}/claude/skills"

  for path in "${CLAUDE_SHARE_PATHS[@]}"; do
    if [[ -e "${CLAUDE_DIR}/${path}" ]]; then
      mkdir -p "${staging}/claude/$(dirname "$path")"
      cp -aL "${CLAUDE_DIR}/${path}" "${staging}/claude/${path}"
    else
      echo "warning: missing ${CLAUDE_DIR}/${path}" >&2
      missing=$((missing + 1))
    fi
  done
  copy_rules_md "${CLAUDE_DIR}/rules" "${staging}/claude/rules"

  for path in "${CODEX_SHARE_PATHS[@]}"; do
    if [[ -e "${CODEX_DIR}/${path}" ]]; then
      mkdir -p "${staging}/codex/$(dirname "$path")"
      cp -a "${CODEX_DIR}/${path}" "${staging}/codex/${path}"
    else
      echo "warning: missing ${CODEX_DIR}/${path}" >&2
      missing=$((missing + 1))
    fi
  done
  copy_rules_md "${CODEX_DIR}/rules" "${staging}/codex/rules"

  for skill in "${CUSTOM_SKILLS[@]}"; do
    if [[ -d "${CLAUDE_SKILLS_DIR}/${skill}" ]]; then
      cp -a "${CLAUDE_SKILLS_DIR}/${skill}" "${staging}/claude/skills/${skill}"
    else
      echo "warning: missing skill ${skill}" >&2
      missing=$((missing + 1))
    fi
  done

  cp -a "$0" "${staging}/export-shared-config.sh"
  chmod +x "${staging}/export-shared-config.sh"
  [[ -f "${CLAUDE_DIR}/SHARE-README.md" ]] && cp -a "${CLAUDE_DIR}/SHARE-README.md" "${staging}/SHARE-README.md"

  manifest="${staging}/MANIFEST.txt"
  {
    echo "Shared agent config bundle (Claude Code + Codex)"
    echo "Created: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo
    echo "Skills:         claude/skills/"
    echo "Claude host:     claude/"
    echo "Codex host:      codex/"
    echo "Setup guide:     SHARE-README.md"
    echo
    echo "Restore:"
    echo "  bash export-shared-config.sh --restore agent-config-<stamp>.zip"
    echo
    echo "Not included (create on target machine):"
    echo "  - ~/.claude/settings.local.json"
    echo "  - ~/.codex/config.toml, auth.json, rules/default.rules"
    echo "  - ~/.codex/skills/.system/"
    echo "  - sessions/, plugins/, runtime caches"
  } >"$manifest"

  (
    cd "$staging"
    zip -qr "$zip_path" .
  )

  rm -rf "$staging"

  echo "Created: ${zip_path}"
  echo "Files:   $(unzip -l "$zip_path" | tail -1 | awk '{print $2}')"
  [[ "$missing" -eq 0 ]] || echo "Note: ${missing} expected path(s) were missing at export time." >&2
}

case "${1:-}" in
  -h|--help|help)
    usage
    ;;
  --restore)
    [[ -n "${2:-}" ]] || { echo "--restore requires a zip path" >&2; usage; exit 1; }
    restore "$2"
    ;;
  *)
    export_config "${1:-}"
    ;;
esac
