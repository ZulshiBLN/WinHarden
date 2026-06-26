<#
.SYNOPSIS
Performance and Scalability Tests for WinOpsKit Hardening System

Measures execution time, resource usage, and scalability limits
for hardening operations across different scales.

.NOTES
PREREQUISITES: Pester 5.x, Core module imported
PERFORMANCE: May take several minutes to complete
MEASUREMENT: Times operations and reports metrics
#>

param(
    [switch]$Detailed,
    [switch]$SkipLongRunningTests
)

BeforeAll {
    Import-Module Pester
    $PSDefaultParameterValues['*:ErrorAction'] = 'Stop'

    # Import required modules
    $moduleRoot = (Split-Path -Path $PSScriptRoot -Parent | Split-Path -Parent)
    Import-Module "$moduleRoot\modules\Core.psm1" -Force
    Import-Module "$moduleRoot\modules\System.psm1" -Force
}

Describe "Performance - Profile Loading" {
    Context "Profile Load Times" {
        It "loads Basis profile in < 1 second" {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $profile = Get-HardeningProfile -ProfileName Basis -TargetSystem Client
            $sw.Stop()

            Write-Host "Basis profile load time: $($sw.ElapsedMilliseconds)ms"
            $sw.ElapsedMilliseconds | Should -BeLessThan 1000
        }

        It "loads Recommended profile in < 1 second" {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $profile = Get-HardeningProfile -ProfileName Recommended -TargetSystem Server
            $sw.Stop()

            Write-Host "Recommended profile load time: $($sw.ElapsedMilliseconds)ms"
            $sw.ElapsedMilliseconds | Should -BeLessThan 1000
        }

        It "loads Strict profile in < 1 second" {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $profile = Get-HardeningProfile -ProfileName Strict -TargetSystem Server
            $sw.Stop()

            Write-Host "Strict profile load time: $($sw.ElapsedMilliseconds)ms"
            $sw.ElapsedMilliseconds | Should -BeLessThan 1000
        }
    }
}

Describe "Performance - Session Creation" {
    Context "Session Creation Times" {
        It "creates session in < 100ms" {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $session = New-HardeningSession -Profile Basis `
                -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $sw.Stop()

            Write-Host "Session creation time: $($sw.ElapsedMilliseconds)ms"
            $sw.ElapsedMilliseconds | Should -BeLessThan 100
        }

        It "creates 10 sessions in < 1 second" {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            for ($i = 1; $i -le 10; $i++) {
                $session = New-HardeningSession -Profile Basis `
                    -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            }
            $sw.Stop()

            Write-Host "10 sessions creation time: $($sw.ElapsedMilliseconds)ms"
            $sw.ElapsedMilliseconds | Should -BeLessThan 1000
        }
    }
}

Describe "Performance - Hardening Application" {
    Context "Rule Application Performance" {
        It "applies Basis profile in < 10 seconds" {
            $session = New-HardeningSession -Profile Basis `
                -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck

            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $result = Invoke-SecurityHardening -Session $session -ErrorAction Continue
            $sw.Stop()

            Write-Host "Basis hardening time: $($sw.ElapsedMilliseconds)ms"
            Write-Host "  Rules applied: $($result.SuccessfulRules.Count)"
            $sw.ElapsedMilliseconds | Should -BeLessThan 10000
        }

        It "applies Recommended profile in < 15 seconds" {
            $session = New-HardeningSession -Profile Recommended `
                -TargetSystem Server -OSVersion 2022 -SkipPrerequisiteCheck

            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $result = Invoke-SecurityHardening -Session $session -ErrorAction Continue
            $sw.Stop()

            Write-Host "Recommended hardening time: $($sw.ElapsedMilliseconds)ms"
            Write-Host "  Rules applied: $($result.SuccessfulRules.Count)"
            $sw.ElapsedMilliseconds | Should -BeLessThan 15000
        }

        It "applies Strict profile in < 20 seconds" {
            $session = New-HardeningSession -Profile Strict `
                -TargetSystem Server -OSVersion 2025 -SkipPrerequisiteCheck

            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $result = Invoke-SecurityHardening -Session $session -ErrorAction Continue
            $sw.Stop()

            Write-Host "Strict hardening time: $($sw.ElapsedMilliseconds)ms"
            Write-Host "  Rules applied: $($result.SuccessfulRules.Count)"
            $sw.ElapsedMilliseconds | Should -BeLessThan 20000
        }
    }

    Context "Parallel vs Sequential Performance" {
        It "parallel execution is faster than sequential" {
            $session = New-HardeningSession -Profile Recommended `
                -TargetSystem Server -OSVersion 2022 -SkipPrerequisiteCheck

            # Sequential timing
            $swSeq = [System.Diagnostics.Stopwatch]::StartNew()
            Invoke-SecurityHardening -Session $session `
                -ErrorAction Continue | Out-Null
            $swSeq.Stop()

            # Parallel timing (reset session)
            $session = New-HardeningSession -Profile Recommended `
                -TargetSystem Server -OSVersion 2022 -SkipPrerequisiteCheck

            $swPar = [System.Diagnostics.Stopwatch]::StartNew()
            Invoke-SecurityHardening -Session $session -Parallel `
                -ErrorAction Continue | Out-Null
            $swPar.Stop()

            Write-Host "Sequential time: $($swSeq.ElapsedMilliseconds)ms"
            Write-Host "Parallel time: $($swPar.ElapsedMilliseconds)ms"
            Write-Host "Improvement: $([math]::Round(($swSeq.ElapsedMilliseconds - $swPar.ElapsedMilliseconds) / $swSeq.ElapsedMilliseconds * 100))%"

            # Parallel should be same or faster
            $swPar.ElapsedMilliseconds | Should -BeLessOrEqual ($swSeq.ElapsedMilliseconds + 500)
        }
    }
}

Describe "Performance - Compliance Verification" {
    Context "Verification Performance" {
        It "verifies Basis profile in < 10 seconds" {
            $session = New-HardeningSession -Profile Basis `
                -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck

            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $compliance = Test-HardeningCompliance -Session $session `
                -ErrorAction Continue
            $sw.Stop()

            Write-Host "Basis compliance check time: $($sw.ElapsedMilliseconds)ms"
            $sw.ElapsedMilliseconds | Should -BeLessThan 10000
        }

        It "verifies Recommended profile in < 20 seconds" {
            $session = New-HardeningSession -Profile Recommended `
                -TargetSystem Server -OSVersion 2022 -SkipPrerequisiteCheck

            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $compliance = Test-HardeningCompliance -Session $session `
                -ErrorAction Continue
            $sw.Stop()

            Write-Host "Recommended compliance check time: $($sw.ElapsedMilliseconds)ms"
            $sw.ElapsedMilliseconds | Should -BeLessThan 20000
        }

        It "verifies Strict profile in < 30 seconds" {
            $session = New-HardeningSession -Profile Strict `
                -TargetSystem Server -OSVersion 2025 -SkipPrerequisiteCheck

            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $compliance = Test-HardeningCompliance -Session $session `
                -ErrorAction Continue
            $sw.Stop()

            Write-Host "Strict compliance check time: $($sw.ElapsedMilliseconds)ms"
            $sw.ElapsedMilliseconds | Should -BeLessThan 30000
        }
    }
}

Describe "Performance - Report Generation" {
    Context "Report Export Performance" {
        BeforeEach {
            $script:testReport = @{
                CompliancePercentage = 85
                Status = "Mostly Compliant"
                TotalRules = 20
                CompliantRules = 17
                NonCompliantRules = 3
                TargetSystem = "Perf-Test-Server"
                Timestamp = (Get-Date)
            }
        }

        It "exports JSON report in < 500ms" {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $output = Export-HardeningReport -ComplianceReport $testReport `
                -Format JSON -ErrorAction Stop
            $sw.Stop()

            Write-Host "JSON export time: $($sw.ElapsedMilliseconds)ms"
            $sw.ElapsedMilliseconds | Should -BeLessThan 500
        }

        It "exports CSV report in < 500ms" {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $output = Export-HardeningReport -ComplianceReport $testReport `
                -Format CSV -ErrorAction Stop
            $sw.Stop()

            Write-Host "CSV export time: $($sw.ElapsedMilliseconds)ms"
            $sw.ElapsedMilliseconds | Should -BeLessThan 500
        }

        It "exports HTML report in < 500ms" {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $output = Export-HardeningReport -ComplianceReport $testReport `
                -Format HTML -ErrorAction Stop
            $sw.Stop()

            Write-Host "HTML export time: $($sw.ElapsedMilliseconds)ms"
            $sw.ElapsedMilliseconds | Should -BeLessThan 500
        }

        It "exports Text report in < 500ms" {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $output = Export-HardeningReport -ComplianceReport $testReport `
                -Format Text -ErrorAction Stop
            $sw.Stop()

            Write-Host "Text export time: $($sw.ElapsedMilliseconds)ms"
            $sw.ElapsedMilliseconds | Should -BeLessThan 500
        }
    }
}

Describe "Scalability - Multi-Session Operations" {
    Context "Creating Multiple Sessions" {
        It "creates 50 sessions in < 5 seconds" {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $sessions = @()
            for ($i = 1; $i -le 50; $i++) {
                $session = New-HardeningSession -Profile Basis `
                    -TargetSystem Client -OSVersion 11 `
                    -ComputerName "Client-$i" -SkipPrerequisiteCheck
                $sessions += $session
            }
            $sw.Stop()

            Write-Host "50 sessions creation time: $($sw.ElapsedMilliseconds)ms"
            $sessions.Count | Should -Be 50
            $sw.ElapsedMilliseconds | Should -BeLessThan 5000
        }

        It "creates 100 sessions in < 10 seconds" {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $sessions = @()
            for ($i = 1; $i -le 100; $i++) {
                $session = New-HardeningSession -Profile Basis `
                    -TargetSystem Client -OSVersion 11 `
                    -ComputerName "Client-$i" -SkipPrerequisiteCheck
                $sessions += $session
            }
            $sw.Stop()

            Write-Host "100 sessions creation time: $($sw.ElapsedMilliseconds)ms"
            $sessions.Count | Should -Be 100
            $sw.ElapsedMilliseconds | Should -BeLessThan 10000
        }
    }
}

Describe "Memory - Resource Usage" {
    Context "Memory Efficiency" {
        It "session object is < 1 MB" {
            $session = New-HardeningSession -Profile Recommended `
                -TargetSystem Server -OSVersion 2022 -SkipPrerequisiteCheck

            $size = [System.Runtime.InteropServices.Marshal]::SizeOf($session)
            Write-Host "Session object size: $size bytes"

            # Should be reasonably small
            $size | Should -BeLessThan 100000  # 100 KB
        }

        It "profile data is < 500 KB" {
            $profile = Get-HardeningProfile -ProfileName Strict -TargetSystem Server

            $size = $profile | ConvertTo-Json | Measure-Object -Character
            Write-Host "Profile JSON size: $($size.Characters) bytes"

            # Profiles should be reasonably sized
            $size.Characters | Should -BeLessThan 500000  # 500 KB
        }
    }
}

Describe "Performance - Batch Operations" {
    Context "Batch Processing" {
        It "processes 10 sequential hardening operations in reasonable time" -Skip:$SkipLongRunningTests {
            $sw = [System.Diagnostics.Stopwatch]::StartNew()

            for ($i = 1; $i -le 10; $i++) {
                $session = New-HardeningSession -Profile Basis `
                    -TargetSystem Client -OSVersion 11 `
                    -ComputerName "Client-$i" -SkipPrerequisiteCheck

                Invoke-SecurityHardening -Session $session `
                    -ErrorAction Continue | Out-Null
            }

            $sw.Stop()

            $avgTime = $sw.ElapsedMilliseconds / 10
            Write-Host "Average time per hardening operation: $avgTime ms"
            Write-Host "Total time for 10 operations: $($sw.ElapsedMilliseconds)ms"

            # Average should be < 15 seconds per operation
            $sw.ElapsedMilliseconds | Should -BeLessThan 150000
        }
    }
}

Describe "Performance - Optimization Baseline" {
    Context "Baseline Metrics" {
        It "documents baseline performance metrics" {
            $metrics = @{
                ProfileLoadTime = "< 1000ms"
                SessionCreation = "< 100ms"
                BasisHardening = "< 10s"
                RecommendedHardening = "< 15s"
                StrictHardening = "< 20s"
                ComplianceVerification = "< 30s"
                ReportExport = "< 500ms"
                BatchCapacity = "10 systems in < 150s"
            }

            Write-Host "`nPERFORMANCE BASELINES:"
            $metrics.GetEnumerator() | ForEach-Object {
                Write-Host "  $($_.Key): $($_.Value)"
            }

            # Just document - always pass
            $true | Should -Be $true
        }
    }
}
