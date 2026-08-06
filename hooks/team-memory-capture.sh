#!/usr/bin/env bash
# SessionEnd (Claude) / sessionEnd + stop (Cursor): append session extract to vault inbox (never auto-promote).
set -euo pipefail

[[ -n "${TEAM_MEMORY_VAULT:-}" ]] || exit 0
[[ -d "$TEAM_MEMORY_VAULT" ]] || exit 0

INPUT=$(cat)

CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
if [[ -z "$CWD" || "$CWD" == "null" ]]; then
  CWD="${PWD:-unknown}"
fi
CWD_BASE=$(basename "$CWD")

SUMMARY=$(echo "$INPUT" | jq -r '.last_assistant_message // empty' | head -1 | tr '\n' ' ' | sed 's/  */ /g')
if [[ -z "$SUMMARY" || "$SUMMARY" == "null" ]]; then
  SUMMARY=$(echo "$INPUT" | jq -r '[.status, .reason, .final_status] | map(select(. != null and . != "")) | first // empty')
fi
SUMMARY=$(printf '%s' "$SUMMARY" | cut -c1-200)

TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
DATE=$(date -u +%Y-%m-%d)
INBOX_DIR="$TEAM_MEMORY_VAULT/inbox"
INBOX_FILE="$INBOX_DIR/${DATE}.md"

mkdir -p "$INBOX_DIR"

{
  echo ""
  echo "## Capture ${TS}"
  echo "- cwd: ${CWD_BASE}"
  if [[ -n "$SUMMARY" ]]; then
    echo "- summary: ${SUMMARY}"
  fi
} >>"$INBOX_FILE"

exit 0
