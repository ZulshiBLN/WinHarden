# WinOpsKit – STRUCTURE.md

Projekt-spezifische Struktur- und Organisationsregeln für WinOpsKit.

---

## Verzeichnis-Hierarchie

```
WinOpsKit/
├── src/
│   └── WinOpsKit/
│       ├── WinOpsKit.psd1          (Manifest)
│       ├── WinOpsKit.psm1          (Root Module)
│       ├── Core/                   (Kernfunktionalität)
│       │   ├── Logging.ps1
│       │   ├── Config.ps1
│       │   └── Validation.ps1
│       ├── Public/                 (Exportierte Functions)
│       │   ├── System/
│       │   ├── Network/
│       │   ├── GPU/
│       │   └── Maintenance/
│       └── Private/                (Interne Helper)
│           ├── Utilities.ps1
│           ├── UI-Helpers.ps1
│           └── System-Helpers.ps1
├── tests/
│   └── Unit/
│       ├── Core/
│       ├── Public/
│       └── Private/
├── examples/
│   └── *.ps1                       (Beispiel-Skripte)
├── build/
│   └── build.ps1                   (Build-Skript)
├── docs/
│   └── *.md                        (Dokumentation)
├── CLAUDE.md
├── STRUCTURE.md
├── DECISIONS.md
└── .gitignore
```

---

## Naming Conventions

### PowerShell Functions

**Public Functions:**
- Format: `Verb-Noun` (PascalCase)
- Verb-Liste: [Microsoft Approved Verbs](https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands)
- Beispiele:
  - `Get-SystemInfo`
  - `Optimize-Performance`
  - `Invoke-Hardening`
  - `Test-NetworkDiagnostics`

**Private Functions:**
- Prefix: `_` oder `Private_`
- Beispiele:
  - `_ValidateInput`
  - `Private_GetRegistryValue`

### Dateien

**PowerShell Scripts:**
- Format: `Function-Name.ps1` (PascalCase mit Bindestrich)
- Beispiel: `Get-SystemInfo.ps1`

**Config/Data Files:**
- Format: `kebab-case.json` oder `kebab-case.ps1`
- Beispiele: `system-config.json`, `gpu-profiles.json`

**Test Files:**
- Format: `FileName.Tests.ps1`
- Beispiel: `Get-SystemInfo.Tests.ps1`

---

## Modul-Struktur

### 1. Modul-Manifest (WinOpsKit.psd1)

```powershell
@{
    ModuleVersion     = '1.0.0'
    Author            = 'Michel Brosche'
    RootModule        = 'WinOpsKit.psm1'
    FunctionsToExport = @()  # Wird via *.ps1 Discovery gefüllt
    VariablesToExport = @()
    AliasesToExport   = @()
    RequiredVersion   = '5.1'
    PowerShellVersion = '5.1'
}
```

### 2. Root Module (WinOpsKit.psm1)

**Aufgaben:**
- Lade Core-Module (Logging, Config, Validation)
- Lade alle Public/Private Functions
- Setze Module-Variablen (z.B. `$ModuleRoot`, `$Version`)
- Initialisiere Logging

**Struktur:**
```powershell
# Setze Module Root
$script:ModuleRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:Version = '1.0.0'

# Lade Core-Module
. "$ModuleRoot/Core/Logging.ps1"
. "$ModuleRoot/Core/Config.ps1"
. "$ModuleRoot/Core/Validation.ps1"

# Lade Public Functions
Get-ChildItem -Path "$ModuleRoot/Public" -Include '*.ps1' -Recurse | 
    ForEach-Object { . $_.FullName }

# Lade Private Functions
Get-ChildItem -Path "$ModuleRoot/Private" -Include '*.ps1' -Recurse | 
    ForEach-Object { . $_.FullName }
```

### 3. Core Module Files

**Logging.ps1:**
- `Write-Log` (Standard-Logging)
- `Write-LogInfo`, `Write-LogWarning`, `Write-LogError`
- Logging-Konfiguration (LogLevel, OutputPath)

**Config.ps1:**
- `Get-ModuleConfig`, `Set-ModuleConfig`
- Config-Dateien laden/speichern
- Environment-Variablen initialisieren

**Validation.ps1:**
- `Test-AdminPrivileges`
- `Test-OSCompatibility`
- `Test-RequiredModules`

---

## Function-Template

**Alle Public Functions folgen diesem Template:**

```powershell
function Get-ExampleFunction {
    <#
    .SYNOPSIS
        Kurze Beschreibung (1 Zeile)
    
    .DESCRIPTION
        Detaillierte Beschreibung
    
    .PARAMETER ParamName
        Parameter-Beschreibung
    
    .EXAMPLE
        Get-ExampleFunction -ParamName "Value"
    
    .NOTES
        Zusätzliche Notizen (falls nötig)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ParamName
    )

    begin {
        Write-Log -Level Info -Message "Function started: $($MyInvocation.MyCommand.Name)"
    }

    process {
        # Validierung
        if (-not (Test-AdminPrivileges)) {
            Write-LogError "Admin privileges required"
            return
        }

        # Logik
        try {
            # Code hier
            $result = "Success"
            Write-Log -Level Info -Message "Operation completed"
        }
        catch {
            Write-LogError "Error occurred: $_"
            return
        }
    }

    end {
        return $result
    }
}
```

---

## Import-Hierarchie

```
1. WinOpsKit.psd1 (Manifest)
   ↓
2. WinOpsKit.psm1 (Root Module)
   ├─→ Core/Logging.ps1
   ├─→ Core/Config.ps1
   ├─→ Core/Validation.ps1
   ├─→ Public/*.ps1 (rekursiv)
   └─→ Private/*.ps1 (rekursiv)

3. Import-Module WinOpsKit
   → Alle Public Functions sind verfügbar
   → Private Functions sind nur intern nutzbar
```

---

## Kategorien für Public Functions

### System
- `Get-SystemInfo`
- `Get-SystemHealth`
- `Invoke-WindowsHardening`
- `Optimize-AutostartConfiguration`

### Network
- `Test-NetworkDiagnostics`
- `Repair-NetworkStack`
- `Get-NetworkStatus`

### GPU
- `Get-GPUInfo`
- `Enable-AutoGameSwitch`
- `Invoke-OptimizeForGame`
- `Monitor-GPUPerformanceDashboard`

### Maintenance
- `Clear-SystemCaches`
- `Optimize-Disk`
- `Get-MaintenanceReport`

---

## Test-Struktur

**Unit Test Layout:**

```
tests/
├── Unit/
│   ├── Core/
│   │   ├── Logging.Tests.ps1
│   │   ├── Config.Tests.ps1
│   │   └── Validation.Tests.ps1
│   ├── Public/
│   │   ├── System/
│   │   │   └── Get-SystemInfo.Tests.ps1
│   │   ├── Network/
│   │   └── GPU/
│   └── Private/
│       └── Utilities.Tests.ps1
└── Integration/           (später)
    └── *.Tests.ps1
```

**Test-Template:**

```powershell
Describe "Get-SystemInfo" {
    BeforeAll {
        $ModulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\src\WinOpsKit"
        Import-Module "$ModulePath\WinOpsKit.psd1" -Force
    }

    Context "When called without parameters" {
        It "Should return system information" {
            $result = Get-SystemInfo
            $result | Should -Not -BeNullOrEmpty
        }
    }

    AfterAll {
        Remove-Module WinOpsKit -Force
    }
}
```

---

## Build-Prozess

**build.ps1 sollte folgende Schritte ausführen:**

```powershell
1. Syntax-Check (PSScriptAnalyzer)
2. Unit-Tests (Pester)
3. Manifest-Validierung
4. Code-Coverage-Report
5. Artifact-Erstellung (optional)
```

**Aufruf:**
```powershell
.\build\build.ps1 -Validate    # Nur Validierung
.\build\build.ps1 -Test        # Tests ausführen
.\build\build.ps1 -Full        # Komplett-Build
```

---

## Versionierung

**Format:** `MAJOR.MINOR.PATCH`
- **MAJOR:** Breaking Changes
- **MINOR:** New Features (backward-compatible)
- **PATCH:** Bugfixes

**Dateien zu aktualisieren:**
1. `src/WinOpsKit/WinOpsKit.psd1` → `ModuleVersion`
2. `WinOpsKit.psm1` → `$script:Version`
3. `CHANGELOG.md` → Neue Version dokumentieren

---

## Richtlinien für Module-Organisation

### ✅ DO:
- Jede Public Function in einer separaten Datei (`Function-Name.ps1`)
- Private Helpers gruppieren nach Funktionalität (`*-Helpers.ps1`)
- Core-Module zuerst laden (kein Circular Dependency)
- Test-Struktur spiegelt Source-Struktur

### ❌ DON'T:
- Mehrere Public Functions in einer Datei
- Private Functions in Public-Ordner
- Helper-Functions direkt in Hauptfunktion
- Circular Dependencies zwischen Modulen

---

## Nächste Schritte

- [ ] Verzeichnisstruktur erstellen (nach dieser STRUCTURE.md)
- [ ] WinOpsKit.psd1 und WinOpsKit.psm1 implementieren
- [ ] Core-Module (Logging, Config, Validation) erstellen
- [ ] Erste Public Functions nach Template
- [ ] Test-Framework initialisieren
- [ ] build.ps1 schreiben
