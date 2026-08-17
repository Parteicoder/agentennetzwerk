#!/usr/bin/env bash

# Start factual Agentennetzwerk telemetry for direct start, model-invoked start,
# or controlled benchmark runs. Stores only local metadata and transcript token snapshots.

set -u
KIND="${1:-start}"
INPUT="$(cat 2>/dev/null)"

# PreToolUse is attached to the Skill tool generally. Matchers cannot filter the
# Skill arguments, so ignore unrelated skills here. Official Claude Code hook
# semantics expose tool_input to command hooks.
if [ "$KIND" = "pretool" ]; then
  if ! printf '%s' "$INPUT" | grep -Fq 'agentennetzwerk:start'; then
    exit 0
  fi
  KIND="start"
fi

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
STATE="$ACTIVE/$SESSION_ID.state"

# Do not reset an active run if a hook is retried.
[ ! -f "$STATE" ] || exit 0

MODE="auto"
if [ "$KIND" = "eval" ]; then
  VARIANT="${COMMAND_ARGS%% *}"
  REST="${COMMAND_ARGS#* }"
  SCENARIO="${REST%% *}"
  case "$VARIANT" in network|baseline) ;; *) VARIANT="unknown" ;; esac
  case "$SCENARIO" in quick|standard|deep) ;; *) SCENARIO="unknown" ;; esac
  MODE="eval-${VARIANT}-${SCENARIO}"
else
  case "${COMMAND_ARGS%% *}" in
    quick|standard|deep) MODE="${COMMAND_ARGS%% *}" ;;
  esac
fi

START_TOKENS=0
START_LINES=0
if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
  START_TOKENS="$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/token-usage.sh" "$TRANSCRIPT" 2>/dev/null || echo 0)"
  START_LINES="$(wc -l < "$TRANSCRIPT" 2>/dev/null | tr -d ' ' || echo 0)"
fi

clean() { printf '%s' "$1" | tr '\t\r\n' '   '; }
printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
  "$(clean "$TRANSCRIPT")" "$START_TOKENS" "$START_LINES" "$MODE" "$(date +%s)" "$(clean "$CWD")" \
  > "$STATE"

: > "$ACTIVE/$SESSION_ID.agents.tsv"
exit 0
