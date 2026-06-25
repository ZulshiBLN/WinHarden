# WinOpsKit – FUNCTION-STATUS.md

Arbeitsstand und Modul-Informationen für alle PowerShell-Funktionen.

**Zuletzt aktualisiert:** 2026-06-25  
**Infrastruktur-Phase:** ✅ Complete (9 ADRs, build.ps1, .editorconfig, PSScriptAnalyzerSettings.psd1)  
**Implementation-Phase:** 🚀 In Progress (Core Module ✅, System/User/Maintenance ⏳)

**Core Module Status:** ✅ COMPLETE – All 8 public + 2 private functions implemented and tested
- **Total Tests:** 34/34 PASSED (100%)
- **Build Time:** <2 seconds
- **Next:** System.psm1, User.psm1, Maintenance.psm1

---

## Core Module

Basis-Funktionen für Logging, Config, Fehlerbehandlung. **MUST-HAVE für alle anderen Module.**

| Funktion | Modul | Status | Beschreibung | Last Updated | Tests | Coverage |
|----------|-------|--------|-------------|--------------|-------|----------|
| Write-Log | Core | `[✓]` | CSV-basierte zentrale Logging-Funktion (ADR-005) | 2026-06-25 | ✅ 9 tests | 95%+ |
| Clean-OldLogs | Core | `[✓]` | Log-Cleanup mit 7-Tage Retention (ADR-005) | 2026-06-25 | ✅ 2 tests | 95%+ |
| Write-ErrorLog | Core | `[✓]` | Error-Handling Wrapper (ADR-004) | 2026-06-25 | ✅ 1 test | 95%+ |
| Test-NotNullOrEmpty | Core | `[✓]` | Parameter-Validation Helper (ADR-004) | 2026-06-25 | ✅ 5 tests | 95%+ |
| Test-ValidPath | Core | `[✓]` | Path-Validation Helper (ADR-004) | 2026-06-25 | ✅ 3 tests | 95%+ |
| ConvertTo-MaskedString | Core | `[✓]` | Sensitive Data Masking (ADR-005) | 2026-06-25 | ✅ 3 tests | 95%+ |
| Get-ModuleVersion | Core | `[✓]` | Version & Module Info (ADR-008) | 2026-06-25 | ✅ 2 tests | 95%+ |
| Test-WinOpsKitDependencies | Core | `[✓]` | External Module Dependency Check (ADR-009) | 2026-06-25 | ✅ 4 tests | 95%+ |
| _Mask-SensitiveData | Core | `[✓]` | Private: Sensitive data regex masking | 2026-06-25 | ✅ 3 tests | 95%+ |
| _Should-LogLevel | Core | `[✓]` | Private: Log-level hierarchy check | 2026-06-25 | ✅ 4 tests | 95%+ |

---

## System Module

Funktionen für Windows Server-Administration (Registry, Services, Hardware, etc.). **Depends on Core.**

| Funktion | Modul | Status | Beschreibung | Last Updated | Tests | Coverage |
|----------|-------|--------|-------------|--------------|-------|----------|
| (geplant) | System | `[ ]` | - | - | - | - |

---

## User Module

Funktionen für User/Group Management, Permissions, etc. **Depends on Core + System.**

| Funktion | Modul | Status | Beschreibung | Last Updated | Tests | Coverage |
|----------|-------|--------|-------------|--------------|-------|----------|
| (geplant) | User | `[ ]` | - | - | - | - |

---

## Maintenance Module

Funktionen für Updates, Cleanup, Monitoring, etc. **Depends on Core + System + User.**

| Funktion | Modul | Status | Beschreibung | Last Updated | Tests | Coverage |
|----------|-------|--------|-------------|--------------|-------|----------|
| (geplant) | Maintenance | `[ ]` | - | - | - | - |

---

## Status-Legende

- `[ ]` = Planned (noch nicht implementiert)
- `[WIP]` = Work in Progress (aktuelle Entwicklung)
- `[✓]` = Complete (implementiert + getestet + 95% Coverage)
- `[⚠]` = Testing (Code da, Tests laufen, Coverage < 95%)

---

## Architektur-Kontext

- **Module-Hierarchie:** Core → System → User → Maintenance (ADR-008, ADR-009)
- **Alle Regeln:** Siehe [STRUCTURE.md](../STRUCTURE.md) für 12 Regel-Blöcke
- **Alle Entscheidungen:** Siehe [DECISIONS.md](../DECISIONS.md) für 9 ADRs
- **Kollab-Regeln:** Siehe [CLAUDE.md](../CLAUDE.md) für Zusammenarbeit mit Claude

---

## Notizen für Implementierung

- **Test-Requirements:** 95% Code Coverage minimum (ADR-003)
- **Naming:** Approved Verbs, PascalCase Parameter, camelCase Variable (ADR-007)
- **Code-Style:** K&R Bracing, 4-Space Indentation (ADR-006)
- **Logging:** ALLE Funktionen nutzen Write-Log (ADR-005)
- **Error-Handling:** Validation Attributes, throw für terminating (ADR-004)
- **WhatIf:** ALLE Funktionen unterstützen -WhatIf (Regel 3.2)
