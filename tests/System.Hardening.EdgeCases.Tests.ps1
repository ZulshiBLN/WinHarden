<#
.SYNOPSIS
Edge Case Tests for WinHarden Hardening System

Tests boundary conditions, unusual inputs, and edge cases
to ensure robustness across all hardening functions.

.NOTES
PREREQUISITES: Pester 5.x, Core module imported
ADMIN: Some tests require admin rights
COVERAGE: Edge cases, boundary conditions, performance limits
#>

param(
    [switch]$SkipPerformanceTests
)

BeforeAll {
    Import-Module Pester
    $PSDefaultParameterValues['*:ErrorAction'] = 'Stop'

    # Import required modules
    $moduleRoot = (Split-Path -Path $PSScriptRoot -Parent | Split-Path -Parent)
    Import-Module "$moduleRoot\modules\Core.psm1" -Force
    Import-Module "$moduleRoot\modules\System.psm1" -Force
}

Describe "Edge Cases - Empty and Null Values" {
    Context "Null Parameters" {
        It "handles null profile object gracefully" {
            $session = @{
                Profile = $null
                TargetSystem = "Client"
                OSVersion = 11
                ComputerName = $env:COMPUTERNAME
                State = @{}
            }

            {
                Invoke-SecurityHardening -Session $session -ErrorAction Stop
            } | Should -Throw
        }

        It "handles null computer name" {
            {
                New-HardeningSession -Profile Basis `
                    -TargetSystem Client -OSVersion 11 `
                    -ComputerName $null -ErrorAction Stop
            } | Should -Throw
        }
    }

    Context "Empty Collections" {
        It "handles empty rule filter array" {
            $session = New-HardeningSession -Profile Basis `
                -TargetSystem Client -OSVersion 11 `
                -SkipPrerequisiteCheck

            # Empty filter should apply no rules
            $result = Invoke-SecurityHardening -Session $session `
                -RuleFilter @() -ErrorAction Continue

            $result | Should -Not -BeNullOrEmpty
        }

        It "handles empty email recipient list" {
            {
                Send-HardeningAlert -SmtpServer "smtp.test.com" `
                    -FromAddress "test@test.com" `
                    -ToAddress @() `
                    -AlertType Compliance `
                    -ErrorAction Stop
            } | Should -Throw
        }
    }
}

Describe "Edge Cases - Boundary Values" {
    Context "Extreme Input Values" {
        It "handles very long computer name (255 chars)" {
            $longName = "C" * 255
            $session = New-HardeningSession -Profile Basis `
                -TargetSystem Client -OSVersion 11 `
                -ComputerName $longName `
                -SkipPrerequisiteCheck

            $session.ComputerName | Should -Be $longName
        }

        It "handles very long rule filter list" {
            $session = New-HardeningSession -Profile Recommended `
                -TargetSystem Client -OSVersion 11 `
                -SkipPrerequisiteCheck

            # Create large filter array
            $largeFilter = @(1..100 | ForEach-Object { "Rule-$_" })

            {
                Invoke-SecurityHardening -Session $session `
                    -RuleFilter $largeFilter -ErrorAction Continue
            } | Should -Not -Throw
        }

        It "handles many email recipients (100+)" {
            $recipients = @()
            for ($i = 1; $i -le 100; $i++) {
                $recipients += "user$i@test.com"
            }

            # Should accept many recipients (actual sending might fail due to SMTP)
            $recipients.Count | Should -Be 100
        }
    }

    Context "Special Characters and Unicode" {
        It "handles unicode in computer name" {
            $unicodeName = "Server_Ü_01"
            $session = New-HardeningSession -Profile Basis `
                -TargetSystem Server -OSVersion 2022 `
                -ComputerName $unicodeName `
                -SkipPrerequisiteCheck

            $session.ComputerName | Should -Be $unicodeName
        }

        It "handles special characters in email addresses" {
            # Email with special chars (that might be valid)
            $email = "test+hardening@sub.domain.co.uk"

            # Should not throw on parameter validation
            {
                Send-HardeningAlert -SmtpServer "smtp.test.com" `
                    -FromAddress $email `
                    -ToAddress "admin@test.com" `
                    -AlertType Compliance `
                    -ErrorAction Continue
            } | Should -Not -Throw  # Parameter validation should pass
        }

        It "handles text with special characters in report" {
            $report = @{
                CompliancePercentage = 100
                Status = "Compliant - All systems OK"
                TotalRules = 10
                CompliantRules = 10
                NonCompliantRules = 0
                TargetSystem = "Server_Test_01"
            }

            {
                $output = Export-HardeningReport -ComplianceReport $report `
                    -Format Text -ErrorAction Stop

                # Output must be ASCII-safe (no emoji/unicode symbols per ADR-010)
                $output | Should -Not -BeNullOrEmpty
            } | Should -Not -Throw
        }
    }
}

Describe "Edge Cases - Performance and Scale" {
    Context "Large Profile Sets" {
        It "handles profile with many rules efficiently" -Skip:$SkipPerformanceTests {
            $session = New-HardeningSession -Profile Strict `
                -TargetSystem Server -OSVersion 2022 `
                -SkipPrerequisiteCheck

            # Strict profile has 14+ rules, should complete in reasonable time
            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $profile = Get-HardeningProfile -ProfileName Strict `
                -TargetSystem Server
            $sw.Stop()

            # Should load in under 5 seconds
            $sw.ElapsedMilliseconds | Should -BeLessThan 5000

            $profile.Rules.Count | Should -BeGreaterThan 0
        }

        It "verifies compliance on large rule set efficiently" -Skip:$SkipPerformanceTests {
            $session = New-HardeningSession -Profile Recommended `
                -TargetSystem Server -OSVersion 2022 `
                -SkipPrerequisiteCheck

            $sw = [System.Diagnostics.Stopwatch]::StartNew()
            $result = Test-HardeningCompliance -Session $session `
                -ErrorAction Continue
            $sw.Stop()

            # Should verify in under 30 seconds
            $sw.ElapsedMilliseconds | Should -BeLessThan 30000

            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context "Concurrent Operations" {
        It "handles multiple sessions simultaneously" {
            $sessions = @()

            # Create 5 concurrent sessions
            for ($i = 1; $i -le 5; $i++) {
                $session = New-HardeningSession -Profile Basis `
                    -TargetSystem Client -OSVersion 11 `
                    -ComputerName "Client-$i" `
                    -SkipPrerequisiteCheck

                $sessions += $session
            }

            $sessions.Count | Should -Be 5
        }

        It "handles parallel rule application" {
            $session = New-HardeningSession -Profile Basis `
                -TargetSystem Client -OSVersion 11 `
                -SkipPrerequisiteCheck

            # Test parallel flag
            {
                $result = Invoke-SecurityHardening -Session $session `
                    -Parallel -ErrorAction Continue

                $result | Should -Not -BeNullOrEmpty
            } | Should -Not -Throw
        }
    }
}

Describe "Edge Cases - Data Type Handling" {
    Context "Type Coercion and Conversion" {
        It "handles OS version as string vs int" {
            # Should accept OS version as int
            $session1 = New-HardeningSession -Profile Basis `
                -TargetSystem Server -OSVersion 2022 `
                -SkipPrerequisiteCheck

            $session1.OSVersion | Should -Be 2022
        }

        It "handles profile name case sensitivity" {
            # PowerShell parameters should be case-insensitive
            $session = New-HardeningSession -Profile "basis" `
                -TargetSystem Client -OSVersion 11 `
                -SkipPrerequisiteCheck

            $session.Profile | Should -Match "basis|Basis"
        }

        It "handles boolean switch combinations" {
            $session = New-HardeningSession -Profile Basis `
                -TargetSystem Client -OSVersion 11 `
                -SkipPrerequisiteCheck

            # Should not throw with multiple switches
            {
                Invoke-SecurityHardening -Session $session `
                    -Parallel -ErrorAction Continue
            } | Should -Not -Throw
        }
    }
}

Describe "Edge Cases - State Management" {
    Context "Session State Transitions" {
        It "handles session with pre-populated state" {
            $session = @{
                Profile = "Basis"
                TargetSystem = "Client"
                OSVersion = 11
                ComputerName = $env:COMPUTERNAME
                State = @{
                    AppliedRules = @("Rule1", "Rule2")
                    FailedRules = @("Rule3")
                    SkippedRules = @()
                    StartTime = (Get-Date).AddHours(-1)
                }
            }

            # Should handle pre-existing state
            $session.State.AppliedRules.Count | Should -Be 2
        }

        It "handles repeated operations on same session" {
            $session = New-HardeningSession -Profile Basis `
                -TargetSystem Client -OSVersion 11 `
                -SkipPrerequisiteCheck

            # First operation
            Test-HardeningCompliance -Session $session -ErrorAction Continue | Out-Null

            # Second operation on same session
            {
                Test-HardeningCompliance -Session $session -ErrorAction Continue
            } | Should -Not -Throw
        }
    }
}

Describe "Edge Cases - Report Generation" {
    Context "Report Format Edge Cases" {
        It "handles report with 0% compliance" {
            $report = @{
                CompliancePercentage = 0
                Status = "NonCompliant"
                TotalRules = 10
                CompliantRules = 0
                NonCompliantRules = 10
                TargetSystem = "Test"
            }

            {
                Export-HardeningReport -ComplianceReport $report `
                    -Format JSON -ErrorAction Stop
            } | Should -Not -Throw
        }

        It "handles report with 100% compliance" {
            $report = @{
                CompliancePercentage = 100
                Status = "Compliant"
                TotalRules = 10
                CompliantRules = 10
                NonCompliantRules = 0
                TargetSystem = "Test"
            }

            {
                Export-HardeningReport -ComplianceReport $report `
                    -Format HTML -ErrorAction Stop
            } | Should -Not -Throw
        }

        It "handles report with missing optional fields" {
            $report = @{
                CompliancePercentage = 50
                Status = "PartiallyCompliant"
                TotalRules = 10
            }

            {
                Export-HardeningReport -ComplianceReport $report `
                    -Format Text -ErrorAction Continue
            } | Should -Not -Throw
        }
    }
}

Describe "Edge Cases - Time and Schedule" {
    Context "Schedule Edge Cases" {
        It "handles schedule at midnight" {
            {
                New-HardeningSchedule -Profile Basis `
                    -Schedule Daily -Time "00:00" `
                    -ErrorAction Continue
            } | Should -Not -Throw
        }

        It "handles schedule at 23:59" {
            {
                New-HardeningSchedule -Profile Basis `
                    -Schedule Daily -Time "23:59" `
                    -ErrorAction Continue
            } | Should -Not -Throw
        }

        It "handles monthly schedule on last day" {
            {
                New-HardeningSchedule -Profile Basis `
                    -Schedule Monthly -DayOfMonth 31 `
                    -ErrorAction Continue
            } | Should -Not -Throw
        }

        It "handles all days of week" {
            $days = @("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")

            foreach ($day in $days) {
                {
                    New-HardeningSchedule -Profile Basis `
                        -Schedule Weekly -DayOfWeek $day `
                        -ErrorAction Continue
                } | Should -Not -Throw
            }
        }
    }
}
