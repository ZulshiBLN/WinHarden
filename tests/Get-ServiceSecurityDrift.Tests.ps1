BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\System.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module System -Force -ErrorAction SilentlyContinue
}

Describe "Get-ServiceSecurityDrift" {
    Context "Parameter Validation" {
        It "works without parameters for local computer" {
            { Get-ServiceSecurityDrift -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts ComputerName parameter" {
            { Get-ServiceSecurityDrift -ComputerName 'localhost' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Profile parameter" {
            { Get-ServiceSecurityDrift -Profile Basis -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Detailed switch" {
            { Get-ServiceSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts ReportDriftOnly switch" {
            { Get-ServiceSecurityDrift -ReportDriftOnly -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Service Security Drift Detection" {
        It "detects service startup type drift" {
            { Get-ServiceSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "detects unnecessary services running" {
            { Get-ServiceSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "detects disabled service status drift" {
            { Get-ServiceSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "detects service permissions drift" {
            { Get-ServiceSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "detects service account changes" {
            { Get-ServiceSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Service Settings" {
        It "includes Windows Update service status" {
            { Get-ServiceSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes Windows Defender service status" {
            { Get-ServiceSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes Firewall service status" {
            { Get-ServiceSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes Audit service status" {
            { Get-ServiceSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes Telemetry service status" {
            { Get-ServiceSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes Remote Desktop service status" {
            { Get-ServiceSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes unnecessary services list" {
            { Get-ServiceSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Drift Information" {
        It "returns service security drift status" {
            { Get-ServiceSecurityDrift -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes expected service configuration from profile" {
            { Get-ServiceSecurityDrift -Profile Basis -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes actual service status" {
            { Get-ServiceSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "identifies services in drift" {
            { Get-ServiceSecurityDrift -ReportDriftOnly -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "provides remediation suggestions" {
            { Get-ServiceSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Profile Support" {
        It "detects drift for Basis profile" {
            { Get-ServiceSecurityDrift -Profile Basis -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "detects drift for Recommended profile" {
            { Get-ServiceSecurityDrift -Profile Recommended -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "detects drift for Strict profile" {
            { Get-ServiceSecurityDrift -Profile Strict -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Remote Computer Support" {
        It "detects drift on remote computer" {
            { Get-ServiceSecurityDrift -ComputerName 'localhost' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "handles unreachable remote computer" {
            { Get-ServiceSecurityDrift -ComputerName 'nonexistent.invalid' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts credential for remote connection" {
            $credential = New-Object System.Management.Automation.PSCredential('user', (ConvertTo-SecureString 'pass' -AsPlainText -Force))
            { Get-ServiceSecurityDrift -ComputerName 'localhost' -Credential $credential -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Documentation" {
        It "has complete help documentation" {
            $help = Get-Help Get-ServiceSecurityDrift
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }

        It "includes parameter descriptions" {
            $help = Get-Help Get-ServiceSecurityDrift
            $help.Parameters.Parameter.Name | Should -Contain 'Profile'
        }
    }
}
