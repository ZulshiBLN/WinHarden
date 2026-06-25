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
Modulare PowerShell-Architektur mit klarer Trennung von Funktionen, Scripts und Tests. 
Siehe **[STRUCTURE.md](STRUCTURE.md)** für konkrete Implementierungs-Regeln (Regel 1.1-5.1).

**Consequences:**
- (+) Hohe Wiederverwendbarkeit durch klare Trennung
- (+) Testbarkeit jeder Funktion isoliert
- (+) Performance-Fokus von Anfang an
- (-) Mehr Initial-Struktur erforderlich
- (-) FUNCTION-STATUS.md muss manuell gepflegt werden

**Alternatives:**
- Monolithische Script-Struktur (schneller zu schreiben, aber schwer zu warten)
- Alles in einen großen `functions.ps1` (unübersichtlich ab Größe)

---

### ADR-002: PowerShell-Version & Compatibility

**Status:** ✅ ACCEPTED

**Context:**
Windows Server-Umgebungen haben gemischte PowerShell-Versionen:
- Ältere Server (2016, frühe 2019) haben nur PowerShell 5.1
- Neuere Server (2022+) haben PowerShell 7.x optional verfügbar
- WinOpsKit soll in beiden Umgebungen funktionieren

**Decision:**
- **Minimum-Version:** PowerShell 5.1 (funktioniert überall)
- **Dual-Support:** Code muss auf 5.1 UND 7.x laufen
- **Runtime-Checks:** Moderne 7.x-Features per `$PSVersionTable.PSVersion.Major -ge 7` abfragen
- **Moderne Cmdlets:** Verwende nicht-deprecated Varianten (z.B. `Get-Process` statt `ps`, `Get-Item` statt `dir`)
- **Windows-only:** Kein cross-plattform-Support nötig (keine UNIX-Pfade, etc.)
- **Keine Breaking Changes:** 5.1-kompatible Syntax default, 7.x-Features optional

**Consequences:**
- (+) Funktioniert in 100% der Windows Server-Umgebungen
- (+) Moderne Features können schrittweise genutzt werden
- (+) Kein Druck auf Server-Updates
- (-) Testing auf beiden Versionen erforderlich
- (-) Manche Conditional-Patterns notwendig für 7.x Features
- (-) Keine modernen PowerShell-7-only Syntaxen (z.B. Native Operators)

**Alternatives:**
- Nur PowerShell 5.1 (nicht zukunftssicher, Features fehlen)
- Nur PowerShell 7.x (funktioniert nicht auf älteren Servern)
- Cross-plattform PowerShell (nicht nötig, Windows-only ist Ziel)

**Implementation Notes:**
- Tests müssen auf mindestens 5.1 laufen
- Moderne Cmdlets: Bevorzuge `Get-*` Pattern über Aliase
- 7.x-Features: Nutze innerhalb von `if ($PSVersionTable.PSVersion.Major -ge 7) { ... }`
- Deprecated Functions dokumentieren mit `# PSv5.1: Use X instead of Y`

---

### ADR-006: Code Style & PSScriptAnalyzer Rules

**Status:** ✅ ACCEPTED

**Context:**
Konsistente Code-Formatierung ist wichtig für Lesbarkeit und Wartbarkeit. PSScriptAnalyzer ist das Standard-Linting-Tool für PowerShell und sollte in den Build-Prozess integriert sein.

**Decision:**
- **PSScriptAnalyzer Ruleset:** Vordefiniertes Ruleset (PSGallery Standard)
- **Linting vor Commit:** Build-Check mit PSScriptAnalyzer (muss BESTEHEN vor jedem Commit)
- **Indentation:** 4 Spaces (nicht Tabs)
- **Line Length:** Optimiert auf Lesbarkeit (keine strikte Limit, aber ca. 120 Zeichen anstreben)
- **Bracing Style:** K&R Style – `{` auf gleicher Zeile (z.B. `if ($x) {`)
- **Format-Exceptions:** Erlaubt wenn für Lesbarkeit notwendig (mit `# PSScriptAnalyzer ignore [rule]` Kommentar)

**Consequences:**
- (+) Konsistente Code-Formatierung across Team/Sessions
- (+) Automatische Qualitäts-Checks vor Commits
- (+) PSScriptAnalyzer findet viele Common Pitfalls
- (-) Build-Check könnte lokal fehlschlagen (muss lokal PSScriptAnalyzer haben)
- (-) Strikte Regeln können manchmal Lesbarkeit beeinträchtigen (daher Exceptions erlaubt)

**Alternatives:**
- Manuelle Code Reviews statt Linting (zeitaufwendig, inkonsistent)
- Keine Formatierungs-Standards (Code-Zoo, schwer zu lesen)
- Custom PSScriptAnalyzer Rules (zu komplex für diesen Stage)

**Implementation Notes:**
- `build.ps1` soll PSScriptAnalyzer laufen lassen: `Invoke-ScriptAnalyzer -Path ./functions, ./scripts, ./tests -IncludeRule PSGallery`
- `.editorconfig` oder `PSScriptAnalyzerSettings.psd1` für lokale IDE-Integration
- **K&R Bracing:**
  ```powershell
  # [YES]
  if ($condition) {
      Write-Host "Hello"
  }
  
  # [NO]
  if ($condition)
  {
      Write-Host "Hello"
  }
  ```
- **4-Space Indentation:**
  ```powershell
  function Test-Something {
      param(
          [string]$Name
      )
      
      if ($Name) {
          Write-Host "Name: $Name"
      }
  }
  ```
- **Line Length:** Anstreben ~100-120 Zeichen, Lesbarkeit > Regel
  ```powershell
  # [OK - Lesbar, auch über 120 Zeichen]
  $LongVariableName = Get-ChildItem -Path $VeryLongPath -Filter $ComplexFilter -ErrorAction Stop
  ```
- **Exceptions:** Nur mit Kommentar, z.B.:
  ```powershell
  # PSScriptAnalyzer ignore PSUseApprovedVerbs
  function Initialize-SpecialContext { }
  ```
