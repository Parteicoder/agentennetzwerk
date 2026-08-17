#!/usr/bin/env bash

# Finalize one Agentennetzwerk run when the parent Claude turn stops.
# Persists factual Claude transcript usage and observed external CLI call counts.

set -u
INPUT="$(cat 2>/dev/null)"

extract_json_string() {
  key="$1"
  printf '%s' "$INPUT" | sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -n 1
}

SESSION_ID="$(extract_json_string session_id)"
AGENT_ID="$(extract_json_string agent_id)"

# Stop hooks can also exist in subagent contexts. Only the parent turn may close a network run.
[ -z "$AGENT_ID" ] || exit 0
[ -n "$SESSION_ID" ] || exit 0

DATA="${CLAUDE_PLUGIN_DATA:-${HOME:-.}/.claude/agentennetzwerk}"
ACTIVE="$DATA/telemetry/active"
STATE="$ACTIVE/$SESSION_ID.state"
AGENTS="$ACTIVE/$SESSION_ID.agents.tsv"
RUNS="$DATA/telemetry/runs.tsv"
[ -f "$STATE" ] || exit 0

IFS='\t' read -r TRANSCRIPT START_TOKENS START_LINES MODE STARTED_AT CWD < "$STATE"
START_TOKENS="${START_TOKENS:-0}"
START_LINES="${START_LINES:-0}"
MODE="${MODE:-auto}"

CURRENT_TOKENS="$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/token-usage.sh" "$TRANSCRIPT" 2>/dev/null || echo 0)"
MAIN_TOKENS=$(( CURRENT_TOKENS - START_TOKENS ))
[ "$MAIN_TOKENS" -ge 0 ] 2>/dev/null || MAIN_TOKENS=0

SUBAGENT_TOKENS=0
SUBAGENT_CALLS=0
if [ -f "$AGENTS" ]; then
  SUBAGENT_TOKENS="$(awk -F '\t' '{s += $3} END {print s+0}' "$AGENTS")"
  SUBAGENT_CALLS="$(awk 'END {print NR+0}' "$AGENTS")"
fi

CODEX_CALLS=0
GROK_CALLS=0
if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
  FROM_LINE=$(( START_LINES + 1 ))
  CODEX_CALLS="$(tail -n +"$FROM_LINE" "$TRANSCRIPT" 2>/dev/null | awk '
    /\"type\"[[:space:]]*:[[:space:]]*\"assistant\"/ && /\"type\"[[:space:]]*:[[:space:]]*\"tool_use\"/ {
      line=$0; n=gsub(/codex exec/, "codex exec", line); c+=n
    } END {print c+0}')"
  GROK_CALLS="$(tail -n +"$FROM_LINE" "$TRANSCRIPT" 2>/dev/null | awk '
    /\"type\"[[:space:]]*:[[:space:]]*\"assistant\"/ && /\"type\"[[:space:]]*:[[:space:]]*\"tool_use\"/ {
      line=$0; n1=gsub(/grok --no-auto-update/, "grok --no-auto-update", line); n2=gsub(/grok -p/, "grok -p", line); c+=n1+n2
    } END {print c+0}')"
fi

TOTAL_CLAUDE=$(( MAIN_TOKENS + SUBAGENT_TOKENS ))
MODEL_CALLS=$(( SUBAGENT_CALLS + CODEX_CALLS + GROK_CALLS ))

BUDGET=0
case "$MODE" in
  quick|eval-network-quick) BUDGET=3 ;;
  standard|eval-network-standard) BUDGET=4 ;;
  deep|eval-network-deep) BUDGET=6 ;;
  # Baseline evals intentionally have no network call budget.
  eval-baseline-*) BUDGET=0 ;;
esac
UNUSED=0
if [ "$BUDGET" -gt "$MODEL_CALLS" ]; then
  UNUSED=$(( BUDGET - MODEL_CALLS ))
fi

mkdir -p "$DATA/telemetry"
if [ ! -f "$RUNS" ]; then
  printf 'timestamp\tsession\tmode\tmain_claude_tokens\tsubagent_claude_tokens\ttotal_claude_tokens\tsubagent_calls\tcodex_calls\tgrok_calls\tunused_call_budget\tcwd\n' > "$RUNS"
fi

clean() { printf '%s' "$1" | tr '\t\r\n' '   '; }
printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
  "$(date +%s)" "$SESSION_ID" "$MODE" "$MAIN_TOKENS" "$SUBAGENT_TOKENS" "$TOTAL_CLAUDE" \
  "$SUBAGENT_CALLS" "$CODEX_CALLS" "$GROK_CALLS" "$UNUSED" "$(clean "$CWD")" >> "$RUNS"

rm -f "$STATE" "$AGENTS"
exit 0
