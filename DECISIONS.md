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
  $longVariableName = Get-ChildItem -Path $veryLongPath -Filter $complexFilter -ErrorAction Stop
  ```
- **Exceptions:** Nur mit Kommentar, z.B.:
  ```powershell
  # PSScriptAnalyzer ignore PSUseApprovedVerbs
  function Initialize-SpecialContext { }
  ```

---

### ADR-007: Naming Conventions (Funktionen, Parameter, Variablen)

**Status:** ✅ ACCEPTED

**Context:**
Konsistente Naming-Konventionen sind kritisch für Lesbarkeit und Verständlichkeit. PowerShell hat Conventions, die befolgt werden sollten, mit einigen Projekt-spezifischen Ergänzungen.

**Decision:**

**Funktions-Namen:**
- **Approved Verbs:** Nur PowerShell-Approved Verbs verwenden (Get, Set, Test, New, Remove, Add, Clear, etc.)
- **Format:** `Verb-Noun` (z.B. `Get-SystemInfo`, `Test-ServiceHealth`)
- **Private Funktionen:** Prefix `_` (z.B. `_GetSystemDetails`)

**Parameter-Namen:**
- **Singular/Plural:** Singular wenn Parameter **einen** Wert nimmt, Plural wenn **mehrere** (z.B. `$Server` vs. `$Servers`)
- **Format:** PascalCase (z.B. `$ComputerName`, `$ProcessList`)

**Variablen-Namen:**
- **Format:** camelCase (z.B. `$systemInfo`, `$isHealthy`, `$errorCount`)
- **Prefix für Typen:** Optional aber konsistent (z.B. `$strName`, `$intCount`)

**Boolean-Funktionen:**
- **Präfix:** `Is` (z.B. `Is-SystemHealthy`, `Is-ServiceRunning`)

**Datei-Namen:**
- **Match Funktions-Name:** Dateiname == Funktions-Name (z.B. `Get-SystemInfo.ps1`)
- **Private Funktionen:** `_PrivateFunction.ps1`

**Consequences:**
- (+) Sofort erkennbar: Funktion vs. Variable vs. Parameter
- (+) PowerShell-Standard + Projekt-Konventionen konsistent
- (+) PSScriptAnalyzer validiert Approved Verbs automatisch
- (-) Mehr Regeln zu merken
- (-) Umbenennungen nötig wenn vorhandene Code nicht komform

**Alternatives:**
- Keine Konventionen (völliges Chaos)
- Nur PowerShell-Standards ohne Projekt-Ergänzungen (weniger Klarheit)
- SCREAMING_SNAKE_CASE überall (nicht PowerShell-Standard)

**Implementation Notes:**

```powershell
# [YES - Approved Verb, PascalCase Parameter, camelCase Variable]
function Get-ServerStatus {
    param(
        [string]$ComputerName,
        [string[]]$Services  # Plural: mehrere Werte
    )
    
    $isHealthy = $true
    $serviceCount = 0
    
    foreach ($service in $Services) {
        if (-not (Get-Service -Name $service -ErrorAction SilentlyContinue)) {
            $isHealthy = $false
        }
        $serviceCount++
    }
    
    return @{
        ComputerName = $ComputerName
        IsHealthy    = $isHealthy
        ServiceCount = $serviceCount
    }
}

# [YES - Boolean function mit Is-Prefix]
function Is-ServiceRunning {
    param([string]$ServiceName)
    
    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    return $null -ne $service -and $service.Status -eq 'Running'
}

# [YES - Private function mit _ Prefix]
function _ValidateInput {
    param([string]$InputValue)
    
    return -not [string]::IsNullOrWhiteSpace($InputValue)
}

# [NO - Non-approved verb]
function Fetch-Data { }  # Use Get-Data instead

# [NO - Parameter plural wenn nur ein Wert]
function Get-Process {
    param([string[]]$ProcessNames)  # Should be $ProcessName if singular
}

# [NO - Variable in PascalCase]
function Test-Something {
    $SystemInfo = "data"  # Should be $systemInfo
}
```
