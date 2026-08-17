---
name: savings
description: Show factual Agentennetzwerk token telemetry plus controlled benchmark quality comparisons without inventing counterfactual savings.
disable-model-invocation: true
allowed-tools: Bash
---

# Agentennetzwerk Savings

Run:

```text
bash "${CLAUDE_PLUGIN_ROOT}/scripts/savings-report.sh"
```

Present the result compactly.

Rules:

- `ACTUAL_CLAUDE_TOKENS_USED` is factual usage recorded from Claude Code transcript usage fields.
- Show supervisor and Claude-subagent token totals separately.
- Show observed Codex/Grok call counts separately. Do not pretend their token totals are included when they are not measured by this ledger.
- `UNUSED_CONFIGURED_CALL_SLOTS` is a factual count of unused model-call budget slots for runs with an explicit network mode. It is not a token count.
- Never multiply skipped calls by an average token value and call that "tokens saved".
- Overall `Verified tokens saved` remains not computable unless all relevant model usage is measured in a controlled counterfactual.

## Controlled eval section

If `/agentennetzwerk:eval` results exist, also show:

- PASS/FAIL counts for baseline and network by quick/standard/deep scenario
- average patch-size facts
- average measured Claude tokens for matching eval modes
- `CLAUDE_ONLY_TOKEN_DELTA_NETWORK_MINUS_BASELINE` when a scenario has both baseline and network measurements

Interpret a negative Claude-only delta as fewer measured Claude tokens in the network run, not as proven total AI-token savings. Codex/Grok token totals are still outside the Claude ledger.

Compare quality before token cost. A cheaper run that fails the controlled tests is not an efficiency win.

For a fair pair, baseline and network should use the same scenario, main Claude model, effort, and relevant local settings.
