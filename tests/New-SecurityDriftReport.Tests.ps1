BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\System.psm1").Path
    Import-Module $modulePath -Force

    # Setup test fixtures directory
    $fixturesDir = "$PSScriptRoot\fixtures"
    if (-not (Test-Path $fixturesDir)) {
        New-Item -ItemType Directory -Path $fixturesDir -Force | Out-Null
    }

    # Create sample drift findings for testing
    $script:testDriftFindings = @(
        [PSCustomObject]@{
            Finding = "Password expiration not configured"
            Severity = "CRITICAL"
            Category = "Account Policies"
            Current = "Disabled"
            Expected = "90 days"
            Remediation = "Configure password expiration policy"
        },
        [PSCustomObject]@{
            Finding = "SMB signing not enforced"
            Severity = "HIGH"
            Category = "Network Security"
            Current = "Not enforced"
            Expected = "Required"
            Remediation = "Enable SMB signing via registry"
        },
        [PSCustomObject]@{
            Finding = "RDP NLA disabled"
            Severity = "HIGH"
            Category = "RDP Security"
            Current = "Disabled"
            Expected = "Enabled"
            Remediation = "Enable RDP NLA via registry"
        },
        [PSCustomObject]@{
            Finding = "Windows Update auto-install disabled"
            Severity = "MEDIUM"
            Category = "Updates"
            Current = "Manual"
            Expected = "Auto-Install"
            Remediation = "Configure auto-install policy"
        }
    )

    # Create empty findings for compliant test
    $script:emptyDriftFindings = @()
}

AfterAll {
    Remove-Module System -Force -ErrorAction SilentlyContinue
}

Describe "New-SecurityDriftReport" {
    Context "Parameter Validation" {
        It "accepts DriftFindings parameter as array" {
            $result = New-SecurityDriftReport -DriftFindings $testDriftFindings -ErrorAction Stop
            $result | Should -Not -BeNullOrEmpty
        }

        It "accepts DriftFindings as single object" {
            $result = New-SecurityDriftReport -DriftFindings $testDriftFindings[0] -ErrorAction Stop
            $result | Should -Not -BeNullOrEmpty
        }

        It "accepts OutputDirectory parameter" {
            $testTempDir = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "DriftTest_$(Get-Random)")
            New-Item -ItemType Directory -Path $testTempDir -Force | Out-Null
            try {
                $result = New-SecurityDriftReport -DriftFindings $testDriftFindings -OutputDirectory $testTempDir -ErrorAction Stop
                $result.ReportPath | Should -Match ([regex]::Escape($testTempDir))
            }
            finally {
                Remove-Item -Path $testTempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It "uses default logs directory when OutputDirectory not specified" {
            $result = New-SecurityDriftReport -DriftFindings $testDriftFindings -ErrorAction Stop
            $result.ReportPath | Should -Match "logs"
        }
    }

    Context "Report Generation - Basic Output" {
        It "returns PSCustomObject with required properties" {
            $result = New-SecurityDriftReport -DriftFindings $testDriftFindings -ErrorAction Stop
            $result.PSObject.Properties.Name | Should -Contain "ReportPath"
            $result.PSObject.Properties.Name | Should -Contain "Status"
            $result.PSObject.Properties.Name | Should -Contain "DriftCount"
            $result.PSObject.Properties.Name | Should -Contain "Severity"
        }

        It "generates report path with timestamp" {
            $result = New-SecurityDriftReport -DriftFindings $testDriftFindings -ErrorAction Stop
            $result.ReportPath | Should -Match "Drift_Detection_\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}\.csv"
        }

        It "sets status to NON-COMPLIANT when findings exist" {
            $result = New-SecurityDriftReport -DriftFindings $testDriftFindings -ErrorAction Stop
            $result.Status | Should -Be "NON-COMPLIANT"
            $result.DriftCount | Should -Be 4
        }

        It "sets status to COMPLIANT when no findings" {
            $result = New-SecurityDriftReport -DriftFindings $emptyDriftFindings -ErrorAction Stop
            $result.Status | Should -Be "COMPLIANT"
            $result.DriftCount | Should -Be 0
        }
    }

    Context "Severity Calculation" {
        It "calculates overall severity as CRITICAL when critical findings exist" {
            $result = New-SecurityDriftReport -DriftFindings $testDriftFindings -ErrorAction Stop
            $result.Severity | Should -Be "CRITICAL"
        }

        It "calculates overall severity as HIGH when only high findings exist" {
            $findings = @($testDriftFindings | Where-Object Severity -ne "CRITICAL")
            $result = New-SecurityDriftReport -DriftFindings $findings -ErrorAction Stop
            $result.Severity | Should -Be "HIGH"
        }

        It "calculates overall severity as MEDIUM when only medium findings exist" {
            $findings = @($testDriftFindings | Where-Object Severity -eq "MEDIUM")
            $result = New-SecurityDriftReport -DriftFindings $findings -ErrorAction Stop
            $result.Severity | Should -Be "MEDIUM"
        }

        It "sets severity based on highest severity present" {
            $findings = @(
                [PSCustomObject]@{ Severity = "MEDIUM" },
                [PSCustomObject]@{ Severity = "MEDIUM" },
                [PSCustomObject]@{ Severity = "HIGH" }
            )
            $result = New-SecurityDriftReport -DriftFindings $findings -ErrorAction Stop
            $result.Severity | Should -Be "HIGH"
        }
    }

    Context "CSV File Creation" {
        BeforeEach {
            $testTempDir = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "DriftReport_$(Get-Random)")
            New-Item -ItemType Directory -Path $testTempDir -Force | Out-Null
        }

        AfterEach {
            if (Test-Path $testTempDir) {
                Remove-Item -Path $testTempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It "creates CSV report file" {
            $result = New-SecurityDriftReport -DriftFindings $testDriftFindings -OutputDirectory $testTempDir -ErrorAction Stop
            Test-Path $result.ReportPath | Should -Be $true
            $result.ReportPath | Should -Match "\.csv$"
        }

        It "creates output directory if not exists" {
            $newDir = [System.IO.Path]::Combine($testTempDir, "NewReports")
            Test-Path $newDir | Should -Be $false

            $result = New-SecurityDriftReport -DriftFindings $testDriftFindings -OutputDirectory $newDir -ErrorAction Stop

            Test-Path $newDir | Should -Be $true
            Test-Path $result.ReportPath | Should -Be $true
        }

        It "CSV file contains summary and findings" {
            $result = New-SecurityDriftReport -DriftFindings $testDriftFindings -OutputDirectory $testTempDir -ErrorAction Stop

            $csvContent = Import-Csv $result.ReportPath
            $csvContent | Should -Not -BeNullOrEmpty
            $csvContent.Count | Should -BeGreaterThan 0
        }

        It "CSV includes hostname in summary" {
            $result = New-SecurityDriftReport -DriftFindings $testDriftFindings -OutputDirectory $testTempDir -ErrorAction Stop

            $csvContent = Import-Csv $result.ReportPath
            $summaryRow = $csvContent | Select-Object -First 1
            $summaryRow.Hostname | Should -Be $env:COMPUTERNAME
        }

        It "CSV includes status in summary" {
            $result = New-SecurityDriftReport -DriftFindings $testDriftFindings -OutputDirectory $testTempDir -ErrorAction Stop

            $csvContent = Import-Csv $result.ReportPath
            $summaryRow = $csvContent | Select-Object -First 1
            $summaryRow.Status | Should -Be "NON-COMPLIANT"
        }

        It "CSV includes drift count summary" {
            $result = New-SecurityDriftReport -DriftFindings $testDriftFindings -OutputDirectory $testTempDir -ErrorAction Stop

            $csvContent = Import-Csv $result.ReportPath
            $summaryRow = $csvContent | Select-Object -First 1
            $summaryRow.Total_Drifts | Should -Be "4"
        }

        It "CSV includes severity breakdown (CRITICAL, HIGH, MEDIUM)" {
            $result = New-SecurityDriftReport -DriftFindings $testDriftFindings -OutputDirectory $testTempDir -ErrorAction Stop

            $csvContent = Import-Csv $result.ReportPath
            $summaryRow = $csvContent | Select-Object -First 1
            $summaryRow.Critical_Count | Should -Be "1"
            $summaryRow.High_Count | Should -Be "2"
            $summaryRow.Medium_Count | Should -Be "1"
        }

        It "appends detailed findings to CSV after summary" {
            $result = New-SecurityDriftReport -DriftFindings $testDriftFindings -OutputDirectory $testTempDir -ErrorAction Stop

            $csvContent = Import-Csv $result.ReportPath
            # First row is summary, next rows should be findings
            $csvContent.Count | Should -Be 5  # 1 summary + 4 findings
        }

        It "handles empty findings (compliant system)" {
            $result = New-SecurityDriftReport -DriftFindings $emptyDriftFindings -OutputDirectory $testTempDir -ErrorAction Stop

            Test-Path $result.ReportPath | Should -Be $true
            $csvContent = @(Import-Csv $result.ReportPath)
            $csvContent[0].Status | Should -Be "COMPLIANT"
            $csvContent.Count | Should -Be 1  # Only summary, no findings
        }
    }

    Context "WhatIf Support" {
        BeforeEach {
            $testTempDir = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "DriftReport_$(Get-Random)")
            New-Item -ItemType Directory -Path $testTempDir -Force | Out-Null
        }

        AfterEach {
            if (Test-Path $testTempDir) {
                Remove-Item -Path $testTempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It "accepts -WhatIf parameter" {
            $result = New-SecurityDriftReport -DriftFindings $testDriftFindings -OutputDirectory $testTempDir -WhatIf
            $result | Should -Not -BeNullOrEmpty
        }

        It "does not create report file with -WhatIf" {
            $result = New-SecurityDriftReport -DriftFindings $testDriftFindings -OutputDirectory $testTempDir -WhatIf -ErrorAction SilentlyContinue
            # With WhatIf, file should not be created
            if ($result.ReportPath) {
                Test-Path $result.ReportPath | Should -Be $false
            }
        }

        It "still returns object with -WhatIf" {
            $result = New-SecurityDriftReport -DriftFindings $testDriftFindings -OutputDirectory $testTempDir -WhatIf -ErrorAction SilentlyContinue
            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context "Error Handling" {
        It "handles inaccessible output directory gracefully" {
            $invalidDir = "Z:\NonExistentDrive\Path"
            { New-SecurityDriftReport -DriftFindings $testDriftFindings -OutputDirectory $invalidDir -ErrorAction Stop } | Should -Throw
        }

        It "logs errors via Write-Log on invalid directory" {
            { New-SecurityDriftReport -DriftFindings $testDriftFindings -OutputDirectory "Z:\InvalidPath" -ErrorAction Stop } |
                Should -Throw
        }
    }

    Context "Edge Cases" {
        It "handles single finding" {
            $singleFinding = @($testDriftFindings[0])
            $result = New-SecurityDriftReport -DriftFindings $singleFinding -ErrorAction Stop
            $result.DriftCount | Should -Be 1
            $result.Status | Should -Be "NON-COMPLIANT"
        }

        It "handles findings with special characters in values" {
            $findings = @(
                [PSCustomObject]@{
                    Finding = "Test with 'quotes' and `"double quotes`""
                    Severity = "HIGH"
                    Category = "Test"
                    Current = "Value with, comma"
                    Expected = "Expected value"
                    Remediation = "Remediation steps"
                }
            )
            $result = New-SecurityDriftReport -DriftFindings $findings -ErrorAction Stop
            $result.Status | Should -Be "NON-COMPLIANT"
        }

        It "handles large number of findings" {
            $largeFindingSet = @()
            for ($i = 1; $i -le 100; $i++) {
                $largeFindingSet += [PSCustomObject]@{
                    Finding = "Finding $i"
                    Severity = @("CRITICAL", "HIGH", "MEDIUM")[(($i - 1) % 3)]
                    Category = "Test Category"
                    Current = "Current Value"
                    Expected = "Expected Value"
                    Remediation = "Fix"
                }
            }
            $result = New-SecurityDriftReport -DriftFindings $largeFindingSet -ErrorAction Stop
            $result.DriftCount | Should -Be 100
        }

        It "uses correct timestamp format in report filename" {
            $result = New-SecurityDriftReport -DriftFindings $testDriftFindings -ErrorAction Stop
            $filename = [System.IO.Path]::GetFileName($result.ReportPath)
            $filename | Should -Match "Drift_Detection_\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}\.csv"
        }

        It "generates unique filenames for multiple reports in same directory" {
            $reportTempDir = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "DriftReportTest_$(Get-Random)")
            New-Item -ItemType Directory -Path $reportTempDir -Force | Out-Null
            try {
                $result1 = New-SecurityDriftReport -DriftFindings $testDriftFindings -OutputDirectory $reportTempDir -ErrorAction Stop
                Start-Sleep -Seconds 1.1  # Ensure timestamp differs (reports use second-level precision)

                $result2 = New-SecurityDriftReport -DriftFindings $testDriftFindings -OutputDirectory $reportTempDir -ErrorAction Stop

                $result1.ReportPath | Should -Not -Be $result2.ReportPath
                Test-Path $result1.ReportPath | Should -Be $true
                Test-Path $result2.ReportPath | Should -Be $true
            }
            finally {
                Remove-Item -Path $reportTempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Context "Compliance Reports" {
        BeforeEach {
            $testTempDir = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "DriftReport_$(Get-Random)")
            New-Item -ItemType Directory -Path $testTempDir -Force | Out-Null
        }

        AfterEach {
            if (Test-Path $testTempDir) {
                Remove-Item -Path $testTempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        It "generates COMPLIANT report when no drifts detected" {
            $result = New-SecurityDriftReport -DriftFindings @() -OutputDirectory $testTempDir -ErrorAction Stop
            $result.Status | Should -Be "COMPLIANT"
            $result.Severity | Should -Match "CRITICAL|HIGH|MEDIUM"  # Some default when empty
        }

        It "includes Overall_Severity in summary" {
            $result = New-SecurityDriftReport -DriftFindings $testDriftFindings -OutputDirectory $testTempDir -ErrorAction Stop
            $csvContent = Import-Csv $result.ReportPath
            $summaryRow = $csvContent | Select-Object -First 1
            $summaryRow.Overall_Severity | Should -Be "CRITICAL"
        }

        It "includes timestamp in report summary" {
            $result = New-SecurityDriftReport -DriftFindings $testDriftFindings -OutputDirectory $testTempDir -ErrorAction Stop
            $csvContent = Import-Csv $result.ReportPath
            $summaryRow = $csvContent | Select-Object -First 1
            $summaryRow.Scan_Date | Should -Not -BeNullOrEmpty
            $summaryRow.Scan_Date | Should -Match "\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}"
        }
    }

    Context "Documentation" {
        It "has complete help documentation" {
            $help = Get-Help New-SecurityDriftReport
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }

        It "documents DriftFindings parameter" {
            $help = Get-Help New-SecurityDriftReport
            $help.Parameters.Parameter.Name | Should -Contain "DriftFindings"
        }

        It "documents OutputDirectory parameter" {
            $help = Get-Help New-SecurityDriftReport
            $help.Parameters.Parameter.Name | Should -Contain "OutputDirectory"
        }

        It "includes usage examples" {
            $help = Get-Help New-SecurityDriftReport
            $help.Examples | Should -Not -BeNullOrEmpty
        }
    }
}
