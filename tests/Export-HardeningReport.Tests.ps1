BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\System.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module System -Force -ErrorAction SilentlyContinue
}

Describe "Export-HardeningReport" {
    Context "Parameter Validation" {
        It "accepts a valid compliance report object" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $compliance = Test-HardeningCompliance -Session $session
            { Export-HardeningReport -ComplianceReport $compliance } | Should -Not -Throw
        }

        It "requires a compliance report parameter" {
            { Export-HardeningReport } | Should -Throw
        }

        It "accepts JSON format" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $compliance = Test-HardeningCompliance -Session $session
            { Export-HardeningReport -ComplianceReport $compliance -Format JSON } | Should -Not -Throw
        }

        It "accepts CSV format" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $compliance = Test-HardeningCompliance -Session $session
            { Export-HardeningReport -ComplianceReport $compliance -Format CSV } | Should -Not -Throw
        }

        It "accepts HTML format" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $compliance = Test-HardeningCompliance -Session $session
            { Export-HardeningReport -ComplianceReport $compliance -Format HTML } | Should -Not -Throw
        }

        It "accepts Text format (default)" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $compliance = Test-HardeningCompliance -Session $session
            { Export-HardeningReport -ComplianceReport $compliance -Format Text } | Should -Not -Throw
        }
    }

    Context "Report Generation" {
        It "generates Text report by default" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $compliance = Test-HardeningCompliance -Session $session
            $report = Export-HardeningReport -ComplianceReport $compliance
            $report | Should -Not -BeNullOrEmpty
            $report -like '*COMPLIANCE SUMMARY*' | Should -Be $true
        }

        It "generates JSON report" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $compliance = Test-HardeningCompliance -Session $session
            $report = Export-HardeningReport -ComplianceReport $compliance -Format JSON
            { $report | ConvertFrom-Json } | Should -Not -Throw
        }

        It "generates CSV report" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $compliance = Test-HardeningCompliance -Session $session
            $report = Export-HardeningReport -ComplianceReport $compliance -Format CSV
            $report | Should -Not -BeNullOrEmpty
            $report[0] -like '*Profile*' | Should -Be $true
        }

        It "generates HTML report" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $compliance = Test-HardeningCompliance -Session $session
            $report = Export-HardeningReport -ComplianceReport $compliance -Format HTML
            $report | Should -Not -BeNullOrEmpty
            $report -like '*<!DOCTYPE html>*' | Should -Be $true
        }

        It "includes profile details in report" {
            $session = New-HardeningSession -Profile Recommended -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $compliance = Test-HardeningCompliance -Session $session
            $report = Export-HardeningReport -ComplianceReport $compliance -Format Text
            $report | Should -Match 'Recommended'
        }

        It "includes compliance percentage in report" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $compliance = Test-HardeningCompliance -Session $session
            $report = Export-HardeningReport -ComplianceReport $compliance -Format Text
            $report | Should -Match "$($compliance.CompliancePercentage)%"
        }
    }

    Context "File Output" {
        It "saves report to file" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $compliance = Test-HardeningCompliance -Session $session
            $testPath = Join-Path -Path $env:TEMP -ChildPath "test-report-$(Get-Random).txt"

            try {
                $result = Export-HardeningReport -ComplianceReport $compliance -Format Text -OutputPath $testPath
                Test-Path -Path $testPath | Should -Be $true
            }
            finally {
                Remove-Item -Path $testPath -Force -ErrorAction SilentlyContinue
            }
        }

        It "returns file info object when saving" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $compliance = Test-HardeningCompliance -Session $session
            $testPath = Join-Path -Path $env:TEMP -ChildPath "test-report-$(Get-Random).json"

            try {
                $result = Export-HardeningReport -ComplianceReport $compliance -Format JSON -OutputPath $testPath
                $result | Should -HaveProperty FullName
                $result.FullName | Should -Be $testPath
            }
            finally {
                Remove-Item -Path $testPath -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Context "Detailed Mode" {
        It "includes rule details when specified" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $compliance = Test-HardeningCompliance -Session $session
            $report = Export-HardeningReport -ComplianceReport $compliance -Format JSON -IncludeRuleDetails

            $json = $report | ConvertFrom-Json
            $json.RuleDetails | Should -Not -BeNullOrEmpty
        }
    }

    Context "Format Support" {
        It "Text format includes summary section" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $compliance = Test-HardeningCompliance -Session $session
            $report = Export-HardeningReport -ComplianceReport $compliance -Format Text
            $report | Should -Match 'COMPLIANCE SUMMARY'
        }

        It "JSON format is valid JSON" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $compliance = Test-HardeningCompliance -Session $session
            $report = Export-HardeningReport -ComplianceReport $compliance -Format JSON
            $json = $report | ConvertFrom-Json
            $json | Should -Not -BeNullOrEmpty
        }

        It "CSV format includes headers" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $compliance = Test-HardeningCompliance -Session $session
            $report = Export-HardeningReport -ComplianceReport $compliance -Format CSV
            $lines = @($report)
            $lines[0] | Should -Match 'Profile'
        }

        It "HTML format includes DOCTYPE" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $compliance = Test-HardeningCompliance -Session $session
            $report = Export-HardeningReport -ComplianceReport $compliance -Format HTML
            $report | Should -Match '<!DOCTYPE'
        }
    }

    Context "Integration with Compliance Reports" {
        It "exports Basis profile report successfully" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $compliance = Test-HardeningCompliance -Session $session
            $report = Export-HardeningReport -ComplianceReport $compliance
            $report | Should -Not -BeNullOrEmpty
        }

        It "exports Recommended profile report successfully" {
            $session = New-HardeningSession -Profile Recommended -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $compliance = Test-HardeningCompliance -Session $session
            $report = Export-HardeningReport -ComplianceReport $compliance
            $report | Should -Not -BeNullOrEmpty
        }

        It "exports Strict profile report successfully" {
            $session = New-HardeningSession -Profile Strict -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $compliance = Test-HardeningCompliance -Session $session
            $report = Export-HardeningReport -ComplianceReport $compliance
            $report | Should -Not -BeNullOrEmpty
        }
    }

    Context "Multiple Format Export" {
        It "can export to multiple formats from same compliance data" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $compliance = Test-HardeningCompliance -Session $session

            $textReport = Export-HardeningReport -ComplianceReport $compliance -Format Text
            $jsonReport = Export-HardeningReport -ComplianceReport $compliance -Format JSON
            $csvReport = Export-HardeningReport -ComplianceReport $compliance -Format CSV
            $htmlReport = Export-HardeningReport -ComplianceReport $compliance -Format HTML

            $textReport | Should -Not -BeNullOrEmpty
            $jsonReport | Should -Not -BeNullOrEmpty
            $csvReport | Should -Not -BeNullOrEmpty
            $htmlReport | Should -Not -BeNullOrEmpty
        }
    }

    Context "Documentation" {
        It "has complete help documentation" {
            $help = Get-Help Export-HardeningReport
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }

        It "help includes parameter descriptions" {
            $help = Get-Help Export-HardeningReport
            $help.Parameters.Parameter.Name | Should -Contain 'ComplianceReport'
            $help.Parameters.Parameter.Name | Should -Contain 'Format'
        }
    }
}

Describe "Export-HardeningReport - Integration" {
    Context "Complete Advanced Workflow" {
        It "can generate report after compliance check" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            Invoke-SecurityHardening -Session $session | Out-Null
            $compliance = Test-HardeningCompliance -Session $session

            $report = Export-HardeningReport -ComplianceReport $compliance -Format Text
            $report | Should -Not -BeNullOrEmpty
        }
    }
}
