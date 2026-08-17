# Agentennetzwerk

A lightweight, token-efficient multi-agent coding workflow for Claude Code.

Claude Code is the supervisor. Codex CLI is the preferred single writer when available. Grok Build is an optional independent breaker/reviewer. Claude plugin subagents provide a small set of focused fallbacks and reviews.

There is no Python/Node orchestration server, no custom agent runtime, and no automatic merge/release authority.

## Install

Inside Claude Code:

```text
/plugin marketplace add Parteicoder/agentennetzwerk
/plugin install agentennetzwerk@parteicoder-agenten
/reload-plugins
```

## Use it naturally or explicitly

The start skill can be selected by Claude when you explicitly ask for Agentennetzwerk or a coordinated multi-agent coding workflow:

```text
Use Agentennetzwerk to fix the import race and verify the regression risk.
```

Ordinary coding requests should stay on Claude Code's normal path. The skill description is intentionally narrow so the network does not add model calls to every task.

The deterministic manual form remains available:

```text
/agentennetzwerk:start <task>
/agentennetzwerk:start quick <task>
/agentennetzwerk:start standard <task>
/agentennetzwerk:start deep <task>
```

## Design goal

**Maximum code quality per token with minimum custom infrastructure.**

Agentennetzwerk follows a few rules:

- one writer at a time
- decision-complete, source-light handoffs
- agents read the worktree instead of receiving pasted source
- real diffs/tests beat model agreement
- risk-specific review instead of reviewer swarms
- early exit when evidence is already clean
- native Claude Code features are preferred over rebuilding orchestration features
- no automatic commit, push, merge, release, dependency install, or destructive reset

## Four Claude roles

v0.8 reduces the plugin from seven Claude agents to four:

- `agentennetzwerk:claude-builder` - fallback single writer when Codex is unavailable
- `agentennetzwerk:architect` - targeted repository exploration + compact planning for non-trivial work
- `agentennetzwerk:reviewer` - correctness, requirements, tests, compatibility, and regression review
- `agentennetzwerk:security-reviewer` - security/privacy/data-integrity review only when a real trust boundary is touched

The supervisor now handles ordinary scouting and the final readiness decision. Separate `repo-explorer`, `regression-hunter`, and `final-judge` calls were removed because they duplicated work that can usually be handled in the supervisor, architect, or consolidated reviewer.

All Claude plugin agents use `model: inherit`, so they follow the model and effort selected in the main Claude Code session.

## Writer and reviewer model

### Codex

When available, Codex is the preferred writer. The workflow prefers a fresh workspace-limited invocation:

```text
codex exec --ephemeral --sandbox workspace-write -
```

The writer receives a compact packet with acceptance criteria, resolved decisions, relevant paths/symbols, risks, and checks. Source code normally stays in the worktree.

### Claude fallback

If Codex is unavailable, `agentennetzwerk:claude-builder` becomes the single writer. Missing Codex never blocks the task.

### Grok

Grok is an optional independent breaker/reviewer, not a second writer. It is used when model diversity is likely to improve confidence, not as a mandatory duplicate review.

The recommended bounded review shape remains:

```text
grok --no-auto-update -p "<review prompt>" --disallowed-tools Edit --no-subagents --no-memory --disable-web-search --max-turns 6
```

## Workflow modes

### quick

Small, mechanically clear local change.

```text
Writer -> relevant checks -> optional reviewer -> stop
```

Normally at most 2 model/agent calls; hard cap 3 including one repair rerun.

### standard

Normal feature, bug fix, or refactor.

```text
optional Architect -> Writer -> Reviewer -> optional targeted Security/Grok
```

Target budget: <=4 model/agent calls. Architect, security review, and Grok are conditional rather than ritual stages.

### deep

Architecture, migration, synchronization, concurrency, public contracts, security, or data-integrity risk.

```text
Architect -> Writer -> Reviewer -> targeted Security/Grok -> supervisor verdict
```

Target budget: <=6 model/agent calls. The supervisor makes the final decision from the code, diff, tests, and unresolved findings. There is no automatic final-judge call.

## Controlled benchmark

v0.8.1 adds a small local benchmark so the routing can be tested with the same tasks instead of relying on anecdotes.

Three isolated scenarios are generated in a temporary Git repository:

- `quick` - small local string-normalization bug
- `standard` - configuration merge behavior with mutation/regression checks
- `deep` - schema migration + persistence validation and data-integrity behavior

Each fixture starts with failing tests and has no external dependencies. The grader also fails if the agent changes `TASK.md`, `package.json`, or the tests.

Run a direct-Claude baseline:

```text
/agentennetzwerk:eval baseline quick
```

Then run the Agentennetzwerk path separately with the same main Claude model/settings:

```text
/agentennetzwerk:eval network quick
```

Repeat with `standard` or `deep` when useful. Keep baseline and network in separate invocations so transcript usage can be measured separately.

Then inspect the comparison:

```text
/agentennetzwerk:savings
```

The eval report separates two things deliberately:

- **quality facts**: PASS/FAIL, changed files, insertions/deletions
- **measured Claude usage**: supervisor + Claude subagent transcript tokens

When matching baseline/network runs exist, the report can show a factual `CLAUDE_ONLY_TOKEN_DELTA_NETWORK_MINUS_BASELINE` for that scenario. This is not claimed as total AI-token savings because Codex/Grok token totals are not silently invented or mixed into the Claude ledger.

Quality comes first: a cheaper benchmark that fails tests is not considered an efficiency win.

## Agent Teams and worktrees

Agentennetzwerk does not recreate Claude Code's native Agent Teams or worktree isolation.

The normal workflow intentionally stays single-writer. If a user explicitly wants truly independent parallel implementation, Claude Code's native isolation/worktree capabilities are preferred over adding a custom Python/Node controller to this plugin.

## Optional dependencies and fallbacks

```text
Codex available  -> preferred single writer
Codex missing    -> claude-builder writer

Grok available   -> optional independent model review
Grok missing     -> continue with Claude review

Git available    -> diff/status/branch evidence
Git missing      -> file-based work without Git-dependent readiness claims
```

Dependency probes are soft and non-destructive. The plugin never installs or authenticates external tools automatically.

## Context and compaction

`/agentennetzwerk:autocompact 60` remains an optional proactive setup command. It is not a requirement for Agentennetzwerk to run and coding tasks do not spend model calls configuring it.

Claude and Grok expose percentage-based compaction controls. Codex exposes an absolute token threshold, so the plugin only reports an exact percentage when an explicit context window makes that calculation verifiable. It never guesses a Codex context-window size from a model name.

Check local state with:

```text
/agentennetzwerk:doctor
```

## Factual telemetry

Show locally recorded run telemetry with:

```text
/agentennetzwerk:savings
```

Agentennetzwerk reads recorded Claude Code usage fields from main-session and plugin-subagent JSONL transcripts. It supports telemetry startup for both direct `/agentennetzwerk:start` expansion and model-invoked `Skill` use, plus dedicated controlled-eval modes.

The report can show:

- measured Claude supervisor tokens
- measured Claude plugin-subagent tokens
- observed Codex/Grok invocation counts
- unused configured call-budget slots
- controlled benchmark quality and Claude-only baseline/network deltas

It deliberately does **not** convert skipped calls into imaginary saved tokens. Without a controlled measured baseline:

```text
Verified tokens saved: not computable yet
```

External Codex/Grok token totals are not silently mixed into Claude totals unless directly measured.

## Update policy: check automatically, install manually

Agentennetzwerk checks its GitHub version at most once per 24 hours on Claude Code startup/resume. A network failure does not block startup and no update is installed automatically.

When a newer version is found:

```text
Agentennetzwerk update available: 0.8.1 -> 0.9.0.
Run /agentennetzwerk:update to install it manually.
```

Only this explicit command performs the update:

```text
/agentennetzwerk:update
```

Then reload when prompted:

```text
/reload-plugins
```

## Commands

```text
/agentennetzwerk:start [quick|standard|deep] <task>
/agentennetzwerk:eval [network|baseline] [quick|standard|deep]
/agentennetzwerk:doctor
/agentennetzwerk:autocompact 60
/agentennetzwerk:savings
/agentennetzwerk:update
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
│   │   ├── eval-fixture.sh
│   │   ├── eval-grade.sh
│   │   └── eval-report.sh
│   ├── skills/
│   │   ├── start/SKILL.md
│   │   ├── eval/SKILL.md
│   │   ├── doctor/SKILL.md
│   │   ├── autocompact/SKILL.md
│   │   ├── savings/SKILL.md
│   │   └── update/SKILL.md
│   └── agents/
│       ├── claude-builder.md
│       ├── architect.md
│       ├── reviewer.md
│       └── security-reviewer.md
├── CHANGELOG.md
├── LICENSE
└── README.md
```

## Development

```bash
git clone https://github.com/Parteicoder/agentennetzwerk.git
cd agentennetzwerk
claude plugin validate .
claude plugin validate ./plugins/agentennetzwerk
claude --plugin-dir ./plugins/agentennetzwerk
```

GitHub Actions validates both a pinned Claude Code baseline and the current `latest` release, along with JSON, shell scripts, agent references, prompt-invocation configuration, the factual token parser, and the controlled benchmark harness.

## License

GNU Affero General Public License v3.0 (AGPL-3.0).
