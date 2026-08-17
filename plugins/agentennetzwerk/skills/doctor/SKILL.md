---
name: doctor
description: Check Agentennetzwerk's optional local tools and explain the active fallback path.
disable-model-invocation: true
allowed-tools: Bash
---

# Agentennetzwerk Doctor

Perform local, non-destructive checks only. Do not install, update, log in, or modify configuration.

Check:

```text
git --version
codex --version
codex login status
grok version
```

If a command is unavailable, record it as missing and continue. Do not make network calls merely to validate authentication.

Return a compact table with:
- tool
- status: READY / MISSING / AUTH UNKNOWN
- detected version when available
- Agentennetzwerk effect

Fallback rules:
- Codex missing -> `claude-builder` is the single writer.
- Grok missing -> external breaker unavailable; Claude targeted review remains available.
- Git missing -> file-based operation only; no Git diff/branch/merge guarantees.

End with `FULL NETWORK AVAILABLE` or `NETWORK AVAILABLE WITH LIMITATIONS`.
