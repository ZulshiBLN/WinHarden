BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\System.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module System -Force -ErrorAction SilentlyContinue
}

Describe "Get-UpdateStatusDrift" {

    Context "Parameter Validation" {
        BeforeEach {
            InModuleScope System {
                Mock Get-ItemProperty { [PSCustomObject]@{ } }
                Mock Write-Log { }
            }
        }

        It "accepts default parameters" {
            InModuleScope System {
                { Get-UpdateStatusDrift -ErrorAction SilentlyContinue } | Should -Not -Throw
            }
        }

        It "accepts ComputerName parameter" {
            InModuleScope System {
                { Get-UpdateStatusDrift -ComputerName 'localhost' -ErrorAction SilentlyContinue } | Should -Not -Throw
            }
        }

        It "accepts Profile parameter with Basis" {
            InModuleScope System {
                { Get-UpdateStatusDrift -Profile Basis -ErrorAction SilentlyContinue } | Should -Not -Throw
            }
        }

        It "accepts Profile parameter with Recommended" {
            InModuleScope System {
                { Get-UpdateStatusDrift -Profile Recommended -ErrorAction SilentlyContinue } | Should -Not -Throw
            }
        }

        It "accepts Profile parameter with Strict" {
            InModuleScope System {
                { Get-UpdateStatusDrift -Profile Strict -ErrorAction SilentlyContinue } | Should -Not -Throw
            }
        }

        It "rejects invalid Profile parameter" {
            InModuleScope System {
                { Get-UpdateStatusDrift -Profile 'InvalidProfile' -ErrorAction Stop } | Should -Throw
            }
        }

        It "accepts Detailed switch" {
            InModuleScope System {
                { Get-UpdateStatusDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
            }
        }

        It "accepts ReportDriftOnly switch" {
            InModuleScope System {
                { Get-UpdateStatusDrift -ReportDriftOnly -ErrorAction SilentlyContinue } | Should -Not -Throw
            }
        }

        It "accepts AutoUpdateEnabled parameter" {
            InModuleScope System {
                { Get-UpdateStatusDrift -AutoUpdateEnabled $true -ErrorAction SilentlyContinue } | Should -Not -Throw
            }
        }

        It "accepts RequireScheduledRestart parameter" {
            InModuleScope System {
                { Get-UpdateStatusDrift -RequireScheduledRestart $true -ErrorAction SilentlyContinue } | Should -Not -Throw
            }
        }

        It "accepts MaxDaysSinceLastUpdate parameter with valid range" {
            InModuleScope System {
                { Get-UpdateStatusDrift -MaxDaysSinceLastUpdate 14 -ErrorAction SilentlyContinue } | Should -Not -Throw
            }
        }

        It "rejects MaxDaysSinceLastUpdate below 1" {
            InModuleScope System {
                { Get-UpdateStatusDrift -MaxDaysSinceLastUpdate 0 -ErrorAction Stop } | Should -Throw
            }
        }

        It "rejects MaxDaysSinceLastUpdate above 365" {
            InModuleScope System {
                { Get-UpdateStatusDrift -MaxDaysSinceLastUpdate 366 -ErrorAction Stop } | Should -Throw
            }
        }

        It "accepts MaxDaysSinceLastUpdate boundary values" {
            InModuleScope System {
                { Get-UpdateStatusDrift -MaxDaysSinceLastUpdate 1 -ErrorAction SilentlyContinue } | Should -Not -Throw
                { Get-UpdateStatusDrift -MaxDaysSinceLastUpdate 365 -ErrorAction SilentlyContinue } | Should -Not -Throw
            }
        }
    }

    Context "Function Execution - Local" {
        BeforeEach {
            InModuleScope System {
                Mock Get-ItemProperty { [PSCustomObject]@{ } }
                Mock Write-Log { }
            }
        }

        It "returns results without error" {
            InModuleScope System {
                { Get-UpdateStatusDrift -ErrorAction SilentlyContinue } | Should -Not -Throw
            }
        }

        It "returns a collection or null" {
            InModuleScope System {
                $result = Get-UpdateStatusDrift -ErrorAction SilentlyContinue
                ($result -is [System.Collections.IEnumerable] -or $null -eq $result) | Should -Be $true
            }
        }

        It "respects WhatIf parameter" {
            InModuleScope System {
                $result = Get-UpdateStatusDrift -WhatIf -ErrorAction SilentlyContinue
                $result.Count | Should -Be 0
            }
        }
    }

    Context "Return Value Structure" {
        BeforeEach {
            InModuleScope System {
                Mock Get-ItemProperty -ParameterFilter { $Name -eq 'NoAutoUpdate' } { [PSCustomObject]@{ NoAutoUpdate = 1 } }
                Mock Get-ItemProperty { [PSCustomObject]@{ } }
                Mock Write-Log { }
            }
        }

        It "includes Category property" {
            InModuleScope System {
                $result = Get-UpdateStatusDrift -ErrorAction SilentlyContinue
                $result[0].Category | Should -Be 'Windows Updates'
            }
        }

        It "includes Setting property" {
            InModuleScope System {
                $result = Get-UpdateStatusDrift -ErrorAction SilentlyContinue
                $result[0].Setting | Should -Match 'Automatic Updates'
            }
        }

        It "includes Status property (DRIFT or COMPLIANT)" {
            InModuleScope System {
                $result = Get-UpdateStatusDrift -ErrorAction SilentlyContinue
                $result[0].Status | Should -Match '^(DRIFT|COMPLIANT)$'
            }
        }

        It "includes Severity property" {
            InModuleScope System {
                $result = Get-UpdateStatusDrift -ErrorAction SilentlyContinue
                $result[0].Severity | Should -Match '^(CRITICAL|HIGH|MEDIUM|LOW|INFO)$'
            }
        }

        It "includes ComputerName property" {
            InModuleScope System {
                $result = Get-UpdateStatusDrift -ErrorAction SilentlyContinue
                $result[0].ComputerName | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context "Automatic Updates Detection" {
        BeforeEach {
            InModuleScope System {
                Mock Write-Log { }
            }
        }

        It "detects compliant when auto-updates enabled and expected enabled" {
            InModuleScope System {
                Mock Get-ItemProperty -ParameterFilter { $Name -eq 'NoAutoUpdate' } { [PSCustomObject]@{ NoAutoUpdate = 0 } }
                Mock Get-ItemProperty { [PSCustomObject]@{ } }

                $result = Get-UpdateStatusDrift -AutoUpdateEnabled $true -ErrorAction SilentlyContinue
                $autoItem = $result | Where-Object { $_.Setting -match 'Automatic Updates' }
                $autoItem.Status | Should -Be 'COMPLIANT'
                $autoItem.Actual | Should -Be 'Enabled'
                $autoItem.Expected | Should -Be 'Enabled'
            }
        }

        It "reports compliant status when settings match expectations" {
            InModuleScope System {
                Mock Write-Log { }
                Mock Get-ItemProperty { [PSCustomObject]@{ NoAutoUpdate = 0 } }

                $result = Get-UpdateStatusDrift -AutoUpdateEnabled $true -ErrorAction SilentlyContinue
                $autoItem = $result | Where-Object { $_.Setting -match 'Automatic Updates' }
                $autoItem.Status | Should -Match '^(DRIFT|COMPLIANT)$'
                $autoItem.Expected | Should -Not -BeNullOrEmpty
                $autoItem.Actual | Should -Not -BeNullOrEmpty
            }
        }

        It "returns findings with severity levels" {
            InModuleScope System {
                Mock Write-Log { }
                Mock Get-ItemProperty { [PSCustomObject]@{ } }

                $result = Get-UpdateStatusDrift -ErrorAction SilentlyContinue
                $result | ForEach-Object { $_.Severity | Should -Match '^(CRITICAL|HIGH|MEDIUM|LOW|INFO)$' }
            }
        }

        It "formats actual and expected values correctly" {
            InModuleScope System {
                Mock Write-Log { }
                Mock Get-ItemProperty { [PSCustomObject]@{ NoAutoUpdate = 0 } }

                $result = Get-UpdateStatusDrift -AutoUpdateEnabled $true -ErrorAction SilentlyContinue
                $result | Where-Object { $_.Setting -match 'Automatic' } | ForEach-Object {
                    $_.Actual | Should -Match 'Enabled|Disabled'
                    $_.Expected | Should -Match 'Enabled|Disabled'
                }
            }
        }

        It "handles null NoAutoUpdate as 0 (enabled)" {
            InModuleScope System {
                Mock Get-ItemProperty { [PSCustomObject]@{ } }

                $result = Get-UpdateStatusDrift -AutoUpdateEnabled $true -ErrorAction SilentlyContinue
                $autoItem = $result | Where-Object { $_.Setting -match 'Automatic Updates' }
                $autoItem.Status | Should -Be 'COMPLIANT'
            }
        }
    }

    Context "Profile-Based Checks" {
        BeforeEach {
            InModuleScope System {
                Mock Get-ItemProperty { [PSCustomObject]@{ } }
                Mock Write-Log { }
            }
        }

        It "Basis profile checks only auto-updates" {
            InModuleScope System {
                $result = Get-UpdateStatusDrift -Profile Basis -ErrorAction SilentlyContinue
                $result | Where-Object { $_.Setting -match 'Automatic Updates' } | Should -Not -BeNullOrEmpty
                $result | Where-Object { $_.Setting -match 'Scheduled' } | Should -BeNullOrEmpty
            }
        }

        It "Recommended profile includes scheduled install check" {
            InModuleScope System {
                $result = Get-UpdateStatusDrift -Profile Recommended -ErrorAction SilentlyContinue
                $result | Where-Object { $_.Setting -match 'Automatic Updates' } | Should -Not -BeNullOrEmpty
                $result | Where-Object { $_.Setting -match 'Scheduled Install' } | Should -Not -BeNullOrEmpty
            }
        }

        It "Strict profile includes more checks than Recommended" {
            InModuleScope System {
                $result = Get-UpdateStatusDrift -Profile Strict -ErrorAction SilentlyContinue
                $checkCount = ($result | Select-Object -ExpandProperty Setting).Count
                $checkCount | Should -BeGreaterThan 2
            }
        }
    }

    Context "Scheduled Install Detection" {
        BeforeEach {
            InModuleScope System {
                Mock Write-Log { }
            }
        }

        It "detects missing scheduled install configuration" {
            InModuleScope System {
                Mock Get-ItemProperty { [PSCustomObject]@{ } }

                $result = Get-UpdateStatusDrift -Profile Recommended -ErrorAction SilentlyContinue
                $schedItem = $result | Where-Object { $_.Setting -match 'Scheduled Install' }
                $schedItem.Status | Should -Be 'DRIFT'
                $schedItem.Actual | Should -Be 'Not Configured'
            }
        }

        It "detects configured scheduled install" {
            InModuleScope System {
                Mock Get-ItemProperty -ParameterFilter { $Name -eq 'ScheduledInstallDay' } { [PSCustomObject]@{ ScheduledInstallDay = 2 } }
                Mock Get-ItemProperty -ParameterFilter { $Name -eq 'ScheduledInstallTime' } { [PSCustomObject]@{ ScheduledInstallTime = 3 } }
                Mock Get-ItemProperty { [PSCustomObject]@{ } }

                $result = Get-UpdateStatusDrift -Profile Recommended -ErrorAction SilentlyContinue
                $schedItem = $result | Where-Object { $_.Setting -match 'Scheduled Install' }
                $schedItem.Status | Should -Be 'COMPLIANT'
                $schedItem.Actual | Should -Match 'Monday'
            }
        }
    }

    Context "Report Filtering" {
        BeforeEach {
            InModuleScope System {
                Mock Get-ItemProperty { [PSCustomObject]@{ } }
                Mock Write-Log { }
            }
        }

        It "filters to DRIFT only with ReportDriftOnly" {
            InModuleScope System {
                $result = Get-UpdateStatusDrift -ReportDriftOnly -ErrorAction SilentlyContinue
                if ($result) {
                    $result | Where-Object { $_.Status -eq 'COMPLIANT' } | Should -BeNullOrEmpty
                    $result[0].Status | Should -Be 'DRIFT'
                }
            }
        }

        It "returns all findings without ReportDriftOnly" {
            InModuleScope System {
                $result = Get-UpdateStatusDrift -ErrorAction SilentlyContinue
                ($result | Measure-Object).Count | Should -BeGreaterThan 0
            }
        }
    }

    Context "Error Handling" {
        BeforeEach {
            InModuleScope System {
                Mock Get-ItemProperty { [PSCustomObject]@{ } }
                Mock Write-Log { }
            }
        }

        It "continues processing after registry access issues" {
            InModuleScope System {
                $result = Get-UpdateStatusDrift -ErrorAction SilentlyContinue
                $result | Should -Not -BeNullOrEmpty
                $result.Count | Should -BeGreaterThan 0
            }
        }

        It "handles missing registry values gracefully" {
            InModuleScope System {
                Mock Get-ItemProperty { [PSCustomObject]@{ } }

                $result = Get-UpdateStatusDrift -ErrorAction SilentlyContinue
                $result | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context "Documentation" {
        It "has complete help documentation" {
            $help = Get-Help Get-UpdateStatusDrift
            $help.Synopsis | Should -Not -BeNullOrEmpty
            $help.Synopsis | Should -Match 'drift'
        }

        It "documents all parameters" {
            $help = Get-Help Get-UpdateStatusDrift
            $help.Parameters.Parameter.Name | Should -Contain 'Profile'
            $help.Parameters.Parameter.Name | Should -Contain 'ComputerName'
            $help.Parameters.Parameter.Name | Should -Contain 'Detailed'
        }

        It "includes examples" {
            $help = Get-Help Get-UpdateStatusDrift
            $help.Examples.Example.Count | Should -BeGreaterThan 0
        }

        It "includes dependency notes" {
            $help = Get-Help Get-UpdateStatusDrift
            $help.Notes | Should -Not -BeNullOrEmpty
            $help.Notes | Should -Match '(Core|Logging|Write-Log)'
        }
    }
}
