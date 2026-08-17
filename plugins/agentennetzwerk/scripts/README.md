# Dependency Gate

Das Agentennetzwerk hat harte externe Laufzeit-Abhängigkeiten:

- `git`
- `codex`
- `grok`

`check-dependencies.sh` wird vom Claude-Code-Hook vor `/agentennetzwerk:start` ausgeführt. Fehlt eine Abhängigkeit oder kann die Binary nicht gestartet werden, beendet das Skript sich mit Exit-Code `2`. Claude Code behandelt Exit-Code `2` bei `UserPromptExpansion` als blockierend und startet den Skill nicht.

`check-dependencies.ps1` enthält dieselbe Prüfung für native PowerShell-/Windows-Setups und kann bei Bedarf direkt zum Testen ausgeführt werden.

Die eigentliche Authentifizierung bleibt Aufgabe der jeweiligen CLI. Das Plugin speichert keine API-Keys oder Login-Tokens.
