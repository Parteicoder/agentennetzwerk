# Changelog

All notable Agentennetzwerk changes are documented here.

## 0.8.0 - 2026-08-17

- Enabled model invocation for the `start` skill with a deliberately narrow description, so explicit natural-language requests such as "use Agentennetzwerk" can trigger the plugin while ordinary coding requests stay on Claude Code's normal path.
- Added the same soft dependency and telemetry startup path for model-invoked `Skill` calls as for direct `/agentennetzwerk:start` expansion.
- Reduced Claude plugin agents from seven to four: `claude-builder`, `architect`, `reviewer`, and `security-reviewer`.
- Removed the dedicated `repo-explorer`; ordinary scouting stays in the supervisor and non-trivial exploration is folded into `architect`.
- Replaced separate QA and regression agents with one consolidated read-only `reviewer` that checks requirements, tests, compatibility, and regression risk in one pass.
- Removed the automatic `final-judge`; the supervisor now makes the final readiness decision from the actual code, diff, tests, and unresolved material findings.
- Recalibrated call budgets to quick <=3 hard cap, standard <=4 target, and deep <=6 target, with earlier exits and targeted reruns only.
- Made Grok an explicitly optional diversity review rather than a ritual duplicate reviewer.
- Added guidance to prefer Claude Code's native Agent Teams/worktree isolation only when parallel independent work is explicitly requested; the default workflow remains single-writer.
- Tightened writer/architect/security prompts and decision-complete handoffs so agents reference paths and symbols rather than receiving pasted source or full chat history.
- Reframed `/agentennetzwerk:autocompact 60` as optional proactive setup rather than a network prerequisite; `doctor` now reports deliberate non-60 settings factually instead of treating them as a limitation.
- Hardened factual token parsing with structural `jq` parsing when available plus a dependency-free awk fallback.
- Updated telemetry role tracking and call budgets for the streamlined architecture.
- CI now validates natural-prompt configuration, current agent references, PowerShell syntax, and both a pinned Claude Code baseline and the current `latest` release.

## 0.7.0 - 2026-08-17

- Added a non-blocking update checker that checks the GitHub release source at most once every 24 hours on Claude Code startup/resume.
- Update checks never install anything and fail silently when the network or `curl` is unavailable.
- When a newer version is detected, Claude Code shows a single notice with the installed and available versions.
- Added `/agentennetzwerk:update` as the explicit user-approved update action.
- The manual update command refreshes the `parteicoder-agenten` marketplace and then runs `claude plugin update agentennetzwerk@parteicoder-agenten`.
- The current session is never silently reloaded; after a successful update the user is told to run `/reload-plugins`.
- Update-check state is kept in `${CLAUDE_PLUGIN_DATA}` and is cleared after a successful manual update so the next loaded version can check cleanly.

## 0.6.0 - 2026-08-17

- Added `/agentennetzwerk:autocompact [percent]`, defaulting to 60%, for proactive native context compaction.
- Claude Code setup merges `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=60` into the user's Claude settings; the setting applies to the main conversation and Claude subagents after restart.
- Grok Build setup writes `[session].auto_compact_threshold_percent = 60` while preserving unrelated Grok configuration.
- Codex is handled factually: because Codex exposes an absolute token threshold rather than a percentage setting, Agentennetzwerk calculates 60% only for scopes with an explicit `model_context_window` and never guesses a window from a model name.
- Added backup behavior before changing existing Grok or Codex configuration.
- Extended `/agentennetzwerk:doctor` to verify auto-compaction state and distinguish `EXACT 60%`, restart-required, other/default values, and Codex `NOT PINNED` states.
- Added the 60% compaction policy to the normal workflow. Coding tasks never disable compaction and do not spend model calls merely to configure it.

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
