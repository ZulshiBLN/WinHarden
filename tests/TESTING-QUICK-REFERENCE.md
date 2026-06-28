# WinHarden – Testing Quick Reference

**Für schnelle Lookups während Test-Entwicklung.**

---

## 🚀 Schnellstart (Copy-Paste Template)

```powershell
BeforeAll {
    # 1. Load module/function
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\Core.psm1").Path
    Import-Module $modulePath -Force
    
    # 2. Load fixtures
    $script:testData = Get-Content "$PSScriptRoot\fixtures\TestData.json" | ConvertFrom-Json
}

AfterAll {
    Remove-Module Core -Force -ErrorAction SilentlyContinue
}

Describe "Function-Under-Test" {
    Context "Happy Path" {
        BeforeEach {
            Mock Write-Log { }              # Mock external dependencies
            Mock Get-HardeningProfile { @{ Profile = "Test"; Rules = @() } }
        }
        
        It "returns correct result" {
            $result = Function-Under-Test -Param $script:testData
            $result | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Error Handling" {
        BeforeEach {
            Mock Write-Log { }
            Mock Write-ErrorLog { }
        }
        
        It "throws on invalid input" {
            { Function-Under-Test -Param $null } | Should -Throw
        }
        
        It "logs error on failure" {
            try { Function-Under-Test -Param $invalid } catch { }
            Assert-MockCalled Write-ErrorLog -Times 1
        }
    }
}
```

---

## 📋 Assertion Cheat Sheet

| Assertion | Beispiel | Wann nutzen |
|-----------|----------|-----------|
| `Should -Be` | `$result | Should -Be "Expected"` | Exact match |
| `Should -Throw` | `{ $function } | Should -Throw` | Exception expected |
| `Should -Match` | `$result | Should -Match "pattern"` | Regex match |
| `Should -Contain` | `$array | Should -Contain "value"` | Array member |
| `Should -Not -BeNullOrEmpty` | `$result | Should -Not -BeNullOrEmpty` | Has value |
| `Should -HaveProperty` | `$obj | Should -HaveProperty "Name"` | Object property exists |
| `Should -Exist` | `"C:\file.txt" | Should -Exist` | File exists |
| `Should -BeGreaterThan` | `$num \| Should -BeGreaterThan 5` | Numeric comparison |

---

## 🎯 Mock Cheat Sheet

| Pattern | Syntax | Beispiel |
|---------|--------|----------|
| **Simple Mock** | `Mock Cmdlet-Name { }` | `Mock Write-Log { }` |
| **Return Value** | `Mock Cmd { @{ key = "value" } }` | `Mock Get-Item { [PSCustomObject]@{ Name = "Test" } }` |
| **Parameter Filter** | `Mock Cmd -ParameterFilter { $param -eq "val" }` | `Mock Write-Log -ParameterFilter { $Level -eq "Error" }` |
| **Multiple Calls** | `Mock Cmd { if ($x) {...} else {...} }` | `Mock Cmd { if ($1) { "A" } else { "B" } }` |
| **Assertion** | `Assert-MockCalled Cmd -Times N` | `Assert-MockCalled Write-Log -Times 1` |
| **Assert Filter** | `Assert-MockCalled Cmd -ParameterFilter { ... }` | `Assert-MockCalled Write-Log -ParameterFilter { $Level -eq "Error" } -Times 1` |

---

## 📁 File Structure

```
tests/
├── MyFunction.Tests.ps1          # Test file (one per function)
├── fixtures/                      # Test data (JSON, CSV)
│   ├── TestData-Valid.json
│   ├── TestData-Invalid.json
│   └── ComplianceReport-Basis.json
├── MOCK-PATTERNS.md              # This guide
└── TESTING-QUICK-REFERENCE.md    # This file
```

---

## ⚡ Common Patterns

### Pattern: Test Logging

```powershell
BeforeEach {
    Mock Write-Log { }
}

It "logs on success" {
    Function-Under-Test
    Assert-MockCalled Write-Log -ParameterFilter {
        $Message -like "*Success*" -and $Level -eq "Info"
    }
}
```

### Pattern: Test File Operations

```powershell
BeforeEach {
    Mock Test-Path { $true }
    Mock Get-Content { "test content" }
}

It "reads file" {
    $content = Read-ConfigFile -Path "C:\config.json"
    $content | Should -Be "test content"
    Assert-MockCalled Get-Content -Times 1
}
```

### Pattern: Test Exceptions

```powershell
It "throws on error" {
    { Risky-Function -Param $invalid } | Should -Throw -ExpectedMessage "*specific error*"
}

It "logs error before throwing" {
    Mock Write-ErrorLog { }
    { Risky-Function -Param $invalid } | Should -Throw
    Assert-MockCalled Write-ErrorLog -Times 1
}
```

### Pattern: Test with Fixtures

```powershell
BeforeAll {
    $script:data = Get-Content "$PSScriptRoot\fixtures\Data.json" | ConvertFrom-Json
}

It "processes fixture data" {
    $result = Process-Data -Data $script:data
    $result.Status | Should -Be "Success"
}
```

---

## 🛠️ Debugging Failed Tests

| Problem | Lösung |
|---------|--------|
| Mock wird nicht aufgerufen | Checke Mock placement: `BeforeEach` (nicht `BeforeAll`) |
| "Assert-MockCalled: Expected was $true, but got $false" | Mock wurde nicht aufgerufen - check Parametername |
| Test braucht Admin-Rechte | Mock externe Dependencies statt echte Ops |
| "Parameter set cannot be resolved" | Check alle Parameter - falsche Flags oder Typen |
| Fixture-Daten nicht geladen | Check Pfad: `"$PSScriptRoot\fixtures\file.json"` |

---

## ✅ Pre-Commit Checklist

Vor `git commit` überprüfen:

- [ ] Alle externen Dependencies gemockt?
- [ ] Test-Daten in `fixtures/` ausgelagert?
- [ ] Aussagekräftige Test-Namen?
- [ ] Coverage-Statements vorhanden?
- [ ] No hardcoded Pfade (verwende `$PSScriptRoot`)?
- [ ] PSScriptAnalyzer: `Invoke-ScriptAnalyzer -Path tests/MyTest.Tests.ps1`?
- [ ] Tests laufen: `Invoke-Pester tests/MyFunction.Tests.ps1`?

---

## 🔗 References

- **MOCK-PATTERNS.md** - Detailed mock guide
- **STRUCTURE.md** - Regel 4.4 (Mock requirement)
- **ADR-003** - Testing framework decision
- **Export-HardeningReport.Tests.ps1** - Praktisches Beispiel

---

## 💡 Pro-Tipps

1. **Fixtures versionieren:** Speichere Test-Daten in Git (JSON/CSV in `fixtures/`)
2. **Mocks isolieren:** Ein Mock pro Context, nicht global in BeforeAll
3. **Aussagekräftige Mocks:** Mock Return-Value sollte echte Funktion nachahmen
4. **BeforeEach nicht BeforeAll:** Mocks in BeforeEach, sonst beeinflussen sie sich
5. **Assert spezifisch:** Mit ParameterFilter arbeiten für präzise Checks

---

**Zuletzt aktualisiert:** 2026-06-26  
**Für schnelle Referenz bei Test-Entwicklung nutzen.**
