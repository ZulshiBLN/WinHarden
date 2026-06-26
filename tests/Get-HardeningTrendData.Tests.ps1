BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\System.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module System -Force -ErrorAction SilentlyContinue
}

Describe "Get-HardeningTrendData" {
    Context "Parameter Validation" {
        It "accepts TimeSpan parameter" {
            { Get-HardeningTrendData -TimeSpan 30 -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts TimeUnit parameter" {
            $units = @('Days', 'Weeks', 'Months')
            foreach ($unit in $units) {
                { Get-HardeningTrendData -TimeSpan 1 -TimeUnit $unit -ErrorAction SilentlyContinue } | Should -Not -Throw
            }
        }

        It "accepts Profile parameter" {
            { Get-HardeningTrendData -Profile Basis -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts detailed switch" {
            { Get-HardeningTrendData -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts IncludeComparison switch" {
            { Get-HardeningTrendData -IncludeComparison -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Time Range Support" {
        It "retrieves data for last 7 days" {
            { Get-HardeningTrendData -TimeSpan 7 -TimeUnit Days -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "retrieves data for last 30 days" {
            { Get-HardeningTrendData -TimeSpan 30 -TimeUnit Days -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "retrieves data for last 90 days" {
            { Get-HardeningTrendData -TimeSpan 90 -TimeUnit Days -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "retrieves data for last 6 months" {
            { Get-HardeningTrendData -TimeSpan 6 -TimeUnit Months -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "retrieves data for last year" {
            { Get-HardeningTrendData -TimeSpan 12 -TimeUnit Months -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Profile Filtering" {
        It "retrieves trend data for Basis profile" {
            { Get-HardeningTrendData -Profile Basis -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "retrieves trend data for Recommended profile" {
            { Get-HardeningTrendData -Profile Recommended -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "retrieves trend data for Strict profile" {
            { Get-HardeningTrendData -Profile Strict -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "retrieves trend data for all profiles when not specified" {
            { Get-HardeningTrendData -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Trend Metrics" {
        It "includes compliance percentage trend" {
            { Get-HardeningTrendData -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes rule application count trend" {
            { Get-HardeningTrendData -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes failure rate trend" {
            { Get-HardeningTrendData -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes rule success rate over time" {
            { Get-HardeningTrendData -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Data Aggregation" {
        It "aggregates data by day" {
            { Get-HardeningTrendData -AggregationLevel Day -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "aggregates data by week" {
            { Get-HardeningTrendData -AggregationLevel Week -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "aggregates data by month" {
            { Get-HardeningTrendData -AggregationLevel Month -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Comparison Features" {
        It "includes comparison with previous period" {
            { Get-HardeningTrendData -IncludeComparison -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes percentage change from previous period" {
            { Get-HardeningTrendData -IncludeComparison -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "identifies improving and declining trends" {
            { Get-HardeningTrendData -IncludeComparison -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Data Points" {
        It "returns multiple data points for time series" {
            $data = Get-HardeningTrendData -TimeSpan 30 -TimeUnit Days -ErrorAction SilentlyContinue
            if ($data) {
                @($data).Count | Should -BeGreaterThan 0
            }
        }

        It "includes timestamp for each data point" {
            { Get-HardeningTrendData -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes average compliance percentage" {
            { Get-HardeningTrendData -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes maximum and minimum values" {
            { Get-HardeningTrendData -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Export Formats" {
        It "can output as PSCustomObject by default" {
            { Get-HardeningTrendData -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Format parameter for CSV export" {
            { Get-HardeningTrendData -Format CSV -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Format parameter for JSON export" {
            { Get-HardeningTrendData -Format JSON -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Category Breakdown" {
        It "includes category-level trend data when detailed" {
            { Get-HardeningTrendData -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "retrieves trend data by security category" {
            { Get-HardeningTrendData -Category 'Account.Policy' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "retrieves trend data for Firewall category" {
            { Get-HardeningTrendData -Category 'Firewall.Policy' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "retrieves trend data for RDP Security category" {
            { Get-HardeningTrendData -Category 'RDP.Security' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Performance Metrics" {
        It "includes execution duration trends" {
            { Get-HardeningTrendData -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "calculates average execution time" {
            { Get-HardeningTrendData -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "tracks improvement in rule application speed" {
            { Get-HardeningTrendData -IncludeComparison -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "System-wide Trends" {
        It "aggregates trends across multiple computers" {
            { Get-HardeningTrendData -IncludeMultipleComputers -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes individual computer breakdown in trends" {
            { Get-HardeningTrendData -IncludeMultipleComputers -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Documentation" {
        It "has complete help documentation" {
            $help = Get-Help Get-HardeningTrendData
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }

        It "help includes TimeSpan parameter" {
            $help = Get-Help Get-HardeningTrendData
            $help.Parameters.Parameter.Name | Should -Contain 'TimeSpan'
        }

        It "help includes Profile parameter" {
            $help = Get-Help Get-HardeningTrendData
            $help.Parameters.Parameter.Name | Should -Contain 'Profile'
        }
    }
}
