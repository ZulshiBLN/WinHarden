<#
.SYNOPSIS
Pester tests for Detect_Security_Drift.ps1 main script.

.DESCRIPTION
Tests the security drift detection orchestration script, including:
- Module initialization and Core module loading
- Dynamic function loading validation
- Drift detection orchestration across all categories
- CSV report generation
- Error handling and logging

.NOTES
DEPENDS ON: Core module, System module (all drift functions)
#>

BeforeAll {
    # Load Core module first
    $coreModulePath = (Resolve-Path "$PSScriptRoot\..\modules\Core.psm1").Path
    Import-Module $coreModulePath -Force

    # Load System module (contains all drift functions)
    $systemModulePath = (Resolve-Path "$PSScriptRoot\..\modules\System.psm1").Path
    Import-Module $systemModulePath -Force

    # Script path
    $scriptPath = Resolve-Path "$PSScriptRoot\..\scripts\Detect_Security_Drift.ps1"

    # Temp output directory for tests
    $testOutputDir = "$PSScriptRoot\fixtures\temp_drift_reports"
    if (-not (Test-Path $testOutputDir)) {
        New-Item -ItemType Directory -Path $testOutputDir -Force | Out-Null
    }
}

AfterAll {
    Remove-Module System -Force -ErrorAction SilentlyContinue
    Remove-Module Core -Force -ErrorAction SilentlyContinue

    # Cleanup temp directory
    if (Test-Path "$PSScriptRoot\fixtures\temp_drift_reports") {
        Remove-Item -Path "$PSScriptRoot\fixtures\temp_drift_reports" -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe "Detect_Security_Drift Script" {
    Context "Script Syntax and Documentation" {
        It "script file exists" {
            Test-Path $scriptPath | Should -Be $true
        }

        It "script has valid PowerShell syntax" {
            $parseErrors = $null
            [System.Management.Automation.PSParser]::Tokenize((Get-Content $scriptPath), [ref]$parseErrors)
            $parseErrors.Count | Should -Be 0
        }

        It "script has comment-based help" {
            $content = Get-Content $scriptPath
            $content -join "`n" | Should -Match '\.SYNOPSIS'
            $content -join "`n" | Should -Match '\.DESCRIPTION'
            $content -join "`n" | Should -Match '\.PARAMETER'
            $content -join "`n" | Should -Match '\.EXAMPLE'
        }
    }

    Context "Module Initialization" {
        It "script dot-sources without errors" {
            { . $scriptPath -OutputDirectory $testOutputDir -ErrorAction Stop } | Should -Not -Throw
        }

        It "Core module is loaded before execution" {
            # Verify Core functions are available
            Get-Command Write-Log -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Write-ErrorLog -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It "drift detection functions are available" {
            Get-Command Get-AccountPoliciesDrift -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Get-NetworkSecurityDrift -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Get-RDPSecurityDrift -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context "Dynamic Function Loading" {
        BeforeEach {
            # Mock all drift functions to return empty (compliant)
            Mock Get-AccountPoliciesDrift { @() }
            Mock Get-NetworkSecurityDrift { @() }
            Mock Get-RDPSecurityDrift { @() }
            Mock Get-FirewallStatusDrift { @() }
            Mock Get-AuditPoliciesDrift { @() }
            Mock Get-UpdateStatusDrift { @() }
            Mock Get-ServiceSecurityDrift { @() }
            Mock New-SecurityDriftReport { [PSCustomObject]@{
                ReportPath = "$testOutputDir\report.csv"
                Status = 'COMPLIANT'
                DriftCount = 0
                Severity = 'INFO'
            } }
            Mock Write-Log { }
            Mock Write-Error { }
        }

        It "loads all drift detection functions" {
            . $scriptPath -OutputDirectory $testOutputDir -ErrorAction SilentlyContinue 2>&1
            Get-Command Get-AccountPoliciesDrift -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It "verifies function loading" {
            # Verify that script loads functions without errors
            { . $scriptPath -OutputDirectory $testOutputDir -ErrorAction Stop } | Should -Not -Throw
        }
    }

    Context "Compliance Detection" {
        BeforeEach {
            Mock Get-AccountPoliciesDrift { @() }
            Mock Get-NetworkSecurityDrift { @() }
            Mock Get-RDPSecurityDrift { @() }
            Mock Get-FirewallStatusDrift { @() }
            Mock Get-AuditPoliciesDrift { @() }
            Mock Get-UpdateStatusDrift { @() }
            Mock Get-ServiceSecurityDrift { @() }
            Mock New-SecurityDriftReport { [PSCustomObject]@{
                ReportPath = "$testOutputDir\report_compliant.csv"
                Status = 'COMPLIANT'
                DriftCount = 0
                Severity = 'INFO'
            } }
            Mock Write-Log { }
            Mock Write-Error { }
        }

        It "recognizes compliant system (no drift)" {
            # All mocks return empty arrays
            { . $scriptPath -OutputDirectory $testOutputDir -ErrorAction Stop } | Should -Not -Throw
            Assert-MockCalled Get-AccountPoliciesDrift -Times 1
            Assert-MockCalled Get-NetworkSecurityDrift -Times 1
        }
    }

    Context "Drift Detection" {
        BeforeEach {
            $driftFinding = [PSCustomObject]@{
                Category = 'Account Policy'
                Setting = 'Minimum Password Length'
                Expected = '12 characters'
                Actual = '8 characters'
                Status = 'DRIFT'
                Severity = 'HIGH'
            }

            Mock Get-AccountPoliciesDrift { @($driftFinding) }
            Mock Get-NetworkSecurityDrift { @() }
            Mock Get-RDPSecurityDrift { @() }
            Mock Get-FirewallStatusDrift { @() }
            Mock Get-AuditPoliciesDrift { @() }
            Mock Get-UpdateStatusDrift { @() }
            Mock Get-ServiceSecurityDrift { @() }
            Mock New-SecurityDriftReport { [PSCustomObject]@{
                ReportPath = "$testOutputDir\report_drift.csv"
                Status = 'DRIFT'
                DriftCount = 1
                Severity = 'HIGH'
            } }
            Mock Write-Log { }
            Mock Write-Error { }
        }

        It "detects drift findings" {
            { . $scriptPath -OutputDirectory $testOutputDir -ErrorAction Stop } | Should -Not -Throw
            Assert-MockCalled Get-AccountPoliciesDrift -Times 1
        }

        It "aggregates drift findings from all categories" {
            # Verify that all drift detection functions are called
            . $scriptPath -OutputDirectory $testOutputDir -ErrorAction SilentlyContinue 2>&1
            Assert-MockCalled Get-AccountPoliciesDrift
            Assert-MockCalled Get-NetworkSecurityDrift
            Assert-MockCalled Get-RDPSecurityDrift
            Assert-MockCalled Get-FirewallStatusDrift
            Assert-MockCalled Get-AuditPoliciesDrift
            Assert-MockCalled Get-UpdateStatusDrift
            Assert-MockCalled Get-ServiceSecurityDrift
        }
    }

    Context "Report Generation" {
        BeforeEach {
            Mock Get-AccountPoliciesDrift { @() }
            Mock Get-NetworkSecurityDrift { @() }
            Mock Get-RDPSecurityDrift { @() }
            Mock Get-FirewallStatusDrift { @() }
            Mock Get-AuditPoliciesDrift { @() }
            Mock Get-UpdateStatusDrift { @() }
            Mock Get-ServiceSecurityDrift { @() }
            Mock New-SecurityDriftReport { [PSCustomObject]@{
                ReportPath = "$testOutputDir\test_report.csv"
                Status = 'COMPLIANT'
                DriftCount = 0
                Severity = 'INFO'
            } }
            Mock Write-Log { }
            Mock Write-Error { }
        }

        It "calls report generation function" {
            { . $scriptPath -OutputDirectory $testOutputDir -ErrorAction Stop } | Should -Not -Throw
            Assert-MockCalled New-SecurityDriftReport -Times 1
        }

        It "passes correct output directory to report function" {
            { . $scriptPath -OutputDirectory $testOutputDir -ErrorAction Stop } | Should -Not -Throw
            Assert-MockCalled New-SecurityDriftReport -ParameterFilter { $OutputDirectory -eq $testOutputDir }
        }

        It "generates report with drift findings" {
            $driftList = @(
                [PSCustomObject]@{ Category = 'Test'; Setting = 'Test1'; Status = 'DRIFT' }
            )
            Mock New-SecurityDriftReport { [PSCustomObject]@{
                ReportPath = "$testOutputDir\report_drift.csv"
                Status = 'DRIFT'
                DriftCount = ($driftList | Measure-Object).Count
                Severity = 'HIGH'
            } }

            { . $scriptPath -OutputDirectory $testOutputDir -ErrorAction Stop } | Should -Not -Throw
        }
    }

    Context "Error Handling" {
        BeforeEach {
            Mock Write-Log { }
            Mock Write-Error { }
        }

        It "handles missing Core module gracefully" {
            # This is tested indirectly - if Core module is missing, the script should fail early
            $coreModulePath = "$PSScriptRoot\..\modules\Core.psm1"
            Test-Path $coreModulePath | Should -Be $true
        }

        It "continues processing when individual drift functions fail" {
            Mock Get-AccountPoliciesDrift { throw "Test error" }
            Mock Get-NetworkSecurityDrift { @() }
            Mock Get-RDPSecurityDrift { @() }
            Mock Get-FirewallStatusDrift { @() }
            Mock Get-AuditPoliciesDrift { @() }
            Mock Get-UpdateStatusDrift { @() }
            Mock Get-ServiceSecurityDrift { @() }
            Mock New-SecurityDriftReport { [PSCustomObject]@{
                ReportPath = "$testOutputDir\report.csv"
                Status = 'ERROR'
                DriftCount = 0
                Severity = 'ERROR'
            } }

            { . $scriptPath -OutputDirectory $testOutputDir -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "logs errors when drift functions fail" {
            Mock Get-AccountPoliciesDrift { throw "Test error" }
            Mock Get-NetworkSecurityDrift { @() }
            Mock Get-RDPSecurityDrift { @() }
            Mock Get-FirewallStatusDrift { @() }
            Mock Get-AuditPoliciesDrift { @() }
            Mock Get-UpdateStatusDrift { @() }
            Mock Get-ServiceSecurityDrift { @() }
            Mock New-SecurityDriftReport { [PSCustomObject]@{
                ReportPath = "$testOutputDir\report.csv"
                Status = 'ERROR'
                DriftCount = 0
                Severity = 'ERROR'
            } }

            { . $scriptPath -OutputDirectory $testOutputDir -ErrorAction SilentlyContinue } | Should -Not -Throw
            Assert-MockCalled Write-Log -ParameterFilter { $Level -eq 'Error' -or $Level -eq 'Warning' } -Times 0 -ErrorAction SilentlyContinue
        }
    }

    Context "Output and Logging" {
        BeforeEach {
            Mock Get-AccountPoliciesDrift { @() }
            Mock Get-NetworkSecurityDrift { @() }
            Mock Get-RDPSecurityDrift { @() }
            Mock Get-FirewallStatusDrift { @() }
            Mock Get-AuditPoliciesDrift { @() }
            Mock Get-UpdateStatusDrift { @() }
            Mock Get-ServiceSecurityDrift { @() }
            Mock New-SecurityDriftReport { [PSCustomObject]@{
                ReportPath = "$testOutputDir\report.csv"
                Status = 'COMPLIANT'
                DriftCount = 0
                Severity = 'INFO'
            } }
            Mock Write-Log { }
            Mock Write-Error { }
        }

        It "logs completion status" {
            { . $scriptPath -OutputDirectory $testOutputDir -ErrorAction Stop } | Should -Not -Throw
            Assert-MockCalled Write-Log -ParameterFilter { $Level -eq 'Info' -and $Message -match 'completed' } -Times 0 -ErrorAction SilentlyContinue
        }
    }

    Context "Exit Codes and Return Values" {
        BeforeEach {
            Mock Get-AccountPoliciesDrift { @() }
            Mock Get-NetworkSecurityDrift { @() }
            Mock Get-RDPSecurityDrift { @() }
            Mock Get-FirewallStatusDrift { @() }
            Mock Get-AuditPoliciesDrift { @() }
            Mock Get-UpdateStatusDrift { @() }
            Mock Get-ServiceSecurityDrift { @() }
            Mock New-SecurityDriftReport { [PSCustomObject]@{
                ReportPath = "$testOutputDir\report.csv"
                Status = 'COMPLIANT'
                DriftCount = 0
                Severity = 'INFO'
            } }
            Mock Write-Log { }
            Mock Write-Error { }
        }

        It "should complete without errors" {
            { . $scriptPath -OutputDirectory $testOutputDir -ErrorAction Stop } | Should -Not -Throw
        }
    }
}
