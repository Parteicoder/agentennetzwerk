# Agentennetzwerk

A prompt-driven, token-efficient multi-agent coding network for Claude Code.

Claude Code acts as the supervisor and coordinates specialized Claude subagents. Codex CLI is the preferred writer when available. Grok Build can provide an independent second-model review. Both external coding AIs are optional and have Claude fallbacks.

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

## Choose your Claude model first

Agentennetzwerk does not force a Claude model. Use Claude Code's normal model selector before starting:

```text
/model
```

Choose Sonnet or Opus. Plugin subagents use `model: inherit`, so they follow the main Claude Code session model. Token savings come from smaller context, fewer calls, bounded turns, early exits, and proactive compaction, not from silently downgrading the model.

## 60% auto-compaction policy

Agentennetzwerk targets proactive context compaction at **60%** so long coding runs keep more headroom instead of waiting until the context window is nearly full.

Run once:

```text
/agentennetzwerk:autocompact 60
```

The command preserves unrelated configuration and configures each engine only through settings it actually supports.

### Claude Code

Claude Code has a native percentage override:

```text
CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=60
```

The setup command merges this into the `env` section of the user's `~/.claude/settings.json`. Claude Code applies the threshold to the main conversation and its subagents. Restart Claude Code after changing it so the running process definitely uses the new value.

### Grok Build

Grok Build has a native percentage setting:

```toml
[session]
auto_compact_threshold_percent = 60
```

The setup command preserves the rest of `~/.grok/config.toml` and updates only this key. New Grok sessions then compact at the configured threshold.

### Codex

Codex currently exposes auto-compaction as an **absolute token limit**, not a percentage setting:

```toml
model_auto_compact_token_limit = 163200
```

Therefore Agentennetzwerk only claims exact 60% for Codex when the same configuration scope already contains a verified explicit context window such as:

```toml
model_context_window = 272000
```

It then computes:

```text
floor(272000 × 0.60) = 163200
```

and writes the corresponding absolute threshold. If Codex resolves the model context window dynamically and no explicit window is present, Agentennetzwerk does **not** guess from the model name and reports `NOT PINNED` instead.

This is intentional: a false "60%" label would be worse than accurately reporting that Codex's exact percentage cannot be proven from local configuration.

Check the factual state at any time:

```text
/agentennetzwerk:doctor
```

The doctor reports `EXACT 60%`, `CONFIGURED / RESTART REQUIRED`, `OTHER`, `DEFAULT`, or `NOT PINNED` as appropriate.

## Optional dependencies

For the full network:

- Claude Code
- Git
- Codex CLI
- Grok Build CLI

Codex and Grok must be installed and authenticated separately. Agentennetzwerk never installs, updates, or logs into external CLIs automatically.

Missing tools do not block the plugin. A soft dependency check reports limitations and selects a fallback:

```text
Codex available  -> Codex is the preferred single writer
Codex missing    -> claude-builder becomes the single writer

Grok available   -> optional independent breaker/reviewer
Grok missing     -> targeted Claude review remains available

Git available    -> diff/status/branch verification available
Git missing      -> file-based workflow without Git guarantees
```

## Factual token telemetry

Starting with **0.5.0**, Agentennetzwerk records local token telemetry for its Claude runs. The telemetry reads the real usage fields written by Claude Code to the main-session and subagent JSONL transcripts. It does not estimate tokens from character counts.

Show the report with:

```text
/agentennetzwerk:savings
```

The report includes:

- completed Agentennetzwerk runs tracked since 0.5.0
- actual Claude tokens consumed by the supervisor
- actual Claude tokens consumed by Agentennetzwerk subagents
- observed Codex and Grok call counts
- unused configured call-budget slots for explicitly selected modes

The telemetry is stored in Claude Code's persistent plugin-data directory, not in the project repository.

### Why the command does not invent a savings number

Actual consumed tokens are measurable. The exact number of tokens an agent **would have consumed if it had been called** is not measurable because that model call never happened.

Therefore Agentennetzwerk deliberately does **not** calculate:

```text
skipped calls × guessed average tokens = "tokens saved"
```

Without a controlled measured A/B baseline, the command reports:

```text
Verified tokens saved: not computable yet
```

Unused call slots are shown as a call count, never converted into fake token savings. External Codex/Grok token totals are also kept separate unless they are directly measured; they are not silently mixed into Claude token totals.

## Token-efficient design

The plugin keeps Sonnet or Opus fully available while reducing unnecessary work:

- proactive 60% compaction where the engine supports a verifiable threshold
- only task-relevant agents are started
- the orchestration skill is manual-only and loads only when invoked
- subagents keep exploration and logs outside the main context
- compact handoffs are reused instead of repeatedly summarized
- reviewers receive relevant diffs/files, not full chat transcripts
- agent output is intentionally short
- `maxTurns` caps each Claude subagent
- after a fix, only affected checks/reviewers run again
- the workflow stops early when QA and checks are already clean
- Agent Teams are not required

### Call budgets

Each Claude subagent, Codex run, or Grok run counts as one call.

| Mode | Target budget | Repair policy |
|---|---:|---|
| `quick` | <= 3 calls | max 1 repair rerun |
| `standard` | <= 5 calls | max 1 normally; second only for HIGH/CRITICAL |
| `deep` | <= 8 calls | max 2 repair reruns |

These are ceilings, not quotas. The supervisor should use fewer calls whenever possible.

## Workflow modes

### quick

For small local changes:

```text
Writer -> QA -> relevant checks -> stop
```

### standard

For normal features, bug fixes, and refactoring:

```text
optional Explorer/Architect -> Writer -> QA -> risk-specific review -> checks
```

### deep

For architecture, migrations, synchronization, security, data models, or high-risk changes:

```text
Explorer -> Architect -> Writer -> targeted reviewers + optional Grok -> Final Judge
```

## Agents

- `claude-builder`: fallback single writer when Codex is unavailable
- `repo-explorer`: minimal read-only repository scouting
- `architect`: compact implementation planning for non-trivial work
- `qa-reviewer`: requirements, behavior, and test review
- `regression-hunter`: compatibility/migration/regression review
- `security-reviewer`: security, privacy, and data-integrity review
- `final-judge`: evidence-based final decision for deep or disputed runs

All Claude agents inherit the user-selected main-session model.

## Safer external runs

### Codex

When available, Codex is the preferred writer. Agentennetzwerk prefers an ephemeral workspace-limited run:

```text
codex exec --ephemeral --sandbox workspace-write -
```

The workflow does not use `danger-full-access`, and Codex is instructed not to commit, push, merge, or reset unrelated work.

### Grok Build

Grok is used as a breaker/reviewer rather than a second writer. Review runs are bounded and remove edit capability when supported. Agentennetzwerk does not use `--always-approve` for Grok reviews.

## Core rules

- one writer at a time
- reviewers do not edit code
- an implementer does not approve its own work
- no automatic commits, pushes, merges, releases, or destructive resets
- unrelated local changes are preserved
- external tools are never installed or authenticated automatically
- critical security/data-integrity decisions are escalated to the user
- code and real checks matter more than model agreement
- only the minimum useful context is passed between agents
- token reporting distinguishes measured facts from counterfactual estimates
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

Then inside Claude Code:

```text
/agentennetzwerk:autocompact 60
/agentennetzwerk:doctor
/agentennetzwerk:start standard Implement a small test change
/agentennetzwerk:savings
```

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
│   │   ├── check-dependencies.ps1
│   │   ├── token-usage.sh
│   │   ├── telemetry-start.sh
│   │   ├── telemetry-subagent.sh
│   │   ├── telemetry-stop.sh
│   │   └── savings-report.sh
│   ├── skills/
│   │   ├── start/SKILL.md
│   │   ├── doctor/SKILL.md
│   │   ├── autocompact/SKILL.md
│   │   └── savings/SKILL.md
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
