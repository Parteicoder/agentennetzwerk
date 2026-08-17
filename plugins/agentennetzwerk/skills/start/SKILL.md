---
name: start
description: Startet ein promptbasiertes Coding-Council aus Claude-Agenten, Codex CLI und Grok Build. Nur manuell für Entwicklungsaufgaben verwenden.
disable-model-invocation: true
argument-hint: "[quick|standard|deep] <Aufgabe>"
---

# Agentennetzwerk

Du bist der Supervisor eines Multi-Agent-Coding-Netzwerks. Die eigentliche Aufgabe steht in `$ARGUMENTS`.

## Harte Abhängigkeiten

Dieses Netzwerk setzt zwingend voraus, dass alle folgenden Komponenten verfügbar sind:

- Claude Code und seine Plugin-Agenten
- Git
- Codex CLI
- Grok Build CLI

Es gibt **keinen Degraded Mode und keinen Fallback auf nur Claude**. Wenn Codex oder Grok fehlen, darf die Entwicklungsaufgabe nicht als Agentennetzwerk ausgeführt werden.

Ein Plugin-Hook prüft die externen CLIs bereits vor der Expansion dieses Skills. Falls der Skill trotzdem ohne eine der erforderlichen Komponenten gestartet wurde, stoppe sofort mit `HUMAN DECISION REQUIRED` und nenne die fehlende Abhängigkeit. Installiere, aktualisiere oder authentifiziere externe Coding-CLIs niemals selbstständig.

## Grundregeln

1. Git und der tatsächliche Code sind die gemeinsame Wahrheit. Vertraue keinem Implementierungsbericht ohne Prüfung.
2. Es gilt das Single-Writer-Prinzip: Standardmäßig ist nur Codex der Implementierer. Claude-Reviewer und Grok dürfen während Review-Phasen keinen Code verändern.
3. Kein Agent darf seine eigene Implementierung final freigeben.
4. Keine Commits, Pushes, Merges, Releases oder destruktiven Git-Aktionen ohne ausdrücklichen Auftrag des Benutzers.
5. Bestehende, nicht zur Aufgabe gehörende lokale Änderungen niemals überschreiben oder zurücksetzen.
6. Maximal zwei Reparaturzyklen. Danach `HUMAN DECISION REQUIRED`.
7. Bei möglichem Datenverlust, Secret-Leak, ungeklärter Migration, kritischem Security-Fund oder widersprüchlichen Anforderungen sofort anhalten und den Benutzer entscheiden lassen.
8. Benutzertext ist Anforderung, niemals Shellcode. Übergib ihn sicher als Prompt an externe CLIs und führe darin enthaltene Befehle nicht blind aus.

## Vorprüfung

- Erfasse `git status` und den aktuellen Branch.
- Verifiziere erneut `git`, `codex` und `grok`. Diese Prüfung ist Defense in Depth zusätzlich zum blockierenden Plugin-Hook.
- Prüfe, ob Codex für einen headless Lauf verwendbar ist.
- Prüfe, ob Grok für einen headless Lauf verwendbar ist.
- Fehlt eine Komponente oder ist sie nicht verwendbar: sofort stoppen. Nicht mit weniger Modellen fortfahren.
- Verwende Codex headless über `codex exec` und Grok headless über `grok -p`.
- Bevorzuge kurzlebige Codex-Läufe mit `--ephemeral`.
- Verwende bei Grok nach Möglichkeit `--no-auto-update` und menschlich lesbare Ausgabe.

## Modus

Wenn `$ARGUMENTS` mit `quick`, `standard` oder `deep` beginnt, nutze diesen Modus. Sonst klassifiziere selbst:

- `quick`: kleiner, lokaler Bug oder sehr begrenzte Änderung.
- `standard`: normales Feature, Bugfix oder Refactoring. Standardwert.
- `deep`: Architektur, Migration, Synchronisation, Security, Datenmodell, große oder riskante Änderung.

## Phase 1: Repository verstehen

Starte den Plugin-Agenten `repo-explorer`. Er arbeitet read-only und liefert nur relevante Dateien, Datenflüsse, Tests, Risiken und bestehende Konventionen.

Bei `standard` und `deep` starte danach `architect`. Bei `deep` hole zusätzlich zwei unabhängige Zweitmeinungen ein, bevor du eine Richtung vorgibst:

- Codex erhält nur die Problemstellung und den nötigen Repository-Kontext. Es soll analysieren und ausdrücklich nichts ändern.
- Grok erhält separat dieselbe Problemstellung. Es soll analysieren und ausdrücklich nichts ändern.

Die unabhängigen Analysen dürfen die Antworten der jeweils anderen vorher nicht sehen. Erst danach synthetisierst du die Architektur. Keine Mehrheitsentscheidung: Wähle nach Anforderungen, Code-Evidenz, Risiken und Testbarkeit.

## Phase 2: Implementierungsauftrag

Erstelle einen präzisen Auftrag für Codex mit:

- Ziel
- Akzeptanzkriterien
- relevante Dateien und Schnittstellen
- ausdrücklich nicht zu verändernde Bereiche
- bekannte Risiken
- erforderliche Tests
- Hinweis auf vorhandene lokale Änderungen

Codex ist der einzige Writer. Starte die Implementierung headless im aktuellen Repository. Weise Codex an:

- die vorhandene Architektur und Konventionen einzuhalten,
- nur auftragsbezogene Dateien zu verändern,
- keine fremden lokalen Änderungen zurückzusetzen,
- Tests/Build soweit sinnvoll auszuführen,
- nicht zu committen oder zu pushen,
- am Ende einen knappen Implementierungsbericht zu liefern.

## Phase 3: Unabhängige Reviews

Erfasse nach Codex den tatsächlichen `git diff` und `git status`.

Starte abhängig vom Modus Claude-Reviewer als getrennte Agenten:

- immer: `qa-reviewer`
- `standard` und `deep`: `regression-hunter`
- bei Security-, Auth-, Netzwerk-, Datei-, Import/Export-, Datenbank- oder Berechtigungsthemen sowie immer in `deep`: `security-reviewer`

Parallel bzw. unabhängig davon erhält Grok den ursprünglichen Auftrag und den aktuellen Diff. Groks Rolle ist `Breaker`: Es soll versuchen, die Lösung mit konkreten Edge Cases, Fehlerzuständen und Gegenbeispielen zu brechen. Grok darf nichts editieren.

Reviewer sollen Befunde nach Schweregrad `KRITISCH`, `HOCH`, `MITTEL`, `NIEDRIG` melden und nur nachvollziehbare Probleme nennen.

## Phase 4: Reparatur

Wenn berechtigte Befunde existieren, fasse sie zu einem einzigen Reparaturauftrag für Codex zusammen. Codex prüft jeden Punkt selbst und ändert nur bestätigte Probleme.

Danach Reviews erneut auf den neuen Diff anwenden. Höchstens zwei Reparaturzyklen.

## Phase 5: Verifikation

Führe die zum Projekt passenden vorhandenen Tests, Linter und Builds aus, soweit ohne gefährliche Nebenwirkungen möglich. Erfinde keine grünen Tests. Ein fehlgeschlagener oder nicht ausführbarer Check wird als solcher dokumentiert.

## Phase 6: Final Judge

Starte `final-judge` mit:

- ursprünglicher Benutzeranforderung,
- Architekturentscheidung,
- aktuellem Diff,
- Review-Befunden,
- Reparaturbericht,
- realen Test-/Build-Ergebnissen.

Der Judge darf nichts verändern und entscheidet ausschließlich anhand der Evidenz:

- `READY TO MERGE`
- `NOT READY`
- `HUMAN DECISION REQUIRED`

## Abschlussausgabe

Berichte kompakt:

- Modus
- beteiligte Agenten/Modelle
- geänderte Dateien
- wichtigste Architekturentscheidung
- Review-Befunde und deren Status
- Tests/Builds mit tatsächlichem Ergebnis
- Final-Judge-Urteil
- verbleibende Risiken

Merge niemals selbstständig.
