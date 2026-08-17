---
name: update
description: Manually update Agentennetzwerk after an update notification. Never runs automatically.
disable-model-invocation: true
allowed-tools: Bash
---

# Agentennetzwerk Manual Update

This command is the explicit user approval to update Agentennetzwerk.

Run exactly:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/manual-update.sh"
```

Do not install or update any other plugin, Claude Code itself, Codex, Grok, or system package.

Report the command result briefly. If the update succeeds, tell the user to run `/reload-plugins` so the current Claude Code session loads the new plugin version.
