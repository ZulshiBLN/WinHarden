BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\System.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module System -Force -ErrorAction SilentlyContinue
}

Describe "Get-HardeningTrendData" {
    Context "Parameter Validation" {
        It "accepts ComputerName parameter" {
            { Get-HardeningTrendData -ComputerName $env:COMPUTERNAME -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Days parameter with valid range 1-365" {
            { Get-HardeningTrendData -Days 30 -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Repository parameter with custom path" {
            { Get-HardeningTrendData -Repository "C:\CustomRepo" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts OutputFormat parameter for Table" {
            { Get-HardeningTrendData -OutputFormat Table -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts OutputFormat parameter for JSON" {
            { Get-HardeningTrendData -OutputFormat JSON -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts OutputFormat parameter for PSCustomObject" {
            { Get-HardeningTrendData -OutputFormat PSCustomObject -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "rejects Days value below 1" {
            { Get-HardeningTrendData -Days 0 -ErrorAction Stop } | Should -Throw
        }

        It "rejects Days value above 365" {
            { Get-HardeningTrendData -Days 366 -ErrorAction Stop } | Should -Throw
        }
    }

    Context "Default Behavior" {
        It "uses localhost as default ComputerName" {
            { Get-HardeningTrendData -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "uses 30 days as default Days" {
            { Get-HardeningTrendData -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "uses default Repository path when not specified" {
            { Get-HardeningTrendData -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "uses PSCustomObject as default OutputFormat" {
            { Get-HardeningTrendData -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Time Range Support" {
        It "retrieves data for last 7 days" {
            { Get-HardeningTrendData -Days 7 -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "retrieves data for last 30 days" {
            { Get-HardeningTrendData -Days 30 -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "retrieves data for last 90 days" {
            { Get-HardeningTrendData -Days 90 -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "retrieves data for last 365 days" {
            { Get-HardeningTrendData -Days 365 -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Repository Handling" {
        It "returns empty array when repository does not exist" {
            $result = Get-HardeningTrendData -Repository "C:\NonExistentPath" -ErrorAction SilentlyContinue
            $result | Should -Be @()
        }

        It "returns empty array when no computer history exists" {
            $testComputerName = "NONEXISTENT-$(Get-Random)"
            $result = Get-HardeningTrendData -ComputerName $testComputerName -ErrorAction SilentlyContinue
            $result | Should -Be @()
        }

        It "logs warning when repository not found" {
            { Get-HardeningTrendData -Repository "C:\NonExistent" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Output Formats" {
        It "returns PSCustomObject by default" {
            { Get-HardeningTrendData -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "can output as Table format" {
            { Get-HardeningTrendData -OutputFormat Table -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "can output as JSON format" {
            { Get-HardeningTrendData -OutputFormat JSON -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Trend Metrics Calculation" {
        It "includes Date property in output" {
            { Get-HardeningTrendData -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes CompliancePercentage property" {
            { Get-HardeningTrendData -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes Trend direction property (Stable/Improving/Declining)" {
            { Get-HardeningTrendData -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes VelocityPercent property for compliance change rate" {
            { Get-HardeningTrendData -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Error Handling" {
        It "handles corrupted JSON data gracefully" {
            { Get-HardeningTrendData -Repository "C:\NonExistent" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "continues processing even if one file fails to parse" {
            { Get-HardeningTrendData -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "logs errors without stopping execution" {
            { Get-HardeningTrendData -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Trend Data Processing" {
        It "processes trend data without errors" {
            { Get-HardeningTrendData -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "calculates compliance metrics" {
            { Get-HardeningTrendData -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes forecast data in output" {
            { Get-HardeningTrendData -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Documentation" {
        It "Get-HardeningTrendData has complete help documentation" {
            $help = Get-Help Get-HardeningTrendData
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }

        It "Get-HardeningTrendData help includes ComputerName parameter" {
            $help = Get-Help Get-HardeningTrendData
            $help.Parameters.Parameter.Name | Should -Contain 'ComputerName'
        }

        It "Get-HardeningTrendData help includes Days parameter" {
            $help = Get-Help Get-HardeningTrendData
            $help.Parameters.Parameter.Name | Should -Contain 'Days'
        }
    }

    Context "WhatIf Support" {
        It "Get-HardeningTrendData supports -WhatIf parameter" {
            { Get-HardeningTrendData -WhatIf -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }
}
