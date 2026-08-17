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

Agentennetzwerk does not force a Claude model.

Use Claude Code's normal model selector before starting the workflow:

```text
/model
```

Choose Sonnet or Opus. Plugin subagents explicitly use `model: inherit`, so they follow the main Claude Code session model. The plugin saves tokens by controlling context and agent count, not by silently downgrading the model.

## Optional dependencies

For the full network:

- Claude Code
- Git
- Codex CLI
- Grok Build CLI

Codex and Grok must be installed and authenticated separately. Agentennetzwerk never installs, updates, or logs into external CLIs automatically.

Missing tools do not block the plugin. The first `/agentennetzwerk:start` call in a session displays a soft warning and selects a fallback:

```text
Codex available  -> Codex is the preferred single writer
Codex missing    -> claude-builder becomes the single writer

Grok available   -> optional independent breaker/reviewer
Grok missing     -> targeted Claude review remains available

Git available    -> diff/status/branch verification available
Git missing      -> file-based workflow without Git guarantees
```

Run a manual local check at any time:

```text
/agentennetzwerk:doctor
```

The doctor command checks local tool availability and reports the active fallback path. It does not install, update, or authenticate anything.

## Token-efficient design

The plugin keeps Sonnet or Opus fully available while reducing unnecessary work:

- only task-relevant agents are started
- the full skill is manual-only and loads only when invoked
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

Repository exploration is used only when the target is unclear.

### standard

For normal features, bug fixes, and refactoring:

```text
optional Explorer/Architect -> Writer -> QA -> risk-specific review -> checks
```

Regression, security, Grok, and Final Judge stages are added only when they provide real value.

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

Passing the task via stdin is preferred when practical. The workflow does not use `danger-full-access`, and Codex is instructed not to commit, push, merge, or reset unrelated work.

### Grok Build

Grok is used as a breaker/reviewer rather than a second writer. The workflow keeps these review runs bounded and avoids unnecessary memory, web search, and subagents when supported.

Agentennetzwerk does not use `--always-approve` for Grok reviews.

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
/agentennetzwerk:doctor
/agentennetzwerk:start standard Implement a small test change
```

## Repository structure

```text
agentennetzwerk/
├── .claude-plugin/marketplace.json
├── plugins/agentennetzwerk/
│   ├── .claude-plugin/plugin.json
│   ├── hooks/hooks.json
│   ├── scripts/
│   │   ├── check-dependencies.sh
│   │   └── check-dependencies.ps1
│   ├── skills/
│   │   ├── start/SKILL.md
│   │   └── doctor/SKILL.md
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
