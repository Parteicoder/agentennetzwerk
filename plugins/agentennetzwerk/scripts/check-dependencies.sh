#!/usr/bin/env bash

# Soft dependency probe. Never blocks Agentennetzwerk.
INPUT="$(cat 2>/dev/null)"
SESSION_ID="$(printf '%s' "$INPUT" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
SAFE_SESSION="$(printf '%s' "${SESSION_ID:-ppid-${PPID:-unknown}}" | tr -cd 'A-Za-z0-9._-')"
STATE_DIR="${TMPDIR:-/tmp}/agentennetzwerk"
MARKER="$STATE_DIR/deps-$SAFE_SESSION"

missing=()

if ! command -v git >/dev/null 2>&1 || ! git --version >/dev/null 2>&1; then
  missing+=("git")
fi
if ! command -v codex >/dev/null 2>&1 || ! codex --version >/dev/null 2>&1; then
  missing+=("codex")
fi
if ! command -v grok >/dev/null 2>&1 || ! grok version >/dev/null 2>&1; then
  missing+=("grok")
fi

mkdir -p "$STATE_DIR" >/dev/null 2>&1 || true
find "$STATE_DIR" -type f -name 'deps-*' -mtime +7 -delete >/dev/null 2>&1 || true

if [ ${#missing[@]} -eq 0 ]; then
  # Tiny invisible context lets the skill distinguish "all ready" from "hook did not run".
  printf '{"hookSpecificOutput":{"hookEventName":"UserPromptExpansion","additionalContext":"SOFT_DEPENDENCY_STATUS missing=none"}}\n'
  exit 0
fi

missing_text="$(IFS=', '; echo "${missing[*]}")"

if [ -f "$MARKER" ]; then
  # Keep supplying status to the supervisor, but do not repeat the user-facing warning.
  printf '{"hookSpecificOutput":{"hookEventName":"UserPromptExpansion","additionalContext":"SOFT_DEPENDENCY_STATUS missing=%s. Continue without blocking. If codex is missing use agentennetzwerk:claude-builder as the only writer. If grok is missing omit the external breaker and use a targeted Claude reviewer only when useful. If git is missing avoid Git-dependent claims. Do not install or authenticate tools automatically."}}\n' "$missing_text"
  exit 0
fi

: > "$MARKER" 2>/dev/null || true
printf '{"systemMessage":"Agentennetzwerk: optional tool(s) unavailable: %s. The plugin will continue with reduced capabilities. Run /agentennetzwerk:doctor for details.","hookSpecificOutput":{"hookEventName":"UserPromptExpansion","additionalContext":"SOFT_DEPENDENCY_STATUS missing=%s. Continue without blocking. If codex is missing use agentennetzwerk:claude-builder as the only writer. If grok is missing omit the external breaker and use a targeted Claude reviewer only when useful. If git is missing avoid Git-dependent claims. Do not install or authenticate tools automatically."}}\n' "$missing_text" "$missing_text"

exit 0
