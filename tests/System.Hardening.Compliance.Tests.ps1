BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\System.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module System -Force -ErrorAction SilentlyContinue
}

Describe "System Module - Test-HardeningCompliance" {
    Context "Test-HardeningCompliance - Parameter Validation" {
        It "accepts a valid hardening session object" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            { Test-HardeningCompliance -Session $session } | Should -Not -Throw
        }

        It "requires a session parameter" {
            { Test-HardeningCompliance } | Should -Throw
        }

        It "accepts RuleFilter parameter" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            { Test-HardeningCompliance -Session $session -RuleFilter @('Account-MinimumPasswordLength') } | Should -Not -Throw
        }

        It "accepts Detailed switch" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            { Test-HardeningCompliance -Session $session -Detailed } | Should -Not -Throw
        }

        It "accepts Remediate switch" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            { Test-HardeningCompliance -Session $session -Remediate } | Should -Not -Throw
        }
    }

    Context "Test-HardeningCompliance - Execution" {
        It "returns a compliance report object" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $report = Test-HardeningCompliance -Session $session
            $report | Should -Not -BeNullOrEmpty
        }

        It "report object has required properties" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $report = Test-HardeningCompliance -Session $session
            $report | Should -HaveProperty SessionId
            $report | Should -HaveProperty Profile
            $report | Should -HaveProperty TargetSystem
            $report | Should -HaveProperty CompliancePercentage
            $report | Should -HaveProperty Status
            $report | Should -HaveProperty RuleResults
        }

        It "preserves session profile in report" {
            $session = New-HardeningSession -Profile Recommended -TargetSystem Server -OSVersion 2022 -SkipPrerequisiteCheck
            $report = Test-HardeningCompliance -Session $session
            $report.Profile | Should -Be 'Recommended'
        }

        It "preserves target system in report" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Server -OSVersion 2025 -SkipPrerequisiteCheck
            $report = Test-HardeningCompliance -Session $session
            $report.TargetSystem | Should -Be 'Server'
        }
    }

    Context "Test-HardeningCompliance - Compliance Metrics" {
        It "calculates compliance percentage" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $report = Test-HardeningCompliance -Session $session
            $report.CompliancePercentage | Should -BeGreaterThanOrEqual 0
            $report.CompliancePercentage | Should -BeLessThanOrEqual 100
        }

        It "calculates total rules count" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $report = Test-HardeningCompliance -Session $session
            $report.TotalRules | Should -Be $session.State.TotalRules
        }

        It "counts compliant rules correctly" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $report = Test-HardeningCompliance -Session $session
            $report.CompliantRules | Should -BeGreaterThanOrEqual 0
            $report.CompliantRules | Should -BeLessThanOrEqual $report.TotalRules
        }

        It "counts non-compliant rules correctly" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $report = Test-HardeningCompliance -Session $session
            ($report.CompliantRules + $report.NonCompliantRules) | Should -Be $report.TotalRules
        }
    }

    Context "Test-HardeningCompliance - Compliance Status" {
        It "assigns Fully Compliant status at 100 percent" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $report = Test-HardeningCompliance -Session $session
            if ($report.CompliancePercentage -eq 100) {
                $report.Status | Should -Be 'Fully Compliant'
            }
        }

        It "assigns status based on compliance percentage" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $report = Test-HardeningCompliance -Session $session
            $validStatuses = @('Fully Compliant', 'Highly Compliant', 'Mostly Compliant', 'Partially Compliant', 'Non-Compliant')
            $report.Status -in $validStatuses | Should -Be $true
        }

        It "report includes category breakdown" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $report = Test-HardeningCompliance -Session $session
            $report.CategoryBreakdown | Should -Not -BeNullOrEmpty
            $report.CategoryBreakdown | Should -HaveProperty 'Account.Policy'
        }
    }

    Context "Test-HardeningCompliance - Rule Results" {
        It "returns individual rule test results" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $report = Test-HardeningCompliance -Session $session
            @($report.RuleResults).Count | Should -BeGreaterThan 0
        }

        It "rule results have required properties" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $report = Test-HardeningCompliance -Session $session
            $ruleResult = $report.RuleResults[0]
            $ruleResult | Should -HaveProperty RuleName
            $ruleResult | Should -HaveProperty Category
            $ruleResult | Should -HaveProperty Severity
            $ruleResult | Should -HaveProperty Compliant
        }

        It "identifies compliant rules" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $report = Test-HardeningCompliance -Session $session
            $compliantRules = @($report.RuleResults | Where-Object { $_.Compliant -eq $true })
            $compliantRules.Count | Should -Be $report.CompliantRules
        }

        It "identifies non-compliant rules" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $report = Test-HardeningCompliance -Session $session
            $nonCompliantRules = @($report.RuleResults | Where-Object { $_.Compliant -eq $false })
            $nonCompliantRules.Count | Should -Be $report.NonCompliantRules
        }
    }

    Context "Test-HardeningCompliance - Rule Filtering" {
        It "tests only filtered rules when RuleFilter provided" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $filterRules = @('Account-MinimumPasswordLength', 'Account-PasswordComplexity')
            $report = Test-HardeningCompliance -Session $session -RuleFilter $filterRules
            $report.TotalRules | Should -Be 2
            $report.RuleResults.Count | Should -Be 2
        }

        It "filtered results match rule names" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $filterRules = @('Account-MinimumPasswordLength')
            $report = Test-HardeningCompliance -Session $session -RuleFilter $filterRules
            $report.RuleResults[0].RuleName | Should -Be 'Account-MinimumPasswordLength'
        }
    }

    Context "Test-HardeningCompliance - Detailed Mode" {
        It "includes expected values in detailed mode" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $report = Test-HardeningCompliance -Session $session -Detailed
            $report.RuleResults[0] | Should -HaveProperty ExpectedValue
        }

        It "includes actual values in detailed mode" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $report = Test-HardeningCompliance -Session $session -Detailed
            $report.RuleResults[0] | Should -HaveProperty ActualValue
        }
    }

    Context "Test-HardeningCompliance - Category Statistics" {
        It "includes statistics for all rule categories" {
            $session = New-HardeningSession -Profile Recommended -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $report = Test-HardeningCompliance -Session $session
            $report.CategoryBreakdown.Keys.Count | Should -BeGreaterThan 0
        }

        It "category breakdown includes required fields" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $report = Test-HardeningCompliance -Session $session
            $categoryStats = $report.CategoryBreakdown['Account.Policy']
            $categoryStats | Should -HaveProperty Total
            $categoryStats | Should -HaveProperty Compliant
            $categoryStats | Should -HaveProperty Percentage
        }

        It "calculates category compliance percentage correctly" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $report = Test-HardeningCompliance -Session $session
            foreach ($category in $report.CategoryBreakdown.Keys) {
                $stats = $report.CategoryBreakdown[$category]
                $expectedPercentage = [math]::Round(($stats.Compliant / $stats.Total) * 100, 2)
                $stats.Percentage | Should -Be $expectedPercentage
            }
        }
    }

    Context "Test-HardeningCompliance - Profile Variations" {
        It "tests Basis profile compliance" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $report = Test-HardeningCompliance -Session $session
            $report.Profile | Should -Be 'Basis'
            $report.CompliancePercentage | Should -BeGreaterThanOrEqual 0
        }

        It "tests Recommended profile compliance" {
            $session = New-HardeningSession -Profile Recommended -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $report = Test-HardeningCompliance -Session $session
            $report.Profile | Should -Be 'Recommended'
            $report.CompliancePercentage | Should -BeGreaterThanOrEqual 0
        }

        It "tests Strict profile compliance" {
            $session = New-HardeningSession -Profile Strict -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $report = Test-HardeningCompliance -Session $session
            $report.Profile | Should -Be 'Strict'
            $report.CompliancePercentage | Should -BeGreaterThanOrEqual 0
        }

        It "Strict profile has more rules to verify than Basis" {
            $basisSession = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $basisReport = Test-HardeningCompliance -Session $basisSession

            $strictSession = New-HardeningSession -Profile Strict -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $strictReport = Test-HardeningCompliance -Session $strictSession

            $strictReport.TotalRules | Should -BeGreaterThan $basisReport.TotalRules
        }
    }

    Context "Test-HardeningCompliance - Server Support" {
        It "tests Windows Server 2019 compliance" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Server -OSVersion 2019 -SkipPrerequisiteCheck
            $report = Test-HardeningCompliance -Session $session
            $report.TotalRules | Should -BeGreaterThan 0
        }

        It "tests Windows Server 2022 compliance" {
            $session = New-HardeningSession -Profile Recommended -TargetSystem Server -OSVersion 2022 -SkipPrerequisiteCheck
            $report = Test-HardeningCompliance -Session $session
            $report.TotalRules | Should -BeGreaterThan 0
        }

        It "tests Windows Server 2025 compliance" {
            $session = New-HardeningSession -Profile Strict -TargetSystem Server -OSVersion 2025 -SkipPrerequisiteCheck
            $report = Test-HardeningCompliance -Session $session
            $report.TotalRules | Should -BeGreaterThan 0
        }
    }

    Context "Test-HardeningCompliance - Integration with Hardening" {
        It "works with sessions created by New-HardeningSession" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $result = Invoke-SecurityHardening -Session $session
            $compliance = Test-HardeningCompliance -Session $session
            $compliance | Should -Not -BeNullOrEmpty
            $compliance.Profile | Should -Be 'Basis'
        }

        It "shows compliance after hardening attempt" {
            $session = New-HardeningSession -Profile Recommended -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            Invoke-SecurityHardening -Session $session | Out-Null
            $compliance = Test-HardeningCompliance -Session $session
            $compliance.TotalRules | Should -Be $session.State.TotalRules
        }

        It "compliance report reflects actual system state" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $compliance = Test-HardeningCompliance -Session $session
            [bool]$compliance.RuleResults -eq $true | Should -Be $true
        }
    }

    Context "Test-HardeningCompliance - Documentation" {
        It "has complete help documentation" {
            $help = Get-Help Test-HardeningCompliance
            $help.Synopsis | Should -Not -BeNullOrEmpty
            $help.Description | Should -Not -BeNullOrEmpty
        }

        It "help includes all parameters" {
            $help = Get-Help Test-HardeningCompliance
            $help.Parameters.Parameter.Name | Should -Contain 'Session'
            $help.Parameters.Parameter.Name | Should -Contain 'RuleFilter'
            $help.Parameters.Parameter.Name | Should -Contain 'Detailed'
            $help.Parameters.Parameter.Name | Should -Contain 'Remediate'
        }

        It "help includes examples" {
            $help = Get-Help Test-HardeningCompliance
            $help.Examples | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "System Module - Hardening Complete Workflow" {
    Context "End-to-End Hardening and Compliance" {
        It "complete workflow: create session, harden, test compliance" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            Invoke-SecurityHardening -Session $session | Out-Null
            $compliance = Test-HardeningCompliance -Session $session

            $compliance.SessionId | Should -Be $session.SessionId
            $compliance.Profile | Should -Be 'Basis'
            $compliance.TotalRules | Should -BeGreaterThan 0
            $compliance.CompliancePercentage | Should -BeGreaterThanOrEqual 0
        }

        It "compliance report contains summary metrics" {
            $session = New-HardeningSession -Profile Recommended -TargetSystem Server -OSVersion 2022 -SkipPrerequisiteCheck
            Invoke-SecurityHardening -Session $session | Out-Null
            $compliance = Test-HardeningCompliance -Session $session

            $compliance | Should -HaveProperty CompliantRules
            $compliance | Should -HaveProperty NonCompliantRules
            $compliance | Should -HaveProperty CompliancePercentage
            $compliance | Should -HaveProperty Status
        }

        It "filtered compliance test works in full workflow" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            Invoke-SecurityHardening -Session $session | Out-Null
            $compliance = Test-HardeningCompliance -Session $session -RuleFilter @('Account-MinimumPasswordLength', 'Firewall-EnableWindowsDefender')

            $compliance.TotalRules | Should -Be 2
            $compliance.RuleResults.Count | Should -Be 2
        }
    }
}
