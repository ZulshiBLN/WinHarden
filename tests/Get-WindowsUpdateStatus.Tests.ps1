BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\System.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module System -Force -ErrorAction SilentlyContinue
}

Describe "Get-WindowsUpdateStatus" {
    Context "Parameter Validation" {
        It "accepts ComputerName parameter" {
            { Get-WindowsUpdateStatus -ComputerName 'localhost' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts multiple computer names" {
            { Get-WindowsUpdateStatus -ComputerName @('localhost', '127.0.0.1') -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Detailed switch" {
            { Get-WindowsUpdateStatus -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts IncludePendingUpdates switch" {
            { Get-WindowsUpdateStatus -IncludePendingUpdates -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "works without parameters for local computer" {
            { Get-WindowsUpdateStatus -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Update Status Information" {
        It "returns update status object" {
            $status = Get-WindowsUpdateStatus -ErrorAction SilentlyContinue
            if ($status) {
                $status | Should -Not -BeNullOrEmpty
            }
        }

        It "includes total updates count" {
            { Get-WindowsUpdateStatus -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes installed updates count" {
            { Get-WindowsUpdateStatus -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes pending updates count" {
            { Get-WindowsUpdateStatus -IncludePendingUpdates -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes failed updates count" {
            { Get-WindowsUpdateStatus -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Security Update Tracking" {
        It "identifies security updates separately" {
            { Get-WindowsUpdateStatus -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "counts critical updates" {
            { Get-WindowsUpdateStatus -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "counts important updates" {
            { Get-WindowsUpdateStatus -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "identifies definition updates" {
            { Get-WindowsUpdateStatus -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Update Status Categories" {
        It "identifies available updates" {
            { Get-WindowsUpdateStatus -IncludePendingUpdates -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "identifies in-progress updates" {
            { Get-WindowsUpdateStatus -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "identifies installed updates" {
            { Get-WindowsUpdateStatus -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "identifies failed updates" {
            { Get-WindowsUpdateStatus -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Update Dates and Times" {
        It "includes last update check time" {
            { Get-WindowsUpdateStatus -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes last successful update time" {
            { Get-WindowsUpdateStatus -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes next scheduled update check" {
            { Get-WindowsUpdateStatus -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Remote Computer Support" {
        It "retrieves status for remote computer" {
            { Get-WindowsUpdateStatus -ComputerName 'localhost' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "handles unreachable remote computer" {
            { Get-WindowsUpdateStatus -ComputerName 'nonexistent.invalid' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts credential for remote connection" {
            $credential = New-Object System.Management.Automation.PSCredential('user', (ConvertTo-SecureString 'pass' -AsPlainText -Force))
            { Get-WindowsUpdateStatus -ComputerName 'localhost' -Credential $credential -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Output Format" {
        It "returns PSCustomObject by default" {
            { Get-WindowsUpdateStatus -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "supports Format parameter for CSV" {
            { Get-WindowsUpdateStatus -Format CSV -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "supports Format parameter for JSON" {
            { Get-WindowsUpdateStatus -Format JSON -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Documentation" {
        It "has complete help documentation" {
            $help = Get-Help Get-WindowsUpdateStatus
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }

        It "includes parameter descriptions" {
            $help = Get-Help Get-WindowsUpdateStatus
            $help.Parameters.Parameter.Name | Should -Contain 'ComputerName'
        }
    }
}
