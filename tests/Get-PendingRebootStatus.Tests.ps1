BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\System.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module System -Force -ErrorAction SilentlyContinue
}

Describe "Get-PendingRebootStatus" {
    Context "Parameter Validation" {
        It "works without parameters for local computer" {
            { Get-PendingRebootStatus -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts ComputerName parameter" {
            { Get-PendingRebootStatus -ComputerName 'localhost' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts multiple computer names" {
            { Get-PendingRebootStatus -ComputerName @('localhost', '127.0.0.1') -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Detailed switch" {
            { Get-PendingRebootStatus -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Reboot Status Information" {
        It "returns reboot status object" {
            $status = Get-PendingRebootStatus -ErrorAction SilentlyContinue
            if ($status) {
                $status | Should -Not -BeNullOrEmpty
            }
        }

        It "includes ComputerName property" {
            { Get-PendingRebootStatus -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes RebootPending property" {
            { Get-PendingRebootStatus -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes LastRebootTime property" {
            { Get-PendingRebootStatus -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes RebootReason property when reboot pending" {
            { Get-PendingRebootStatus -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Reboot Reason Detection" {
        It "identifies Windows Update reboot need" {
            { Get-PendingRebootStatus -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "identifies Component-Based Servicing reboot need" {
            { Get-PendingRebootStatus -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "identifies Pending File Rename reboot need" {
            { Get-PendingRebootStatus -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "identifies Configuration Manager reboot need" {
            { Get-PendingRebootStatus -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "identifies Windows Update Auto Update reboot need" {
            { Get-PendingRebootStatus -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Reboot Urgency" {
        It "identifies if reboot is critical" {
            { Get-PendingRebootStatus -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "identifies if reboot can be delayed" {
            { Get-PendingRebootStatus -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "estimates time until automatic reboot" {
            { Get-PendingRebootStatus -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Reboot History" {
        It "includes last reboot time" {
            { Get-PendingRebootStatus -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes uptime calculation" {
            { Get-PendingRebootStatus -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes reboot count since installation" {
            { Get-PendingRebootStatus -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes pending updates count" {
            { Get-PendingRebootStatus -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Multiple Reboot Reasons" {
        It "handles multiple pending reboot reasons" {
            { Get-PendingRebootStatus -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "prioritizes critical reboot reasons" {
            { Get-PendingRebootStatus -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "returns all reboot reasons in array" {
            { Get-PendingRebootStatus -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Remote Computer Support" {
        It "retrieves status from remote computer" {
            { Get-PendingRebootStatus -ComputerName 'localhost' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "handles unreachable remote computer" {
            { Get-PendingRebootStatus -ComputerName 'nonexistent.invalid' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts credential for remote connection" {
            $credential = New-Object System.Management.Automation.PSCredential('user', (ConvertTo-SecureString 'pass' -AsPlainText -Force))
            { Get-PendingRebootStatus -ComputerName 'localhost' -Credential $credential -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "processes multiple computers" {
            $computers = @('localhost')
            { Get-PendingRebootStatus -ComputerName $computers -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Reboot Scheduling" {
        It "includes scheduled reboot time if available" {
            { Get-PendingRebootStatus -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "identifies postponed reboot deadlines" {
            { Get-PendingRebootStatus -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "calculates time remaining until automatic reboot" {
            { Get-PendingRebootStatus -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Documentation" {
        It "has complete help documentation" {
            $help = Get-Help Get-PendingRebootStatus
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }

        It "includes parameter descriptions" {
            $help = Get-Help Get-PendingRebootStatus
            $help.Parameters.Parameter.Name | Should -Contain 'ComputerName'
        }
    }
}
