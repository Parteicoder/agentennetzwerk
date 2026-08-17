---
name: start
description: Use Agentennetzwerk for a coding task when the user explicitly asks for Agentennetzwerk, a multi-agent coding workflow, or coordinated Claude/Codex/Grok implementation and review. Do not auto-trigger for ordinary coding requests.
when_to_use: Trigger on requests such as "use Agentennetzwerk", "run this through the agent network", or an explicit request for coordinated Claude, Codex, and Grok coding. Keep normal coding requests on the normal Claude Code path.
argument-hint: "[quick|standard|deep] <task>"
---

# Agentennetzwerk

Task: `$ARGUMENTS`

If invoked automatically and `$ARGUMENTS` is empty, use the triggering user coding request as the task.

Optimize for code quality per token. Use the smallest workflow that can solve the task safely. Claude subagents inherit the model and effort selected in the main session. Never silently override the user's model choice.

## Capabilities

Prefer hook-provided `SOFT_DEPENDENCY_STATUS`.

If it is absent, perform one lightweight local probe for `git --version`, `codex --version`, and `grok version`. Show one short limitation notice if needed. Never install, update, or authenticate dependencies automatically and do not probe again later.

- Codex available: preferred single writer.
- Codex missing: use `agentennetzwerk:claude-builder` as the single writer.
- Grok available: optional independent breaker/reviewer when model diversity materially helps.
- Grok missing: continue without blocking.
- Git missing: continue file-based, but make no Git-dependent readiness claims.

## Plugin agents

Use only these scoped plugin agents:

- `agentennetzwerk:claude-builder`
- `agentennetzwerk:architect`
- `agentennetzwerk:reviewer`
- `agentennetzwerk:security-reviewer`

The supervisor handles ordinary repository scouting and the final readiness decision. Do not spawn a separate explorer or final-judge model call.

## Core rules

- One writer at a time. Reviewers never edit.
- The implementer never approves its own work.
- No commit, push, merge, release, dependency installation, destructive Git action, or reset of unrelated work unless explicitly requested.
- Evidence beats model agreement: inspect the actual diff and run real checks.
- Stop early when acceptance criteria are met and the relevant evidence is clean.
- Do not use Agent Teams in the normal workflow. If the user explicitly requests parallel independent implementation, prefer Claude Code's native isolation/worktree features rather than inventing a custom multi-writer controller.

## Decision-complete handoffs

Keep handoffs source-light and decision-complete. Prefer paths and symbols over pasted source.

A writer packet should normally stay under ~500 words and contain only:
- goal + acceptance criteria
- relevant files/interfaces/symbols
- resolved decisions
- 3-7 steps when useful
- material risks
- checks to run
- explicit do-not-change boundaries

Do not forward the full chat transcript or large logs. Agents can read the worktree themselves.

Review packets should contain the task, acceptance criteria, relevant diff/files, and any known risk boundary. Reuse good handoffs directly instead of repeatedly summarizing them.

## Call budgets

Count each Claude subagent, Codex run, and Grok run as one model/agent call.

- `quick`: normally <=2 calls, hard cap 3 including one repair rerun.
- `standard`: target <=4 calls, normally one repair rerun maximum.
- `deep`: target <=6 calls, maximum two repair reruns only for confirmed material findings.

Budgets are ceilings, not quotas.

## Routing

If the user specifies a mode, respect it. Otherwise choose the smallest sufficient mode.

### quick
For a small, local, mechanically clear change.

1. Supervisor locates the target directly.
2. Writer: Codex, otherwise `agentennetzwerk:claude-builder`.
3. Run relevant existing checks.
4. Add `agentennetzwerk:reviewer` only when the diff is behaviorally meaningful, weakly tested, or carries a plausible regression risk.
5. If evidence is clean, stop.

### standard
For a normal feature, bug fix, or refactor.

1. Use `agentennetzwerk:architect` only when a real design decision remains or multiple components are involved.
2. Freeze the acceptance criteria and unresolved decisions before implementation.
3. Writer: Codex, otherwise `agentennetzwerk:claude-builder`.
4. Run `agentennetzwerk:reviewer` on the actual patch.
5. Add `agentennetzwerk:security-reviewer` only for auth, permissions, network, secrets, files/import-export, persistence integrity, or another concrete security boundary.
6. Use Grok only when an independent model is likely to catch something the targeted Claude review will not. Do not add it as a ritual duplicate review.
7. Repair confirmed findings only, then rerun only affected checks/reviews.

### deep
For architecture, migrations, synchronization, concurrency, security, public contracts, data models, or other high-risk work.

1. Run `agentennetzwerk:architect` and freeze the intended contract before implementation.
2. If multiple plausible architectures remain, optionally request one independent Grok opinion before writing. Resolve the choice in the supervisor.
3. Writer: Codex, otherwise `agentennetzwerk:claude-builder`.
4. Run `agentennetzwerk:reviewer` plus `agentennetzwerk:security-reviewer` when the patch crosses a security/data-integrity boundary.
5. Use Grok post-write only when independent model diversity materially improves confidence or Claude reviews conflict.
6. Repair only evidence-backed findings and rerun only affected checks.
7. The supervisor makes the final `READY`, `NOT READY`, or `HUMAN DECISION REQUIRED` decision from code, diff, tests, and unresolved material findings. No automatic final-judge call.

## External CLI discipline

### Codex writer

Prefer a fresh, ephemeral, workspace-limited run and pass the task through stdin when practical:

```text
codex exec --ephemeral --sandbox workspace-write -
```

Do not use `danger-full-access`. Tell Codex not to commit, push, merge, release, install dependencies, or reset unrelated work unless explicitly authorized.

### Grok breaker

Use Grok as read-only analysis/review, not a second writer. Keep the run bounded and remove unnecessary capabilities when supported:

```text
grok --no-auto-update -p "<review prompt>" --disallowed-tools Edit --no-subagents --no-memory --disable-web-search --max-turns 6
```

Do not use `--always-approve`. Explicitly forbid file modification in the review prompt.

## Compaction

Do not alter compaction settings during a coding task. `/agentennetzwerk:autocompact 60` remains an optional user setup command, not a prerequisite or a reason to spend a model call. `/agentennetzwerk:doctor` reports the factual local state.

## Verification and finish

Run only existing checks relevant to the touched area. Never invent successful results.

Final response should be compact:
- mode + writer
- changed files
- essential implementation result
- material findings or fallback limitations
- checks actually run
- `READY`, `NOT READY`, or `HUMAN DECISION REQUIRED`

Never merge automatically.
