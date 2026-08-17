---
name: doctor
description: Check Agentennetzwerk's local tools, update state, fallback path, and native auto-compaction configuration.
disable-model-invocation: true
allowed-tools: Bash, Read
---

# Agentennetzwerk Doctor

Perform local, non-destructive checks only. Do not install, update, log in, or modify configuration.

## Tool availability

Check locally:

```text
git --version
codex --version
codex login status
grok version
```

If a command is unavailable, record it as missing and continue. Do not make network calls merely to validate authentication.

## Last known update state

Read only the local update cache if it exists:

```text
${CLAUDE_PLUGIN_DATA}/update/status
```

Possible values are:

```text
UP_TO_DATE|installed|remote
UPDATE_AVAILABLE|installed|remote
```

Do not perform a network update check from `doctor`. If the cached state says an update is available, report the versions and suggest:

```text
/agentennetzwerk:update
```

If no cache exists, report `UPDATE STATUS UNKNOWN — automatic check has not completed yet`.

## Auto-compaction status

Target policy for Agentennetzwerk is **60%** unless the user deliberately configured a different value.

### Claude Code

Check the current `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` environment value and `~/.claude/settings.json` (Windows: `%USERPROFILE%\.claude\settings.json`). Report:

- `EXACT 60%` if the active environment is 60.
- `CONFIGURED 60% / RESTART REQUIRED` if the settings file contains 60 but the running session does not expose 60.
- `OTHER` with the real value when a different threshold is configured.
- `DEFAULT` when no override is found.

Do not infer an active value from documentation defaults.

### Grok Build

Inspect the local Grok configuration without changing it. Prefer `grok inspect` when available and also inspect `~/.grok/config.toml`. Report the actual configured `[session].auto_compact_threshold_percent` value when visible. If it is 60, report `EXACT 60%`; otherwise report the actual value or `DEFAULT/UNKNOWN`.

### Codex

Inspect `~/.codex/config.toml`. Codex uses `model_auto_compact_token_limit`, an absolute token threshold.

For every scope that explicitly contains both `model_context_window = N` and `model_auto_compact_token_limit = L`, calculate whether `L == floor(N * 60 / 100)`.

Report:

- `EXACT 60%` only when the configured values prove it.
- `OTHER` with the calculable percentage when both values exist but differ.
- `NOT PINNED` when the context window is dynamically resolved or either required value is absent.

Never guess a Codex context window from a model name.

## Output

Return one compact table with:

- component
- availability/auth status
- auto-compact status when applicable
- Agentennetzwerk effect/fallback

Then add one short `Update` line from the cached state.

Fallback rules:
- Codex missing -> `agentennetzwerk:claude-builder` is the single writer.
- Grok missing -> external breaker unavailable; targeted Claude review remains available.
- Git missing -> file-based operation only; no Git diff/branch/merge guarantees.

If any auto-compact engine is not at the intended 60% policy, suggest:

```text
/agentennetzwerk:autocompact 60
```

End with `FULL NETWORK AVAILABLE` or `NETWORK AVAILABLE WITH LIMITATIONS`.
