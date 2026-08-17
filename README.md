# Agentennetzwerk

Ein promptbasiertes, tokensparendes Multi-Agent-Coding-Netzwerk für Claude Code.

Claude Code koordiniert spezialisierte Claude-Subagents. Codex CLI kann als bevorzugter Writer und Grok Build als unabhängiger Breaker eingebunden werden. Beide sind optional: Fehlen externe Coding-KIs, arbeitet das Plugin mit Claude-Agenten weiter und meldet die Einschränkung.

Es gibt keinen eigenen Python-, Node- oder Server-Orchestrator.

## Installation

In Claude Code:

```text
/plugin marketplace add Parteicoder/agentennetzwerk
/plugin install agentennetzwerk@parteicoder-agenten
/reload-plugins
```

Start:

```text
/agentennetzwerk:start <Aufgabe>
```

Optional:

```text
/agentennetzwerk:start quick Behebe den NullPointer im Import
/agentennetzwerk:start standard Baue eine Suchfunktion ein
/agentennetzwerk:start deep Überarbeite die Synchronisationsarchitektur
```

## Abhängigkeiten und Fallbacks

Für den vollen Funktionsumfang sind sinnvoll:

- Claude Code
- Git
- Codex CLI
- Grok Build CLI

Codex und Grok müssen separat installiert und authentifiziert werden. Das Plugin installiert oder loggt externe CLIs niemals automatisch ein.

Fehlt eine Abhängigkeit, wird der Workflow **nicht blockiert**. Beim ersten `/agentennetzwerk:start` einer Claude-Code-Sitzung zeigt ein Soft-Dependency-Hook einmalig eine Meldung. Danach läuft das Plugin mit Einschränkungen weiter:

```text
Codex vorhanden  -> Codex ist bevorzugter Single Writer
Codex fehlt      -> claude-builder übernimmt als Single Writer

Grok vorhanden   -> Grok kann unabhängiger Breaker sein
Grok fehlt       -> gezielter Claude-Reviewer übernimmt bei Bedarf; geringere Modellvielfalt

Git vorhanden    -> Status und Diff können verifiziert werden
Git fehlt        -> dateibasierter Workflow ohne Git-Garantien
```

Der Hook nutzt Exit-Code `0`. Es gibt kein hartes Gate mehr.

## Tokensparendes Design

Version 0.3.0 ist bewusst auf niedrigen Kontextverbrauch ausgelegt:

- nur die Agenten starten, die für das konkrete Risiko nötig sind
- `quick` vermeidet Architect und Final Judge normalerweise vollständig
- `standard` startet Spezialreviewer nur bei passendem Risiko
- `deep` nutzt die vollständige Kette nur bei großen oder riskanten Änderungen
- Repo Explorer läuft mit Haiku, low effort und maximal 8 Turns
- Architect/Reviewer laufen überwiegend mit Sonnet und begrenzten Turns
- keine Opus-Reviewer im Standardworkflow
- Agentenausgaben sind auf wenige Stichpunkte bzw. kurze Zusammenfassungen begrenzt
- große Logs und Dateien bleiben im Subagent-Kontext
- nur der relevante Diff wird reviewed, nicht jedes Mal das ganze Repository
- nach einem Fix werden nur betroffene Checks erneut ausgeführt
- keine Agent Teams im Standardbetrieb

## Modi

### quick

Kleine lokale Änderung:

```text
Writer -> QA -> Checks
```

Repo Explorer nur wenn nötig. Maximal eine Reparaturrunde.

### standard

Normales Feature oder Refactoring:

```text
optional Explorer/Architect -> Writer -> QA -> optionale gezielte Reviews -> Checks
```

Grok wird nur eingesetzt, wenn verfügbar und ein unabhängiger Gegencheck echten Mehrwert bringt.

### deep

Architektur, Migration, Security, Synchronisation oder große/riskante Änderungen:

```text
Explorer -> Architect -> Writer -> gezielte Reviewer + optional Grok -> Final Judge
```

Maximal zwei Reparaturrunden.

## Agenten

- `claude-builder`: Fallback-Writer, wenn Codex fehlt
- `repo-explorer`: findet nur relevante Komponenten und Checks
- `architect`: plant nichttriviale Änderungen knapp
- `qa-reviewer`: prüft Auftrag, Verhalten und Tests
- `regression-hunter`: nur bei Kompatibilitäts-/Migrationsrisiko
- `security-reviewer`: nur bei sicherheitsrelevantem Scope
- `final-judge`: nur bei Deep- oder strittigen Läufen

Es gilt das Single-Writer-Prinzip. Reviewer sind read-only.

## Externe Modelle

### Codex

Wenn verfügbar, wird Codex über `codex exec` als bevorzugter Writer genutzt. Codex soll nicht selbst committen, pushen oder mergen.

### Grok Build

Wenn verfügbar und sinnvoll, wird Grok headless als unabhängiger Breaker eingesetzt. Seine Aufgabe ist das Finden konkreter Edge Cases und Fehlerpfade, nicht eine zweite Komplettimplementierung.

## Sicherheitsregeln

- nur ein Writer gleichzeitig
- keine automatischen Commits, Pushes oder Merges
- fremde lokale Änderungen nicht zurücksetzen
- keine automatische Installation oder Authentifizierung externer CLIs
- kritische Daten-/Security-Risiken an den Benutzer eskalieren
- Evidenz statt Modellmehrheit

## Entwicklung und Test

```bash
git clone https://github.com/Parteicoder/agentennetzwerk.git
cd agentennetzwerk
claude plugin validate .
claude plugin validate ./plugins/agentennetzwerk
claude --plugin-dir ./plugins/agentennetzwerk
```

## Repository-Struktur

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

## Lizenz

GNU Affero General Public License v3.0 (AGPL-3.0).
