# Changelog

All notable Agentennetzwerk changes are documented here.

## 0.4.0 - 2026-08-17

- Added explicit `model: inherit` to Claude agents so the user's Sonnet/Opus selection is respected.
- Added bounded call budgets for `quick`, `standard`, and `deep` workflows.
- Shortened the main orchestration skill and all agent prompts to reduce recurring context use.
- Added early-exit behavior when QA and relevant checks are already clean.
- Added compact direct handoffs to avoid repeated supervisor summarization.
- Added `/agentennetzwerk:doctor` for non-destructive local dependency diagnostics.
- Improved the soft dependency probe: executable checks, stale marker cleanup, and clearer fallbacks.
- Hardened recommended Codex usage with ephemeral `workspace-write` runs and stdin prompts where practical.
- Bounded Grok breaker runs and disabled unnecessary subagents/memory/web search in the recommended review shape.
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
