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
