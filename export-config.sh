#!/usr/bin/env bash
# Bundle shareable Claude Code machine config into a zip.
#
# Usage:
#   export-config.sh              # writes ~/Desktop/claude-code-config-<timestamp>.zip
#   export-config.sh /path/out    # custom output directory
#   export-config.sh --restore path/to/archive.zip
#
# Skills live in ~/.claude/skills/ (canonical real directory).
#
# For a combined Claude + Codex bundle, use export-shared-config.sh instead.

set -euo pipefail

CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
CLAUDE_SKILLS_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"

SHARE_PATHS=(
  agents
  contracts
  hooks
  CLAUDE.md
  README.md
  RTK.md
  settings.json
  statusline-command.sh
)

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
)

usage() {
  cat <<'EOF'
Usage:
  export-config.sh [output-dir]     Create a timestamped zip (default: ~/Desktop)
  export-config.sh --restore <zip>  Restore archive into ~/.claude (backs up first)

Environment:
  CLAUDE_DIR         Claude host root (default: ~/.claude)
  CLAUDE_SKILLS_DIR  Skills root (default: ~/.claude/skills)
EOF
}

copy_rules_md() {
  local src_dir="$1" dest_dir="$2"
  mkdir -p "$dest_dir"
  shopt -s nullglob
  for f in "$src_dir"/*.md; do cp -a "$f" "$dest_dir/"; done
  shopt -u nullglob
}

restore_rules_md() {
  local src_dir="$1" dest_dir="$2"
  mkdir -p "$dest_dir"
  shopt -s nullglob
  for f in "$src_dir"/*.md; do cp -a "$f" "$dest_dir/"; done
  shopt -u nullglob
}

restore() {
  local archive="$1"
  local backup_dir stamp staging

  [[ -f "$archive" ]] || { echo "archive not found: $archive" >&2; exit 1; }

  stamp="$(date +%Y%m%d-%H%M%S)"
  backup_dir="${CLAUDE_DIR}/_restore_backup_${stamp}"
  staging="$(mktemp -d)"

  echo "Backing up current config to ${backup_dir}"
  mkdir -p "$backup_dir/skills"
  for path in "${SHARE_PATHS[@]}"; do
    [[ -e "${CLAUDE_DIR}/${path}" ]] && mkdir -p "$backup_dir/$(dirname "$path")" && cp -a "${CLAUDE_DIR}/${path}" "${backup_dir}/${path}"
  done
  copy_rules_md "${CLAUDE_DIR}/rules" "${backup_dir}/rules"
  for skill in "${CUSTOM_SKILLS[@]}"; do
    [[ -d "${CLAUDE_SKILLS_DIR}/${skill}" ]] && cp -a "${CLAUDE_SKILLS_DIR}/${skill}" "$backup_dir/skills/"
  done

  unzip -q -o "$archive" -d "$staging"
  mkdir -p "$CLAUDE_DIR" "$CLAUDE_SKILLS_DIR"

  for path in "${SHARE_PATHS[@]}"; do
    [[ -e "${staging}/${path}" ]] && cp -a "${staging}/${path}" "${CLAUDE_DIR}/${path}"
  done
  [[ -d "${staging}/rules" ]] && restore_rules_md "${staging}/rules" "${CLAUDE_DIR}/rules"
  for skill in "${CUSTOM_SKILLS[@]}"; do
    if [[ -d "${staging}/skills/${skill}" ]]; then
      rm -rf "${CLAUDE_SKILLS_DIR}/${skill}"
      cp -a "${staging}/skills/${skill}" "${CLAUDE_SKILLS_DIR}/${skill}"
    elif [[ -d "${staging}/.agents/skills/${skill}" ]]; then
      rm -rf "${CLAUDE_SKILLS_DIR}/${skill}"
      cp -a "${staging}/.agents/skills/${skill}" "${CLAUDE_SKILLS_DIR}/${skill}"
    fi
  done

  chmod +x "${CLAUDE_DIR}/export-config.sh" 2>/dev/null || true
  chmod +x "${CLAUDE_DIR}/statusline-command.sh" 2>/dev/null || true
  chmod +x "${CLAUDE_DIR}/hooks/"*.sh 2>/dev/null || true
  rm -rf "$staging"

  echo "Restored. Review settings.local.json and runtime dirs separately."
  echo "Previous config backed up at: ${backup_dir}"
}

export_config() {
  local output_dir="${1:-$HOME/Desktop}"
  local stamp zip_path staging missing=0

  stamp="$(date +%Y%m%d-%H%M%S)"
  zip_path="${output_dir%/}/claude-code-config-${stamp}.zip"
  staging="$(mktemp -d)"
  mkdir -p "$output_dir" "${staging}/skills"

  for path in "${SHARE_PATHS[@]}"; do
    if [[ -e "${CLAUDE_DIR}/${path}" ]]; then
      mkdir -p "${staging}/$(dirname "$path")"
      cp -aL "${CLAUDE_DIR}/${path}" "${staging}/${path}"
    else
      echo "warning: missing ${CLAUDE_DIR}/${path}" >&2
      missing=$((missing + 1))
    fi
  done
  copy_rules_md "${CLAUDE_DIR}/rules" "${staging}/rules"
  for skill in "${CUSTOM_SKILLS[@]}"; do
    if [[ -d "${CLAUDE_SKILLS_DIR}/${skill}" ]]; then
      cp -a "${CLAUDE_SKILLS_DIR}/${skill}" "${staging}/skills/${skill}"
    else
      echo "warning: missing skill ${skill}" >&2
      missing=$((missing + 1))
    fi
  done

  cp -a "$0" "${staging}/export-config.sh"
  chmod +x "${staging}/export-config.sh"

  {
    echo "Claude Code config bundle"
    echo "Created: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "Skills source: ${CLAUDE_SKILLS_DIR}"
    echo "Not included: settings.local.json, projects/, plugins/, runtime caches"
  } > "${staging}/MANIFEST.txt"

  (
    cd "$staging"
    zip -qr "$zip_path" .
  )
  rm -rf "$staging"

  echo "Wrote $zip_path"
  [[ "$missing" -eq 0 ]] || echo "warnings: $missing missing paths" >&2
}

case "${1:-}" in
  -h|--help) usage ;;
  --restore)
    [[ $# -ge 2 ]] || { usage >&2; exit 1; }
    restore "$2"
    ;;
  *) export_config "${1:-}" ;;
esac
