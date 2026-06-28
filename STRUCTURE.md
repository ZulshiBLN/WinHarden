# WinHarden – STRUCTURE.md

Projekt-spezifische Struktur- und Organisationsregeln für WinHarden.

---

## 1. VERZEICHNIS-STRUKTUR

- **Regel 1.1:** Funktionen → `functions/`
- **Regel 1.2:** Scripts → `scripts/`
- **Regel 1.3:** Tests → `tests/` (pro Funktion eine Test-Funktion)

---

## 2. DESIGN-PRINZIPIEN

- **Regel 2.1:** Scripts müssen modular aus Funktionen aufgebaut sein
- **Regel 2.2:** Funktionen müssen allgemeingültig & wiederverwendbar sein (high reuse value)

---

## 3. FUNKTIONS-ANFORDERUNGEN

Performance-optimiert, dokumentiert, robust:

- **Regel 3.1:** Comment-based Help für alle Funktionen (PUBLIC vs PRIVATE unterschiedlich)
  - **PUBLIC Funktionen (keine `_` prefix):** Vollständige Help erforderlich
    - `.SYNOPSIS` (Zusammenfassung, 1-2 Zeilen)
    - `.DESCRIPTION` (Detaillierte Erklärung)
    - `.PARAMETER` (Für jeden Parameter)
    - `.EXAMPLE` (Mindestens 1 Anwendungsbeispiel)
    - `.NOTES` (Dependencies, Requirements, etc.)
    - **Enforcement:** PSScriptAnalyzer Regel `PSProvideCommentHelp` mit `ExportedOnly = true`
  
  - **PRIVATE Funktionen (mit `_` prefix):** Minimal-Help erforderlich
    - `.SYNOPSIS` (Zusammenfassung, 1-2 Zeilen)
    - `.NOTES` (Optional, für komplexe Helper)
    - Alternativ: Aussagekräftige Inline-Kommentare `# ...` wenn Funktion selbsterklärend
    - **Grund:** Private Funktionen sind interne Helpers (keine public API)
    - **Enforcement:** PSScriptAnalyzer wird nicht auf private Funktionen angewendet
  
  - **Beispiel [OK] PUBLIC:**
    ```powershell
    function Is-SystemHealthy {
        <#
        .SYNOPSIS
        Checks if system health status is good.
        
        .DESCRIPTION
        Tests CPU, memory, and disk health...
        
        .PARAMETER ComputerName
        Target computer name.
        
        .EXAMPLE
        Is-SystemHealthy -ComputerName SERVER01
        
        .NOTES
        DEPENDENCIES: Get-SystemMetrics
        #>
        ...
    }
    ```
  
  - **Beispiel [OK] PRIVATE:**
    ```powershell
    function _CalculateHealthScore {
        <#
        .SYNOPSIS
        Internal helper: Calculates health score from metrics.
        #>
        ...
    }
    ```

- **Regel 3.2:** `-WhatIf` Option in jeder Funktion
- **Regel 3.3:** Performance-optimiert (keine unnötigen Loops, effiziente Algorithmen)

---

## 4. TESTING (Pester 5.x)

Siehe **[ADR-003](DECISIONS.md)** für vollständigen Kontext.

- **Regel 4.1:** Pro Funktion muss eine Test-Datei unter `tests/` existieren: `<FunctionName>.Tests.ps1`
- **Regel 4.2:** Pester 5.x (mindestens 5.0+)
- **Regel 4.3:** Code Coverage Minimum: **95%** (via `Invoke-Pester -CodeCoverage`)
  - Exceptions nur mit explizitem Kommentar: `# Code Coverage Exception: [Reason]`
  - Beispiel: `# Code Coverage Exception: Cannot mock Windows Registry access`
  - Alle Exceptions müssen in Test-Datei dokumentiert sein (Comment oberhalb des Skips)
- **Regel 4.4:** Nutze **Pester `Mock`** für externe Dependencies (APIs, Dateisystem, Registry)
- **Regel 4.5:** Assertion Style: Standard Pester Assertions (`Should -Be`, `Should -Throw`, `Should -Match`, etc.)
- **Regel 4.6:** Test-Data: Nutze **Fixtures** in `tests/fixtures/` (JSON, CSV, oder PowerShell-Objekte)
- **Regel 4.7:** Test-Struktur: `Describe` → `Context` → `It` (aussagekräftige Namen)
- **Regel 4.8:** Test-Runner: Lokal PowerShell via `Invoke-Pester` (in `build.ps1`)

---

## 5. DOKUMENTATION

- **Regel 5.1:** `functions/FUNCTION-STATUS.md` dokumentiert aktuellen Arbeitsstand und Modul-Informationen

---

## 6. POWERSHELL-VERSION & COMPATIBILITY

Siehe **[ADR-002](DECISIONS.md)** für vollständigen Kontext.

- **Regel 6.1:** Minimum PowerShell 5.1, Dual-Support für 5.1 und 7.x
- **Regel 6.2:** Moderne Cmdlets nutzen (Get-Process statt ps, Get-Item statt dir)
- **Regel 6.3:** PowerShell-7-Features nur mit Runtime-Check: `if ($PSVersionTable.PSVersion.Major -ge 7) { ... }`
- **Regel 6.4:** Keine Breaking Changes zwischen 5.1 und 7.x (5.1-kompatible Syntax default)
- **Regel 6.5:** Windows-only Code (keine cross-plattform Umschreibungen)

---

## 7. CODE STYLE & LINTING

Siehe **[ADR-006](DECISIONS.md)** für Formatierung und **[ADR-010](DECISIONS.md)** für Output-Handling.

- **Regel 7.1:** PSScriptAnalyzer mit PSGallery-Standard Ruleset verwenden
- **Regel 7.2:** Linting-Check vor jedem Commit (via `build.ps1`)

- **Regel 7.3:** Konsistente 4-Space Indentation (PSUseConsistentIndentation)
  - **Indentation:** Exakt 4 Spaces pro Ebene (keine Tabs)
  - **Spaces nicht Tabs:** Alle Dateien müssen Spaces verwenden
  - **Konsistenz:** Alle Zeilen in einem Block müssen gleich eingerückt sein
  - **Pipeline:** Piped Befehle erhöhen Indentation um 4 Spaces
  - **Enforcement:** PSScriptAnalyzer Regel `PSUseConsistentIndentation` ENABLED (Fehler, nicht Warnung)
  - **Auto-Fix:** `Invoke-Formatter` repariert automatisch bei `build.ps1`
  - **IDE-Unterstützung:** `.editorconfig` und `PSScriptAnalyzerSettings.psd1` konfigurieren automatische Formatierung
  - **Beispiel [OK]:**
    ```powershell
    foreach ($item in $items) {
        if ($item.Valid) {
            Write-Output $item
        }
    }
    ```
  - **Beispiel [FAIL]:**
    ```powershell
    foreach ($item in $items) {
      if ($item.Valid) {  # 2 Spaces statt 4 = FEHLER
          Write-Output $item
      }
    }
    ```

- **Regel 7.4:** K&R Bracing Style (vollständig)
  - Öffnende `{` auf gleicher Zeile: `if ($x) {`
  - Schließende `}` auf eigener Zeile, dedented
  - Beispiel:
    ```powershell
    if ($condition) {
        Write-Output "Code"
    }
    ```
  - Exception: Einzeilige Konstrukte dürfen `{ }` zusammen haben (z.B. Hashtabellen)
  - PSScriptAnalyzer Rules: `PSPlaceOpenBrace` + `PSPlaceCloseBrace` beide ENABLED

- **Regel 7.5:** Line Length optimiert auf Lesbarkeit (~100-120 Zeichen anstreben, aber nicht strikte Limit)
- **Regel 7.6:** Format-Exceptions erlaubt mit `# PSScriptAnalyzer ignore [rule]` Kommentar

- **Regel 7.7:** PSScriptAnalyzer Konfiguration (PSScriptAnalyzerSettings.psd1)
  - **Datei:** `PSScriptAnalyzerSettings.psd1` im Root-Verzeichnis
  - **Konfiguriert:** Indentation, Bracing, Security, Naming, Output Regeln
  - **Enforcement:** PSUseConsistentIndentation, PSPlaceOpenBrace, PSPlaceCloseBrace
  - **Auto-Format:** VS Code, Visual Studio, PowerShell ISE laden diese Einstellungen automatisch
  - **Build-Integration:** `build.ps1` nutzt diese Konfiguration für PSScriptAnalyzer Checks

- **Regel 7.8:** EditorConfig für Cross-IDE Formatierung (.editorconfig)
  - **Datei:** `.editorconfig` im Root-Verzeichnis
  - **Konfiguriert:** 4-Space Indentation für PowerShell, UTF-8 Encoding, Line Endings (CRLF)
  - **Auto-Formatierung:** VS Code, Visual Studio, JetBrains IDEs formatieren automatisch beim Speichern
  - **Portable:** Funktioniert unabhängig von IDE-Einstellungen

**Output & Logging Conventions (ADR-010):**
- **Regel 7.9:** Output-Cmdlets korrekt nutzen
  - `Write-Output` für normale Ausgaben (Standard, kann gepipet werden)
  - `Write-Verbose` für Debug-Info (gesteuert via `-Verbose`)
  - `Write-Error` nur für echte Fehler (setzt `$?` = `$false`)
  - `Write-Host` VERMEIDEN (funktioniert nicht in Remote-Sessions, nicht weiterleitbar)
  - `Write-Log` für persistente Audit-Logs (zentrale Logging-Funktion)

- **Regel 7.10:** ASCII-only Output Strings (KEINE Unicode-Zeichen)
  - Box-Drawing VERMEIDEN: `╔═╝║╚` → Verwende `=`, `-`, `|` stattdessen
  - Emoji-Symbole VERMEIDEN: `✅❌⚠️📋` → Verwende ASCII-Tags: `[OK]`, `[ERROR]`, `[WARN]`, `[INFO]`
  - Grund: PowerShell 5.1 + Windows UTF-8 Encoding erzeugt Ausgabe-Korruption
  - Auch in Logs konsistent halten

- **Regel 7.11:** Keine `-ForegroundColor` in Production Scripts
  - Farbausgabe funktioniert nicht in Task Scheduler / CI/CD / Remote-Sessions
  - Alternative: Strukturierte ASCII-Präfixe `[OK]`, `[ERROR]`, `[WARN]` verwenden
  - Ausnahme: Nur in interaktiven IDE-Scripts mit Kommentar `# Interactive-only`

---

## 8. NAMING CONVENTIONS

Siehe **[ADR-007](DECISIONS.md)** für vollständigen Kontext.

- **Regel 8.1:** Funktions-Präfixe: PowerShell Approved Verbs (Get, Set, Test, New, Remove, Add, Clear, etc.)
  - **Exception:** Boolean-Funktionen verwenden `Is`-Prefix statt Approved Verb (siehe Regel 8.7, ADR-007)
  - **Grund:** 'Is' ist semantisch korrekter für Zustandsabfragen als Test-Verben
    (z.B. 'Is-SystemHealthy' vs. 'Test-SystemHealth' — ersteres ist idiomatischer)
  - **PSScriptAnalyzer:** Diese Exception ist in PSScriptAnalyzerSettings.psd1 dokumentiert und wird nicht als Fehler gemeldet
- **Regel 8.2:** Funktions-Format: `Verb-Noun` (z.B. `Get-SystemInfo`)
- **Regel 8.3:** Private Funktionen: Prefix `_` (z.B. `_PrivateHelper`)
- **Regel 8.4:** Parameter-Namen: PascalCase (z.B. `$ComputerName`)
- **Regel 8.5:** Parameter-Plural: Plural (`$Servers`) wenn mehrere Werte, Singular (`$Server`) wenn ein Wert
- **Regel 8.6:** Variablen-Namen: camelCase (z.B. `$systemInfo`, `$isHealthy`)
- **Regel 8.7:** Boolean-Funktionen: Prefix `Is` (z.B. `Is-SystemHealthy`)
- **Regel 8.8:** Datei-Namen: Funktions-Name == Datei-Name (z.B. `Get-SystemInfo.ps1`)

---

## 9. ERROR HANDLING

Siehe **[ADR-004](DECISIONS.md)** für vollständigen Kontext.

- **Regel 9.1:** Try-Catch nur wo nötig (externe Ressourcen, bekannte Fehlerquellen)
- **Regel 9.2:** Terminating Errors: `throw` Exception (stoppt sofort)
- **Regel 9.3:** Non-Terminating Errors: `Write-Error` (setzt ErrorActionPreference)
- **Regel 9.4:** ErrorActionPreference: Default `Stop` (Fehler sind terminating)
- **Regel 9.5:** Alle Errors werden **automatisch geloggt** (zentrale Logging-Funktion, siehe ADR-005)
- **Regel 9.6:** Parameter Validation: Nutze `[ValidateNotNullOrEmpty()]`, `[ValidateSet(...)]`, etc.
- **Regel 9.7:** WhatIf & Confirm: Fehlerbehandlung läuft gleich wie normalem Run
- **Regel 9.8:** Script Exit-Codes: 0=OK, 1=General Error, 2=Cmdlet Error, 3+=Custom

**Sichere Command-Ausführung (Security - CLAUDE.md Regel 1.4):**
- **Regel 9.9:** `Invoke-Expression` VERMEIDEN (PSAvoidUsingInvokeExpression)
  - **NIEMALS** dynamischen Code ausführen mit `Invoke-Expression`
  - **Grund:** Injection-Risiko (Command Injection), Debugging-Schwierigkeiten, Performance-Overhead
  - **Alternativen:**
    * `&` Call-Operator für Native Commands: `& schtasks /create /tn "task" /tr "script.ps1"`
    * `.NET APIs` wenn verfügbar (z.B. `System.Diagnostics.Process` statt cmd-Strings)
    * Explizite Parameter (keine String-Konstruktion für Code)
    * `Invoke-Command -ScriptBlock` nur mit vertrautem, nicht-benutzer-generiertem Code
  - **Beispiel [OK]:** `& schtasks /create /tn $taskPath /tr $command /sc $schedule`
  - **Beispiel [FAIL]:** `Invoke-Expression "schtasks /create /tn $taskPath /tr $command"`
  - **PSScriptAnalyzer:** Fehler (nicht Warnung) - muss beseitigt sein vor Commit

---

## 10. LOGGING STRATEGY

Siehe **[ADR-005](DECISIONS.md)** für vollständigen Kontext.

- **Regel 10.1:** Logging-Ziel: Datei `$PSScriptRoot\logs\log_YYYY-MM-DD.csv` (tägliche Rotation)
- **Regel 10.2:** Log-Format: CSV mit Spalten: Timestamp, Level, Caller, Function, LineNumber, Message
- **Regel 10.3:** Log-Levels: Error, Warning, Info, Debug, Verbose (Hierarchie in dieser Reihenfolge)
- **Regel 10.4:** Zentrale Logging-Funktion: `Write-Log` -Message, -Level, -Caller
- **Regel 10.5:** Sensitive Data Maskieren: `*password*`, `*token*`, `*secret*`, `*apikey*`, `*credential*` → `***`
- **Regel 10.6:** Caller Info: Funktions-Name, Zeilen-Nummer (aus CallStack)
- **Regel 10.7:** Log-Level-Kontrolle: `$env:LOG_LEVEL` oder `-Verbose`/`-Debug` Flags
- **Regel 10.8:** Retention: Automatisch löschen nach 7 Tagen (via `Clean-OldLogs`)

---

## 11. MODUL-IMPORT-STRATEGIE

Siehe **[ADR-008](DECISIONS.md)** für vollständigen Kontext.

- **Regel 11.1:** Getrennte Module (nicht alles in 1 .psm1):
  - **Implementiert:** `Core.psm1`, `System.psm1`
  - **Geplant (Phase 2+, siehe ADR-008):** `User.psm1`, `Maintenance.psm1`
- **Regel 11.2:** Core-Modul ist **Basis für alles** (Write-Log, Error-Helpers, Validatoren, Masking)
- **Regel 11.3:** Core-Modul IMMER laden (erste Zeile in Scripts)
- **Regel 11.4:** Zusätzliche Module on-demand laden (nur wenn nötig)
- **Regel 11.5:** Import-Reihenfolge: Core → System → User → Maintenance (abhängigkeiten beachten)
- **Regel 11.6:** Alle Funktionen in **Global Scope** (nach Import)
- **Regel 11.7:** Private Helper-Funktionen: Prefix `_` (z.B. `_ValidateServerName`)
- **Regel 11.8:** Load-Performance: On-Startup nur Core, dann optional andere Module

---

## 12. DEPENDENCY MANAGEMENT

Siehe **[ADR-009](DECISIONS.md)** für vollständigen Kontext.

- **Regel 12.1:** Linear Dependency Hierarchy: Core → System → User → Maintenance (keine Rückwärts-Dependencies)
- **Regel 12.2:** Modul N darf nur Modul M aufrufen wenn M < N in Hierarchie
- **Regel 12.3:** Inter-Module Dependencies explizit dokumentieren (Kommentar: `# DEPENDS ON: ...`)
- **Regel 12.4:** Test-Mocking für alle Inter-Modul-Aufrufe (ADR-003)
- **Regel 12.5:** External Dependencies optional deklarieren (Kommentar: `# REQUIRES (optional): ...`)
- **Regel 12.6:** Graceful Degradation für externe Abhängigkeiten:
  - Wenn externes PowerShell-Modul fehlt: Loggen + `Write-Error` + `return` gracefully (NICHT `throw`)
  - `Write-Error` ist non-terminating (setzt $? zu $false, aber Ausführung läuft weiter)
  - `throw` ist terminating (stoppt sofort) — NICHT für externe Dependencies nutzen
  - Beispiel: Wenn ActiveDirectory-Modul fehlt, loggen und return, Script läuft mit Einschränkungen
- **Regel 12.7:** PowerShell-Version Constraint: Minimum 5.1, Runtime-Checks für 7.x Features (ADR-002)
- **Regel 12.8:** Optional: `Test-WinHardenDependencies` Helper-Funktion in Core (nicht blocking)

---

## Verzeichnis-Übersicht

```
WinHarden/
├── functions/              # Wiederverwendbare PowerShell-Funktionen (Source)
│   ├── FUNCTION-STATUS.md  # Arbeitsstand und Modul-Info (von Hand gepflegt)
│   ├── Core/
│   ├── System/
│   ├── User/
│   └── Maintenance/
├── modules/                # Geladene PowerShell-Module (exports)
│   ├── Core.psm1           # [IMPLEMENTED] Zentrale Basis-Funktionen (IMMER laden)
│   ├── System.psm1         # [IMPLEMENTED] System-Admin Funktionen (optional)
│   ├── User.psm1           # [PLANNED] User/Group Management (Phase 2+, siehe ADR-008)
│   └── Maintenance.psm1    # [PLANNED] Updates, Cleanup, Monitoring (Phase 2+, siehe ADR-008)
├── scripts/                # Hauptscripte (modular aus modules aufgebaut)
├── tests/                  # Test-Funktionen (pro function/ eine entsprechende)
│   └── fixtures/           # Test-Daten (JSON, CSV, PowerShell-Objekte)
├── logs/                   # Runtime Logs (CSV, täglich rotiert, 7-Tage Retention)
├── build.ps1               # Build-Script (PSScriptAnalyzer, Pester, Coverage-Check)
├── CLAUDE.md               # Collaboration Rules & Best Practices
├── DECISIONS.md            # Architectural Decision Records (ADRs)
└── STRUCTURE.md            # Diese Datei (Regeln)
```

---

## Status: Infrastruktur-Phase [OK] COMPLETE

Alle 10 ADRs sind dokumentiert und akzeptiert:

- [OK] **ADR-001:** Modulare PowerShell-Architektur mit Funktionen & Scripts
- [OK] **ADR-002:** PowerShell-Version (5.1 vs. 7.x compatibility)
- [OK] **ADR-003:** Testing Framework (Pester 5.x, 95% Coverage)
- [OK] **ADR-004:** Error Handling Convention
- [OK] **ADR-005:** Logging Strategy (CSV-basiert, 7-Tage Retention)
- [OK] **ADR-006:** Code Style & PSScriptAnalyzer Rules (K&R, 4-Space)
- [OK] **ADR-007:** Naming Conventions (Approved Verbs, camelCase)
- [OK] **ADR-008:** Modul-Import-Strategie (Core-Modul + Optional)
- [OK] **ADR-009:** Dependency Management (Linear Hierarchy, Graceful Degradation)
- [OK] **ADR-010:** Output-Handling & Logging-Konventionen (ASCII-only, Write-* Korrektheit)

**Status:** ✅ PRODUCTION READY - v1.1 Release
**Phase:** Implementation COMPLETE | All systems operational
