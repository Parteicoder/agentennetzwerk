---
name: savings
description: Show factual Agentennetzwerk token telemetry without inventing counterfactual savings.
disable-model-invocation: true
allowed-tools: Bash
---

# Agentennetzwerk Savings

Run:

```text
bash "${CLAUDE_PLUGIN_ROOT}/scripts/savings-report.sh"
```

Present the result as a compact table.

Rules:

- `ACTUAL_CLAUDE_TOKENS_USED` is factual usage recorded from Claude Code transcript usage fields after Agentennetzwerk 0.5.0 telemetry was installed.
- Show supervisor and Claude-subagent token totals separately.
- Show observed Codex/Grok call counts separately. Do not pretend their tokens are included when they are not measured by this ledger.
- `UNUSED_CONFIGURED_CALL_SLOTS` is a factual count of unused model-call budget slots for runs with an explicit mode. It is **not** a token count.
- Never multiply skipped calls by an average token value and call that "tokens saved".
- Never use Claude Code's projected plugin token cost as an actual savings figure; projected component token costs are estimates.
- A numerically verified `TOKENS SAVED` value requires a controlled, measured counterfactual baseline for the same workload. If none exists, display exactly: `Verified tokens saved: not computable yet`.
- Briefly explain why: actual usage exists, but the token consumption of a model call that never happened is unknowable without a real comparison run.

Suggested output:

```text
Agentennetzwerk factual token report
Tracked runs: ...
Actual Claude tokens used: ...
  Supervisor: ...
  Claude subagents: ...
Observed external calls: Codex ... | Grok ...
Unused configured call slots: ...
Verified tokens saved: not computable yet
```

Do not start any model or benchmark run merely to produce this report. The reporting command itself should remain cheap and local.
