# Agentennetzwerk

A prompt-driven, token-efficient multi-agent coding network for Claude Code.

Claude Code is the supervisor. Codex CLI is the preferred writer when available. Grok Build can act as an independent breaker/reviewer. Specialized Claude subagents handle planning, QA, regression, security, and final review. Missing external AIs do not block the plugin; Claude fallbacks remain available.

There is no Python, Node.js, or server-side orchestrator.

## Install

Inside Claude Code:

```text
/plugin marketplace add Parteicoder/agentennetzwerk
/plugin install agentennetzwerk@parteicoder-agenten
/reload-plugins
```

Start a task:

```text
/agentennetzwerk:start <task>
```

Optional modes:

```text
/agentennetzwerk:start quick Fix the null pointer in the import flow
/agentennetzwerk:start standard Add a search feature
/agentennetzwerk:start deep Redesign the synchronization architecture
```

## Update policy: check automatically, install manually

Agentennetzwerk does **not** auto-install its own updates.

On Claude Code startup or resume, the plugin performs a lightweight GitHub version check at most once every 24 hours. If the check fails because the network or `curl` is unavailable, startup continues normally.

When a newer release exists, you get a notice such as:

```text
Agentennetzwerk update available: 0.7.0 -> 0.8.0.
Run /agentennetzwerk:update to install it manually.
```

Nothing changes until you explicitly run:

```text
/agentennetzwerk:update
```

That command is the user approval. It refreshes the `parteicoder-agenten` marketplace and runs Claude Code's native plugin updater for `agentennetzwerk@parteicoder-agenten`.

After a successful update, run:

```text
/reload-plugins
```

The current session is never silently reloaded. Automatic marketplace/plugin auto-update is not required for this workflow and can remain disabled.

`/agentennetzwerk:doctor` shows the last locally cached update state without making another network request.

## Choose the Claude model first

Agentennetzwerk does not force a Claude model. Use Claude Code's normal model selector before starting:

```text
/model
```

Choose Sonnet or Opus. Plugin subagents use `model: inherit`, so they follow the main Claude Code session model. Token efficiency comes from smaller context, fewer calls, bounded turns, early exits, and proactive compaction, not from silently downgrading the model.

## 60% auto-compaction policy

Configure proactive context compaction once:

```text
/agentennetzwerk:autocompact 60
```

Claude Code and Grok Build support percentage-based thresholds directly. Codex currently exposes an absolute token threshold, so Agentennetzwerk only claims exact 60% when an explicit Codex context window is available in local configuration. It never guesses a context-window size from a model name.

Check the factual state with:

```text
/agentennetzwerk:doctor
```

The doctor distinguishes exact settings, restart-required states, defaults, and Codex `NOT PINNED` states.

## Optional dependencies and fallbacks

For the full network:

- Claude Code
- Git
- Codex CLI
- Grok Build CLI

Codex and Grok must be installed and authenticated separately. Agentennetzwerk never installs, updates, or logs into external coding CLIs automatically.

```text
Codex available  -> Codex is the preferred single writer
Codex missing    -> agentennetzwerk:claude-builder is the writer

Grok available   -> optional independent breaker/reviewer
Grok missing     -> targeted Claude review remains available

Git available    -> diff/status/branch verification available
Git missing      -> file-based workflow without Git guarantees
```

Missing dependencies produce a soft limitation notice instead of blocking the plugin.

## Workflow modes

### quick

For small local changes:

```text
Writer -> QA -> relevant checks -> stop
```

Target budget: up to 3 model/agent calls.

### standard

For normal features, bug fixes, and refactoring:

```text
optional Explorer/Architect -> Writer -> QA -> risk-specific review -> checks
```

Target budget: up to 5 calls. Regression, security, Grok, and Final Judge stages are used only when they add real value.

### deep

For architecture, migrations, synchronization, security, data models, or other high-risk work:

```text
Explorer -> Architect -> Writer -> targeted reviewers + optional Grok -> Final Judge
```

Target budget: up to 8 calls, with at most two repair reruns.

These budgets are ceilings, not quotas. The supervisor should stop early whenever the acceptance criteria, QA, and relevant checks are already clean.

## Claude agents

- `agentennetzwerk:claude-builder` — fallback single writer when Codex is unavailable
- `agentennetzwerk:repo-explorer` — minimal read-only repository scouting
- `agentennetzwerk:architect` — compact planning for non-trivial work
- `agentennetzwerk:qa-reviewer` — requirements, behavior, and test review
- `agentennetzwerk:regression-hunter` — compatibility/migration/regression review
- `agentennetzwerk:security-reviewer` — security, privacy, and data-integrity review
- `agentennetzwerk:final-judge` — evidence-based final decision for deep or disputed runs

All Claude agents inherit the model selected in the main Claude Code session.

## External coding AIs

### Codex

When available, Codex is the preferred writer. Agentennetzwerk prefers an ephemeral workspace-limited run:

```text
codex exec --ephemeral --sandbox workspace-write -
```

The workflow does not use `danger-full-access`, and Codex is instructed not to commit, push, merge, or reset unrelated work.

### Grok Build

Grok is a breaker/reviewer, not a second writer. Review runs are bounded and remove edit capability when supported. Agentennetzwerk does not use `--always-approve` for Grok reviews.

## Factual token telemetry

Starting with 0.5.0, Agentennetzwerk records local token telemetry for its Claude runs by reading the real usage fields written by Claude Code to main-session and subagent JSONL transcripts.

Show the report with:

```text
/agentennetzwerk:savings
```

It reports actual Claude supervisor/subagent token usage, observed Codex/Grok call counts, and unused configured call-budget slots.

The plugin deliberately does not calculate fake savings from skipped calls. Without a controlled measured A/B baseline, it reports:

```text
Verified tokens saved: not computable yet
```

Telemetry is stored in Claude Code's persistent plugin-data directory, not in project repositories.

## Commands

```text
/agentennetzwerk:start [quick|standard|deep] <task>
/agentennetzwerk:doctor
/agentennetzwerk:autocompact 60
/agentennetzwerk:savings
/agentennetzwerk:update
```

## Core rules

- one writer at a time
- reviewers do not edit code
- an implementer does not approve its own work
- no automatic commits, pushes, merges, releases, or destructive resets
- unrelated local changes are preserved
- external coding CLIs are never installed or authenticated automatically
- plugin updates are detected automatically but installed only after `/agentennetzwerk:update`
- critical security/data-integrity decisions are escalated to the user
- code and real checks matter more than model agreement
- only the minimum useful context is passed between agents
- auto-compaction is never disabled by the workflow
- Codex context-window sizes are never guessed

## Development

```bash
git clone https://github.com/Parteicoder/agentennetzwerk.git
cd agentennetzwerk
claude plugin validate .
claude plugin validate ./plugins/agentennetzwerk
claude --plugin-dir ./plugins/agentennetzwerk
```

GitHub Actions validates the marketplace, plugin manifest, hook JSON, Bash scripts, and factual token parser on pushes and pull requests.

## Repository structure

```text
agentennetzwerk/
├── .claude-plugin/marketplace.json
├── .github/workflows/validate-plugin.yml
├── plugins/agentennetzwerk/
│   ├── .claude-plugin/plugin.json
│   ├── hooks/hooks.json
│   ├── scripts/
│   │   ├── check-dependencies.sh
│   │   ├── check-update.sh
│   │   ├── manual-update.sh
│   │   ├── token-usage.sh
│   │   ├── telemetry-start.sh
│   │   ├── telemetry-subagent.sh
│   │   ├── telemetry-stop.sh
│   │   └── savings-report.sh
│   ├── skills/
│   │   ├── start/SKILL.md
│   │   ├── doctor/SKILL.md
│   │   ├── autocompact/SKILL.md
│   │   ├── savings/SKILL.md
│   │   └── update/SKILL.md
│   └── agents/
│       ├── claude-builder.md
│       ├── repo-explorer.md
│       ├── architect.md
│       ├── qa-reviewer.md
│       ├── regression-hunter.md
│       ├── security-reviewer.md
│       └── final-judge.md
├── CHANGELOG.md
├── LICENSE
└── README.md
```

## License

GNU Affero General Public License v3.0 (AGPL-3.0).
