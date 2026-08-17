#!/usr/bin/env bash

# Explicit, user-triggered Agentennetzwerk update.
# This script is never called by the automatic update checker.

set -u

if ! command -v claude >/dev/null 2>&1; then
  echo 'Agentennetzwerk update failed: Claude Code CLI is not available in PATH.' >&2
  exit 1
fi

CURRENT=""
if [ -f "${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json" ]; then
  CURRENT="$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([0-9][0-9.]*\)".*/\1/p' "${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json" | head -n 1)"
fi

printf 'Refreshing marketplace parteicoder-agenten...\n'
if ! claude plugin marketplace update parteicoder-agenten; then
  echo 'Marketplace refresh failed. No plugin update was installed.' >&2
  exit 1
fi

printf 'Updating agentennetzwerk@parteicoder-agenten...\n'
if ! claude plugin update agentennetzwerk@parteicoder-agenten; then
  echo 'Plugin update failed. Open /plugin to verify the installation scope and marketplace.' >&2
  exit 1
fi

DATA="${CLAUDE_PLUGIN_DATA:-${HOME:-.}/.claude/plugins/data/agentennetzwerk-parteicoder-agenten}"
rm -f "$DATA/update/last-check" "$DATA/update/status" 2>/dev/null || true

if [ -n "$CURRENT" ]; then
  printf 'Agentennetzwerk update command completed. Previous loaded version: %s. Run /reload-plugins to load the updated plugin in this Claude Code session.\n' "$CURRENT"
else
  printf 'Agentennetzwerk update command completed. Run /reload-plugins to load the updated plugin in this Claude Code session.\n'
fi

exit 0
