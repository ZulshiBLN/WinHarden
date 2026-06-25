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

## 4. TESTING

- **Regel 4.1:** Pro Funktion muss eine Test-Funktion unter `tests/` existieren (gleiche Anforderungen wie Production-Funktionen)

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

*(Noch zu definieren)*

- Try-Catch-Standard
- Logging-Integration
- Exit-Code-Konventionen

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

## Roadmap: Fehlende Definitionen

Folgende Standards müssen noch in [DECISIONS.md](DECISIONS.md) als ADRs dokumentiert werden:

- [✓] **ADR-002:** PowerShell-Version (5.1 vs. 7.x compatibility) – ACCEPTED
- [✓] **ADR-006:** Code Style & PSScriptAnalyzer Rules – ACCEPTED
- [✓] **ADR-007:** Naming Conventions (Funktions-Präfixe, Parameter, Variablen) – ACCEPTED
- [ ] **ADR-003:** Testing Framework (Pester 5.x setup)
- [ ] **ADR-004:** Error Handling Convention
- [ ] **ADR-005:** Logging Strategy
- [ ] **ADR-008:** Modul-Import-Strategie
- [ ] **ADR-009:** Dependency Management zwischen Funktionen
