#!/usr/bin/env bash

# Soft dependency probe for Agentennetzwerk start. Never blocks the workflow.
set -u
INPUT="$(cat 2>/dev/null)"

# The hook is attached to all model-invoked Skill calls so it can cover natural
# language invocation. Ignore every skill except agentennetzwerk:start.
if ! printf '%s' "$INPUT" | grep -Fq 'agentennetzwerk:start'; then
  exit 0
fi

extract_json_string() {
  key="$1"
  printf '%s' "$INPUT" | sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -n 1
}

SESSION_ID="$(extract_json_string session_id)"
HOOK_EVENT="$(extract_json_string hook_event_name)"
[ -n "$HOOK_EVENT" ] || HOOK_EVENT="UserPromptExpansion"
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

emit_context() {
  text="$1"
  printf '{"hookSpecificOutput":{"hookEventName":"%s","additionalContext":"%s"}}\n' "$HOOK_EVENT" "$text"
}

if [ ${#missing[@]} -eq 0 ]; then
  emit_context 'SOFT_DEPENDENCY_STATUS missing=none'
  exit 0
fi

missing_text="$(IFS=', '; echo "${missing[*]}")"
context="SOFT_DEPENDENCY_STATUS missing=${missing_text}. Continue without blocking. If codex is missing use agentennetzwerk:claude-builder as the only writer. If grok is missing omit the external breaker. If git is missing avoid Git-dependent claims. Do not install or authenticate tools automatically."

if [ -f "$MARKER" ]; then
  emit_context "$context"
  exit 0
fi

: > "$MARKER" 2>/dev/null || true
printf '{"systemMessage":"Agentennetzwerk: optional tool(s) unavailable: %s. The plugin will continue with reduced capabilities. Run /agentennetzwerk:doctor for details.","hookSpecificOutput":{"hookEventName":"%s","additionalContext":"%s"}}\n' \
  "$missing_text" "$HOOK_EVENT" "$context"

exit 0
