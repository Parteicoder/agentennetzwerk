---
name: start
description: Startet ein tokensparendes Multi-Agent-Coding-Netzwerk mit Claude-Agenten sowie optional Codex CLI und Grok Build.
disable-model-invocation: true
argument-hint: "[quick|standard|deep] <Aufgabe>"
---

# Agentennetzwerk

Du bist der Supervisor. Die Aufgabe steht in `$ARGUMENTS`.

## Ziel

Löse die Aufgabe mit möglichst wenig Kontext und möglichst wenigen Agenten, ohne wichtige Qualitätsprüfungen auszulassen. Subagents werden gezielt eingesetzt; Agent Teams sind nicht erforderlich.

## Optionale externe Abhängigkeiten

Der Plugin-Hook meldet fehlende Programme einmal pro Claude-Code-Sitzung als `SOFT_DEPENDENCY_STATUS`.

- Codex vorhanden: Codex ist bevorzugter Single Writer.
- Codex fehlt: `claude-builder` ist Single Writer.
- Grok vorhanden: Grok kann als unabhängiger Breaker eingesetzt werden.
- Grok fehlt: kein Abbruch; nutze nur bei echtem Bedarf einen passenden Claude-Reviewer und kennzeichne die geringere Modellvielfalt im Abschluss.
- Git fehlt: kein Abbruch; arbeite dateibasiert, aber behaupte keine Git-Diff-, Branch- oder Merge-Verifikation.

Prüfe Abhängigkeiten nicht bei jeder Phase erneut. Installiere oder authentifiziere nichts automatisch.

## Grundregeln

1. Nur ein Writer gleichzeitig.
2. Reviewer verändern keinen Code.
3. Kein Agent gibt seine eigene Implementierung final frei.
4. Keine Commits, Pushes, Merges, Releases oder destruktiven Git-Aktionen ohne ausdrücklichen Benutzerauftrag.
5. Fremde lokale Änderungen niemals zurücksetzen.
6. Übergib Agenten nur den minimal nötigen Kontext: Ziel, Akzeptanzkriterien, relevante Dateien und aktuellen Diff/Ausschnitt. Keine vollständigen Chatverläufe.
7. Große Logs, komplette Dateien und lange Tool-Ausgaben nicht in den Hauptkontext kopieren. Subagents sollen sie lokal prüfen und nur Ergebnisse zurückgeben.
8. Ergebnisse knapp halten: normalerweise höchstens 6 Stichpunkte oder ca. 150 Wörter pro Agent.
9. Keine Mehrheitsabstimmung. Code, Tests und konkrete Evidenz entscheiden.

## Modus

Wenn angegeben, nutze `quick`, `standard` oder `deep`. Sonst wähle den kleinsten ausreichenden Modus.

### quick
Für kleine, lokal begrenzte Änderungen.

- Kein Architect, außer die Aufgabe ist überraschend mehrdeutig.
- `repo-explorer` nur wenn relevante Dateien nicht sofort erkennbar sind.
- Ein Writer: Codex, sonst `claude-builder`.
- Danach genau ein `qa-reviewer`.
- Höchstens eine Reparaturrunde.
- Kein Final Judge, solange QA und Checks sauber sind.

### standard
Für normale Features, Bugfixes und Refactorings.

- `repo-explorer` nur wenn Repository-Kontext wirklich gebraucht wird.
- `architect` nur bei mehreren Komponenten, Schnittstellen oder nichttrivialer Entscheidung.
- Ein Writer: Codex, sonst `claude-builder`.
- Immer `qa-reviewer`.
- `regression-hunter` nur bei Kompatibilitäts-, Persistenz-, API-, Lifecycle- oder Migrationsrisiko.
- `security-reviewer` nur bei Auth, Netzwerk, Dateien, Import/Export, Datenbank, Secrets, Berechtigungen oder klarer Security-Relevanz.
- Grok nur wenn verfügbar und die Änderung nicht trivial ist oder ein unabhängiger Gegencheck Mehrwert bringt.
- Höchstens eine Reparaturrunde; zweite nur bei einem konkret verbleibenden HOCH/KRITISCH-Befund.
- Final Judge nur bei offenen Risiken oder widersprüchlichen Reviews.

### deep
Für Architektur, Migrationen, Security, Synchronisation, Datenmodelle und große/riskante Änderungen.

- `repo-explorer` und `architect` verwenden.
- Externe Zweitmeinung vor Implementierung nur wenn wirklich eine Architekturentscheidung mit mehreren plausiblen Wegen besteht.
- Ein Writer: Codex, sonst `claude-builder`.
- Nach Implementierung höchstens zwei gezielte Claude-Reviewer plus Grok, falls verfügbar.
- Maximal zwei Reparaturrunden.
- `final-judge` am Ende verwenden.

## Arbeitsablauf

### 1. Kontext minimieren

Ermittle nur die Dateien und Schnittstellen, die für die Aufgabe nötig sind. Wenn Git vorhanden ist, erfasse knapp `git status` und später den relevanten Diff. Lies keine großen Verzeichnisbäume oder vollständigen Logs ohne Grund.

### 2. Plan nur wenn nötig

Für einfache Aufgaben direkt zum Writer. Für nichttriviale Aufgaben `architect` mit einem kompakten Kontextpaket starten. Der Plan soll nur enthalten:

- Ziel
- betroffene Bereiche
- 3 bis 7 Umsetzungsschritte
- Risiken
- Tests/Akzeptanzkriterien

### 3. Implementieren

Bevorzugt Codex über `codex exec`; wenn Codex fehlt, `claude-builder` einsetzen. Der Writer erhält nur den kompakten Auftrag und darf nicht committen oder pushen.

### 4. Gezielt reviewen

Prüfe den tatsächlichen geänderten Code. Starte nur Reviewer, deren Fachgebiet zum Risiko passt. Übergib ihnen den Auftrag plus relevanten Diff bzw. relevante Dateien, nicht das gesamte Repository.

Grok ist, falls verfügbar und sinnvoll, der unabhängige Breaker. Seine Aufgabe: konkrete Edge Cases und Fehlerpfade finden, nicht eine zweite Komplettimplementierung schreiben.

Befunde nur als `KRITISCH`, `HOCH`, `MITTEL`, `NIEDRIG` melden. Niedrige Stilfragen lösen keine Reparaturrunde aus.

### 5. Reparieren und verifizieren

Berechtigte Befunde zu einem einzigen kurzen Reparaturauftrag bündeln. Danach nur die betroffenen Checks/Reviewer erneut ausführen, nicht die komplette Pipeline wiederholen.

Führe passende vorhandene Tests, Linter und Builds aus. Keine erfundenen Ergebnisse.

### 6. Abschluss

Maximal folgende Punkte ausgeben:

- Modus und verwendeter Writer
- fehlende optionale Abhängigkeiten/Fallbacks
- geänderte Dateien
- wesentliche Umsetzung
- relevante Review-Befunde
- Tests/Builds
- Status: `READY`, `NOT READY` oder `HUMAN DECISION REQUIRED`

Merge niemals selbstständig.
