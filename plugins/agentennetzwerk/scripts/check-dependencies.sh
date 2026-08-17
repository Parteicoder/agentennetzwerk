#!/usr/bin/env bash

# Agentennetzwerk hard dependency gate.
# Exit code 2 is intentional: Claude Code treats it as a blocking hook error.

missing=()

if ! command -v git >/dev/null 2>&1; then
  missing+=("git")
fi

if ! command -v codex >/dev/null 2>&1; then
  missing+=("codex")
fi

if ! command -v grok >/dev/null 2>&1; then
  missing+=("grok")
fi

if [ ${#missing[@]} -gt 0 ]; then
  printf 'Agentennetzwerk kann nicht gestartet werden. Fehlende harte Abhaengigkeit(en): %s. Installiere und authentifiziere alle benoetigten Coding-CLIs und starte Claude Code danach neu.\n' "${missing[*]}" >&2
  exit 2
fi

# Verify that the binaries can actually start, not only that a PATH entry exists.
if ! git --version >/dev/null 2>&1; then
  echo 'Agentennetzwerk blockiert: git wurde gefunden, kann aber nicht ausgefuehrt werden.' >&2
  exit 2
fi

if ! codex --version >/dev/null 2>&1; then
  echo 'Agentennetzwerk blockiert: codex wurde gefunden, kann aber nicht ausgefuehrt werden. Pruefe Installation und PATH.' >&2
  exit 2
fi

if ! grok version >/dev/null 2>&1; then
  echo 'Agentennetzwerk blockiert: grok wurde gefunden, kann aber nicht ausgefuehrt werden. Pruefe Installation und PATH.' >&2
  exit 2
fi

exit 0
