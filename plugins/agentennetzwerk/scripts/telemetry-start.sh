#!/usr/bin/env bash

# Start factual Agentennetzwerk telemetry for a direct /agentennetzwerk:start invocation.
# Stores only local metadata and transcript token snapshots in CLAUDE_PLUGIN_DATA.

set -u
INPUT="$(cat 2>/dev/null)"

extract_json_string() {
  key="$1"
  printf '%s' "$INPUT" | sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -n 1
}

SESSION_ID="$(extract_json_string session_id)"
TRANSCRIPT="$(extract_json_string transcript_path)"
COMMAND_ARGS="$(extract_json_string command_args)"
CWD="$(extract_json_string cwd)"

[ -n "$SESSION_ID" ] || exit 0
DATA="${CLAUDE_PLUGIN_DATA:-${HOME:-.}/.claude/agentennetzwerk}"
ACTIVE="$DATA/telemetry/active"
mkdir -p "$ACTIVE" "$DATA/telemetry"

MODE="auto"
case "${COMMAND_ARGS%% *}" in
  quick|standard|deep) MODE="${COMMAND_ARGS%% *}" ;;
esac

START_TOKENS=0
START_LINES=0
if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
  START_TOKENS="$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/token-usage.sh" "$TRANSCRIPT" 2>/dev/null || echo 0)"
  START_LINES="$(wc -l < "$TRANSCRIPT" 2>/dev/null | tr -d ' ' || echo 0)"
fi

# Use a simple tab-separated state file. Paths may contain spaces; tabs/newlines are sanitized.
clean() { printf '%s' "$1" | tr '\t\r\n' '   '; }
printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
  "$(clean "$TRANSCRIPT")" "$START_TOKENS" "$START_LINES" "$MODE" "$(date +%s)" "$(clean "$CWD")" \
  > "$ACTIVE/$SESSION_ID.state"

: > "$ACTIVE/$SESSION_ID.agents.tsv"
exit 0
