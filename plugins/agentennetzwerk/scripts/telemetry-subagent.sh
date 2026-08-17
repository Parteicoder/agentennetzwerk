#!/usr/bin/env bash

# Record factual token usage for Agentennetzwerk Claude subagents.
# Triggered by SubagentStop and reads the subagent's real JSONL transcript.

set -u
INPUT="$(cat 2>/dev/null)"

extract_json_string() {
  key="$1"
  printf '%s' "$INPUT" | sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -n 1
}

SESSION_ID="$(extract_json_string session_id)"
AGENT_ID="$(extract_json_string agent_id)"
AGENT_TYPE="$(extract_json_string agent_type)"
AGENT_TRANSCRIPT="$(extract_json_string agent_transcript_path)"

case "$AGENT_TYPE" in
  agentennetzwerk:claude-builder|agentennetzwerk:architect|agentennetzwerk:reviewer|agentennetzwerk:security-reviewer) ;;
  *) exit 0 ;;
esac

[ -n "$SESSION_ID" ] || exit 0
DATA="${CLAUDE_PLUGIN_DATA:-${HOME:-.}/.claude/agentennetzwerk}"
ACTIVE="$DATA/telemetry/active"
STATE="$ACTIVE/$SESSION_ID.state"
LOG="$ACTIVE/$SESSION_ID.agents.tsv"
[ -f "$STATE" ] || exit 0

# Avoid double recording if a stop hook is retried.
if [ -f "$LOG" ] && grep -Fq "${AGENT_ID}" "$LOG" 2>/dev/null; then
  exit 0
fi

TOKENS="$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/token-usage.sh" "$AGENT_TRANSCRIPT" 2>/dev/null || echo 0)"
printf '%s\t%s\t%s\n' "$AGENT_ID" "$AGENT_TYPE" "$TOKENS" >> "$LOG"
exit 0
