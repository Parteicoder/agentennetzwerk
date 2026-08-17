#!/usr/bin/env bash

# Sum actual Claude token usage recorded in a Claude Code JSONL transcript.
# Counts recorded API usage fields only; it never estimates tokens from text.

set -u
FILE="${1:-}"

if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
  echo 0
  exit 0
fi

# Prefer structural JSON parsing when jq is available. Keep an awk fallback so
# telemetry remains optional and does not introduce a new dependency.
if command -v jq >/dev/null 2>&1; then
  jq -rs '
    [ .[]
      | select(.type == "assistant")
      | .message as $m
      | select(($m.usage // null) != null)
      | {
          id: ($m.id // null),
          tokens: (
            (($m.usage.input_tokens // 0) | tonumber) +
            (($m.usage.cache_creation_input_tokens // 0) | tonumber) +
            (($m.usage.cache_read_input_tokens // 0) | tonumber) +
            (($m.usage.output_tokens // 0) | tonumber)
          )
        }
    ]
    | reduce .[] as $item (
        {seen: {}, total: 0};
        if ($item.id != null and (.seen[$item.id] // false))
        then .
        else .total += $item.tokens
          | if $item.id != null then .seen[$item.id] = true else . end
        end
      )
    | .total
  ' "$FILE" 2>/dev/null || echo 0
  exit 0
fi

awk '
function fieldnum(line, key,    re, hit) {
  re = "\"" key "\"[[:space:]]*:[[:space:]]*[0-9]+"
  if (match(line, re)) {
    hit = substr(line, RSTART, RLENGTH)
    sub(/^.*:/, "", hit)
    gsub(/[[:space:]]/, "", hit)
    return hit + 0
  }
  return 0
}
{
  if ($0 !~ /\"type\"[[:space:]]*:[[:space:]]*\"assistant\"/ || $0 !~ /\"usage\"[[:space:]]*:/) next

  id = ""
  if (match($0, /\"id\"[[:space:]]*:[[:space:]]*\"msg_[^\"]+\"/)) {
    id = substr($0, RSTART, RLENGTH)
    if (seen[id]++) next
  }

  total += fieldnum($0, "input_tokens")
  total += fieldnum($0, "cache_creation_input_tokens")
  total += fieldnum($0, "cache_read_input_tokens")
  total += fieldnum($0, "output_tokens")
}
END { print total + 0 }
' "$FILE"
