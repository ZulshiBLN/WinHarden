# WinHarden – CLAUDE.md

PowerShell Automation & Operations Toolkit für Windows Server-Administration.

---

## Projekt-Kontext

**Version:** v1.12.0  
**Status:** [OK] Infrastruktur-Phase COMPLETE (10 ADRs accepted) – Implementation COMPLETE - Production Ready  
**Sprache:** PowerShell 5.1 (Windows)  
**Ziel:** Sichere, performante, tokensparende Zusammenarbeit mit Claude

**Wichtige Dokumente:**
- [RULES] **[STRUCTURE.md](STRUCTURE.md)** – Konkrete Implementierungs-Regeln (HOW)
- [ADR] **[DECISIONS.md](DECISIONS.md)** – Architektur-Entscheidungen & Begründungen (WHY)
- [COLLAB] **[CLAUDE.md](CLAUDE.md)** (dieses Dokument) – Collaboration Rules & Best Practices

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

**Regel 1.4 - Invoke-Expression VERMEIDEN (Security)**
- **NIEMALS `Invoke-Expression` nutzen** (Security-Risiko, PSAvoidUsingInvokeExpression)
- Grund: Injection-Anfälligkeit, Debugging-Probleme, Performance-Overhead
- **Alternativen:**
  * `&` Call-Operator für Native Commands: `& schtasks /create /tn "task" ...`
  * `.NET APIs` wenn verfügbar (statt String-Evaluation)
  * Explizite Parameter (nie String-Konstruktion für Code)
  * `Invoke-Command` mit `-ScriptBlock` (wenn remote nötig, nicht mit user input)
- **Dokumentierte Exceptions:** Invoke-Expression kann in Spezialfällen verwendet werden (siehe PSScriptAnalyzerSettings.psd1)
  * Exception nur wenn Code aus **trusted, statischen Quellen** kommt (.psd1 Profile-Dateien)
  * NICHT bei User-Input oder dynamisch generiertem Code
  * Alle Exceptions müssen in PSScriptAnalyzerSettings.psd1 dokumentiert werden mit Grund
  * Beispiel: Test-HardeningCompliance.ps1 lädt Verify-Commands aus .psd1 Profilen (trusted static data)
- **Konsequenz:** Alle Invoke-Expression Aufrufe ohne Exception führen zu PSScriptAnalyzer-Fehler
- **Siehe auch:** STRUCTURE.md Regel 9.9 (Sichere Command-Ausführung)

**Regel 1.5 - Dokumentation von Public vs Private Funktionen (STRUCTURE.md Regel 3.1)**
- **PUBLIC Funktionen** (keine `_` prefix): Vollständige Comment-based Help erforderlich
  - `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`, `.NOTES`
  - PSScriptAnalyzer Enforcement: `PSProvideCommentHelp` (Fehler, nicht Warnung)
  - `Get-Help Funktion-Name` muss vollständig dokumentiert sein
- **PRIVATE Funktionen** (mit `_` prefix): Minimal-Help erforderlich
  - Mindestens `.SYNOPSIS` (1-2 Zeilen) ODER aussagekräftige Inline-Kommentare
  - Grund: Private Funktionen sind interne Helpers, nicht public API
  - PSScriptAnalyzer Enforcement: Nicht erzwungen (ExportedOnly = true in Settings)
- **Grund:** Public API braucht vollständige Dokumentation; private Helpers können lean sein
- **Siehe auch:** STRUCTURE.md Regel 3.1 (detaillierte Anforderungen)

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

**Regel 3.1a - ASCII-only Output Strings (ADR-010)**
- Alle Output-Strings verwenden **AUSSCHLIESSLICH ASCII-Zeichen**
- NICHT verwenden: Unicode Symbole (°, ✓, ✗, •, █, ░, →, ←, ⏳) und Emoji (✅❌⚠️📋)
- NICHT verwenden: Box-Drawing Zeichen (╔═╝║╚)
- STATTDESSEN: C (statt °C), [OK]/[ERROR]/[WARN]/[INFO], *, -, #, >, <, [WAIT], etc.
- **Grund:** PowerShell 5.1 + Windows UTF-8 Encoding erzeugt Ausgabe-Korruption
- **Gilt für:** Alle Output-Strings, Logs, User-Messages, Script-Ausgaben, Test-Skripte
- **Siehe auch:** ADR-010 (Output-Handling), STRUCTURE.md Regel 7.8-7.10

**Regel 3.1b - Richtige Output-Cmdlets nutzen (ADR-010)**
- `Write-Output` verwenden für normale Ausgaben (kann gepipet, umgeleitet werden)
- `Write-Verbose` für Debug-Info (gesteuert via `-Verbose` Flag)
- `Write-Error` nur für echte Fehler (setzt `$?` zu `$false`)
- **`Write-Host` VERMEIDEN** (funktioniert nicht in Remote-Sessions, Task Scheduler, nicht weiterleitbar)
- `Write-Log` für persistente Audit-Logs (zentrale Logging-Funktion)
- **Grund:** Write-Host ist PowerShell-Antipattern (funktioniert nicht überall)
- **Keine `-ForegroundColor`** in Production Scripts (funktioniert nicht in Automation)

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

## Arbeitsregeln für WinHarden

### Context-Management für Claude-Sessions

**Regel 5.1 - Build & Compile Check vor jedem Commit**
- **Automatisch via Pre-Commit Hook:** PSScriptAnalyzer läuft bei jedem `git commit` automatisch
  - Hook blockiert Commits mit Linting-Fehlern
  - Fehler müssen vor Commit behoben werden
  - Bypass (nur im Notfall): `git commit --no-verify` (nicht empfohlen)
- **Manuell:** `.\build.ps1 -Validate` (4-Raum Indentation, K&R Bracing, Whitespace, BOM)
- Bei Erfolg: Commit wird erstellt. Bei Fehler: Hook blockiert, Fehlerliste angezeigt → Fixen → Retry.

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

## Git-Workflow: Three-Tier Release Model

### Repository Remotes

| Remote | System | Rolle |
|--------|--------|-------|
| `origin` | Azure DevOps | Primary (Hauptsystem) |
| `github` | GitHub | Secondary (Public Backup & Mirror) |

**Synk-Strategie:** Alle Branches und Tags werden zu **BEIDEN Systemen** gepusht (Redundanz + Public Spiegelung).

### Branch-Struktur (Three-Tier Model)

```
develop (Aktive Entwicklung)
    ↓
prerelease (Testing/Beta)
    ↓
main (Stable Production)
```

| Branch | Typ | Zweck | Commits | Releases |
|--------|-----|-------|---------|----------|
| `develop` | Integration | Aktive Entwicklung | Täglich | Keine |
| `prerelease` | Testing | Pre-Release/Beta Testing | Bugfixes | v1.x.x-beta.* |
| `main` | Production | Stable Releases | Merges nur | v1.x.x |

### Entwicklungs-Zyklus

#### Phase 1: Development (develop branch)

Täglich arbeiten auf `develop`:

```powershell
git checkout develop
git add <Dateien>
git commit -m "<Typ>: <Beschreibung>"
git push origin develop
git push github develop
```

**Commit-Typen:**
- `Feature:` Neue Funktionen, Module, Cmdlets
- `Fix:` Bugfixes
- `Refactor:` Struktur-Änderungen
- `Docs:` Dokumentation, Kommentare
- `Test:` Tests, Test-Fixtures

**Regel:** Beliebig viele Commits, keine Rücksicht auf Stabilität erforderlich.

#### Phase 2: Pre-Release (prerelease branch)

Nach Feature-Completion → Testing-Phase:

```powershell
# 1. Merge develop in prerelease
git checkout prerelease
git merge develop
git push origin prerelease && git push github prerelease

# 2. Update Version
# WinHarden.psd1: ModuleVersion = '1.12.0'
# CLAUDE.md: Version = v1.12.0
# README.md: Version + Release notes

git add WinHarden.psd1 CLAUDE.md README.md
git commit -m "Release: v1.12.0-beta.1 - Version bump"
git push origin prerelease && git push github prerelease

# 3. Beta-Tag erstellen
git tag -a v1.12.0-beta.1 -m "Release: v1.12.0-beta.1 - Description of features

## What's New
- Feature: Description
- Fix: Description

## Testing Focus
- Test area 1
- Test area 2"

git push origin v1.12.0-beta.1 && git push github v1.12.0-beta.1
```

**GitHub Release Automation:**
- Release erstellt (Pre-release Checkbox aktiviert)
- ZIP-Download verfügbar
- **NICHT** zu PowerShell Gallery published

**Regel:** Bugfixes direkt auf prerelease, danach rebase develop von prerelease.

#### Phase 3: Stable Release (main branch)

Nach bestandenem Testing → Stable:

```powershell
# 1. Merge prerelease in main
git checkout main
git merge prerelease
git push origin main && git push github main

# 2. Stable-Tag erstellen
git tag -a v1.12.0 -m "Release: v1.12.0 - Full Release Notes

## What's New
- Feature: Description
- Fix: Critical bug in X

## Installation
Install-Module -Name WinHarden -RequiredVersion 1.12.0

## Compatibility
- Windows Server 2019, 2022, 2025
- PowerShell 5.1, 7.x"

git push origin v1.12.0 && git push github v1.12.0
```

**Automation:**
- GitHub Release erstellt (Final Release)
- ZIP-Download verfügbar
- **Automatisch** zu PowerShell Gallery published (~4-5 Min)

### Versionierung (Semantic Versioning)

```
MAJOR.MINOR.PATCH
1.12.0
│ │   │
│ │   └─ PATCH (Bugfixes): v1.12.0 → v1.12.1
│ └───── MINOR (Features): v1.12.0 → v1.13.0
└─────── MAJOR (Breaking): v1.x → v2.0.0
```

**Pre-Release Versionen:**
- `v1.12.0-beta.1`, `v1.12.0-beta.2` - Beta
- `v1.12.0-rc.1` - Release Candidate (optional)
- `v1.12.0` - Final Stable

### Tag-Format & Annotations

**Alle Tags müssen annotiert sein** (mit `-a` Flag):

```powershell
# ✅ RICHTIG
git tag -a v1.12.0 -m "Release: v1.12.0 - Description"

# ❌ FALSCH
git tag v1.12.0
```

### Merge-Richtung

```
develop → prerelease → main (nur forward)
```

**Regeln:**
- ✅ develop → prerelease
- ✅ prerelease → main
- ✅ Bugfixes in prerelease, rebase develop
- ❌ Nie von main zurück mergen

---

## Dokumentation & Referenzen

**Architektur-Entscheidungen (WHY):**
- Siehe [DECISIONS.md](DECISIONS.md) für alle 10 ADRs (Kontext, Gründe, Alternativen)

**Implementierungs-Regeln (HOW):**
- Siehe [STRUCTURE.md](STRUCTURE.md) für alle 12 Regel-Blöcke (Regeln 1.1-12.8)

**Arbeitsstand & Tracking:**
- Siehe [FUNCTION-STATUS.md](functions/FUNCTION-STATUS.md) für aktuellen Status der Funktionen
