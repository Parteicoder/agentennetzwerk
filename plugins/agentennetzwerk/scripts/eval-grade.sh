#!/usr/bin/env bash

# Grade an Agentennetzwerk benchmark workspace using immutable task/tests.
# Records quality facts only. Token usage is recorded separately by telemetry.

set -u

WORKSPACE="${1:-}"
SCENARIO="${2:-}"
VARIANT="${3:-network}"

case "$SCENARIO" in quick|standard|deep) ;; *) echo "invalid scenario" >&2; exit 2 ;; esac
case "$VARIANT" in network|baseline) ;; *) echo "invalid variant" >&2; exit 2 ;; esac
[ -d "$WORKSPACE/.git" ] || { echo "workspace is not an eval fixture" >&2; exit 2; }

PROTECTED_CHANGED="$(cd "$WORKSPACE" && git diff --name-only HEAD -- TASK.md package.json test | tr '\n' ',' | sed 's/,$//')"
TEST_EXIT=0
(
  cd "$WORKSPACE"
  npm test
) >/tmp/agentennetzwerk-eval-test-$$.log 2>&1 || TEST_EXIT=$?

CHANGED_FILES="$(cd "$WORKSPACE" && git diff --name-only HEAD | wc -l | tr -d ' ')"
read -r INSERTIONS DELETIONS <<EOF
$(cd "$WORKSPACE" && git diff --numstat HEAD | awk '{a+=$1; d+=$2} END {print a+0, d+0}')
EOF

QUALITY="FAIL"
REASON="tests_failed"
if [ -n "$PROTECTED_CHANGED" ]; then
  REASON="protected_files_changed:$PROTECTED_CHANGED"
elif [ "$TEST_EXIT" -eq 0 ]; then
  QUALITY="PASS"
  REASON="all_tests_passed"
fi

DATA="${CLAUDE_PLUGIN_DATA:-${HOME:-.}/.claude/agentennetzwerk}"
RESULTS="$DATA/eval/results.tsv"
mkdir -p "$DATA/eval"
if [ ! -f "$RESULTS" ]; then
  printf 'timestamp\tvariant\tscenario\tquality\ttest_exit\tchanged_files\tinsertions\tdeletions\treason\n' > "$RESULTS"
fi
printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
  "$(date +%s)" "$VARIANT" "$SCENARIO" "$QUALITY" "$TEST_EXIT" "$CHANGED_FILES" "$INSERTIONS" "$DELETIONS" "$REASON" >> "$RESULTS"

printf 'EVAL_VARIANT=%s\n' "$VARIANT"
printf 'EVAL_SCENARIO=%s\n' "$SCENARIO"
printf 'QUALITY=%s\n' "$QUALITY"
printf 'TEST_EXIT=%s\n' "$TEST_EXIT"
printf 'CHANGED_FILES=%s\n' "$CHANGED_FILES"
printf 'INSERTIONS=%s\n' "$INSERTIONS"
printf 'DELETIONS=%s\n' "$DELETIONS"
printf 'REASON=%s\n' "$REASON"
printf 'TEST_LOG=%s\n' "/tmp/agentennetzwerk-eval-test-$$.log"

[ "$QUALITY" = "PASS" ]
