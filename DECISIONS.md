# WinOpsKit – Architectural Decision Records (ADRs)

Zentrale Dokumentation für Architektur-Entscheidungen, die das Projekt massgeblich beeinflussen.

---

## ADR-Vorlage

```markdown
## ADR-XXX: [Kurzer Titel]

**Status:** [PENDING | ACCEPTED | REJECTED | SUPERSEDED]

**Context:** 
[Beschreibung des Problems/Kontexts]

**Decision:** 
[Was wurde entschieden?]

**Consequences:** 
- [Positive Auswirkungen]
- [Negative Auswirkungen]

**Alternatives:** 
- [Alternative 1]
- [Alternative 2]
```

---

## Entscheidungen

### ADR-001: Modulare PowerShell-Architektur mit Funktionen & Scripts

**Status:** ✅ ACCEPTED

**Context:**
WinOpsKit benötigt eine klare Struktur für Wiederverwendbarkeit, Testbarkeit und Wartbarkeit. PowerShell-Code sollte nicht monolithisch sein.

**Decision:**
- Funktionen leben in `functions/` mit Kategorien (Core, System, User, Maintenance)
- Scripts leben in `scripts/` und bauen modular auf Funktionen auf
- Tests leben in `tests/` parallel zur Funktionsstruktur
- Jede Funktion muss wiederverwendbar, allgemeingültig und performance-optimiert sein
- `functions/FUNCTION-STATUS.md` dokumentiert den Arbeitsstand

**Consequences:**
- (+) Hohe Wiederverwendbarkeit durch klare Trennung
- (+) Testbarkeit jeder Funktion isoliert
- (+) Performance-Fokus von Anfang an
- (-) Mehr Initial-Struktur erforderlich
- (-) FUNCTION-STATUS.md muss manuell gepflegt werden

**Alternatives:**
- Monolithische Script-Struktur (schneller zu schreiben, aber schwer zu warten)
- Alles in einen großen `functions.ps1` (unübersichtlich ab Größe)
