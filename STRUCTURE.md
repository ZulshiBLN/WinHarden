# WinOpsKit – STRUCTURE.md

Projekt-spezifische Struktur- und Organisationsregeln für WinOpsKit.

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

- **Regel 3.1:** Vollständige `.SYNOPSIS` + klare Kommentare in jeder Funktion
- **Regel 3.2:** `-WhatIf` Option in jeder Funktion
- **Regel 3.3:** Performance-optimiert (keine unnötigen Loops, effiziente Algorithmen)

---

## 4. TESTING (Pester 5.x)

Siehe **[ADR-003](DECISIONS.md)** für vollständigen Kontext.

- **Regel 4.1:** Pro Funktion muss eine Test-Datei unter `tests/` existieren: `<FunctionName>.Tests.ps1`
- **Regel 4.2:** Pester 5.x (mindestens 5.0+)
- **Regel 4.3:** Code Coverage Minimum: **95%** (via `Invoke-Pester -CodeCoverage`)
- **Regel 4.4:** Nutze **Pester `Mock`** für externe Dependencies (APIs, Dateisystem, Registry)
- **Regel 4.5:** Assertion Style: Standard Pester Assertions (`Should -Be`, `Should -Throw`, `Should -Match`, etc.)
- **Regel 4.6:** Test-Data: Nutze **Fixtures** in `tests/fixtures/` (JSON, CSV, oder PowerShell-Objekte)
- **Regel 4.7:** Test-Struktur: `Describe` → `Context` → `It` (aussagekräftige Namen)
- **Regel 4.8:** Test-Runner: Lokal PowerShell via `Invoke-Pester` (in `build.ps1`)

---

## 5. DOKUMENTATION

- **Regel 5.1:** `functions/FUNCTION-STATUS.md` dokumentiert aktuellen Arbeitsstand und Modul-Informationen

---

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

Siehe **[ADR-006](DECISIONS.md)** für vollständigen Kontext.

- **Regel 7.1:** PSScriptAnalyzer mit PSGallery-Standard Ruleset verwenden
- **Regel 7.2:** Linting-Check vor jedem Commit (via `build.ps1`)
- **Regel 7.3:** 4-Space Indentation (keine Tabs)
- **Regel 7.4:** K&R Bracing Style – `{` auf gleicher Zeile
- **Regel 7.5:** Line Length optimiert auf Lesbarkeit (~100-120 Zeichen anstreben, aber nicht strikte Limit)
- **Regel 7.6:** Format-Exceptions erlaubt mit `# PSScriptAnalyzer ignore [rule]` Kommentar
- **Regel 7.7:** `.editorconfig` oder `PSScriptAnalyzerSettings.psd1` für IDE-Integration

---

## 8. NAMING CONVENTIONS

Siehe **[ADR-007](DECISIONS.md)** für vollständigen Kontext.

- **Regel 8.1:** Funktions-Präfixe: PowerShell Approved Verbs (Get, Set, Test, New, Remove, Add, Clear, etc.)
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

- **Regel 11.1:** Getrennte Module (nicht alles in 1 .psm1): `Core.psm1`, `System.psm1`, `User.psm1`, `Maintenance.psm1`
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
- **Regel 12.6:** Graceful Degradation: External Module fehlt → Loggen + Error + Continue (nicht throw)
- **Regel 12.7:** PowerShell-Version Constraint: Minimum 5.1, Runtime-Checks für 7.x Features (ADR-002)
- **Regel 12.8:** Optional: `Test-WinOpsKitDependencies` Helper-Funktion in Core (nicht blocking)

---

## Verzeichnis-Übersicht

```
WinOpsKit/
├── functions/              # Wiederverwendbare PowerShell-Funktionen
│   ├── FUNCTION-STATUS.md  # Arbeitsstand und Modul-Info (von Hand gepflegt)
│   ├── Core/
│   ├── System/
│   ├── User/
│   └── Maintenance/
├── scripts/                # Hauptscripte (modular aus functions aufgebaut)
├── tests/                  # Test-Funktionen (pro function/ eine entsprechende)
├── CLAUDE.md               # Collaboration Rules & Best Practices
├── DECISIONS.md            # Architectural Decision Records (ADRs)
└── STRUCTURE.md            # Diese Datei
```

---

## Status: Infrastruktur-Phase ✅ COMPLETE

Alle 9 ADRs sind dokumentiert und akzeptiert:

- [✓] **ADR-001:** Modulare PowerShell-Architektur mit Funktionen & Scripts
- [✓] **ADR-002:** PowerShell-Version (5.1 vs. 7.x compatibility)
- [✓] **ADR-003:** Testing Framework (Pester 5.x, 95% Coverage)
- [✓] **ADR-004:** Error Handling Convention
- [✓] **ADR-005:** Logging Strategy (CSV-basiert, 7-Tage Retention)
- [✓] **ADR-006:** Code Style & PSScriptAnalyzer Rules (K&R, 4-Space)
- [✓] **ADR-007:** Naming Conventions (Approved Verbs, camelCase)
- [✓] **ADR-008:** Modul-Import-Strategie (Core-Modul + Optional)
- [✓] **ADR-009:** Dependency Management (Linear Hierarchy, Graceful Degradation)

**Nächste Phase:** Implementation (Code schreiben)
