---
name: start
description: Start a token-efficient multi-agent coding workflow using Claude agents plus optional Codex CLI and Grok Build.
disable-model-invocation: true
argument-hint: "[quick|standard|deep] <task>"
---

# Agentennetzwerk

Task: `$ARGUMENTS`

Use the smallest workflow that can solve the task safely. Claude subagents inherit the model and effort selected in the main Claude Code session. Never override the user's Sonnet/Opus choice.

## Capabilities

The soft dependency hook may provide `SOFT_DEPENDENCY_STATUS`.

- Codex available: preferred single writer.
- Codex missing: use `claude-builder` as single writer.
- Grok available: optional independent breaker/reviewer.
- Grok missing: continue with Claude reviewers and mention reduced model diversity once in the final summary.
- Git missing: continue file-based, but make no branch, diff, or merge-readiness claims that require Git.

Do not repeatedly probe dependencies. Never install, update, or authenticate external CLIs automatically.

## Non-negotiable rules

- One writer at a time. Reviewers never edit.
- No commit, push, merge, release, destructive Git action, or reset of unrelated local changes unless the user explicitly requests it.
- Do not let an implementer approve its own work.
- Pass agents only: task, acceptance criteria, relevant files/interfaces, and the relevant diff or excerpts. Never forward the full chat transcript.
- Keep agent returns compact: normally <=5 bullets, no unchanged code, no repeated task text.
- Evidence beats model agreement. Use actual code and checks.
- Stop early when acceptance criteria are met, QA is clean, and relevant checks pass.

## Call budget

Treat every Claude subagent run, Codex run, and Grok run as one call.

- `quick`: target <=3 calls, maximum 1 repair rerun.
- `standard`: target <=5 calls, maximum 1 repair rerun. A second rerun is allowed only for a remaining HIGH/CRITICAL issue.
- `deep`: target <=8 calls, maximum 2 repair reruns.

Do not spend the budget merely because it exists.

## Routing

If no mode is supplied, choose the smallest sufficient mode.

### quick
Small, local change.

1. Find the target directly; use `repo-explorer` only if necessary.
2. Writer: Codex, otherwise `claude-builder`.
3. Run `qa-reviewer` on the changed code.
4. Run only the relevant checks. If clean, stop.

### standard
Normal feature, bug fix, or refactor.

1. Use `repo-explorer` only when repository context is unclear.
2. Use `architect` only for multi-component or non-trivial design decisions.
3. Writer: Codex, otherwise `claude-builder`.
4. Always run `qa-reviewer`.
5. Add `regression-hunter` only for compatibility/persistence/API/lifecycle/migration risk.
6. Add `security-reviewer` only for auth, permissions, network, secrets, files, import/export, database, or security-sensitive changes.
7. Prefer Grok over a redundant generic Claude review when independent model diversity adds value.
8. Use `final-judge` only for unresolved risk or conflicting reviews.

### deep
Architecture, migration, synchronization, security, data-model, or high-risk change.

1. Run `repo-explorer`, then `architect`.
2. Before implementation, request an external second opinion only when multiple plausible architectures exist.
3. Writer: Codex, otherwise `claude-builder`.
4. Run QA plus at most two risk-specific reviewers. Add Grok when available and useful.
5. Repair only confirmed findings and rerun only affected reviews/checks.
6. Finish with `final-judge`.

## External CLI discipline

### Codex writer
Prefer an ephemeral workspace-limited run. When practical, pass the prompt through stdin rather than interpolating user text into a shell command.

Preferred shape:

```text
codex exec --ephemeral --sandbox workspace-write -
```

Do not use `danger-full-access`. Tell Codex not to commit, push, or reset unrelated changes.

### Grok breaker
Use Grok only for review/analysis, not as a second writer. Keep the run bounded and disable unnecessary features when supported:

```text
grok --no-auto-update -p "<review prompt>" --no-subagents --no-memory --disable-web-search --max-turns 6
```

Do not use `--always-approve`. Explicitly instruct Grok not to edit files.

## Handoffs

Do not re-summarize a good agent result before passing it onward. Reuse the compact handoff directly.

Writer handoff should contain only:
- goal and acceptance criteria
- relevant files/interfaces
- 3-7 implementation steps when needed
- risks and required checks

Review findings should contain only:
`SEVERITY | file/location | concrete problem | expected correction`

LOW/style-only findings do not trigger a repair cycle.

## Verification and finish

Run only existing checks relevant to the touched area. Never invent successful results.

Final response should be compact:
- mode + writer
- optional dependency fallback, if any
- changed files
- essential implementation result
- material review findings
- checks actually run
- `READY`, `NOT READY`, or `HUMAN DECISION REQUIRED`

Never merge automatically.
