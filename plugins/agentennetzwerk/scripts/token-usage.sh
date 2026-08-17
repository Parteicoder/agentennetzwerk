#!/usr/bin/env bash

# Sum actual Claude token usage recorded in a Claude Code JSONL transcript.
# Counts non-cached input, cache creation, cache reads, and output tokens.
# This reads recorded usage fields only; it does not estimate or tokenize text.

set -u
FILE="${1:-}"

if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
  echo 0
  exit 0
fi

awk '
function fieldnum(line, key,    re, hit, n) {
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
  # Claude Code transcript assistant records contain the API usage object.
  if ($0 !~ /\"type\"[[:space:]]*:[[:space:]]*\"assistant\"/ || $0 !~ /\"usage\"[[:space:]]*:/) next

  # Deduplicate message IDs defensively if the same assistant response is serialized more than once.
  id = ""
  if (match($0, /\"id\"[[:space:]]*:[[:space:]]*\"msg_[^\"]+\"/)) {
    id = substr($0, RSTART, RLENGTH)
    if (seen[id]++) next
  }

  input = fieldnum($0, "input_tokens")
  output = fieldnum($0, "output_tokens")
  cache_create = fieldnum($0, "cache_creation_input_tokens")
  cache_read = fieldnum($0, "cache_read_input_tokens")
  total += input + output + cache_create + cache_read
}
END { print total + 0 }
' "$FILE"
