---
name: doctor
description: Check Agentennetzwerk's local tools, update state, fallback path, and optional native auto-compaction configuration.
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

Possible values:

```text
UP_TO_DATE|installed|remote
UPDATE_AVAILABLE|installed|remote
```

Do not perform a network update check from `doctor`. If an update is available, report the versions and suggest `/agentennetzwerk:update`. If no cache exists, report `UPDATE STATUS UNKNOWN — automatic check has not completed yet`.

## Optional auto-compaction status

`/agentennetzwerk:autocompact 60` is an optional proactive setup, not a requirement for the network to function. If the user configured a different threshold deliberately, report it factually without treating it as an error.

### Claude Code

Check the current `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` environment value and `~/.claude/settings.json` (Windows: `%USERPROFILE%\.claude\settings.json`). Report the active value when visible, `CONFIGURED / RESTART REQUIRED` when a settings-file value is not active yet, or `DEFAULT` when no override exists.

### Grok Build

Inspect the local Grok configuration without changing it. Report the actual configured `[session].auto_compact_threshold_percent` value when visible, otherwise `DEFAULT/UNKNOWN`.

### Codex

Inspect `~/.codex/config.toml`. Codex uses the absolute `model_auto_compact_token_limit` threshold. If the same scope explicitly contains `model_context_window = N`, calculate and report the resulting percentage. If the context window is dynamically resolved or unavailable, report `NOT PINNED`. Never guess a context window from a model name.

If all three can be verified against a user-selected target, state that target. Do not label a different deliberate threshold as a network limitation.

## Output

Return one compact table with:
- component
- availability/auth status
- compaction status when visible
- Agentennetzwerk effect/fallback

Then add one short `Update` line from the cached state.

Fallback rules:
- Codex missing -> `agentennetzwerk:claude-builder` is the single writer.
- Grok missing -> external model diversity is unavailable; normal Claude review remains available.
- Git missing -> file-based operation only; no Git diff/branch/merge guarantees.

If compaction is still at defaults and the user wants the proactive setup, mention:

```text
/agentennetzwerk:autocompact 60
```

End with `FULL NETWORK AVAILABLE` or `NETWORK AVAILABLE WITH LIMITATIONS` based on tool availability, not on compaction preferences.
