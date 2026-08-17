# Agentennetzwerk

A prompt-driven, token-efficient multi-agent coding network for Claude Code.

Claude Code coordinates specialized Claude subagents. Codex CLI can be used as the preferred writer, while Grok Build can act as an independent breaker/reviewer. Both are optional: if an external coding AI is missing, the plugin continues with Claude-based fallbacks and reports the limitation once per Claude Code session.

There is no custom Python, Node.js, or server-side orchestrator.

## Installation

Inside Claude Code:

```text
/plugin marketplace add Parteicoder/agentennetzwerk
/plugin install agentennetzwerk@parteicoder-agenten
/reload-plugins
```

Start the network with:

```text
/agentennetzwerk:start <task>
```

Optional modes:

```text
/agentennetzwerk:start quick Fix the null pointer in the import flow
/agentennetzwerk:start standard Add a search feature
/agentennetzwerk:start deep Redesign the synchronization architecture
```

## Claude model selection

Agentennetzwerk does **not** force a specific Claude model.

Choose the model you want to use in Claude Code **before** starting the workflow, for example Sonnet or Opus. The plugin subagents inherit the model and effort level of the main Claude Code session by default.

Example:

```text
/model
```

Select Sonnet or Opus, then run:

```text
/agentennetzwerk:start standard Implement the feature
```

The plugin does not silently downgrade agents to Haiku or another smaller model. Token savings come from smaller context packages, limited agent turns, selective reviews, and short result summaries.

Claude Code also supports `CLAUDE_CODE_SUBAGENT_MODEL` if a user explicitly wants to override the model used by all subagents.

## Dependencies and fallbacks

For the full workflow, the following tools are useful:

- Claude Code
- Git
- Codex CLI
- Grok Build CLI

Codex and Grok must be installed and authenticated separately. Agentennetzwerk never installs, updates, or logs into external coding CLIs automatically.

Missing dependencies do **not** block the plugin. On the first `/agentennetzwerk:start` call of a Claude Code session, a soft dependency hook reports missing tools once. The workflow then continues with the available components:

```text
Codex available  -> Codex is the preferred single writer
Codex missing    -> claude-builder becomes the single writer

Grok available   -> Grok can act as an independent breaker
Grok missing     -> targeted Claude reviewer is used when needed; model diversity is reduced

Git available    -> status and diff can be verified
Git missing      -> file-based workflow without Git guarantees
```

The dependency hook exits with code `0`. There is no hard gate.

## Token-efficient design

Agentennetzwerk is designed to reduce unnecessary context usage without forcing a cheaper Claude model.

- only agents relevant to the actual task are started
- subagents inherit the Claude model selected for the main session
- `quick` normally skips architecture and final-judge stages
- `standard` launches specialized reviewers only when their risk area applies
- `deep` uses the fuller review chain only for large or risky changes
- agent turn counts are capped with `maxTurns`
- agent outputs are limited to short summaries or a few findings
- large logs and file contents stay inside subagent contexts where possible
- reviewers receive the relevant diff or files instead of repeatedly re-reading the whole repository
- after a fix, only affected checks and reviewers are rerun
- Agent Teams are not required for the normal workflow

## Modes

### quick

For small, local changes:

```text
Writer -> QA -> Checks
```

The Repo Explorer is only used when needed. Usually only one repair cycle is allowed.

### standard

For normal features, bug fixes, and refactoring:

```text
optional Explorer/Architect -> Writer -> QA -> targeted optional reviews -> Checks
```

Grok is used only when available and when an independent second model provides meaningful value.

### deep

For architecture, migrations, security, synchronization, data models, or other large/risky changes:

```text
Explorer -> Architect -> Writer -> targeted reviewers + optional Grok -> Final Judge
```

A maximum of two repair cycles is allowed.

## Agents

- `claude-builder`: fallback writer when Codex is unavailable
- `repo-explorer`: finds only the repository context relevant to the task
- `architect`: produces a compact plan for non-trivial changes
- `qa-reviewer`: checks requirements, behavior, and tests
- `regression-hunter`: used only when compatibility or migration risk exists
- `security-reviewer`: used only for security-relevant changes
- `final-judge`: used for deep or disputed workflows

All Claude plugin agents inherit the model selected in the main Claude Code session unless the user explicitly overrides subagent model selection through Claude Code configuration.

The network follows a single-writer rule. Review agents are read-only.

## External coding AIs

### Codex

When available, Codex is invoked through `codex exec` as the preferred writer. It is instructed not to commit, push, or merge automatically.

If Codex is unavailable, `claude-builder` takes over implementation.

### Grok Build

When available and useful, Grok is invoked headlessly as an independent breaker. Its job is to find concrete edge cases, failure paths, and weaknesses rather than produce a second full implementation.

If Grok is unavailable, the workflow continues with Claude reviewers and reports the reduced model diversity.

## Core rules

- one writer at a time
- reviewers do not edit code
- no automatic commits, pushes, merges, or releases
- unrelated local changes are never reset
- no automatic installation or authentication of external CLIs
- critical security or data-integrity risks are escalated to the user
- evidence, tests, and actual code matter more than model agreement
- only the minimum useful context is passed between agents

## Development and local testing

```bash
git clone https://github.com/Parteicoder/agentennetzwerk.git
cd agentennetzwerk
claude plugin validate .
claude plugin validate ./plugins/agentennetzwerk
claude --plugin-dir ./plugins/agentennetzwerk
```

Then, inside Claude Code:

```text
/agentennetzwerk:start standard Analyze this repository and implement a small test change
```

## Repository structure

```text
agentennetzwerk/
├── .claude-plugin/
│   └── marketplace.json
├── plugins/
│   └── agentennetzwerk/
│       ├── .claude-plugin/plugin.json
│       ├── hooks/hooks.json
│       ├── scripts/
│       │   ├── check-dependencies.sh
│       │   └── check-dependencies.ps1
│       ├── skills/start/SKILL.md
│       └── agents/
│           ├── claude-builder.md
│           ├── repo-explorer.md
│           ├── architect.md
│           ├── qa-reviewer.md
│           ├── regression-hunter.md
│           ├── security-reviewer.md
│           └── final-judge.md
├── LICENSE
└── README.md
```

## License

GNU Affero General Public License v3.0 (AGPL-3.0).
