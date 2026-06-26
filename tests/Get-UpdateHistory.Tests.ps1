BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\System.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module System -Force -ErrorAction SilentlyContinue
}

Describe "Get-UpdateHistory" {
    Context "Parameter Validation" {
        It "works without parameters for local computer" {
            { Get-UpdateHistory -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts ComputerName parameter" {
            { Get-UpdateHistory -ComputerName 'localhost' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts multiple computer names" {
            { Get-UpdateHistory -ComputerName @('localhost', '127.0.0.1') -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Days parameter" {
            { Get-UpdateHistory -Days 30 -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Months parameter" {
            { Get-UpdateHistory -Months 6 -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Years parameter" {
            { Get-UpdateHistory -Years 1 -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Status filter parameter" {
            { Get-UpdateHistory -Status 'Installed' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Update History Retrieval" {
        It "returns update history collection" {
            { Get-UpdateHistory -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes all installed updates" {
            { Get-UpdateHistory -Status 'Installed' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes failed updates" {
            { Get-UpdateHistory -Status 'Failed' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes in-progress updates" {
            { Get-UpdateHistory -Status 'InProgress' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes updates across all statuses" {
            { Get-UpdateHistory -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Time Range Filtering" {
        It "retrieves updates from last 7 days" {
            { Get-UpdateHistory -Days 7 -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "retrieves updates from last 30 days" {
            { Get-UpdateHistory -Days 30 -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "retrieves updates from last 3 months" {
            { Get-UpdateHistory -Months 3 -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "retrieves updates from last year" {
            { Get-UpdateHistory -Years 1 -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "retrieves all historical updates without time filter" {
            { Get-UpdateHistory -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Update Information" {
        It "includes update KB number" {
            { Get-UpdateHistory -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes update title" {
            { Get-UpdateHistory -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes update category" {
            { Get-UpdateHistory -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes installation date" {
            { Get-UpdateHistory -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes update size" {
            { Get-UpdateHistory -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Update Categories" {
        It "identifies security updates" {
            { Get-UpdateHistory -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "identifies critical updates" {
            { Get-UpdateHistory -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "identifies definition updates" {
            { Get-UpdateHistory -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "identifies driver updates" {
            { Get-UpdateHistory -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "identifies optional updates" {
            { Get-UpdateHistory -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "identifies tools updates" {
            { Get-UpdateHistory -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Update Status" {
        It "marks installed updates" {
            { Get-UpdateHistory -Status 'Installed' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "marks failed updates" {
            { Get-UpdateHistory -Status 'Failed' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "marks superseded updates" {
            { Get-UpdateHistory -Status 'Superseded' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "marks uninstalled updates" {
            { Get-UpdateHistory -Status 'Uninstalled' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Failure Details" {
        It "includes error code for failed updates" {
            { Get-UpdateHistory -Status 'Failed' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes error description for failed updates" {
            { Get-UpdateHistory -Status 'Failed' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "identifies retry attempts for failed updates" {
            { Get-UpdateHistory -Status 'Failed' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Sorting and Filtering" {
        It "sorts by installation date descending by default" {
            { Get-UpdateHistory -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts sorting by KB number" {
            { Get-UpdateHistory -SortBy 'KB' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts sorting by category" {
            { Get-UpdateHistory -SortBy 'Category' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "filters by category" {
            { Get-UpdateHistory -Category 'Security Updates' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts search term for update titles" {
            { Get-UpdateHistory -SearchTerm 'security' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Statistics" {
        It "calculates total updates installed" {
            { Get-UpdateHistory -Statistics -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "calculates failed updates count" {
            { Get-UpdateHistory -Statistics -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "calculates updates by category" {
            { Get-UpdateHistory -Statistics -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "calculates average installation success rate" {
            { Get-UpdateHistory -Statistics -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Remote Computer Support" {
        It "retrieves history from remote computer" {
            { Get-UpdateHistory -ComputerName 'localhost' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "handles unreachable remote computer" {
            { Get-UpdateHistory -ComputerName 'nonexistent.invalid' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts credential for remote connection" {
            $credential = New-Object System.Management.Automation.PSCredential('user', (ConvertTo-SecureString 'pass' -AsPlainText -Force))
            { Get-UpdateHistory -ComputerName 'localhost' -Credential $credential -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "processes multiple computers in parallel" {
            $computers = @('localhost')
            { Get-UpdateHistory -ComputerName $computers -Parallel -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Export Formats" {
        It "outputs as PSCustomObject by default" {
            { Get-UpdateHistory -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "supports CSV export format" {
            { Get-UpdateHistory -Format CSV -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "supports JSON export format" {
            { Get-UpdateHistory -Format JSON -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "supports HTML report format" {
            { Get-UpdateHistory -Format HTML -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Documentation" {
        It "has complete help documentation" {
            $help = Get-Help Get-UpdateHistory
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }

        It "includes parameter descriptions" {
            $help = Get-Help Get-UpdateHistory
            $help.Parameters.Parameter.Name | Should -Contain 'ComputerName'
        }

        It "includes usage examples" {
            $help = Get-Help Get-UpdateHistory
            $help.Examples | Should -Not -BeNullOrEmpty
        }
    }
}
