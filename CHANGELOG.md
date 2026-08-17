# Changelog

All notable Agentennetzwerk changes are documented here.

## 0.5.0 - 2026-08-17

- Added `/agentennetzwerk:savings` for fact-only local token reporting.
- Added local telemetry for actual Claude supervisor and Agentennetzwerk subagent token usage from Claude Code JSONL transcript usage fields.
- Added `UserPromptExpansion`, `SubagentStop`, and parent `Stop` telemetry hooks.
- Added persistent run history under Claude Code's `${CLAUDE_PLUGIN_DATA}` directory instead of writing telemetry into project repositories.
- Added factual counts for observed Codex/Grok calls and unused configured call-budget slots.
- Deliberately refuses to convert skipped calls into fake token savings. A verified saved-token number requires a controlled measured baseline.
- Added a transcript token parser that includes non-cached input, cache-creation input, cache-read input, and output tokens.
- Documented telemetry scope: external Codex/Grok token totals are not silently mixed into Claude totals when they are not directly measured.

## 0.4.0 - 2026-08-17

- Added explicit `model: inherit` to Claude agents so the user's Sonnet/Opus selection is respected.
- Added bounded call budgets for `quick`, `standard`, and `deep` workflows.
- Shortened the main orchestration skill and all agent prompts to reduce recurring context use.
- Added early-exit behavior when QA and relevant checks are already clean.
- Added compact direct handoffs to avoid repeated supervisor summarization.
- Added `/agentennetzwerk:doctor` for non-destructive local dependency diagnostics.
- Improved the soft dependency probe: executable checks, stale marker cleanup, persistent hidden status, one visible warning per session, and clearer fallbacks.
- Added a current-shell fallback probe if the dependency hook is unavailable.
- Scoped all plugin-agent references as `agentennetzwerk:<agent>` to avoid collisions with project or user agents.
- Hardened recommended Codex usage with ephemeral `workspace-write` runs and stdin prompts where practical.
- Hardened Grok review runs with bounded turns, disabled unnecessary subagents/memory/web search, and explicit edit-tool denial.
- Added GitHub Actions validation for marketplace/plugin metadata, JSON syntax, and Bash script syntax.
- Removed the duplicated plugin version from the marketplace entry so `plugin.json` is the single plugin-version source.
- Standardized public documentation and internal agent prompts in English.

## 0.3.1 - 2026-08-17

- Claude subagents inherit the model selected in the main Claude Code session.
- Removed forced Haiku/Sonnet/Opus assignments.
- Documented Sonnet/Opus selection before starting a workflow.

## 0.3.0 - 2026-08-17

- Replaced hard dependency blocking with soft Codex/Grok/Git fallbacks.
- Added `claude-builder` as the Codex fallback writer.
- Reduced unnecessary reviewer usage and repeated review cycles.

## 0.2.0 - 2026-08-17

- Added initial dependency checks for Codex, Grok, and Git.

## 0.1.0 - 2026-08-17

- Initial Claude Code marketplace/plugin structure.
- Added the `start` skill and specialized Claude review agents.
