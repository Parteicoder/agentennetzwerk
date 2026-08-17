# Agentennetzwerk

Ein promptbasiertes Multi-Agent-Coding-Netzwerk für Claude Code.

Claude Code übernimmt die Koordination, spezialisierte Claude-Subagents analysieren und reviewen, Codex CLI ist standardmäßig der einzige Code-Writer und Grok Build arbeitet als unabhängiger Gegenprüfer/Breaker.

Es gibt keinen eigenen Python-, Node- oder Server-Orchestrator. Das Netzwerk besteht aus Claude-Code-Plugin-Metadaten, Skills, Agent-Prompts und einem kleinen Dependency-Gate.

## Harte Laufzeit-Abhängigkeiten

Für den vollständigen Betrieb sind diese Komponenten zwingend erforderlich:

- Claude Code
- Git
- Codex CLI, installiert, im `PATH` verfügbar und authentifiziert
- Grok Build CLI, installiert, im `PATH` verfügbar und authentifiziert

Diese Anforderungen sind nicht nur Dokumentation. Das Plugin enthält einen blockierenden Hook vor dem Start des Skills. Beim direkten Aufruf von `/agentennetzwerk:start` werden die benötigten Programme geprüft. Fehlt Git, Codex oder Grok, wird die Skill-Ausführung abgebrochen.

```text
Claude Code  = Supervisor + Claude-Agenten
Codex        = Single Writer / Implementierung
Grok         = unabhängiger Breaker / Gegenprüfung
Git          = gemeinsame Wahrheit
```

Das Plugin installiert oder authentifiziert Codex und Grok absichtlich nicht automatisch. Die Abhängigkeiten müssen auf dem System bereits funktionsfähig sein.

## Prinzip

```text
Benutzer
   |
   v
/agentennetzwerk:start
   |
   v
Dependency Gate
   |
   +--> git vorhanden?
   +--> codex vorhanden?
   +--> grok vorhanden?
   |
   +--> NEIN -> BLOCK
   |
   v
Claude Supervisor
   |
   +--> Repo Explorer
   +--> Architect
   |
   +--> Codex CLI --------> Implementierung (Single Writer)
   |
   +--> QA Reviewer
   +--> Regression Hunter
   +--> Security Reviewer
   +--> Grok Build -------> unabhängiger Breaker
   |
   v
Final Judge
   |
   +--> READY TO MERGE
   +--> NOT READY
   +--> HUMAN DECISION REQUIRED
```

## Installation direkt aus GitHub

In Claude Code:

```text
/plugin marketplace add Parteicoder/agentennetzwerk
/plugin install agentennetzwerk@parteicoder-agenten
/reload-plugins
```

Danach steht der Skill zur Verfügung:

```text
/agentennetzwerk:start <Aufgabe>
```

Optional kann ein Modus vorangestellt werden:

```text
/agentennetzwerk:start quick Behebe den NullPointer im Import
/agentennetzwerk:start standard Baue eine Suchfunktion ein
/agentennetzwerk:start deep Überarbeite die Synchronisationsarchitektur
```

Ohne Modus klassifiziert der Supervisor die Aufgabe selbst.

## Dependency-Gate testen

Vor der ersten echten Aufgabe kannst du lokal prüfen:

```text
codex --version
grok version
git --version
```

Fehlt eine Abhängigkeit, wird `/agentennetzwerk:start` blockiert und nennt die fehlende CLI.

Unter Windows liegt zusätzlich `scripts/check-dependencies.ps1` bei. Das eigentliche Plugin-Gate verwendet die Bash-Variante, weil Git for Windows eine Bash-Umgebung mitbringt und Claude Code diese auf Windows bevorzugt, wenn sie verfügbar ist.

## Modi

### quick

Für kleine, lokal begrenzte Änderungen. Weniger Agenten, kurze Review-Kette.

### standard

Standardworkflow mit Repository-Analyse, Architektur, Codex-Implementierung, Claude-Reviews und Grok-Gegenprüfung.

### deep

Für Architektur, Migrationen, Security, Datenmodelle und riskante Änderungen. Mehrere unabhängige Analysen werden erstellt, bevor eine Richtung gewählt wird.

## Agenten

- `repo-explorer`: findet relevante Komponenten und Abhängigkeiten
- `architect`: entwirft die minimale testbare Lösung
- `qa-reviewer`: prüft Anforderung, Verhalten und Tests
- `regression-hunter`: sucht beschädigtes Altverhalten
- `security-reviewer`: prüft Security, Datenschutz und Datenintegrität
- `final-judge`: entscheidet unabhängig über Merge-Bereitschaft

Die Review-Agenten sind read-only konzipiert. Standardmäßig darf nur Codex die Implementierung verändern.

## Externe Modelle

### Codex

Das Netzwerk nutzt Codex im nicht-interaktiven Modus über `codex exec`. Codex ist standardmäßig der Code-Writer. Der Skill weist Codex an, nicht selbst zu committen, zu pushen oder zu mergen.

### Grok Build

Grok wird headless über `grok -p` aufgerufen. Seine Hauptrolle ist nicht das Schreiben, sondern das Brechen der vorgeschlagenen Lösung mit Edge Cases, Gegenbeispielen und unabhängiger Kritik.

## Sicherheitsregeln

- Single Writer
- keine automatischen Commits, Pushes oder Merges
- fremde lokale Änderungen nicht zurücksetzen
- maximal zwei Reparaturzyklen
- Stop bei kritischen Security-Befunden oder möglichem Datenverlust
- keine Mehrheitsabstimmung zwischen Modellen; Evidenz entscheidet
- Codex, Grok und Git müssen vor dem Workflow vorhanden sein

## Entwicklung und Test

Repository klonen:

```bash
git clone https://github.com/Parteicoder/agentennetzwerk.git
cd agentennetzwerk
```

Marketplace validieren:

```bash
claude plugin validate .
```

Plugin separat validieren:

```bash
claude plugin validate ./plugins/agentennetzwerk
```

Plugin lokal ohne Installation testen:

```bash
claude --plugin-dir ./plugins/agentennetzwerk
```

Dann in Claude Code:

```text
/agentennetzwerk:start standard Analysiere dieses Repository und schlage eine kleine Teständerung vor
```

## Repository-Struktur

```text
agentennetzwerk/
├── .claude-plugin/
│   └── marketplace.json
├── plugins/
│   └── agentennetzwerk/
│       ├── .claude-plugin/
│       │   └── plugin.json
│       ├── hooks/
│       │   └── hooks.json
│       ├── scripts/
│       │   ├── check-dependencies.sh
│       │   └── check-dependencies.ps1
│       ├── skills/
│       │   └── start/
│       │       └── SKILL.md
│       └── agents/
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
