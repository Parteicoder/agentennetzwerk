#!/usr/bin/env bash

# Soft dependency check for Agentennetzwerk.
# Warns at most once per Claude Code session and never blocks the skill.

INPUT="$(cat 2>/dev/null)"
SESSION_ID="$(printf '%s' "$INPUT" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
SAFE_SESSION="$(printf '%s' "${SESSION_ID:-unknown}" | tr -cd 'A-Za-z0-9._-')"
STATE_DIR="${TMPDIR:-/tmp}/agentennetzwerk"
MARKER="$STATE_DIR/deps-${SAFE_SESSION:-unknown}"

missing=()
command -v git >/dev/null 2>&1 || missing+=("git")
command -v codex >/dev/null 2>&1 || missing+=("codex")
command -v grok >/dev/null 2>&1 || missing+=("grok")

# Nothing missing, nothing to add to Claude's context.
if [ ${#missing[@]} -eq 0 ]; then
  exit 0
fi

# Only warn once for this Claude Code session.
mkdir -p "$STATE_DIR" >/dev/null 2>&1
if [ -f "$MARKER" ]; then
  exit 0
fi
: > "$MARKER" 2>/dev/null || true

missing_text=""
for item in "${missing[@]}"; do
  if [ -n "$missing_text" ]; then
    missing_text="$missing_text, $item"
  else
    missing_text="$item"
  fi
done

# UserPromptExpansion accepts structured JSON on stdout with exit 0.
# systemMessage is visible to the user; additionalContext tells the supervisor
# which fallbacks to use without repeating the check in the skill.
printf '{"systemMessage":"Agentennetzwerk: optionale Abhaengigkeit(en) fehlen: %s. Das Plugin funktioniert weiter mit Einschraenkungen und nutzt vorhandene Claude-Agenten als Fallback.","hookSpecificOutput":{"hookEventName":"UserPromptExpansion","additionalContext":"SOFT_DEPENDENCY_STATUS missing=%s. Weiterarbeiten. Fehlt codex: claude-builder als Single Writer verwenden. Fehlt grok: externen Breaker auslassen und nur bei Bedarf einen gezielten Claude-Reviewer verwenden. Fehlt git: keine git-basierten Aussagen oder Diff-Garantien machen. Nichts automatisch installieren oder authentifizieren."}}\n' "$missing_text" "$missing_text"

exit 0
