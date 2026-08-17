#!/usr/bin/env bash

# Facts-only Agentennetzwerk usage/savings report.
# Never converts skipped calls into token savings without a measured counterfactual baseline.

set -u
DATA="${CLAUDE_PLUGIN_DATA:-${HOME:-.}/.claude/agentennetzwerk}"
RUNS="$DATA/telemetry/runs.tsv"

if [ ! -f "$RUNS" ] || [ "$(wc -l < "$RUNS" | tr -d ' ')" -le 1 ]; then
  cat <<'EOF'
TRACKED_RUNS=0
ACTUAL_CLAUDE_TOKENS_USED=0
ACTUAL_SUPERVISOR_TOKENS=0
ACTUAL_SUBAGENT_TOKENS=0
CLAUDE_SUBAGENT_CALLS=0
CODEX_CALLS_OBSERVED=0
GROK_CALLS_OBSERVED=0
UNUSED_CONFIGURED_CALL_SLOTS=0
VERIFIED_TOKENS_SAVED=NOT_MEASURABLE_YET
REASON=No completed Agentennetzwerk telemetry runs have been recorded yet. Tracking starts with plugin version 0.5.0.
EOF
else
  awk -F '\t' '
  NR == 1 { next }
  {
    runs++
    main += $4
    sub += $5
    total += $6
    subcalls += $7
    codex += $8
    grok += $9
    unused += $10
  }
  END {
    printf "TRACKED_RUNS=%d\n", runs
    printf "ACTUAL_CLAUDE_TOKENS_USED=%.0f\n", total
    printf "ACTUAL_SUPERVISOR_TOKENS=%.0f\n", main
    printf "ACTUAL_SUBAGENT_TOKENS=%.0f\n", sub
    printf "CLAUDE_SUBAGENT_CALLS=%d\n", subcalls
    printf "CODEX_CALLS_OBSERVED=%d\n", codex
    printf "GROK_CALLS_OBSERVED=%d\n", grok
    printf "UNUSED_CONFIGURED_CALL_SLOTS=%d\n", unused
    print "VERIFIED_TOKENS_SAVED=NOT_COMPUTABLE_WITHOUT_CONTROLLED_BASELINE"
    print "REASON=Actual usage is measurable; tokens a skipped model call would have consumed are counterfactual and are not invented. Unused call slots are reported as calls, not converted into tokens."
    print "SCOPE=Claude token totals come from recorded Claude Code main/subagent transcript usage fields. External Codex/Grok call counts are observed, but their token totals are not included in ACTUAL_CLAUDE_TOKENS_USED."
  }
  ' "$RUNS"
fi

printf '\n--- CONTROLLED EVALS ---\n'
bash "${CLAUDE_PLUGIN_ROOT}/scripts/eval-report.sh"
