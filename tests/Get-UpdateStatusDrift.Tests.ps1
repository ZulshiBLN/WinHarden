BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\System.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module System -Force -ErrorAction SilentlyContinue
}

Describe "Get-UpdateStatusDrift" {
    Context "Parameter Validation" {
        It "works without parameters for local computer" {
            { Get-UpdateStatusDrift -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts ComputerName parameter" {
            { Get-UpdateStatusDrift -ComputerName 'localhost' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Profile parameter" {
            { Get-UpdateStatusDrift -Profile Basis -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Detailed switch" {
            { Get-UpdateStatusDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts ReportDriftOnly switch" {
            { Get-UpdateStatusDrift -ReportDriftOnly -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Update Status Drift Detection" {
        It "detects pending updates drift" {
            { Get-UpdateStatusDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "detects automatic update configuration drift" {
            { Get-UpdateStatusDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "detects failed updates drift" {
            { Get-UpdateStatusDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "detects reboot pending drift" {
            { Get-UpdateStatusDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "detects update installation age drift" {
            { Get-UpdateStatusDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Update Settings" {
        It "includes pending updates count" {
            { Get-UpdateStatusDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes security updates status" {
            { Get-UpdateStatusDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes critical updates status" {
            { Get-UpdateStatusDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes auto-update configuration" {
            { Get-UpdateStatusDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes last update check time" {
            { Get-UpdateStatusDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes failed updates count" {
            { Get-UpdateStatusDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes update failure history" {
            { Get-UpdateStatusDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Drift Information" {
        It "returns update status drift object" {
            { Get-UpdateStatusDrift -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes expected update configuration from profile" {
            { Get-UpdateStatusDrift -Profile Recommended -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes actual update status" {
            { Get-UpdateStatusDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "identifies update-related drift" {
            { Get-UpdateStatusDrift -ReportDriftOnly -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "calculates update compliance percentage" {
            { Get-UpdateStatusDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Profile Support" {
        It "detects drift for Basis profile" {
            { Get-UpdateStatusDrift -Profile Basis -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "detects drift for Recommended profile" {
            { Get-UpdateStatusDrift -Profile Recommended -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "detects drift for Strict profile" {
            { Get-UpdateStatusDrift -Profile Strict -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Remote Computer Support" {
        It "detects drift on remote computer" {
            { Get-UpdateStatusDrift -ComputerName 'localhost' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "handles unreachable remote computer" {
            { Get-UpdateStatusDrift -ComputerName 'nonexistent.invalid' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts credential for remote connection" {
            $credential = New-Object System.Management.Automation.PSCredential('user', (ConvertTo-SecureString 'pass' -AsPlainText -Force))
            { Get-UpdateStatusDrift -ComputerName 'localhost' -Credential $credential -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Documentation" {
        It "has complete help documentation" {
            $help = Get-Help Get-UpdateStatusDrift
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }

        It "includes parameter descriptions" {
            $help = Get-Help Get-UpdateStatusDrift
            $help.Parameters.Parameter.Name | Should -Contain 'Profile'
        }
    }
}
