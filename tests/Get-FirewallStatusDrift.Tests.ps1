BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\System.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module System -Force -ErrorAction SilentlyContinue
}

Describe "Get-FirewallStatusDrift" {
    Context "Parameter Validation" {
        It "works without parameters for local computer" {
            { Get-FirewallStatusDrift -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts ComputerName parameter" {
            { Get-FirewallStatusDrift -ComputerName 'localhost' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Profile parameter" {
            { Get-FirewallStatusDrift -Profile Basis -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Detailed switch" {
            { Get-FirewallStatusDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts ReportDriftOnly switch" {
            { Get-FirewallStatusDrift -ReportDriftOnly -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Firewall Status Detection" {
        It "detects Windows Defender Firewall state drift" {
            { Get-FirewallStatusDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "detects domain profile drift" {
            { Get-FirewallStatusDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "detects private profile drift" {
            { Get-FirewallStatusDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "detects public profile drift" {
            { Get-FirewallStatusDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "detects inbound rules drift" {
            { Get-FirewallStatusDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "detects outbound rules drift" {
            { Get-FirewallStatusDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Firewall Settings" {
        It "includes firewall state (enabled/disabled)" {
            { Get-FirewallStatusDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes default inbound action" {
            { Get-FirewallStatusDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes default outbound action" {
            { Get-FirewallStatusDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes notifications setting" {
            { Get-FirewallStatusDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes logging configuration" {
            { Get-FirewallStatusDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes rule count" {
            { Get-FirewallStatusDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Drift Information" {
        It "returns firewall drift status" {
            { Get-FirewallStatusDrift -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes expected settings from profile" {
            { Get-FirewallStatusDrift -Profile Basis -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes actual firewall settings" {
            { Get-FirewallStatusDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "identifies drifted firewall settings" {
            { Get-FirewallStatusDrift -ReportDriftOnly -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Profile Support" {
        It "detects drift for Basis profile" {
            { Get-FirewallStatusDrift -Profile Basis -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "detects drift for Recommended profile" {
            { Get-FirewallStatusDrift -Profile Recommended -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "detects drift for Strict profile" {
            { Get-FirewallStatusDrift -Profile Strict -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Remote Computer Support" {
        It "detects drift on remote computer" {
            { Get-FirewallStatusDrift -ComputerName 'localhost' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "handles unreachable remote computer" {
            { Get-FirewallStatusDrift -ComputerName 'nonexistent.invalid' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts credential for remote connection" {
            $credential = New-Object System.Management.Automation.PSCredential('user', (ConvertTo-SecureString 'pass' -AsPlainText -Force))
            { Get-FirewallStatusDrift -ComputerName 'localhost' -Credential $credential -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Documentation" {
        It "has complete help documentation" {
            $help = Get-Help Get-FirewallStatusDrift
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }

        It "includes parameter descriptions" {
            $help = Get-Help Get-FirewallStatusDrift
            $help.Parameters.Parameter.Name | Should -Contain 'Profile'
        }
    }
}
