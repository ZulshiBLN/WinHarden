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

---

### ADR-004: Error Handling Convention

**Status:** ✅ ACCEPTED

**Context:**
Konsistente Fehlerbehandlung ist kritisch für robuste PowerShell-Scripts. PowerShell hat verschiedene Error-Handling-Mechanismen (Try-Catch, ErrorActionPreference, Write-Error, Throw), die konsistent genutzt werden müssen.

**Decision:**

**Try-Catch Nutzung:**
- Nur wo **nötig** verwenden, nicht standardmäßig um alle Code wrappen
- Nutzen für externe Ressourcen (Datei-Zugriff, Netzwerk, Registry) oder bekannte Fehlerquellen
- Nicht für interne Code-Logik verwenden

**Fehlerbehandlung-Strategie:**
- **Terminating Errors:** `throw` Exception (stoppt Ausführung sofort)
- **Non-Terminating Errors:** `Write-Error` (gibt Error aus, setzt `$?` zu `$false`, aber setzt ErrorActionPreference)
- **ErrorActionPreference:** Default `Stop` (behandelt Fehler als terminating)

**Automatisches Logging:**
- Alle Errors werden **automatisch geloggt** (siehe ADR-005 für Logging-Implementation)
- Try-Catch sollte Fehler fangen, loggen, und neu-werfen oder Write-Error aufrufen
- Keine doppelten Logs (Logging-Funktion ist zentral)

**Exit-Codes (für Scripts, nicht Funktionen):**
- `0` = Erfolgreich
- `1` = General Error (unerwarteter Fehler)
- `2` = Cmdlet Error (PowerShell Fehler)
- `3+` = Custom Exit Codes (projekt-spezifisch)

**WhatIf & Confirm:**
- Fehlerbehandlung läuft **gleich** wie bei normalem Run
- `-WhatIf` ändert Fehler-Handling nicht
- Errors werden auch bei WhatIf geworfen/geloggt

**Parameter Validation:**
- Nutze **PowerShell Validation Attributes** (nicht manuelle Checks):
  - `[ValidateNotNullOrEmpty()]`
  - `[ValidateSet(...)]`
  - `[ValidateRange(...)]`
  - `[ValidateScript({...})]`
  - `[ValidatePath]`
- Diese werfen automatisch Errors bei ungültigen Inputs

**Consequences:**
- (+) Fehler stoppen Ausführung sofort (kein stummes Fehlschlag)
- (+) Zentrale Fehler-Handling & Logging reduziert Redundanz
- (+) ValidationAttributes sind lesbar und wartbar
- (+) Exit-Codes ermöglichen Scripting in Batch/Automation
- (-) `ErrorActionPreference Stop` ist streng (könnte manchmal zu restriktiv sein)
- (-) Braucht zentrale Logging-Funktion (ADR-005)
- (-) Try-Catch wird oft nicht gebraucht (könnte Code-Komplexität senken)

**Alternatives:**
- `ErrorActionPreference Continue` (weniger restriktiv, aber Fehler können ignoriert werden)
- Alle Errors als Write-Error (nicht streng genug)
- Jede Funktion mit eigenem Try-Catch (redundant, schwer zu maintainen)

**Implementation Notes:**

```powershell
# [YES - ErrorActionPreference Stop, Validation Attributes]
function Get-ServerStatus {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName,
        
        [ValidateSet('Running', 'Stopped', 'Paused')]
        [string[]]$States = @('Running')
    )
    
    # Try-Catch nur für externe Ressource (Netzwerk-Call)
    try {
        $server = Get-ADComputer -Identity $ComputerName -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to find server '$ComputerName': $_"
        return
    }
    
    # Interne Logik ohne Try-Catch
    $processes = Get-Process
    return $processes | Where-Object { $_.ProcessName -in @('svchost', 'system') }
}

# [YES - Throw for terminating errors]
function New-Backup {
    param(
        [Parameter(Mandatory)]
        [ValidatePath]
        [string]$SourcePath
    )
    
    if (-not (Test-Path $SourcePath)) {
        throw "Source path does not exist: $SourcePath"
    }
    
    # ... Backup logic
}

# [YES - Script with Exit Codes]
try {
    & ./Backup-Server.ps1 -ServerName "SRV01"
    exit 0
}
catch {
    Write-Error "Backup failed: $_"
    exit 1
}

# [NO - Too much Try-Catch]
function Get-Data {
    try {
        $item = $items[0]  # No exception possible here
        try {
            $value = $item.Property  # Also no exception
        }
        catch { Write-Error $_; return }
    }
    catch { Write-Error $_; return }
}

# [NO - Manual validation instead of Attributes]
function Get-Items {
    param([string]$Name)
    
    if ([string]::IsNullOrEmpty($Name)) {
        throw "Name is required"  # Use [ValidateNotNullOrEmpty()] instead
    }
}

# [NO - Write-Error for terminating errors]
function Delete-Item {
    if (-not $Path) {
        Write-Error "Path is required"  # Should throw or use [ValidateNotNullOrEmpty()]
        return
    }
}
```

**Related ADRs:**
- **ADR-005:** Logging Strategy (definiert zentrale Logging-Funktion)

---

### ADR-005: Logging Strategy

**Status:** ✅ ACCEPTED

**Context:**
Logging ist kritisch für Troubleshooting und Compliance. PowerShell-Scripts brauchen eine zentrale, konsistente Logging-Strategie, die Fehler und Operationen protokolliert, ohne sensitive Daten zu exponieren.

**Decision:**

**Logging-Ziele:**
- Datei-basiert: `$PSScriptRoot\logs\`
- Format: CSV (strukturiert, leicht zu analysieren)
- Datei-Name: `log_YYYY-MM-DD.csv` (tägliche Rotation)

**Log-Levels (in dieser Hierarchie):**
1. **Error** - Kritische Fehler (immer loggen)
2. **Warning** - Potenzielle Probleme (meist loggen)
3. **Info** - Standard-Operationen (loggen wenn NICHT `-Verbose`)
4. **Debug** - Detaillierte Debug-Info (loggen nur bei `-Debug`)
5. **Verbose** - Sehr detailliert (loggen nur bei `-Verbose`)

**Zentrale Logging-Funktion: `Write-Log`**
- Parameter: `-Message`, `-Level`, `-Caller` (optional)
- CSV-Spalten:
  ```
  Timestamp, Level, Caller, Function, LineNumber, Message
  2026-06-25 14:23:45.123, ERROR, Get-ServerStatus:42, Get-ServerStatus, 42, "Failed to connect to server: ***"
  ```

**Sensitive Data Masking:**
- Automatisches Maskieren bekannter sensitive Parameter:
  - `*password*`, `*token*`, `*secret*`, `*apikey*`, `*credential*`
  - Ersetzung: `***` (3 Sternchen)
- Auch Parameter-Werte maskieren wenn Name sensitive ist
- Beispiel: `"Password: ***"` statt `"Password: SecureP@ssw0rd"`

**Caller Info:**
- Funktions-Name (aus CallStack)
- Zeilen-Nummer (aus CallStack)
- Optional: Parameter (maskiert)

**Log-Rotation & Retention:**
- **Daily Files:** Ein CSV-Datei pro Tag (`log_2026-06-25.csv`)
- **Retention:** Automatisch löschen nach **7 Tagen**
- **Cleanup:** Läuft beim `Write-Log` erste Aufruf pro Tag

**LogLevel-Kontrolle:**
- Über `$env:LOG_LEVEL` (z.B. `$env:LOG_LEVEL = 'Debug'`)
- Default: `Info` (keine Debug/Verbose ohne Umgebungsvariable)
- Cmdlet-Parameter `-Verbose` und `-Debug` steuern auch LogLevel

**Consequences:**
- (+) Zentrale, strukturierte Logging-Strategie
- (+) CSV leicht zu analysieren und zu parsen
- (+) Sensitive Daten automatisch maskiert (compliance)
- (+) Caller Info hilft bei Troubleshooting
- (+) Tägliche Rotation reduziert Datei-Größe
- (-) CSV-Header muss konsistent sein
- (-) 7-Tage-Retention könnte zu Datenverlust führen (bei Audits beachten)
- (-) Maskieren kann legitime Daten verstecken (Fehler-Kontexte)

**Alternatives:**
- JSON-Logging (komplexer, aber besser strukturiert)
- Event Viewer (Windows-spezifisch, schwerer zu parsen)
- keine Logging (unmöglich zu debuggen)
- Plaintext (unklar, schwer zu parsen)

**Implementation Notes:**

**CSV-Header:**
```
Timestamp,Level,Caller,Function,LineNumber,Message
```

**Write-Log Funktion:**
```powershell
function Write-Log {
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ValidateSet('Error', 'Warning', 'Info', 'Debug', 'Verbose')]
        [string]$Level = 'Info',
        
        [string]$Caller = (Get-PSCallStack)[1].FunctionName
    )
    
    # Beispiel-Logik (vereinfacht)
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
    $logPath = Join-Path $PSScriptRoot "logs/log_$((Get-Date).ToString('yyyy-MM-dd')).csv"
    
    # Sensitive Data Maskieren
    $maskedMessage = Mask-SensitiveData $Message
    
    # CSV-Eintrag
    $logEntry = "$timestamp,$Level,$Caller,<function>,<line>,$maskedMessage"
    Add-Content -Path $logPath -Value $logEntry
    
    # Auch auf Console ausgeben (bei bestimmtem LogLevel)
    if (Should-LogLevel $Level) {
        Write-Host "[$Level] $maskedMessage"
    }
}

function Mask-SensitiveData {
    param([string]$InputString)
    
    $sensitivePrefixes = @('password', 'token', 'secret', 'apikey', 'credential', 'api_key', 'private_key')
    
    foreach ($prefix in $sensitivePrefixes) {
        $InputString = $InputString -replace "(?i)$prefix\s*[:=]\s*[^\s,;]*", "$prefix = ***"
    }
    
    return $InputString
}

function Should-LogLevel {
    param([string]$Level)
    
    $logLevel = $env:LOG_LEVEL ?? 'Info'
    $hierarchy = @('Error', 'Warning', 'Info', 'Debug', 'Verbose')
    
    return $hierarchy.IndexOf($Level) -le $hierarchy.IndexOf($logLevel)
}

function Clean-OldLogs {
    param([int]$DaysToKeep = 7)
    
    $logDir = Join-Path $PSScriptRoot 'logs'
    if (-not (Test-Path $logDir)) { return }
    
    $cutoffDate = (Get-Date).AddDays(-$DaysToKeep)
    Get-ChildItem $logDir -Filter 'log_*.csv' | Where-Object { $_.LastWriteTime -lt $cutoffDate } | Remove-Item -Force
}
```

**Beispiel Log-Datei:**
```csv
Timestamp,Level,Caller,Function,LineNumber,Message
2026-06-25 14:23:45.123,Error,Get-ServerStatus,Get-ServerStatus,42,Failed to connect to server SRV01: Connection timeout
2026-06-25 14:23:50.456,Warning,Get-ServerStatus,Get-ServerStatus,48,Server SRV01 returned empty result set
2026-06-25 14:24:00.789,Info,Initialize-Backup,Initialize-Backup,15,Backup started for path: \\server\share
2026-06-25 14:24:15.012,Error,Invoke-Backup,Invoke-Backup,32,Authentication failed - credentials: *** (masked)
2026-06-25 14:24:20.345,Debug,Test-Config,Test-Config,10,Configuration parameter ApiKey set to: ***
```

**Sensitive Data Masking Beispiele:**
```
Input:  "Password: SecureP@ss, Token: abc123xyz"
Output: "Password: ***, Token: ***"

Input:  "API_KEY=secret_12345 connection successful"
Output: "API_KEY=*** connection successful"

Input:  "Credentials: (Username=admin, Password=P@ss123)"
Output: "Credentials: (Username=admin, Password=***)"
```

**Related ADRs:**
- **ADR-004:** Error Handling Convention (nutzt Write-Log)

---

### ADR-003: Testing Framework (Pester 5.x)

**Status:** ✅ ACCEPTED

**Context:**
Automatisierte Tests sind kritisch für Qualitätsicherung und Regression-Verhinderung. Pester ist das Standard-Testing-Framework für PowerShell und sollte für alle Funktionen genutzt werden.

**Decision:**

**Pester-Version:**
- **Pester 5.x** (modern, aktuell gewartet, bessere Features)
- Mindestanforderung: Pester 5.0+

**Test-Struktur:**
- Tests in `tests/` Verzeichnis (parallel zu `functions/`)
- Test-Datei-Name: `<FunctionName>.Tests.ps1` (z.B. `Get-SystemInfo.Tests.ps1`)
- Jede Produktivfunktion MUSS eine entsprechende Test-Funktion haben
- Tests in eigenen `.Tests.ps1` Dateien organisieren

**Test-Mocking:**
- Nutzen von **Pester `Mock`** für externe Dependencies (APIs, Dateisystem, Registry, etc.)
- `InModuleScope` nur wenn nötig (private Funktionen testen)
- Mock mit `-ParameterFilter` für präzise Kontrolle

**Code Coverage:**
- **Minimum 95%** Code Coverage für alle Funktionen
- Coverage-Report via `Invoke-Pester -CodeCoverage`
- Ausnahmen nur mit explizitem Kommentar (z.B. `# Code Coverage Exception: Cannot mock registry access`)

**Test-Runner:**
- **Lokal PowerShell** (via `Invoke-Pester` im `build.ps1`)
- Keine CI/CD Pipeline zwingend (aber möglich)
- Test-Run vor jedem Commit (über Git Hook oder manual)

**Assertion Style:**
- Nutze **Standard Pester Assertions** (am weitesten verbreitet):
  - `Should -Be` (Gleichheit)
  - `Should -Throw` (Exception werfen)
  - `Should -Exist` (Datei/Verzeichnis existiert)
  - `Should -Match` (Regex-Matching)
  - `Should -BeTrue`, `Should -BeFalse` (Boolean)
  - `Should -Contain` (Array-Membership)
  - `Should -BeNullOrEmpty`, `Should -Not.BeNullOrEmpty`
  - Custom Assertions via Assertion Scopes erlaubt

**Test-Data:**
- **Fixtures:** Externe Test-Daten-Dateien unter `tests/fixtures/`
- Format: JSON, CSV, oder PowerShell-Objekte (je nach Usecase)
- Beispiel: `tests/fixtures/TestServers.json` mit Mock-Server-Daten
- Setup & Teardown via `BeforeEach` / `AfterEach` Blocks

**Test-Konventionen:**
- **Describe Block:** Funktion testen (z.B. `Describe "Get-SystemInfo"`)
- **Context Block:** Spezifischer Use-Case (z.B. `Context "When server is online"`)
- **It Block:** Einzelner Test (z.B. `It "returns system info"`)
- Aussagekräftige Test-Namen (nicht nur `Test 1`, `Test 2`)

**Consequences:**
- (+) 95% Coverage findet die meisten Bugs
- (+) Pester 5.x ist modern und aktiv gepflegt
- (+) Mocking isoliert Tests (schnell, zuverlässig)
- (+) Fixtures ermöglichen realistische Test-Daten
- (-) 95% Coverage ist streng (kann zeitaufwendig sein)
- (-) Mocking kann zu False-Positives führen (echte externe Fehler nicht fangen)
- (-) Fixture-Management muss gepflegt werden

**Alternatives:**
- Keine Tests (unakzeptabel)
- Integration Tests statt Unit Tests (langsam, instabil)
- Lower Coverage 80% (zu viele Bugs durchgehen)
- Pester 4.x (legacy, weniger Features)

**Implementation Notes:**

**Pester Test-Struktur:**
```powershell
# tests/Get-SystemInfo.Tests.ps1

BeforeAll {
    # Import function
    . "$PSScriptRoot/../functions/System/Get-SystemInfo.ps1"
    
    # Load fixtures
    $testServers = @(
        @{ Name = 'SRV01'; Online = $true; CPU = 4 }
        @{ Name = 'SRV02'; Online = $false; CPU = 8 }
    )
}

Describe "Get-SystemInfo" {
    Context "When server is online" {
        BeforeEach {
            Mock Get-WmiObject {
                return @{ TotalPhysicalMemory = 16384 }
            } -ParameterFilter { $Class -eq 'Win32_ComputerSystemProduct' }
        }
        
        It "returns system information" {
            $result = Get-SystemInfo -ComputerName 'SRV01'
            $result | Should -Not -BeNullOrEmpty
            $result.ComputerName | Should -Be 'SRV01'
        }
        
        It "returns CPU count" {
            $result = Get-SystemInfo -ComputerName 'SRV01'
            $result.CPUCount | Should -BeGreaterThan 0
        }
    }
    
    Context "When server is offline" {
        BeforeEach {
            Mock Get-WmiObject {
                throw "RPC server is unavailable"
            }
        }
        
        It "throws error when cannot connect" {
            { Get-SystemInfo -ComputerName 'OFFLINE' } | Should -Throw
        }
    }
    
    Context "When parameter is invalid" {
        It "throws for empty ComputerName" {
            { Get-SystemInfo -ComputerName '' } | Should -Throw
        }
        
        It "throws for null ComputerName" {
            { Get-SystemInfo -ComputerName $null } | Should -Throw
        }
    }
}
```

**Fixtures-Beispiel:**
```powershell
# tests/fixtures/TestServers.json
[
    {
        "Name": "SRV01",
        "Online": true,
        "OS": "Windows Server 2022",
        "CPUCount": 4,
        "Memory": 16384
    },
    {
        "Name": "SRV02",
        "Online": false,
        "OS": "Windows Server 2019",
        "CPUCount": 8,
        "Memory": 32768
    }
]

# Im Test:
$fixtures = Get-Content "$PSScriptRoot/fixtures/TestServers.json" | ConvertFrom-Json
$testServers = $fixtures
```

**Code Coverage Report:**
```powershell
# In build.ps1
$codeCoverage = Invoke-Pester -Path ./tests -CodeCoverage ./functions -PassThru
$coverage = ($codeCoverage.CodeCoverage.NumberOfCommandsExecuted / $codeCoverage.CodeCoverage.NumberOfCommandsMissed) * 100

if ($coverage -lt 95) {
    throw "Code coverage is $coverage%, but 95% is required"
}
```

**Test-Konventionen (Naming):**
```powershell
# [YES - Aussagekräftig]
Describe "Get-SystemInfo"
Context "When server is online and has valid credentials"
It "returns complete system information including CPU and memory"

# [NO - Zu generisch]
Describe "Function"
Context "Test 1"
It "checks something"
```

**Related ADRs:**
- **ADR-004:** Error Handling Convention (Tests für Exceptions)
- **ADR-007:** Naming Conventions (Test-Naming)

---

### ADR-008: Modul-Import-Strategie

**Status:** ✅ ACCEPTED

**Context:**
WinOpsKit hat mehrere Funktions-Module (System, User, Maintenance, etc.). Die Import-Strategie muss klären:
1. Wie werden Module organisiert (1x .psm1 oder separate)?
2. Wie werden Dependencies gelöst (alle funktionieren)?
3. Wie wird Script-Initialisierung sauber (nur nötige Funktionen)?

**Decision:**

**Modul-Struktur:**
- **Getrennte Module** (nicht alles in 1 .psm1):
  - `Core.psm1` – Zentrale Basis-Funktionen (IMMER laden)
  - `System.psm1` – System-Admin Funktionen (optional)
  - `User.psm1` – User/Group Management (optional)
  - `Maintenance.psm1` – Updates, Cleanup, Monitoring (optional)

**Core-Modul Inhalte (IMMER verfügbar):**
- `Write-Log` – Zentrale Logging-Funktion
- `Write-Error` Wrapper – Error-Handling Basis
- `Test-* Validatoren` – Parameter-Validation Helpers
- `ConvertTo-MaskedString` – Sensitive Data Masking
- `Get-ModuleVersion` – Version Info

**Script-Initialisierung:**
```powershell
# Minimum Setup (alle Scripts)
. "$PSScriptRoot/modules/Core.psm1"  # IMMER laden

# Optional: Zusätzliche Module
. "$PSScriptRoot/modules/System.psm1"   # Nur wenn System-Funktionen nötig
. "$PSScriptRoot/modules/User.psm1"     # Nur wenn User-Funktionen nötig
```

**Oder mit Import-Funktion (eleganter):**
```powershell
function Import-WinOpsKit {
    param(
        [string[]]$Modules = @('Core'),  # Core immer
        [switch]$All                      # Alle Module
    )
    
    if ($All) { $Modules = @('Core', 'System', 'User', 'Maintenance') }
    
    foreach ($module in $Modules) {
        $path = "$PSScriptRoot/modules/$module.psm1"
        if (Test-Path $path) {
            . $path
        }
    }
}

# Usage:
Import-WinOpsKit -Modules @('Core', 'System')
# oder
Import-WinOpsKit -All
```

**Dependency Resolution:**
- Core-Modul als **Basis für alles** (alle anderen nutzen Write-Log)
- Andere Module können aufeinander aufbauen (System ruft User-Funktionen auf)
- Reihenfolge beim Import beachten:
  1. Core.psm1 (obligatorisch)
  2. System.psm1
  3. User.psm1
  4. Maintenance.psm1

**Load-Performance:**
- **On-Startup:** Nur Core laden (schnell)
- **Dann:** Zusätzliche Module bei Bedarf laden
- Nicht lazy-load einzelne Funktionen (zu komplex)
- Jedes Modul lädt komplett oder gar nicht

**Global Scope:**
- Alle Funktionen landen im **Global Scope** (nach Import)
- Kein `$script:` private Scope (würde Dependencies komplizieren)
- Private Helper-Funktionen: Prefix `_` (z.B. `_ValidateServerName`)

**Consequences:**
- (+) Einfache, klare Struktur
- (+) Core ist immer verfügbar (keine Überraschungen)
- (+) Saubere Abhängigkeitsauflösung
- (+) Auf-Startup schnell (Core ist klein)
- (+) Scripts sind einfach zu schreiben (funktionen verfügbar)
- (-) Core muss stabil sein (alle hängen dran)
- (-) Global Scope könnte zu Naming-Konflikten führen (Regel 8: Naming verhindert das)

**Alternatives:**
- Alles in 1 .psm1 (monolithisch, schwer zu warten)
- Lazy-load Funktionen on-demand (komplex, schwer zu debuggen)
- Keine Module, nur dot-sourcing (unstrukturiert)
- Private Scopes für alle (Abhängigkeiten unmöglich)

**Implementation Notes:**

**Verzeichnis-Struktur:**
```
WinOpsKit/
├── modules/
│   ├── Core.psm1
│   ├── System.psm1
│   ├── User.psm1
│   └── Maintenance.psm1
├── scripts/
│   └── Backup-Server.ps1
└── functions/
    ├── Core/
    ├── System/
    ├── User/
    └── Maintenance/
```

**Core.psm1 Struktur:**
```powershell
# Core.psm1 – Zentrale Basis-Funktionen

# Logging
function Write-Log {
    # Implementation (siehe ADR-005)
}

# Error Helper
function Write-ErrorLog {
    param([string]$Message)
    Write-Log -Message $Message -Level Error
}

# Validation Helpers
function Test-NotNullOrEmpty {
    param([string]$Value, [string]$Name)
    if ([string]::IsNullOrEmpty($Value)) {
        throw "$Name cannot be null or empty"
    }
}

# Sensitive Data
function ConvertTo-MaskedString {
    param([string]$InputString)
    # Maskieren (siehe ADR-005)
}

# Export (optional)
Export-ModuleMember -Function @(
    'Write-Log',
    'Write-ErrorLog',
    'Test-NotNullOrEmpty',
    'ConvertTo-MaskedString'
)
```

**System.psm1 Struktur:**
```powershell
# System.psm1 – System-Admin Funktionen

# Braucht Core verfügbar
# (Core muss vorher geladen sein)

function Get-SystemInfo {
    param([string]$ComputerName)
    
    Write-Log -Message "Getting info for $ComputerName" -Level Info
    # ...
}

function Test-ServerHealth {
    param([string]$ServerName)
    
    if (-not (Test-NotNullOrEmpty $ServerName)) {
        throw "Server name invalid"
    }
    # ...
}
```

**Script-Initialization (Beispiel):**
```powershell
# Backup-Server.ps1

# Import Core (immer)
. "$PSScriptRoot/../modules/Core.psm1"

# Import nur nötige Module
. "$PSScriptRoot/../modules/System.psm1"

# Jetzt können alle Funktionen genutzt werden
function Backup-Server {
    param([string]$ServerName)
    
    $info = Get-SystemInfo -ComputerName $ServerName
    Write-Log -Message "Server info: $info" -Level Info
    
    # Backup logic
}

# Main
try {
    Backup-Server -ServerName 'SRV01'
}
catch {
    Write-ErrorLog -Message "Backup failed: $_"
    exit 1
}
```

**Related ADRs:**
- **ADR-004:** Error Handling Convention (nutzt Core-Error-Funktionen)
- **ADR-005:** Logging Strategy (Write-Log in Core)

---

### ADR-009: Dependency Management zwischen Funktionen

**Status:** ✅ ACCEPTED

**Context:**
Mit mehreren Modulen (Core, System, User, Maintenance) müssen Abhängigkeiten zwischen Funktionen gemanagt werden. Ziele:
1. Zirkuläre Abhängigkeiten verhindern
2. Klare Dependency-Hierarchie etablieren
3. External Dependencies optional halten
4. Version-Kompatibilität sichern (PowerShell 5.1+)

**Decision:**

**Circular Dependencies Prevention:**
- **Linear Dependency Hierarchy:**
  ```
  Core (keine Dependencies)
    ↓
  System (darf Core nutzen)
    ↓
  User (darf Core + System nutzen)
    ↓
  Maintenance (darf Core + System + User nutzen)
  ```
- **Regel:** Modul N darf nur Modul M aufrufen wenn M < N in Hierarchie
- **Keine Rückwärts-Abhängigkeiten:** System darf NOT User aufrufen, User darf NOT Maintenance aufrufen

**Inter-Module Dependencies:**
- **Explizit dokumentieren** (Kommentar oben in Funktion):
  ```powershell
  # DEPENDS ON: Write-Log (Core), Test-NotNullOrEmpty (Core)
  # OPTIONAL: Get-UserInfo (User.psm1)
  ```
- **Test-Mocking** für alle Inter-Modul-Aufrufe (siehe ADR-003)
- Kein direct `.psm1` Import nötig (alles lädt beim Script-Start, ADR-008)

**External Dependencies (PowerShell-Module, APIs, etc.):**
- **Deklarieren optional:**
  ```powershell
  # REQUIRES (optional): ActiveDirectory Module 2.0+
  # REQUIRES (optional): Az.Storage Module 4.0+
  ```
- **Graceful Degradation:** Wenn externe Module fehlen, loggen + Error + return gracefully
- **Nicht hard-require:** WinOpsKit funktioniert ohne externe Modules (nur mit Einschränkungen)
- Nutzen von `Test-WinOpsKitDependencies` Helper (optional)

**Version Constraints:**
- **Minimum PowerShell:** 5.1 (alle Funktionen, siehe ADR-002)
- **Keine Version-Pinning:** Zu restriktiv
- **Modern Features nutzen mit Checks:** `if ($PSVersionTable.PSVersion.Major -ge 7) { ... }`
- **Breaking Changes:** Neue ADR schreiben wenn Major-Version inkompatibel

**Dependency Validation (Helper-Funktion in Core):**
```powershell
function Test-WinOpsKitDependencies {
    param([string[]]$RequiredModules = @())
    
    $missing = @()
    foreach ($module in $RequiredModules) {
        if (-not (Get-Module $module -ListAvailable)) {
            $missing += $module
            Write-Log "Missing module: $module" -Level Warning
        }
    }
    
    if ($missing) {
        Write-Host "Install: Install-Module $($missing -join ', ')"
        return $false
    }
    return $true
}
```
- Optional, nicht blocking (graceful)
- Script kann selbst entscheiden: fail hard oder continue

**Consequences:**
- (+) Keine zirkulären Dependencies (saubere Architektur)
- (+) Klare Hierarchie (einfach zu verstehen)
- (+) External Modules optional (höhere Kompatibilität)
- (+) PowerShell 5.1+ überall (breite Unterstützung)
- (+) Test-Mocking verhindert aktuell-Abhängigkeiten (ADR-003)
- (-) Linear Hierarchy ist streng (könnte manchmal zu viel sein)
- (-) Graceful Degradation kann Error-Handling komplizieren
- (-) Dokumentation (DEPENDS ON) muss manuell gepflegt werden

**Alternatives:**
- Keine Hierarchie (Chaos)
- Automatische Dependency Resolution (zu komplex)
- Hard-require alle Modules (zu restriktiv)
- Keine External-Module Support (Limited)

**Implementation Notes:**

**Dependency Documentation (Beispiel):**
```powershell
# functions/System/Get-SystemInfo.ps1

# DEPENDS ON: Write-Log (Core), Test-NotNullOrEmpty (Core)
# OPTIONAL: Get-UserInfo (User.psm1) – test-mocked
# REQUIRES (optional): ActiveDirectory Module 2.0+

function Get-SystemInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName,
        
        [switch]$IncludeADInfo  # Requires AD module
    )
    
    Write-Log "Getting system info for $ComputerName" -Level Info
    
    # Internal dependency (User-Modul)
    $userInfo = Get-UserInfo -ComputerName $ComputerName
    
    $systemInfo = @{
        ComputerName = $ComputerName
        Users        = $userInfo
    }
    
    # External dependency (optional)
    if ($IncludeADInfo) {
        if (-not (Test-WinOpsKitDependencies -RequiredModules @('ActiveDirectory'))) {
            Write-Log "Skipping AD info: ActiveDirectory module not available" -Level Warning
            $systemInfo['ADInfo'] = $null
        }
        else {
            try {
                $systemInfo['ADInfo'] = Get-ADComputer -Identity $ComputerName
            }
            catch {
                Write-Log "Failed to get AD info: $_" -Level Error
                $systemInfo['ADInfo'] = $null
            }
        }
    }
    
    return $systemInfo
}
```

**Modul-Hierarchie im Code:**
```powershell
# Core.psm1 – Keine Dependencies
function Write-Log { ... }
function Test-NotNullOrEmpty { ... }

# System.psm1 – Depends on Core
function Get-SystemInfo {
    Write-Log "..."  # OK: Core ist verfügbar
    Get-UserInfo     # ERROR: User-Modul wird NICHT hier aufgerufen
}

# User.psm1 – Depends on Core + System
function Get-UserInfo {
    Write-Log "..."           # OK
    Get-SystemInfo            # OK: System < User in Hierarchie
}

# Maintenance.psm1 – Depends on Core + System + User
function Invoke-SystemMaintenance {
    Write-Log "..."           # OK
    Get-SystemInfo            # OK
    Get-UserInfo              # OK
}
```

**Script-Initialization mit Dependency Check:**
```powershell
# Backup-Server.ps1

# Import Core (immer)
. "$PSScriptRoot/../modules/Core.psm1"

# Import Optional Modules
. "$PSScriptRoot/../modules/System.psm1"
. "$PSScriptRoot/../modules/User.psm1"

# Check External Dependencies
if (-not (Test-WinOpsKitDependencies -RequiredModules @('ActiveDirectory'))) {
    Write-Log "Warning: AD functions will be limited" -Level Warning
    # Continue anyway (graceful degradation)
}

# Main
function Backup-Server {
    param([string]$ServerName)
    
    $info = Get-SystemInfo -ComputerName $ServerName
    Write-Log "System info: $info" -Level Info
}
```

**Testing Dependencies (ADR-003 + ADR-009):**
```powershell
# tests/Get-SystemInfo.Tests.ps1

Describe "Get-SystemInfo with AD" {
    BeforeEach {
        # Mock external AD dependency
        Mock Get-ADComputer {
            return @{ Name = 'SRV01'; Enabled = $true }
        }
        
        # Mock User-Modul dependency
        Mock Get-UserInfo {
            return @{ Count = 5; Users = @() }
        }
    }
    
    It "returns system info with AD data" {
        $result = Get-SystemInfo -ComputerName 'SRV01' -IncludeADInfo
        $result.ADInfo.Name | Should -Be 'SRV01'
    }
}
```

**Related ADRs:**
- **ADR-002:** PowerShell-Version (Version Constraints)
- **ADR-003:** Testing Framework (Test-Mocking für Dependencies)
- **ADR-004:** Error Handling (Graceful Degradation)
- **ADR-005:** Logging Strategy (Dependency Logging)
- **ADR-008:** Modul-Import (Linear Hierarchy)
```
