# WinOpsKit – FUNCTION-STATUS.md

Arbeitsstand und Modul-Informationen für alle PowerShell-Funktionen.

**Zuletzt aktualisiert:** 2026-06-25  
**Infrastruktur-Phase:** ✅ Complete (9 ADRs)  
**Implementation-Phase:** ⏳ Starting

---

## Core Module

Basis-Funktionen für Logging, Config, Fehlerbehandlung. **MUST-HAVE für alle anderen Module.**

| Funktion | Modul | Status | Beschreibung | Last Updated | Tests | Coverage |
|----------|-------|--------|-------------|--------------|-------|----------|
| Write-Log | Core | `[ ]` | CSV-basierte zentrale Logging-Funktion (ADR-005) | - | - | - |
| Write-ErrorLog | Core | `[ ]` | Error-Handling Wrapper (ADR-004) | - | - | - |
| Test-NotNullOrEmpty | Core | `[ ]` | Parameter-Validation Helper (ADR-009) | - | - | - |
| ConvertTo-MaskedString | Core | `[ ]` | Sensitive Data Masking (ADR-005) | - | - | - |
| Test-WinOpsKitDependencies | Core | `[ ]` | External Module Dependency Check (ADR-009) | - | - | - |

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
