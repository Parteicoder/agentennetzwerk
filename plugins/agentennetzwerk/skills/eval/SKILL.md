---
name: eval
description: Run one controlled Agentennetzwerk coding benchmark and grade result quality separately from token telemetry.
disable-model-invocation: true
argument-hint: "[network|baseline] [quick|standard|deep]"
---

# Agentennetzwerk Eval

Arguments: `$ARGUMENTS`

This is a controlled benchmark, not normal project work. Never modify the user's current repository as part of an eval.

## Arguments

Require exactly:

```text
/agentennetzwerk:eval network quick
/agentennetzwerk:eval network standard
/agentennetzwerk:eval network deep
```

or the matching `baseline` variant.

- `network`: use the Agentennetzwerk routing policy for the requested scenario.
- `baseline`: the main Claude session implements the same task directly with no Agentennetzwerk subagents, Codex, or Grok.

Run baseline and network as separate invocations so their transcript usage can be measured separately.

## Prepare isolated fixture

Run:

```text
bash "${CLAUDE_PLUGIN_ROOT}/scripts/eval-fixture.sh" <scenario>
```

Capture the reported `WORKSPACE`. Read only `<WORKSPACE>/TASK.md` plus files needed to solve that task. The fixture is a temporary Git repository with an initial baseline commit.

Do not edit:
- `TASK.md`
- `package.json`
- anything under `test/`

Do not install dependencies. The fixtures use Node's built-in test runner and require no network access.

## Baseline variant

Implement the task directly in the main Claude session.

Rules:
- no Claude subagents
- no Codex
- no Grok
- no Agent Teams
- inspect only the fixture workspace
- make the smallest correct patch
- run `npm test` in the fixture workspace

The purpose is to measure a real same-model single-agent baseline, not to intentionally handicap it.

## Network variant

Use the normal Agentennetzwerk v0.8 routing rules for the selected scenario, but operate only inside the fixture workspace.

- `quick`: writer first; add reviewer only if materially useful.
- `standard`: architect only if a real design decision remains, then writer + reviewer.
- `deep`: architect, writer, reviewer, and security reviewer only if the fixture actually crosses a security/data-integrity boundary.
- Codex is the preferred writer when available; otherwise use `agentennetzwerk:claude-builder`.
- Grok is optional and must not be invoked merely to consume the benchmark budget.
- one writer at a time
- no commits, pushes, dependency installation, or edits outside the fixture

When invoking a Claude plugin agent, give it the absolute fixture workspace path and explicitly forbid edits outside that path. For Codex, run it from the fixture directory with the normal workspace-write sandbox.

## Grade

After implementation, run:

```text
bash "${CLAUDE_PLUGIN_ROOT}/scripts/eval-grade.sh" "<WORKSPACE>" <scenario> <variant>
```

The grader fails the benchmark if tests fail or if `TASK.md`, `package.json`, or tests were changed. It records PASS/FAIL and patch-size facts under `${CLAUDE_PLUGIN_DATA}/eval/results.tsv`.

Do not repair after grading. A failed grade is the measured outcome for that run.

## Report

Return only:
- variant + scenario
- writer/routing used
- `PASS` or `FAIL`
- changed-file and insertion/deletion counts
- checks actually run
- fixture workspace path
- reminder that `/agentennetzwerk:savings` reports measured token usage and benchmark comparisons

Never claim overall token savings from a single run. A meaningful comparison requires at least one baseline and one network run for the same scenario. Network Codex/Grok token totals remain outside Claude token telemetry unless separately measurable.
