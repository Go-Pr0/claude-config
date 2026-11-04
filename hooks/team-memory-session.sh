#!/usr/bin/env bash
# SessionStart / sessionStart (matcher startup|resume|compact on Claude): pull vault and inject INDEX (Claude) or set env (Cursor).
set -euo pipefail

MAX_INDEX_CHARS=7000
PREFIX='Team memory INDEX (read wiki/concepts/ on demand, ≤4 notes):'

fail() {
  echo "team-memory-session: $*" >&2
  exit 1
}

require_vault() {
  [[ -n "${TEAM_MEMORY_VAULT:-}" ]] || fail "TEAM_MEMORY_VAULT is unset"
  [[ -d "$TEAM_MEMORY_VAULT" ]] || fail "TEAM_MEMORY_VAULT path missing: $TEAM_MEMORY_VAULT"
}

detect_host() {
  local flag="${1:-}"
  local input="${2:-}"

  case "$flag" in
    --cursor) echo cursor; return ;;
    --claude) echo claude; return ;;
  esac

  if [[ -z "$input" ]]; then
    echo claude
    return
  fi

  local event
  event=$(echo "$input" | jq -r '.hook_event_name // .hookEventName // empty')
  if [[ "$event" == "SessionStart" ]]; then
    echo claude
    return
  fi

  if echo "$input" | jq -e 'has("session_id")' >/dev/null 2>&1; then
    echo cursor
    return
  fi

  echo claude
}

INPUT=""
if [[ ! -t 0 ]]; then
  INPUT=$(cat)
fi

HOST=$(detect_host "${1:-}" "$INPUT")

require_vault
git -C "$TEAM_MEMORY_VAULT" pull --ff-only >&2

if [[ "$HOST" == "cursor" ]]; then
  jq -n --arg v "$TEAM_MEMORY_VAULT" '{"env":{"TEAM_MEMORY_VAULT":$v}}'
  exit 0
fi

INDEX_FILE="$TEAM_MEMORY_VAULT/INDEX.md"
[[ -f "$INDEX_FILE" ]] || fail "INDEX.md missing at $INDEX_FILE"

INDEX_CONTENT=$(<"$INDEX_FILE")
if ((${#INDEX_CONTENT} > MAX_INDEX_CHARS)); then
  INDEX_CONTENT="${INDEX_CONTENT:0:MAX_INDEX_CHARS}
… [INDEX truncated at ${MAX_INDEX_CHARS} chars; read ${INDEX_FILE} on demand]"
fi

CONTEXT="${PREFIX}
${INDEX_CONTENT}"

jq -n --arg ctx "$CONTEXT" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: $ctx
  }
}'
