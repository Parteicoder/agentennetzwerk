---
name: autocompact
description: Configure native context auto-compaction for Claude Code, Grok Build, and Codex where the active context window is explicitly known.
disable-model-invocation: true
argument-hint: "[percent]"
allowed-tools: Read, Write, Edit, Bash
---

# Agentennetzwerk Auto-Compact Setup

Configure native auto-compaction for the local coding AIs. `$ARGUMENTS` is the requested percentage. If omitted, use **60**.

## Safety

- Accept only an integer from 1 through 85. Otherwise stop without changing files.
- Preserve unrelated settings and comments.
- Never install, update, authenticate, or launch a paid model call.
- Before changing an existing Grok or Codex config, create a sibling backup with suffix `.agentennetzwerk.bak`, replacing only an older backup created by this command.
- Do not invent model context-window sizes.

## Claude Code: exact native percentage

Edit the user settings file at `~/.claude/settings.json` (Windows: `%USERPROFILE%\.claude\settings.json`). Preserve all existing settings and ensure:

```json
{
  "env": {
    "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE": "<percent>"
  }
}
```

Merge the key into the existing `env` object; do not replace other environment variables.

This setting applies to the main Claude Code conversation and Claude subagents. Tell the user that an already-running Claude Code process must be restarted before the new threshold is guaranteed to govern its own context compaction.

## Grok Build: exact native percentage

Edit `~/.grok/config.toml` (Windows: `%USERPROFILE%\.grok\config.toml`). Preserve all unrelated settings and ensure the user-level `[session]` table contains:

```toml
[session]
auto_compact_threshold_percent = <percent>
```

If `[session]` already exists, update only this key. Do not create a duplicate table. This applies to new Grok sessions, including headless sessions that use the user config.

## Codex: exact percentage only from verified context windows

Codex currently exposes an absolute token threshold, not a percentage setting. Inspect `~/.codex/config.toml` (Windows: `%USERPROFILE%\.codex\config.toml`).

For each configuration scope where an explicit positive integer is already present as:

```toml
model_context_window = N
```

calculate exactly:

```text
limit = floor(N * percent / 100)
```

and set in the same scope:

```toml
model_auto_compact_token_limit = <limit>
model_auto_compact_token_limit_scope = "total"
```

Apply this independently to the top-level config and to profiles that explicitly define their own `model_context_window`.

If a Codex scope does **not** explicitly define `model_context_window`, do not guess from a model name and do not insert a context-window override. Leave that scope unchanged and report:

`Codex 60%: NOT PINNED — model context window is resolved dynamically; Codex has no native percentage setting.`

Replace `60` in that sentence with the requested percentage.

## Verification

After editing, re-read the affected files and report a compact table:

| Engine | Target | Result | Effective setting |
|---|---:|---|---|
| Claude | N% | EXACT / FAILED | `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=N` |
| Grok | N% | EXACT / FAILED | `auto_compact_threshold_percent=N` |
| Codex | N% | EXACT / PARTIAL / NOT PINNED | configured token limit(s), or why none were written |

Do not call Codex, Grok, or Claude APIs merely to verify configuration.

End with one short note stating when a restart/new session is required. Do not claim Codex is exactly at N% unless every reported Codex scope was calculated from an explicit context window.
