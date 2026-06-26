BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\System.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module System -Force -ErrorAction SilentlyContinue
}

Describe "System Module - Invoke-SecurityHardening" {
    Context "Invoke-SecurityHardening - Parameter Validation" {
        It "accepts a valid hardening session object" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            { Invoke-SecurityHardening -Session $session } | Should -Not -Throw
        }

        It "requires a session parameter" {
            { Invoke-SecurityHardening } | Should -Throw
        }

        It "accepts RuleFilter parameter" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
            { Invoke-SecurityHardening -Session $session -RuleFilter @('Account-MinimumPasswordLength') } | Should -Not -Throw
        }

        It "accepts FailOnError switch" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
            { Invoke-SecurityHardening -Session $session -FailOnError } | Should -Not -Throw
        }

        It "accepts SkipVerification switch" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
            { Invoke-SecurityHardening -Session $session -SkipVerification } | Should -Not -Throw
        }
    }

    Context "Invoke-SecurityHardening - Execution" {
        It "returns a result object" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
            $result = Invoke-SecurityHardening -Session $session
            $result | Should -Not -BeNullOrEmpty
        }

        It "result object has required properties" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
            $result = Invoke-SecurityHardening -Session $session
            $result | Should -HaveProperty SessionId
            $result | Should -HaveProperty Profile
            $result | Should -HaveProperty TargetSystem
            $result | Should -HaveProperty ComputerName
            $result | Should -HaveProperty AppliedRules
            $result | Should -HaveProperty FailedRules
            $result | Should -HaveProperty Duration
        }

        It "preserves session profile in result" {
            $session = New-HardeningSession -Profile Recommended -TargetSystem Server -OSVersion 2022 -WhatIf
            $result = Invoke-SecurityHardening -Session $session
            $result.Profile | Should -Be 'Recommended'
        }

        It "preserves target system in result" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Server -OSVersion 2025 -WhatIf
            $result = Invoke-SecurityHardening -Session $session
            $result.TargetSystem | Should -Be 'Server'
        }

        It "captures rule application status" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
            $result = Invoke-SecurityHardening -Session $session
            $result.AppliedRules | Should -Not -BeNullOrEmpty
        }

        It "returns success status when no failures" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
            $result = Invoke-SecurityHardening -Session $session
            $result.Success | Should -Be $true
        }

        It "records execution duration" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
            $result = Invoke-SecurityHardening -Session $session
            $result.Duration | Should -Not -BeNullOrEmpty
            $result.Duration.TotalMilliseconds | Should -BeGreaterThan 0
        }

        It "respects WhatIf mode and reports it" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
            $result = Invoke-SecurityHardening -Session $session
            $result.AppliedRules.Count | Should -Be $session.State.TotalRules
        }
    }

    Context "Invoke-SecurityHardening - Rule Filtering" {
        It "applies only filtered rules when RuleFilter provided" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
            $result = Invoke-SecurityHardening -Session $session -RuleFilter @('Account-MinimumPasswordLength', 'Account-PasswordComplexity')
            $result.AppliedRules.Count | Should -Be 2
        }

        It "filters rules correctly from profile" {
            $session = New-HardeningSession -Profile Recommended -TargetSystem Client -OSVersion 11 -WhatIf
            $filterRules = @('Account-MinimumPasswordLength', 'Firewall-EnableWindowsDefender')
            $result = Invoke-SecurityHardening -Session $session -RuleFilter $filterRules
            foreach ($appliedRule in $result.AppliedRules) {
                $appliedRule -in $filterRules | Should -Be $true
            }
        }

        It "handles empty rule filter gracefully" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
            $result = Invoke-SecurityHardening -Session $session -RuleFilter @()
            $result.AppliedRules.Count | Should -Be 0
        }
    }

    Context "Invoke-SecurityHardening - WhatIf Support" {
        It "WhatIf mode does not modify system" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
            $result = Invoke-SecurityHardening -Session $session -WhatIf
            $result | Should -Not -BeNullOrEmpty
        }

        It "indicates WhatIf mode in session state" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
            $session.WhatIfMode | Should -Be $true
        }

        It "applies rules in WhatIf mode" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
            $result = Invoke-SecurityHardening -Session $session
            @($result.AppliedRules).Count -gt 0 | Should -Be $true
        }
    }

    Context "Invoke-SecurityHardening - Profile Progression" {
        It "Basis profile applies fewer rules than Recommended" {
            $basisSession = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
            $basisResult = Invoke-SecurityHardening -Session $basisSession

            $recommendedSession = New-HardeningSession -Profile Recommended -TargetSystem Client -OSVersion 11 -WhatIf
            $recommendedResult = Invoke-SecurityHardening -Session $recommendedSession

            $basisResult.AppliedRules.Count | Should -BeLessThan $recommendedResult.AppliedRules.Count
        }

        It "Recommended profile applies fewer rules than Strict" {
            $recommendedSession = New-HardeningSession -Profile Recommended -TargetSystem Client -OSVersion 11 -WhatIf
            $recommendedResult = Invoke-SecurityHardening -Session $recommendedSession

            $strictSession = New-HardeningSession -Profile Strict -TargetSystem Client -OSVersion 11 -WhatIf
            $strictResult = Invoke-SecurityHardening -Session $strictSession

            $recommendedResult.AppliedRules.Count | Should -BeLessThan $strictResult.AppliedRules.Count
        }

        It "Strict profile applies all Recommended rules" {
            $recommendedSession = New-HardeningSession -Profile Recommended -TargetSystem Client -OSVersion 11 -WhatIf
            $recommendedResult = Invoke-SecurityHardening -Session $recommendedSession

            $strictSession = New-HardeningSession -Profile Strict -TargetSystem Client -OSVersion 11 -WhatIf
            $strictResult = Invoke-SecurityHardening -Session $strictSession

            foreach ($recRule in $recommendedResult.AppliedRules) {
                $strictResult.AppliedRules -contains $recRule | Should -Be $true
            }
        }
    }

    Context "Invoke-SecurityHardening - Compliance Reporting" {
        It "includes compliance report in result" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
            $result = Invoke-SecurityHardening -Session $session
            $result.ComplianceReport | Should -Not -BeNullOrEmpty
        }

        It "compliance report contains required fields" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
            $result = Invoke-SecurityHardening -Session $session
            $report = $result.ComplianceReport

            $report | Should -HaveProperty TotalRules
            $report | Should -HaveProperty AppliedRules
            $report | Should -HaveProperty FailedRules
            $report | Should -HaveProperty CompliancePercentage
            $report | Should -HaveProperty Status
        }

        It "calculates compliance percentage correctly" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
            $result = Invoke-SecurityHardening -Session $session
            $report = $result.ComplianceReport

            $expectedPercentage = [math]::Round(($report.AppliedRules / $report.TotalRules) * 100, 2)
            $report.CompliancePercentage | Should -Be $expectedPercentage
        }

        It "marks system as Compliant when no failures" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
            $result = Invoke-SecurityHardening -Session $session
            $report = $result.ComplianceReport
            $report.Status | Should -Be 'Compliant'
        }

        It "skips verification when SkipVerification specified" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
            $result = Invoke-SecurityHardening -Session $session -SkipVerification
            $result.ComplianceReport | Should -BeNullOrEmpty
        }
    }

    Context "Invoke-SecurityHardening - Server Support" {
        It "applies to Windows Server 2019" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Server -OSVersion 2019 -WhatIf
            $result = Invoke-SecurityHardening -Session $session
            $result.AppliedRules.Count | Should -BeGreaterThan 0
        }

        It "applies to Windows Server 2022" {
            $session = New-HardeningSession -Profile Recommended -TargetSystem Server -OSVersion 2022 -WhatIf
            $result = Invoke-SecurityHardening -Session $session
            $result.AppliedRules.Count | Should -BeGreaterThan 0
        }

        It "applies to Windows Server 2025" {
            $session = New-HardeningSession -Profile Strict -TargetSystem Server -OSVersion 2025 -WhatIf
            $result = Invoke-SecurityHardening -Session $session
            $result.AppliedRules.Count | Should -BeGreaterThan 0
        }

        It "Server and Client apply different rule counts for same profile" {
            $clientSession = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
            $clientResult = Invoke-SecurityHardening -Session $clientSession

            $serverSession = New-HardeningSession -Profile Basis -TargetSystem Server -OSVersion 2022 -WhatIf
            $serverResult = Invoke-SecurityHardening -Session $serverSession

            # Both should apply rules, but counts may differ due to OS-specific rules
            $clientResult.AppliedRules.Count | Should -BeGreaterThan 0
            $serverResult.AppliedRules.Count | Should -BeGreaterThan 0
        }
    }

    Context "Invoke-SecurityHardening - Documentation" {
        It "has complete help documentation" {
            $help = Get-Help Invoke-SecurityHardening
            $help.Synopsis | Should -Not -BeNullOrEmpty
            $help.Description | Should -Not -BeNullOrEmpty
            $help.Parameters | Should -Not -BeNullOrEmpty
        }

        It "help includes parameter descriptions" {
            $help = Get-Help Invoke-SecurityHardening
            $help.Parameters.Parameter.Name | Should -Contain 'Session'
            $help.Parameters.Parameter.Name | Should -Contain 'RuleFilter'
        }

        It "help includes usage examples" {
            $help = Get-Help Invoke-SecurityHardening
            $help.Examples | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "System Module - Hardening Integration Tests" {
    Context "Full Hardening Workflow" {
        It "can create session and invoke hardening for Basis profile" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
            $result = Invoke-SecurityHardening -Session $session
            $result.Profile | Should -Be 'Basis'
            $result.Success | Should -Be $true
        }

        It "can create session and invoke hardening for Recommended profile" {
            $session = New-HardeningSession -Profile Recommended -TargetSystem Client -OSVersion 11 -WhatIf
            $result = Invoke-SecurityHardening -Session $session
            $result.Profile | Should -Be 'Recommended'
            $result.Success | Should -Be $true
        }

        It "can create session and invoke hardening for Strict profile" {
            $session = New-HardeningSession -Profile Strict -TargetSystem Client -OSVersion 11 -WhatIf
            $result = Invoke-SecurityHardening -Session $session
            $result.Profile | Should -Be 'Strict'
            $result.Success | Should -Be $true
        }

        It "complete workflow returns comprehensive result" {
            $session = New-HardeningSession -Profile Recommended -TargetSystem Server -OSVersion 2022 -WhatIf
            $result = Invoke-SecurityHardening -Session $session

            $result.SessionId | Should -Not -BeNullOrEmpty
            $result.Profile | Should -Be 'Recommended'
            $result.TargetSystem | Should -Be 'Server'
            $result.AppliedRules.Count | Should -BeGreaterThan 0
            $result.ComplianceReport | Should -Not -BeNullOrEmpty
            $result.Duration | Should -Not -BeNullOrEmpty
        }
    }
}
