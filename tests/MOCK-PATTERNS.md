# WinHarden – Mock-Patterns für Unit-Tests

**Regelwerk-Referenz:** STRUCTURE.md Regel 4.4 (Pester Mock), ADR-003 (Testing Framework)

---

## Überblick

Mock-Objects isolieren Unit-Tests von externen Dependencies (APIs, Dateisystem, Registry, etc.). Sie sind **Pflicht** für Regelwerk-Konformität.

| Situation | Pattern | Vorher (❌) | Nachher (✅) |
|-----------|---------|------------|-----------|
| Test externe Funktion | `Mock` | Real function called (slow, fragile) | Mocked (fast, isolated) |
| Test mit File I/O | `Mock` + Fixture | Real file operations | Simulated I/O |
| Test mit Registry | `Mock` + InModuleScope | Real registry access (admin!) | Mocked access |
| Test mit Logging | `Mock Write-Log` | Real logs created | Captured in mock |

---

## 🔧 Pattern 1: Einfacher Mock (externe Dependencies)

**Situation:** Deine Funktion ruft `Write-Log` auf

```powershell
# ❌ FALSCH (Integration Test)
It "logs message when processing" {
    $result = Get-SystemInfo
    # Problem: Write-Log wird real aufgerufen, erzeugt Log-Datei
}

# ✅ RICHTIG (Unit Test mit Mock)
BeforeEach {
    Mock Write-Log -ParameterFilter { $true }  # Mock alle Write-Log Aufrufe
}

It "logs message when processing" {
    $result = Get-SystemInfo
    # Write-Log ist gemockt, keine echte Log-Datei
    Assert-MockCalled Write-Log -Times 1
}
```

**Warum:**
- Real: Tests sind langsam, erzeugen Datei-Artefakte, brauchen Permissions
- Mock: Tests sind schnell (~ms), saubere Isolation, reproduzierbar

---

## 🔧 Pattern 2: Mock mit Return-Value

**Situation:** Deine Funktion ruft `Get-HardeningProfile` auf und verarbeitet Result

```powershell
# Test Setup
BeforeEach {
    Mock Get-HardeningProfile {
        @{
            Profile = "Basis"
            Rules = @("Rule1", "Rule2")
            Version = "1.0"
        }
    }
}

It "processes profile correctly" {
    # Get-HardeningProfile gibt gemocktes Objekt zurück
    $result = Invoke-SecurityHardening -Profile Basis
    $result.Profile | Should -Be "Basis"
}
```

**Wichtig:** Mock muss gleiche Objektstruktur zurückgeben wie echte Funktion!

---

## 🔧 Pattern 3: Mock mit ParameterFilter

**Situation:** Funktion ruft `Write-Log` auf, aber nur in bestimmten Szenarien

```powershell
BeforeEach {
    # Mock nur Error-Level Logs
    Mock Write-Log -ParameterFilter {
        $Level -eq "Error"
    }
}

It "logs error on failure" {
    $function | Should -Throw
    Assert-MockCalled Write-Log -ParameterFilter { $Level -eq "Error" } -Times 1
}

It "does not log info in this test" {
    # Write-Log mit Level Info ist nicht gemockt
    # Diese Zeile würde echten Log-Aufruf machen
}
```

**ParameterFilter Syntax:**
```powershell
Mock Cmdlet-Name -ParameterFilter { $ParamName -eq "Value" }
Mock Cmdlet-Name -ParameterFilter { $Level -in @("Error", "Warning") }
Mock Cmdlet-Name -ParameterFilter { $Message -match "pattern" }
```

---

## 🔧 Pattern 4: Mock mit Assertion

**Situation:** Verify dass Funktion X mit bestimmten Parametern aufgerufen wurde

```powershell
BeforeEach {
    Mock Write-Log
    Mock New-LogFile
}

It "creates log file before writing" {
    Test-Compliance -Session $session
    
    # Verify order: New-LogFile wurde vor Write-Log aufgerufen
    Assert-MockCalled New-LogFile -Times 1
    Assert-MockCalled Write-Log -Times 1
}

It "writes correct message" {
    Test-Compliance -Session $session
    
    # Verify mit ParameterFilter
    Assert-MockCalled Write-Log -ParameterFilter {
        $Message -like "*Compliance*"
    } -Times 1
}
```

**Assert-MockCalled Syntax:**
```powershell
Assert-MockCalled Cmdlet-Name                                    # Called at least once
Assert-MockCalled Cmdlet-Name -Times 0                           # Never called
Assert-MockCalled Cmdlet-Name -Times 1                           # Called exactly once
Assert-MockCalled Cmdlet-Name -ParameterFilter { condition }     # With specific params
```

---

## 🔧 Pattern 5: Mock mit InModuleScope (Private Funktionen)

**Situation:** Test private Funktionen (`_PrivateHelper`)

```powershell
# BeforeAll: Load function
BeforeAll {
    $corePath = (Resolve-Path "$PSScriptRoot\..\modules\Core.psm1").Path
    Import-Module $corePath -Force
}

# Test private function inside module scope
It "validates input correctly" {
    InModuleScope Core {
        Mock Write-Log { }  # Mock wird INSIDE modul scope ausgeführt
        
        # Test _PrivateHelper
        _PrivateHelper -Name "Test" | Should -Not -BeNullOrEmpty
        Assert-MockCalled Write-Log -Times 1
    }
}
```

**Wann InModuleScope verwenden:**
- ✅ Private Funktionen testen (mit `_` Prefix)
- ✅ Modul-interne Mocks brauchen
- ❌ Nicht für public Funktionen (sie sind in Global scope)

---

## 🔧 Pattern 6: Fixture-Daten statt Mocks

**Situation:** Test braucht realistische Test-Daten (nicht gemockt, sondern aus JSON)

```powershell
# tests/fixtures/ComplianceReport-Basis.json
{
  "CompliancePercentage": 85,
  "Status": "Mostly Compliant",
  "TotalRules": 20,
  ...
}

# Test
BeforeAll {
    $script:basisReport = Get-Content "$PSScriptRoot\fixtures\ComplianceReport-Basis.json" | ConvertFrom-Json
}

It "exports Basis report" {
    $report = Export-HardeningReport -ComplianceReport $script:basisReport
    $report | Should -Not -BeNullOrEmpty
}
```

**Unterschied Mock vs Fixture:**
| Mock | Fixture |
|------|---------|
| Mocked Funktion, gemocktes Verhalten | Real Daten, aber aus Datei |
| `Mock Get-HardeningProfile { ... }` | `$data = Get-Content fixture.json` |
| Für Dependencies (Logging, API, etc.) | Für Test-Daten (Reports, Config, etc.) |
| Schnell, isoliert | Realistische Szenarien |

**Best Practice:** 
- Externe Dependencies mocken → Mock
- Test-Daten bereitstellen → Fixture

---

## 🔧 Pattern 7: Kombiniert - Mock + Fixture

**Situation:** Test externe Funktion, aber mit realistischen Test-Daten

```powershell
# BeforeAll
BeforeAll {
    # Mock dependency
    Mock Write-Log { }
    
    # Load fixture data
    $script:testReport = Get-Content "$PSScriptRoot\fixtures\Report.json" | ConvertFrom-Json
}

# Test
It "processes fixture data correctly" {
    # Use real test-data, mock external dependency
    $result = Export-HardeningReport -ComplianceReport $script:testReport -Format JSON
    
    $result | Should -Not -BeNullOrEmpty
    Assert-MockCalled Write-Log -Times 1
}
```

---

## ⚡ Häufige Fehler & Lösungen

### ❌ **Fehler 1: Mock wird nicht aufgerufen**

```powershell
# FALSCH
BeforeAll {
    Mock Write-Log { }  # Mock ist nur in BeforeAll sichtbar!
}

It "test" {
    # Mock ist hier nicht vorhanden!
    Function-That-Calls-WriteLog
}

# RICHTIG
BeforeEach {  # BeforeEach, nicht BeforeAll!
    Mock Write-Log { }
}

It "test" {
    Function-That-Calls-WriteLog
    Assert-MockCalled Write-Log -Times 1
}
```

**Grund:** `BeforeEach` runs vor jedem Test, `BeforeAll` nur einmal

---

### ❌ **Fehler 2: Mock wird überschrieben**

```powershell
# FALSCH
BeforeEach {
    Mock Write-Log { }  # Erste Mock
    Mock Write-Log { Write-Host "Override" }  # Überschreibt erste Mock
}

# RICHTIG
BeforeEach {
    Mock Write-Log {
        if ($Level -eq "Error") {
            # Handle Error
        }
        else {
            # Handle other levels
        }
    }
}
```

---

### ❌ **Fehler 3: False Positives mit Assert-MockCalled**

```powershell
# FALSCH
It "test" {
    Function-A
    Function-B
    
    Assert-MockCalled Write-Log -Times 2  # Beide Funktionen rufen auf?
}

# RICHTIG
It "test A" {
    Function-A
    Assert-MockCalled Write-Log -Times 1 -ParameterFilter { $Message -like "*A*" }
}

It "test B" {
    Function-B
    Assert-MockCalled Write-Log -Times 1 -ParameterFilter { $Message -like "*B*" }
}
```

**Grund:** Separate Tests, separate Assertions

---

### ❌ **Fehler 4: Mock mit falscher Rückgabedatenstruktur**

```powershell
# FALSCH
Mock Get-HardeningProfile {
    "Basis"  # Falscher Typ! Funktion erwartet Object
}

It "test" {
    $profile = Get-HardeningProfile
    $profile.Rules  # ERROR: String hat keine Rules-Eigenschaft!
}

# RICHTIG
Mock Get-HardeningProfile {
    [PSCustomObject]@{
        Profile = "Basis"
        Rules = @("Rule1", "Rule2")
        Version = "1.0"
    }
}

It "test" {
    $profile = Get-HardeningProfile
    $profile.Rules | Should -Contain "Rule1"  # OK!
}
```

---

## 📋 Checkliste für neue Tests

Verwende diese Checkliste beim Schreiben neuer Tests:

```powershell
# ✅ 1. Externe Dependencies mocken?
BeforeEach {
    Mock Write-Log { }
    Mock New-HardeningSession { }
    # etc.
}

# ✅ 2. Test-Daten als Fixtures (JSON)?
BeforeAll {
    $script:testData = Get-Content "$PSScriptRoot\fixtures\Data.json" | ConvertFrom-Json
}

# ✅ 3. Aussagekräftige Test-Namen?
It "processes valid report correctly" {
    # Good name, describes what's being tested
}

# ✅ 4. Assertions mit Mocks?
It "logs on error" {
    Function-Under-Test
    Assert-MockCalled Write-Log -Times 1
}

# ✅ 5. Cleanup nach Tests?
AfterEach {
    Remove-Item -Path $testFile -ErrorAction SilentlyContinue
}
```

---

## 🎯 Mock-Patterns pro Funktion

### **Logging Functions (Write-Log, Write-ErrorLog)**

```powershell
Mock Write-Log { }
Mock Write-ErrorLog { }

It "logs error on failure" {
    Function | Should -Throw
    Assert-MockCalled Write-Log -ParameterFilter { $Level -eq "Error" }
}
```

### **Session Functions (New-HardeningSession)**

```powershell
Mock New-HardeningSession {
    [PSCustomObject]@{
        Profile = "Basis"
        TargetSystem = "Client"
        SessionId = "TEST-001"
    }
}

It "creates session" {
    $session = New-HardeningSession -Profile Basis
    $session.Profile | Should -Be "Basis"
}
```

### **Compliance Functions (Test-HardeningCompliance)**

```powershell
# Use fixture instead of mock (data-heavy)
$script:compliance = @{
    CompliancePercentage = 85
    TotalRules = 20
    CompliantRules = 17
} | ConvertTo-Json | ConvertFrom-Json

It "processes compliance report" {
    Export-HardeningReport -ComplianceReport $script:compliance
}
```

### **File Operations (Get-Item, Out-File)**

```powershell
Mock Get-Item {
    [PSCustomObject]@{
        FullName = "C:\test.txt"
        Length = 1024
    }
}

Mock Out-File { }

It "saves file" {
    Export-Report -Path "C:\test.txt"
    Assert-MockCalled Out-File -Times 1
}
```

---

## 📚 Weitere Ressourcen

- **Pester Docs:** https://pester.dev/docs/usage/mocking
- **STRUCTURE.md:** Regel 4.4 (Mock requirement)
- **ADR-003:** Testing Framework details
- **Export-HardeningReport.Tests.ps1:** Praktisches Beispiel

---

## ✅ Regelwerk-Konformität

Diese Patterns erfüllen:
- ✅ STRUCTURE.md Regel 4.4 - Pester Mock für externe Dependencies
- ✅ STRUCTURE.md Regel 4.6 - Test-Fixtures in `tests/fixtures/`
- ✅ STRUCTURE.md Regel 4.7 - Test-Struktur mit Describe/Context/It
- ✅ ADR-003 - Testing Framework (Pester 5.x)
- ✅ CLAUDE.md Regel 3.2 - Keine Über-Abstraktionen

---

**Zuletzt aktualisiert:** 2026-06-26  
**Autor:** Claude Code  
**Status:** Dokumentation für Entwickler-Referenz
