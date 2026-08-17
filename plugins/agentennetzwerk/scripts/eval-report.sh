#!/usr/bin/env bash

# Report controlled benchmark quality and factual Claude-only token comparisons.

set -u
DATA="${CLAUDE_PLUGIN_DATA:-${HOME:-.}/.claude/agentennetzwerk}"
RESULTS="$DATA/eval/results.tsv"
RUNS="$DATA/telemetry/runs.tsv"

if [ ! -f "$RESULTS" ] || [ "$(wc -l < "$RESULTS" | tr -d ' ')" -le 1 ]; then
  echo "EVAL_RUNS=0"
  echo "EVAL_STATUS=No controlled eval results recorded yet."
  exit 0
fi

TOTAL="$(awk -F '\t' 'NR>1{n++} END{print n+0}' "$RESULTS")"
PASS="$(awk -F '\t' 'NR>1 && $4=="PASS"{n++} END{print n+0}' "$RESULTS")"
printf 'EVAL_RUNS=%s\n' "$TOTAL"
printf 'EVAL_PASSES=%s\n' "$PASS"

for scenario in quick standard deep; do
  for variant in baseline network; do
    q="$(awk -F '\t' -v v="$variant" -v s="$scenario" '
      NR>1 && $2==v && $3==s {n++; if($4=="PASS")p++; files+=$6; ins+=$7; del+=$8}
      END {if(n>0) printf "%d|%d|%.1f|%.1f|%.1f", n,p,files/n,ins/n,del/n; else printf "0|0|0|0|0"}
    ' "$RESULTS")"
    IFS='|' read -r qruns qpass qfiles qins qdel <<EOF
$q
EOF

    truns=0
    tavg=0
    if [ -f "$RUNS" ]; then
      t="$(awk -F '\t' -v m="eval-${variant}-${scenario}" '
        NR>1 && $3==m {n++; tok+=$6}
        END {if(n>0) printf "%d|%.0f", n,tok/n; else printf "0|0"}
      ' "$RUNS")"
      IFS='|' read -r truns tavg <<EOF
$t
EOF
    fi

    prefix="$(printf '%s_%s' "$variant" "$scenario" | tr '[:lower:]' '[:upper:]')"
    printf '%s_QUALITY_RUNS=%s\n' "$prefix" "$qruns"
    printf '%s_QUALITY_PASSES=%s\n' "$prefix" "$qpass"
    printf '%s_AVG_CHANGED_FILES=%s\n' "$prefix" "$qfiles"
    printf '%s_AVG_INSERTIONS=%s\n' "$prefix" "$qins"
    printf '%s_AVG_DELETIONS=%s\n' "$prefix" "$qdel"
    printf '%s_TOKEN_RUNS=%s\n' "$prefix" "$truns"
    printf '%s_AVG_CLAUDE_TOKENS=%s\n' "$prefix" "$tavg"
  done

done

for scenario in quick standard deep; do
  base="$(awk -F '\t' -v m="eval-baseline-${scenario}" 'NR>1 && $3==m {n++; t+=$6} END{if(n)printf "%.0f",t/n; else print "NA"}' "$RUNS" 2>/dev/null || echo NA)"
  net="$(awk -F '\t' -v m="eval-network-${scenario}" 'NR>1 && $3==m {n++; t+=$6} END{if(n)printf "%.0f",t/n; else print "NA"}' "$RUNS" 2>/dev/null || echo NA)"
  upper="$(printf '%s' "$scenario" | tr '[:lower:]' '[:upper:]')"
  if [ "$base" != "NA" ] && [ "$net" != "NA" ]; then
    delta=$(( net - base ))
    printf '%s_CLAUDE_ONLY_TOKEN_DELTA_NETWORK_MINUS_BASELINE=%s\n' "$upper" "$delta"
  else
    printf '%s_CLAUDE_ONLY_TOKEN_DELTA_NETWORK_MINUS_BASELINE=NOT_PAIRED_YET\n' "$upper"
  fi
done

echo "EVAL_TOKEN_SCOPE=Claude-only. Codex/Grok token totals are not included, so this is not an overall AI-token-savings claim."
echo "EVAL_COMPARISON_RULE=Compare quality first; interpret token deltas only when baseline and network runs use the same scenario and main Claude model/settings."
