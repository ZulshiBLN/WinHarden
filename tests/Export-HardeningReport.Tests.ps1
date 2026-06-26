BeforeAll {
    # Load Core module for Write-Log and Write-ErrorLog dependencies
    $corePath = (Resolve-Path "$PSScriptRoot\..\modules\Core.psm1").Path
    Import-Module $corePath -Force

    # Source Export-HardeningReport function and its private helpers directly
    $exportReportPath = (Resolve-Path "$PSScriptRoot\..\functions\System\Hardening\Export-HardeningReport.ps1").Path
    . $exportReportPath

    # Load test fixtures
    $script:basisReport = Get-Content "$PSScriptRoot\fixtures\ComplianceReport-Basis.json" | ConvertFrom-Json
    $script:recommendedReport = Get-Content "$PSScriptRoot\fixtures\ComplianceReport-Recommended.json" | ConvertFrom-Json
}

AfterAll {
    Remove-Module Core -Force -ErrorAction SilentlyContinue
}

Describe "Export-HardeningReport" {
    Context "Parameter Validation" {
        BeforeEach {
            Mock Write-Log -ParameterFilter { $true }
        }

        It "accepts a valid compliance report object" {
            { Export-HardeningReport -ComplianceReport $script:basisReport } | Should -Not -Throw
        }

        It "requires a compliance report parameter" {
            { Export-HardeningReport } | Should -Throw
        }

        It "accepts JSON format" {
            { Export-HardeningReport -ComplianceReport $script:basisReport -Format JSON } | Should -Not -Throw
        }

        It "accepts CSV format" {
            { Export-HardeningReport -ComplianceReport $script:basisReport -Format CSV } | Should -Not -Throw
        }

        It "accepts HTML format" {
            { Export-HardeningReport -ComplianceReport $script:basisReport -Format HTML } | Should -Not -Throw
        }

        It "accepts Text format (default)" {
            { Export-HardeningReport -ComplianceReport $script:basisReport -Format Text } | Should -Not -Throw
        }
    }

    Context "Report Generation" {
        BeforeEach {
            Mock Write-Log -ParameterFilter { $true }
        }

        It "generates Text report by default" {
            $report = Export-HardeningReport -ComplianceReport $script:basisReport
            $report | Should -Not -BeNullOrEmpty
            $report -like '*COMPLIANCE SUMMARY*' | Should -Be $true
        }

        It "generates JSON report" {
            $report = Export-HardeningReport -ComplianceReport $script:basisReport -Format JSON
            { $report | ConvertFrom-Json } | Should -Not -Throw
            $json = $report | ConvertFrom-Json
            $json.ComplianceSummary.CompliancePercentage | Should -Be $script:basisReport.CompliancePercentage
        }

        It "generates CSV report" {
            $report = Export-HardeningReport -ComplianceReport $script:basisReport -Format CSV
            $report | Should -Not -BeNullOrEmpty
            $report[0] -like '*Profile*' | Should -Be $true
        }

        It "generates HTML report" {
            $report = Export-HardeningReport -ComplianceReport $script:basisReport -Format HTML
            $report | Should -Not -BeNullOrEmpty
            $report -like '*<!DOCTYPE html>*' | Should -Be $true
        }

        It "includes profile details in report" {
            $report = Export-HardeningReport -ComplianceReport $script:recommendedReport -Format Text
            $report | Should -Match 'Recommended'
        }

        It "includes compliance percentage in report" {
            $report = Export-HardeningReport -ComplianceReport $script:basisReport -Format Text
            $report | Should -Match "$($script:basisReport.CompliancePercentage)%"
        }
    }

    Context "File Output" {
        BeforeEach {
            Mock Write-Log -ParameterFilter { $true }
        }

        It "saves report to file" {
            $testPath = Join-Path -Path $env:TEMP -ChildPath "test-report-$(Get-Random).txt"

            try {
                Export-HardeningReport -ComplianceReport $script:basisReport -Format Text -OutputPath $testPath | Out-Null
                Test-Path -Path $testPath | Should -Be $true
            }
            finally {
                Remove-Item -Path $testPath -Force -ErrorAction SilentlyContinue
            }
        }

        It "returns file info object when saving" {
            $testPath = Join-Path -Path $env:TEMP -ChildPath "test-report-$(Get-Random).json"

            try {
                $result = Export-HardeningReport -ComplianceReport $script:basisReport -Format JSON -OutputPath $testPath
                $result | Should -Not -BeNullOrEmpty
                # Normalize paths for comparison (Windows may expand short names)
                $result.FullName | Should -Match ([regex]::Escape("test-report"))
                Test-Path -Path $testPath | Should -Be $true
            }
            finally {
                Remove-Item -Path $testPath -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Context "Detailed Mode" {
        BeforeEach {
            Mock Write-Log -ParameterFilter { $true }
        }

        It "includes rule details when specified" {
            $report = Export-HardeningReport -ComplianceReport $script:basisReport -Format JSON -IncludeRuleDetails
            $json = $report | ConvertFrom-Json
            $json.RuleDetails | Should -Not -BeNullOrEmpty
            $json.RuleDetails.Count | Should -BeGreaterThan 0
        }

        It "omits rule details when not specified" {
            $report = Export-HardeningReport -ComplianceReport $script:basisReport -Format JSON
            $json = $report | ConvertFrom-Json
            $json.RuleDetails | Should -BeNullOrEmpty
        }
    }

    Context "Format Support" {
        BeforeEach {
            Mock Write-Log -ParameterFilter { $true }
        }

        It "Text format includes summary section" {
            $report = Export-HardeningReport -ComplianceReport $script:basisReport -Format Text
            $report | Should -Match 'COMPLIANCE SUMMARY'
        }

        It "JSON format is valid JSON" {
            $report = Export-HardeningReport -ComplianceReport $script:basisReport -Format JSON
            $json = $report | ConvertFrom-Json
            $json | Should -Not -BeNullOrEmpty
            $json.ComplianceSummary | Should -Not -BeNullOrEmpty
        }

        It "CSV format includes headers" {
            $report = Export-HardeningReport -ComplianceReport $script:basisReport -Format CSV
            $lines = @($report)
            $lines[0] | Should -Match 'Profile'
        }

        It "HTML format includes DOCTYPE" {
            $report = Export-HardeningReport -ComplianceReport $script:basisReport -Format HTML
            $report | Should -Match '<!DOCTYPE'
        }

        It "Text format includes category breakdown" {
            $report = Export-HardeningReport -ComplianceReport $script:basisReport -Format Text
            $report | Should -Match 'CATEGORY BREAKDOWN'
        }

        It "JSON includes metadata" {
            $report = Export-HardeningReport -ComplianceReport $script:basisReport -Format JSON
            $json = $report | ConvertFrom-Json
            $json.ReportMetadata.Profile | Should -Be $script:basisReport.Profile
            $json.ReportMetadata.SessionId | Should -Be $script:basisReport.SessionId
        }
    }

    Context "Integration with Compliance Reports" {
        BeforeEach {
            Mock Write-Log -ParameterFilter { $true }
        }

        It "exports Basis profile report successfully" {
            $report = Export-HardeningReport -ComplianceReport $script:basisReport
            $report | Should -Not -BeNullOrEmpty
            $report | Should -Match 'Basis'
        }

        It "exports Recommended profile report successfully" {
            $report = Export-HardeningReport -ComplianceReport $script:recommendedReport
            $report | Should -Not -BeNullOrEmpty
            $report | Should -Match 'Recommended'
        }

        It "exports different compliance percentages correctly" {
            $report1 = Export-HardeningReport -ComplianceReport $script:basisReport -Format Text
            $report2 = Export-HardeningReport -ComplianceReport $script:recommendedReport -Format Text

            $report1 | Should -Match '85%'
            $report2 | Should -Match '95%'
        }
    }

    Context "Multiple Format Export" {
        BeforeEach {
            Mock Write-Log -ParameterFilter { $true }
        }

        It "can export to multiple formats from same compliance data" {
            $textReport = Export-HardeningReport -ComplianceReport $script:basisReport -Format Text
            $jsonReport = Export-HardeningReport -ComplianceReport $script:basisReport -Format JSON
            $csvReport = @(Export-HardeningReport -ComplianceReport $script:basisReport -Format CSV)
            $htmlReport = Export-HardeningReport -ComplianceReport $script:basisReport -Format HTML

            $textReport | Should -Not -BeNullOrEmpty
            $jsonReport | Should -Not -BeNullOrEmpty
            $csvReport | Should -Not -BeNullOrEmpty
            $htmlReport | Should -Not -BeNullOrEmpty
        }

        It "all formats contain compliance percentage" {
            $textReport = Export-HardeningReport -ComplianceReport $script:basisReport -Format Text
            $jsonReport = Export-HardeningReport -ComplianceReport $script:basisReport -Format JSON
            $htmlReport = Export-HardeningReport -ComplianceReport $script:basisReport -Format HTML

            $textReport | Should -Match '85%'
            ($jsonReport | ConvertFrom-Json).ComplianceSummary.CompliancePercentage | Should -Be 85
            $htmlReport | Should -Match '85'
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

    Context "Error Handling" {
        BeforeEach {
            Mock Write-Log -ParameterFilter { $true }
            Mock Write-ErrorLog -ParameterFilter { $true }
        }

        It "throws on null compliance report" {
            { Export-HardeningReport -ComplianceReport $null } | Should -Throw
        }

        It "throws on invalid format" {
            { Export-HardeningReport -ComplianceReport $script:basisReport -Format "InvalidFormat" } | Should -Throw
        }

        It "processes report even with minimal properties" {
            $minimalReport = [PSCustomObject]@{
                CompliancePercentage = 50
                Status = "Test"
                TotalRules = 10
                CompliantRules = 5
                NonCompliantRules = 5
                Profile = "Test"
                TargetSystem = "Test"
                VerificationTime = (Get-Date)
                SessionId = "TEST-001"
                CategoryBreakdown = @{}
                RuleResults = @()
            }
            # Should succeed with minimal properties
            $result = Export-HardeningReport -ComplianceReport $minimalReport -Format Text
            $result | Should -Not -BeNullOrEmpty
        }

        It "creates file with proper UTF-8 encoding" {
            $testPath = Join-Path -Path $env:TEMP -ChildPath "test-utf8-$(Get-Random).txt"
            try {
                Export-HardeningReport -ComplianceReport $script:basisReport -Format Text -OutputPath $testPath
                $fileContent = Get-Content -Path $testPath -Encoding UTF8
                $fileContent | Should -Not -BeNullOrEmpty
            }
            finally {
                Remove-Item -Path $testPath -Force -ErrorAction SilentlyContinue
            }
        }

        It "overwrites existing file when OutputPath exists" {
            $testPath = Join-Path -Path $env:TEMP -ChildPath "test-overwrite-$(Get-Random).txt"
            try {
                # Create initial file
                "Old Content" | Set-Content -Path $testPath -Encoding UTF8

                # Export report (should overwrite)
                Export-HardeningReport -ComplianceReport $script:basisReport -Format Text -OutputPath $testPath

                # Verify file was overwritten
                $content = @(Get-Content -Path $testPath -Encoding UTF8)
                $fullContent = $content -join "`n"
                $fullContent | Should -Match "COMPLIANCE SUMMARY"
            }
            finally {
                Remove-Item -Path $testPath -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

Describe "Export-HardeningReport - Edge Cases" {
    BeforeEach {
        Mock Write-Log -ParameterFilter { $true }
        Mock Write-ErrorLog -ParameterFilter { $true }
    }

    Context "CSV Format Validation" {
        It "CSV output is properly formatted with headers" {
            $report = Export-HardeningReport -ComplianceReport $script:basisReport -Format CSV
            $lines = @($report)
            $lines | Should -Not -BeNullOrEmpty
            # First line should contain headers
            $lines[0] | Should -Match "Profile|TargetSystem"
        }
    }

    Context "Fixture Data Validation" {
        It "Basis report has expected profile name" {
            $report = Export-HardeningReport -ComplianceReport $script:basisReport -Format JSON
            $json = $report | ConvertFrom-Json
            $json.ReportMetadata.Profile | Should -Be "Basis"
        }

        It "Recommended report has higher compliance percentage than Basis" {
            $report1 = Export-HardeningReport -ComplianceReport $script:basisReport -Format JSON
            $report2 = Export-HardeningReport -ComplianceReport $script:recommendedReport -Format JSON

            $json1 = $report1 | ConvertFrom-Json
            $json2 = $report2 | ConvertFrom-Json

            $json2.ComplianceSummary.CompliancePercentage | Should -BeGreaterThan $json1.ComplianceSummary.CompliancePercentage
        }
    }

    Context "WhatIf Support" {
        It "respects -WhatIf flag and does not create file" {
            $testPath = Join-Path -Path $env:TEMP -ChildPath "test-whatif-$(Get-Random).txt"

            try {
                Export-HardeningReport -ComplianceReport $script:basisReport -Format Text -OutputPath $testPath -WhatIf
                Test-Path -Path $testPath | Should -Be $false
            }
            finally {
                Remove-Item -Path $testPath -Force -ErrorAction SilentlyContinue
            }
        }

        It "without -WhatIf creates file normally" {
            $testPath = Join-Path -Path $env:TEMP -ChildPath "test-normal-$(Get-Random).txt"

            try {
                Export-HardeningReport -ComplianceReport $script:basisReport -Format Text -OutputPath $testPath
                Test-Path -Path $testPath | Should -Be $true
            }
            finally {
                Remove-Item -Path $testPath -Force -ErrorAction SilentlyContinue
            }
        }

        It "allows report generation without -WhatIf when OutputPath omitted" {
            $report = Export-HardeningReport -ComplianceReport $script:basisReport -Format Text -WhatIf
            $report | Should -Not -BeNullOrEmpty
            $report | Should -Match 'COMPLIANCE SUMMARY'
        }
    }
}
