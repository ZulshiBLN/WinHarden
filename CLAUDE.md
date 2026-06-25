# WinOpsKit – CLAUDE.md

PowerShell Automation & Operations Toolkit für Windows Server-Administration.

---

## Projekt-Kontext

**Status:** [OK] Infrastruktur-Phase COMPLETE (9 ADRs accepted) – Implementation in Progress  
**Sprache:** PowerShell 5.1 (Windows)  
**Ziel:** Sichere, performante, tokensparende Zusammenarbeit mit Claude

**Wichtige Dokumente:**
- 📋 **[STRUCTURE.md](STRUCTURE.md)** – Konkrete Implementierungs-Regeln (HOW)
- ✅ **[DECISIONS.md](DECISIONS.md)** – Architektur-Entscheidungen & Begründungen (WHY)
- 🔧 **[CLAUDE.md](CLAUDE.md)** (dieses Dokument) – Collaboration Rules & Best Practices

➡️ **Lese-Reihenfolge:** DECISIONS.md (Kontext) → STRUCTURE.md (Regeln) → CLAUDE.md (Collaboration)**

---

## Allgemeine Collaboration Rules (Claude Best Practices)

### Sicherheit & Datenhandling

**Regel 1.1 - Zero Data Retention (ZDR)**
- Keine Credentials, Secrets oder sensible Daten in Prompts
- `.env`, `.local`, `secrets.json` grundsätzlich NICHT mit Claude teilen
- Nur Struktur/Patterns zeigen, keine echten Werte
- Bei Sicherheitsreviews: Anonymisierte Beispiele verwenden

**Regel 1.2 - Validierung an Grenzen**
- Externe Eingaben validieren (User-Input, APIs, Config-Files)
- Interne Code-Garantien vertrauen; nicht über-validieren
- OWASP Top 10 im Auge behalten (XSS, Injection, etc.)

**Regel 1.3 - Destructive Operations erfordern Bestätigung**
- Force-Push, Hard-Reset, Permanent Delete → Explizite Genehmigung ERST einholen
- Bei Unsicherheit fragen, nicht silent weitermachen
- Git-Hooks nicht skippen (--no-verify) ohne guten Grund

---

### Token-Effizienz & Context-Management

**Regel 2.1 - Token-bewusste Prompts**
- Relevante Code-Ausschnitte gezielt teilen (nicht ganze Dateien)
- Grep/Glob für Suche nutzen → Read nur spezifische Bereiche
- Large Context Windows (200k+) = Ressource, nicht Freibrief für alles hochladen

**Regel 2.2 - Context Discipline**
- **Progressive Disclosure:** Nur relevante Kontexte pro Request
- **Lookback-Fenster:** Alte Conversation-Turns nicht unnötig re-laden
- **Tool-Strategien:** Spezialisierte Tools (Read/Edit/Grep/Glob) statt Bash
  - Grep für Content-Search statt `grep` Bash-Kommand
  - Glob für Datei-Pattern statt `find` Kommand
  - Edit/Write statt Echo/Sed für File-Ops

**Regel 2.3 - Parallelisierung wo möglich**
- Unabhängige Tool-Calls parallel ausführen (mehrere Read/Grep gleichzeitig)
- Abhängigkeiten auflösen → sequenzielle Ausführung nur wenn nötig

**Regel 2.4 - Agent-Delegation sinnvoll nutzen**
- Agents nur für breite Codebase-Erkundung (Explore, general-purpose)
- Für fokussierte Lookups direkt Tools nutzen (keine Agents nötig)
- Nie mehrfach recherchieren: Agent-Ergebnisse vertrauen

---

### Code-Qualität & Hygiene

**Regel 3.1 - Minimale Kommentare, maximale Klarheit**
- Keine Kommentare für offensichtliches (selbsprechende Namen reichen)
- Nur Kommentare für **WHY**, nicht WHAT
- Beispiel [NO] Falsch: `# Loop durch Array`
- Beispiel [YES] Richtig: `# Skip first N rows due to header offset in legacy format`

**Regel 3.1a - ASCII-only Output Strings (Keine Unicode-Zeichen)**
- Alle Output-Strings verwenden **AUSSCHLIESSLICH ASCII-Zeichen**
- NICHT verwenden: °, ✓, ✗, •, █, ░, →, ←, ⏳, etc.
- STATTDESSEN: C (statt °C), [OK]/[FAIL], *, -, #, >, <, [WAIT], etc.
- **Grund:** PowerShell + Windows + UTF-8 Encoding kombinieren schlecht
- **Gilt für:** Alle Output-Strings, Logs, User-Messages, Test-Skripte

**Regel 3.2 - Keine Über-Abstraktionen**
- YAGNI-Prinzip: Nicht für hypothetische Zukunft bauen
- 3 gleiche Zeilen = noch nicht reif für Abstraktion
- Keine Fallbacks für unmögliche Szenarien

**Regel 3.3 - Keine unnötigen Cleanup-Commits**
- Bugfix = nur Bugfix, keine Umbenennungen im gleichen Commit
- Refactor = nur Struktur-Änderung, keine Features
- Separate Commits für verschiedene Zwecke

---

### Transparente Zusammenarbeit

**Regel 4.1 - Klare Statusupdates**
- State-Änderungen mit kurzen 1-2 Satz-Updates mitteilen
- Nicht über interne Überlegungen berichten, sondern Ergebnisse fokussieren
- Blockers sofort kommunizieren, nicht stumm weitermachen

**Regel 4.2 - Memory-System nutzen**
- Learnings über Zusammenarbeit speichern → zukünftige Sessions nutzen
- User-Profil, Feedback und Projekt-Kontext dokumentieren
- Memories vor Handlungen verifizieren (können veraltet sein)
- Keine Code-Patterns/Architektur in Memory (läßt sich aus Code ableiten)

---

## Arbeitsregeln für WinOpsKit

### Context-Management für Claude-Sessions

**Regel 5.1 - Build & Compile Check vor jedem Commit**
```powershell
.\build.ps1 -Validate  # oder equivalent für PowerShell-Linting
```
Bei Erfolg auf passender Branch committen. Bei Fehler fixen → nochmal committen.

**Regel 5.2 - CLAUDE.md aktuell halten**
Nach Änderungen updaten wenn:
- Neue Module/Komponenten hinzukommen
- Konventionen/Patterns etablieren
- Dependencies/Versionen kritisch ändern
Immer kompakt formulieren.

**Regel 5.3 - Dokumentation vor Code**
Neue Features nach Scope:
1. **Architektur-Entscheidung** (massgebliche Änderung) → ADR in [DECISIONS.md](DECISIONS.md)
2. **Implementierungs-Regel** (konkrete Standard) → Regel in [STRUCTURE.md](STRUCTURE.md)
3. **Collaboration-Update** (Claude-spezifisch) → Anpassung in [CLAUDE.md](CLAUDE.md)
4. **Große Features** → `/plan` starten vor Code

---

### Decision Making & Architecture

**Regel 5.4 - Architektur-Entscheidungen in DECISIONS.md (ADRs)**
Nur Entscheidungen, die das Projekt **massgeblich ändern**, bekommen eine ADR:

**Gehört in DECISIONS.md (massgebliche Entscheidung):**
- [YES] Projekt-Struktur / Architektur (Folder-Layout, Module-Design)
- [YES] Tech-Stack Änderungen (neue Frameworks, Libraries, PowerShell-Version)
- [YES] Prozess-Entscheidungen (Testing-Framework, Versioning, Logging-Strategie)
- [YES] Design-Patterns (Error-Handling Philosophie, große Conventions)

**Gehört in STRUCTURE.md (konkrete Regel):**
- Implementierungs-Standards (Naming, Kommentare, Code-Style)
- Verzeichnis-Layout
- Anforderungen pro Funktion

**Gehört NICHT in ADR (lokale Entscheidungen):**
- Einzelne Function-Namen oder lokale Bugfixes
- Taktische Implementierungen

**Wie ADR schreiben?**
1. Neue ADR in [DECISIONS.md](DECISIONS.md) hinzufügen
2. Status setzen: `[PENDING]`, `[ACCEPTED]`, `[REJECTED]`, `[SUPERSEDED]`
3. Context + Decision + Consequences + Alternatives
4. Im Code referenzieren wenn relevant: `# See ADR-002 for error handling strategy`
5. Auf [STRUCTURE.md](STRUCTURE.md) verweisen für Implementierungs-Details

**Beispiel:**
```markdown
## ADR-002: PowerShell-Version & Compatibility

**Status:** [PENDING]

**Context:** Sollen wir 5.1 oder 7.x unterstützen?...
**Decision:** PowerShell 5.1+ mit optional 7.x...
**Consequences:** (Positiv/Negativ)
```

**Regel 5.5 - Tool-Strategie**
- **Grep → Zeilennummer → Read(offset:N, limit:20)** (nicht whole-file lesen)
- **Edit/Write melden Fehler selbst** (kein Verifikations-Read nötig)
- **Glob für Pattern-Match**, dann Read für Details
- **Bash für Kommandos** (POSIX-Shell über Git Bash), **PowerShell für Windows-spezifisches**

---

### Sicherheit in Development

**Regel 6.1 - Secrets niemals in Code oder Config**
- PowerShell-Secrets über `$env:VAR` oder Credential Manager
- Lokale `.env.local` → `.gitignore` (nie committen!)
- Beispiele nur mit Platzhaltern: `api_key = "<YOUR_API_KEY>"`

**Regel 6.2 - Code Review vor Sicherheits-Commits**
- Alles was Credentials/Permission/Auth berührt → `/code-review` vorher
- Oder direkt `/security-review` für sensitive Änderungen

**Regel 6.3 - PowerShell Execution Policy**
- Lokal: `-ExecutionPolicy RemoteSigned` (entwickler-freundlich)
- Prod/Shared: `-ExecutionPolicy AllSigned` (sicher)
- Scriptblöcke signieren wo erforderlich

---

## Git-Workflow

### Branch-Konvention

| Commit-Typ  | Branch         | Wann                                    |
|-------------|----------------|-----------------------------------------|
| `Feature:`  | `dev/feature`  | Neue Funktionen, Module, Cmdlets        |
| `Fix:`      | `dev/fix`      | Bugfixes                                |
| `Cleanup:`  | `dev/cleanup`  | Unused code, Umbenennungen, Formatierung|
| `Refactor:` | `dev/refactor` | Struktur-Änderungen ohne neues Verhalten|
| `Docs:`     | `dev/docs`     | CLAUDE.md-Updates, Kommentare           |

CLAUDE.md-Updates begleiten Code-Commits auf **gleichem Branch**.

### Auto-Backup nach jeder Änderung

Reihenfolge: **Build → commit → push**

```powershell
git checkout <dev/branch>
git add <Dateien>
git commit -m "<Typ>: <Beschreibung>"
git push origin <dev/branch>
```

### Stable Backup auf `master` (nur auf explizite Aufforderung)

1. Build-Check durchführen
2. Merge-Reihenfolge:
   ```powershell
   git checkout master
   git merge dev/fix
   git merge dev/refactor
   git merge dev/cleanup
   git merge dev/feature
   git merge dev/docs
   git push origin master
   ```
3. `master` zurückmergen in alle `dev/*` (Sync):
   ```powershell
   git checkout dev/feature; git merge master
   git checkout dev/fix; git merge master
   git checkout dev/refactor; git merge master
   git checkout dev/cleanup; git merge master
   git checkout dev/docs; git merge master
   git push origin dev/feature, dev/fix, dev/refactor, dev/cleanup, dev/docs
   ```

**Regel:** Nie eigenständig in `master` mergen – immer auf explizite Aufforderung warten.

---

## Tech-Stack (WinOpsKit)

| Bereich | Technology |
|---------|------------|
| **Sprache** | PowerShell 5.1+ |
| **Shell** | Git Bash (POSIX) / PowerShell |
| **OS** | Windows 11 Pro, Windows Server 2016+ |
| **Umgebung** | VS Code oder PowerShell ISE |

---

## Architektur & Implementierungs-Standards

**Architektur-Entscheidungen (WHY):**
- Siehe [DECISIONS.md](DECISIONS.md) für alle ADRs (Kontext, Gründe, Alternativen)

**Implementierungs-Regeln (HOW):**
- Siehe [STRUCTURE.md](STRUCTURE.md) für alle konkreten Standards (Regeln 1.1-5.1)
- Siehe [STRUCTURE.md Roadmap](STRUCTURE.md#roadmap-fehlende-definitionen) für geplante ADRs

---

## Next Steps für WinOpsKit Implementation

**Phase 1: Infrastruktur & Standards ✅ COMPLETE**
- [✓] Verzeichnisstruktur erstellen (ADR-001)
- [✓] ADR-002: PowerShell-Version & Compatibility
- [✓] ADR-003: Testing Framework (Pester 5.x, 95% Coverage)
- [✓] ADR-004: Error Handling Convention
- [✓] ADR-005: Logging Strategy (CSV, 7-Tage Retention)
- [✓] ADR-006: Code Style & PSScriptAnalyzer Rules
- [✓] ADR-007: Naming Conventions (Approved Verbs, camelCase)
- [✓] ADR-008: Modul-Import-Strategie (Core-Modul + Optional)
- [✓] ADR-009: Dependency Management (Linear Hierarchy)

**Phase 2: Implementation (Code)**
- [ ] build.ps1 erstellen (PSScriptAnalyzer, Pester, Coverage-Check)
- [ ] Core.psm1 schreiben:
  - [ ] Write-Log Funktion (ADR-005)
  - [ ] Error-Handling Helpers (ADR-004)
  - [ ] Validation Helpers (Test-NotNullOrEmpty, etc.)
  - [ ] Sensitive Data Masking (ADR-005)
  - [ ] Test-WinOpsKitDependencies Helper (ADR-009)
- [ ] System.psm1, User.psm1, Maintenance.psm1 (initial)
- [ ] Erste Funktionen mit Tests (95% Coverage via ADR-003)
- [ ] Beispiele & Dokumentation

---

## Memory & Collaboration Hints

[YES] **Kommunikation mit Claude:**
- Ziele & Kontext clear kommunizieren
- Blockers sofort erwähnen
- Explizite Genehmigung für destructive Ops

[YES] **Token-Sparsam arbeiten:**
- Kleine, fokussierte Requests
- Zwischen-Ergebnisse in `.md` Files speichern (nicht in Conversation nachladen)
- Grep/Glob statt große Dateien teilen

[YES] **Sicherheit first:**
- Keine Secrets in Prompts
- Code-Reviews für sensitive Änderungen
- Validation only at boundaries
