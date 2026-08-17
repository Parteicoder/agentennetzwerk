#!/usr/bin/env bash

# Non-blocking update checker for Agentennetzwerk.
# Checks GitHub at most once every 24 hours. Never installs updates.

set -u

DATA="${CLAUDE_PLUGIN_DATA:-${HOME:-.}/.claude/plugins/data/agentennetzwerk-parteicoder-agenten}"
STATE_DIR="$DATA/update"
STAMP="$STATE_DIR/last-check"
CACHE="$STATE_DIR/status"
INTERVAL=86400
NOW="$(date +%s 2>/dev/null || echo 0)"

mkdir -p "$STATE_DIR" >/dev/null 2>&1 || exit 0

# Reuse the last result until the 24h interval expires.
if [ -f "$STAMP" ]; then
  LAST="$(cat "$STAMP" 2>/dev/null || echo 0)"
  case "$LAST" in ''|*[!0-9]*) LAST=0 ;; esac
  if [ "$NOW" -gt 0 ] && [ $((NOW - LAST)) -lt "$INTERVAL" ]; then
    if [ -f "$CACHE" ] && grep -q '^UPDATE_AVAILABLE|' "$CACHE" 2>/dev/null; then
      IFS='|' read -r _ CURRENT LATEST < "$CACHE"
      printf '{"systemMessage":"Agentennetzwerk update available: %s -> %s. Run /agentennetzwerk:update to install it manually.","hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"Agentennetzwerk update %s -> %s is available. Do not install automatically. Only update when the user explicitly runs /agentennetzwerk:update."}}\n' "$CURRENT" "$LATEST" "$CURRENT" "$LATEST"
    fi
    exit 0
  fi
fi

printf '%s\n' "$NOW" > "$STAMP" 2>/dev/null || true

LOCAL_MANIFEST="${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json"
[ -f "$LOCAL_MANIFEST" ] || exit 0

extract_version() {
  sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([0-9][0-9.]*\)".*/\1/p' "$1" 2>/dev/null | head -n 1
}

CURRENT="$(extract_version "$LOCAL_MANIFEST")"
[ -n "$CURRENT" ] || exit 0

# Network failure, missing curl, or malformed remote data must never affect Claude Code startup.
command -v curl >/dev/null 2>&1 || exit 0
REMOTE_TMP="$STATE_DIR/remote-plugin.json.tmp"
URL="https://raw.githubusercontent.com/Parteicoder/agentennetzwerk/main/plugins/agentennetzwerk/.claude-plugin/plugin.json"
if ! curl -fsSL --connect-timeout 2 --max-time 5 "$URL" -o "$REMOTE_TMP" 2>/dev/null; then
  rm -f "$REMOTE_TMP"
  exit 0
fi
LATEST="$(extract_version "$REMOTE_TMP")"
rm -f "$REMOTE_TMP"
[ -n "$LATEST" ] || exit 0

version_gt() {
  awk -v a="$1" -v b="$2" 'BEGIN {
    na=split(a,A,"."); nb=split(b,B,"."); n=(na>nb?na:nb);
    for(i=1;i<=n;i++) { x=(i<=na?A[i]+0:0); y=(i<=nb?B[i]+0:0); if(x>y) exit 0; if(x<y) exit 1 }
    exit 1
  }'
}

if version_gt "$LATEST" "$CURRENT"; then
  printf 'UPDATE_AVAILABLE|%s|%s\n' "$CURRENT" "$LATEST" > "$CACHE"
  printf '{"systemMessage":"Agentennetzwerk update available: %s -> %s. Run /agentennetzwerk:update to install it manually.","hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"Agentennetzwerk update %s -> %s is available. Do not install automatically. Only update when the user explicitly runs /agentennetzwerk:update."}}\n' "$CURRENT" "$LATEST" "$CURRENT" "$LATEST"
else
  printf 'UP_TO_DATE|%s|%s\n' "$CURRENT" "$LATEST" > "$CACHE"
fi

exit 0
