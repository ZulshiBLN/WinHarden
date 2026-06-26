BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\System.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module System -Force -ErrorAction SilentlyContinue
}

Describe "System Module - Export-HardeningReport" {
    Context "Export-HardeningReport - Parameter Validation" {
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

    Context "Export-HardeningReport - Report Generation" {
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

    Context "Export-HardeningReport - File Output" {
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

    Context "Export-HardeningReport - Detailed Mode" {
        It "includes rule details when specified" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            $compliance = Test-HardeningCompliance -Session $session
            $report = Export-HardeningReport -ComplianceReport $compliance -Format JSON -IncludeRuleDetails

            $json = $report | ConvertFrom-Json
            $json.RuleDetails | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "System Module - Invoke-RemoteHardening" {
    Context "Invoke-RemoteHardening - Parameter Validation" {
        It "accepts ComputerName parameter" {
            { Invoke-RemoteHardening -ComputerName 'localhost' -Profile Basis -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts multiple computer names" {
            { Invoke-RemoteHardening -ComputerName @('localhost', '127.0.0.1') -Profile Basis -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Parallel switch" {
            { Invoke-RemoteHardening -ComputerName 'localhost' -Profile Basis -Parallel -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts UseSSL switch" {
            { Invoke-RemoteHardening -ComputerName 'localhost' -Profile Basis -UseSSL -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Port parameter" {
            { Invoke-RemoteHardening -ComputerName 'localhost' -Profile Basis -Port 5986 -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }
}

Describe "System Module - New-HardeningSchedule" {
    Context "New-HardeningSchedule - Parameter Validation" {
        It "accepts Profile parameter" {
            { New-HardeningSchedule -Profile Basis -Schedule OneTime -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Schedule parameter" {
            { New-HardeningSchedule -Profile Basis -Schedule Daily -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Time parameter" {
            { New-HardeningSchedule -Profile Basis -Schedule Daily -Time "02:00" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts DayOfWeek for Weekly schedule" {
            { New-HardeningSchedule -Profile Basis -Schedule Weekly -DayOfWeek Monday -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts DayOfMonth for Monthly schedule" {
            { New-HardeningSchedule -Profile Basis -Schedule Monthly -DayOfMonth 1 -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts AutoRemediate switch" {
            { New-HardeningSchedule -Profile Basis -Schedule OneTime -AutoRemediate -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts GenerateReport switch" {
            { New-HardeningSchedule -Profile Basis -Schedule OneTime -GenerateReport -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "New-HardeningSchedule - Validation Rules" {
        It "requires DayOfWeek for Weekly schedule" {
            { New-HardeningSchedule -Profile Basis -Schedule Weekly -ErrorAction Stop } | Should -Throw
        }

        It "requires DayOfMonth for Monthly schedule" {
            { New-HardeningSchedule -Profile Basis -Schedule Monthly -ErrorAction Stop } | Should -Throw
        }
    }
}

Describe "System Module - Phase 4 Integration" {
    Context "Complete Advanced Workflow" {
        It "can generate report after compliance check" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
            Invoke-SecurityHardening -Session $session | Out-Null
            $compliance = Test-HardeningCompliance -Session $session

            $report = Export-HardeningReport -ComplianceReport $compliance -Format Text
            $report | Should -Not -BeNullOrEmpty
        }

        It "exports to multiple formats from same compliance data" {
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
}

Describe "System Module - Documentation" {
    Context "Phase 4 Functions Help" {
        It "Export-HardeningReport has help" {
            $help = Get-Help Export-HardeningReport
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }

        It "Invoke-RemoteHardening has help" {
            $help = Get-Help Invoke-RemoteHardening
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }

        It "New-HardeningSchedule has help" {
            $help = Get-Help New-HardeningSchedule
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }
    }
}
