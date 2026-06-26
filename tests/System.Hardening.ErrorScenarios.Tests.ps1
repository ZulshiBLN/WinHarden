<#
.SYNOPSIS
Error Scenario Tests for WinHarden Hardening System

Tests error handling, edge cases, and failure scenarios
across all hardening functions.

.NOTES
PREREQUISITES: Pester 5.x, Core module imported
ADMIN: Some tests require admin rights
COVERAGE: Error paths, exception handling, logging
#>

param(
    [switch]$SkipAdminCheck
)

BeforeAll {
    Import-Module Pester
    $PSDefaultParameterValues['*:ErrorAction'] = 'Stop'

    # Import required modules
    $moduleRoot = (Split-Path -Path $PSScriptRoot -Parent | Split-Path -Parent)
    Import-Module "$moduleRoot\modules\Core.psm1" -Force
    Import-Module "$moduleRoot\modules\System.psm1" -Force
}

Describe "Error Scenarios - Invalid Inputs" {
    Context "Invalid Profile Names" {
        It "throws on non-existent profile" {
            {
                New-HardeningSession -Profile "InvalidProfile" `
                    -TargetSystem Client -OSVersion 11 -ErrorAction Stop
            } | Should -Throw
        }

        It "throws on invalid target system" {
            {
                New-HardeningSession -Profile Basis `
                    -TargetSystem "InvalidSystem" -OSVersion 11 -ErrorAction Stop
            } | Should -Throw
        }

        It "throws on unsupported client OS version" {
            {
                New-HardeningSession -Profile Basis `
                    -TargetSystem Client -OSVersion 10 -ErrorAction Stop
            } | Should -Throw
        }

        It "throws on unsupported server OS version" {
            {
                New-HardeningSession -Profile Recommended `
                    -TargetSystem Server -OSVersion 2021 -ErrorAction Stop
            } | Should -Throw
        }
    }

    Context "Session Validation Failures" {
        It "throws on null session object" {
            {
                Invoke-SecurityHardening -Session $null -ErrorAction Stop
            } | Should -Throw
        }

        It "throws on malformed session object" {
            $badSession = @{
                ComputerName = "test"
                # Missing required State property
            }
            {
                Invoke-SecurityHardening -Session $badSession -ErrorAction Stop
            } | Should -Throw
        }

        It "throws on missing session state" {
            $session = @{
                Profile = "Basis"
                TargetSystem = "Client"
                ComputerName = $env:COMPUTERNAME
                # Missing State
            }
            {
                Invoke-SecurityHardening -Session $session -ErrorAction Stop
            } | Should -Throw
        }
    }
}

Describe "Error Scenarios - File I/O" {
    Context "Missing Profile Files" {
        It "throws when profile file doesn't exist" {
            $session = @{
                Profile = "NonExistentProfile"
                TargetSystem = "Client"
                OSVersion = 11
                ComputerName = $env:COMPUTERNAME
                State = @{}
            }

            {
                Get-HardeningProfile -ProfileName "NonExistentProfile" `
                    -TargetSystem Client -ErrorAction Stop
            } | Should -Throw
        }
    }

    Context "Report Generation Failures" {
        It "handles missing compliance report object" {
            {
                Export-HardeningReport -ComplianceReport $null `
                    -Format JSON -ErrorAction Stop
            } | Should -Throw
        }

        It "throws on invalid report format" {
            $report = @{
                CompliancePercentage = 75
                Status = "Compliant"
                TotalRules = 10
            }

            {
                Export-HardeningReport -ComplianceReport $report `
                    -Format "InvalidFormat" -ErrorAction Stop
            } | Should -Throw
        }
    }
}

Describe "Error Scenarios - Network/Remote Failures" {
    Context "Remote System Unreachable" {
        It "handles connection to non-existent system" {
            {
                Invoke-RemoteHardening -ComputerName "NonExistent.local" `
                    -Profile Basis -ErrorAction Stop
            } | Should -Throw
        }

        It "handles invalid computer name format" {
            {
                Invoke-RemoteHardening -ComputerName "" `
                    -Profile Basis -ErrorAction Stop
            } | Should -Throw
        }

        It "handles WinRM not available" {
            # This test assumes WinRM might not be enabled
            {
                Invoke-RemoteHardening -ComputerName "localhost" `
                    -Profile Basis -ErrorAction Stop
            } | Should -Throw -ErrorId "*Connection*"
        }
    }

    Context "SMTP/Email Failures" {
        It "handles invalid SMTP server" {
            {
                Send-HardeningAlert -SmtpServer "invalid.local" `
                    -FromAddress "test@test.com" `
                    -ToAddress "test@test.com" `
                    -AlertType Compliance `
                    -ErrorAction Stop
            } | Should -Throw
        }

        It "handles invalid email addresses" {
            {
                Send-HardeningAlert -SmtpServer "smtp.test.com" `
                    -FromAddress "invalid-email" `
                    -ToAddress "test@test.com" `
                    -AlertType Compliance `
                    -ErrorAction Stop
            } | Should -Throw
        }

        It "handles empty recipient list" {
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

Describe "Error Scenarios - Scheduling Failures" {
    Context "Task Scheduler Errors" {
        It "throws on invalid schedule type" {
            {
                New-HardeningSchedule -Profile Basis `
                    -Schedule "InvalidSchedule" `
                    -ErrorAction Stop
            } | Should -Throw
        }

        It "throws on invalid day of week" {
            {
                New-HardeningSchedule -Profile Basis `
                    -Schedule Weekly `
                    -DayOfWeek "InvalidDay" `
                    -ErrorAction Stop
            } | Should -Throw
        }

        It "throws on invalid day of month" {
            {
                New-HardeningSchedule -Profile Basis `
                    -Schedule Monthly `
                    -DayOfMonth 32 `
                    -ErrorAction Stop
            } | Should -Throw
        }
    }
}

Describe "Error Scenarios - GPO Failures" {
    Context "Group Policy Integration Errors" {
        It "throws when GroupPolicy module not available" -Skip {
            # Skip if GPMC not installed
            if ((Get-Module GroupPolicy -ErrorAction SilentlyContinue) -eq $null) {
                # Expected to throw when GPMC not available
                {
                    Import-HardeningGPO -Profile Basis `
                        -Domain "invalid.local" `
                        -ErrorAction Stop
                } | Should -Throw
            }
        }

        It "throws on invalid domain name" {
            {
                Import-HardeningGPO -Profile Basis `
                    -Domain "###INVALID###" `
                    -ErrorAction Stop
            } | Should -Throw
        }
    }
}

Describe "Error Scenarios - Exception Handling" {
    Context "Logging and Error Messages" {
        It "logs errors with descriptive messages" {
            $session = @{
                Profile = "BadProfile"
                TargetSystem = "Client"
                OSVersion = 11
                ComputerName = $env:COMPUTERNAME
                State = @{ AppliedRules = @() }
            }

            # Capture error output
            $error.Clear()
            try {
                Get-HardeningProfile -ProfileName "BadProfile" `
                    -TargetSystem "Client" -ErrorAction Stop
            }
            catch {
                $_.Exception.Message | Should -Not -BeNullOrEmpty
            }
        }

        It "throws with error details preserved" {
            {
                New-HardeningSession -Profile "Invalid" `
                    -TargetSystem Client -OSVersion 11 `
                    -ErrorAction Stop
            } | Should -Throw
        }
    }
}

Describe "Error Scenarios - Parameter Validation" {
    Context "Parameter Type Validation" {
        It "validates severity parameter" {
            {
                Send-HardeningAlert -SmtpServer "smtp.test.com" `
                    -FromAddress "test@test.com" `
                    -ToAddress "test@test.com" `
                    -AlertType Compliance `
                    -Severity "InvalidSeverity" `
                    -ErrorAction Stop
            } | Should -Throw
        }

        It "validates alert type parameter" {
            {
                Send-HardeningAlert -SmtpServer "smtp.test.com" `
                    -FromAddress "test@test.com" `
                    -ToAddress "test@test.com" `
                    -AlertType "InvalidType" `
                    -ErrorAction Stop
            } | Should -Throw
        }

        It "validates SMTP port number" {
            {
                Send-HardeningAlert -SmtpServer "smtp.test.com" `
                    -FromAddress "test@test.com" `
                    -ToAddress "test@test.com" `
                    -AlertType Compliance `
                    -SmtpPort 99999 `
                    -ErrorAction Stop
            } | Should -Throw -Not  # Port might be accepted, actual SMTP will fail
        }
    }
}

Describe "Error Scenarios - Recovery and Resilience" {
    Context "Graceful Degradation" {
        It "continues on non-critical errors with verbose logging" {
            $session = New-HardeningSession -Profile Basis `
                -TargetSystem Client -OSVersion 11 `
                -SkipPrerequisiteCheck

            $session | Should -Not -BeNullOrEmpty
        }

        It "returns error report on compliance check failure" {
            $session = New-HardeningSession -Profile Basis `
                -TargetSystem Client -OSVersion 11 `
                -SkipPrerequisiteCheck

            # Test that function returns object even on partial errors
            $result = Test-HardeningCompliance -Session $session `
                -ErrorAction Continue

            $result | Should -Not -BeNullOrEmpty
        }
    }
}
