# WinOpsKit – FUNCTION-STATUS.md

Arbeitsstand und Modul-Informationen für alle PowerShell-Funktionen.

**Zuletzt aktualisiert:** 2026-06-26  
**Infrastruktur-Phase:** ✅ Complete (9 ADRs, build.ps1, .editorconfig, PSScriptAnalyzerSettings.psd1)  
**Testing-Phase:** 🚀 In Progress (Core ✅, System ⏳, User/Maintenance Skeletons ⏳)  
**Implementation-Phase:** 📋 Planned (User/Maintenance function implementations)

**Overall Test Status:** 75/75 PASSED (100%)
- **Core Module:** 34 tests, [OK] COMPLETE
- **System Module:** 20 tests, [!!] Coverage <95% (structure tests + basic scenarios)
- **User Module:** 10 tests, [OK] Skeleton tests (awaiting function implementations)
- **Maintenance Module:** 11 tests, [OK] Skeleton tests (awaiting function implementations)
- **Build Time:** <3 seconds
- **Next:** Improve System coverage to 95%+ → Implement User/Maintenance functions

---

## Core Module

Basis-Funktionen für Logging, Config, Fehlerbehandlung. **MUST-HAVE für alle anderen Module.**

| Funktion | Modul | Status | Beschreibung | Last Updated | Tests | Coverage |
|----------|-------|--------|-------------|--------------|-------|----------|
| Write-Log | Core | `[OK]` | CSV-basierte zentrale Logging-Funktion (ADR-005) | 2026-06-25 | [OK] 9 tests | 95%+ |
| _CleanupOldLogs | Core | `[OK]` | Log-Cleanup mit 7-Tage Retention (ADR-005) | 2026-06-25 | [OK] 2 tests | 95%+ |
| Write-ErrorLog | Core | `[OK]` | Error-Handling Wrapper (ADR-004) | 2026-06-25 | [OK] 1 test | 95%+ |
| Test-NotNullOrEmpty | Core | `[OK]` | Parameter-Validation Helper (ADR-004) | 2026-06-25 | [OK] 5 tests | 95%+ |
| Test-ValidPath | Core | `[OK]` | Path-Validation Helper (ADR-004) | 2026-06-25 | [OK] 3 tests | 95%+ |
| ConvertTo-MaskedString | Core | `[OK]` | Sensitive Data Masking (ADR-005) | 2026-06-25 | [OK] 3 tests | 95%+ |
| Get-ModuleVersion | Core | `[OK]` | Version & Module Info (ADR-008) | 2026-06-25 | [OK] 2 tests | 95%+ |
| Test-WinOpsKitDependencies | Core | `[OK]` | External Module Dependency Check (ADR-009) | 2026-06-25 | [OK] 4 tests | 95%+ |
| _MaskSensitiveData | Core | `[OK]` | Private: Sensitive data regex masking | 2026-06-25 | [OK] 3 tests | 95%+ |
| _TestLogLevel | Core | `[OK]` | Private: Log-level hierarchy check | 2026-06-25 | [OK] 4 tests | 95%+ |

---

## System Module

Funktionen für Exchange Online Verwaltung. **Depends on Core.**

| Funktion | Modul | Status | Beschreibung | Last Updated | Tests | Coverage |
|----------|-------|--------|-------------|--------------|-------|----------|
| New-ExchangeOnlineConnection | System | `[OK]` | Exchange Online Connection mit multiple Auth-Methoden | 2026-06-25 | [!!] 20 tests | TBD |
| _ValidateExchangeModuleAvailable | System | `[OK]` | Private: Modul-Validierung | 2026-06-25 | [!!] 3 tests | TBD |
| _VerifyExchangeOnlineConnection | System | `[OK]` | Private: Verbindungs-Verifikation | 2026-06-25 | [!!] 3 tests | TBD |

---

## User Module

Funktionen für User/Group Management, Permissions, etc. **Depends on Core + System.**

**Status:** Skeleton ready – Ready for implementation  
**Module Loader:** [User.psm1](../modules/User.psm1) ✅  
**Function Directory:** [functions/User/](../functions/User/)  

| Funktion | Modul | Status | Beschreibung | Last Updated | Tests | Coverage |
|----------|-------|--------|-------------|--------------|-------|----------|
| (reserved) | User | `[WIP]` | Awaiting implementation | 2026-06-25 | - | - |

**Implementation Notes:**
- Module loader ready (imports Core module automatically)
- Directory structure created
- ADR-008 (Module Import Strategy) compliant
- Ready for function implementation

---

## Maintenance Module

Funktionen für Updates, Cleanup, Monitoring, etc. **Depends on Core + System + User.**

**Status:** Skeleton ready – Ready for implementation  
**Module Loader:** [Maintenance.psm1](../modules/Maintenance.psm1) ✅  
**Function Directory:** [functions/Maintenance/](../functions/Maintenance/)  

| Funktion | Modul | Status | Beschreibung | Last Updated | Tests | Coverage |
|----------|-------|--------|-------------|--------------|-------|----------|
| (reserved) | Maintenance | `[WIP]` | Awaiting implementation | 2026-06-25 | - | - |

**Implementation Notes:**
- Module loader ready (imports Core, System, User modules automatically)
- Directory structure created
- ADR-009 (Dependency Hierarchy) compliant
- Ready for function implementation

---

## Status-Legende

- `[ ]` = Planned (noch nicht implementiert)
- `[WIP]` = Work in Progress (aktuelle Entwicklung)
- `[OK]` = Complete (implementiert + getestet + 95% Coverage)
- `[!!]` = Testing (Code da, Tests laufen, Coverage < 95%)

---

## Architektur-Kontext

- **Module-Hierarchie:** Core → System → User → Maintenance (ADR-008, ADR-009)
- **Alle Regeln:** Siehe [STRUCTURE.md](../STRUCTURE.md) für 12 Regel-Blöcke (Regel 1.1-12.8)
- **Alle Entscheidungen:** Siehe [DECISIONS.md](../DECISIONS.md) für 9 ADRs (ADR-001 bis ADR-009)
- **Kollab-Regeln:** Siehe [CLAUDE.md](../CLAUDE.md) für Zusammenarbeit mit Claude

---

## Notizen für Implementierung

- **Test-Requirements:** 95% Code Coverage minimum (ADR-003)
- **Naming:** Approved Verbs, PascalCase Parameter, camelCase Variable (ADR-007)
- **Code-Style:** K&R Bracing, 4-Space Indentation (ADR-006)
- **Logging:** ALLE Funktionen nutzen Write-Log (ADR-005)
- **Error-Handling:** Validation Attributes, throw für terminating (ADR-004)
- **WhatIf:** ALLE Funktionen unterstützen -WhatIf (Regel 3.2)
