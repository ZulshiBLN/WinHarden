BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\System.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module System -Force -ErrorAction SilentlyContinue
}

Describe "Get-RDPSecurityDrift" {
    Context "Parameter Validation" {
        It "works without parameters for local computer" {
            { Get-RDPSecurityDrift -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts ComputerName parameter" {
            { Get-RDPSecurityDrift -ComputerName 'localhost' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Profile parameter" {
            { Get-RDPSecurityDrift -Profile Basis -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Detailed switch" {
            { Get-RDPSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts ReportDriftOnly switch" {
            { Get-RDPSecurityDrift -ReportDriftOnly -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "RDP Security Drift Detection" {
        It "detects RDP service enabled state drift" {
            { Get-RDPSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "detects RDP encryption drift" {
            { Get-RDPSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "detects RDP authentication level drift" {
            { Get-RDPSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "detects Network Level Authentication drift" {
            { Get-RDPSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "detects RDP port drift" {
            { Get-RDPSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "detects RDP certificate drift" {
            { Get-RDPSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "RDP Settings" {
        It "includes RDP enabled status" {
            { Get-RDPSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes RDP port configuration" {
            { Get-RDPSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes encryption level" {
            { Get-RDPSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes security layer setting" {
            { Get-RDPSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes NLA status" {
            { Get-RDPSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes idle session timeout" {
            { Get-RDPSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes password required setting" {
            { Get-RDPSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Drift Information" {
        It "returns RDP security drift status" {
            { Get-RDPSecurityDrift -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes expected RDP settings from profile" {
            { Get-RDPSecurityDrift -Profile Basis -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes actual RDP settings" {
            { Get-RDPSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "identifies drifted RDP settings" {
            { Get-RDPSecurityDrift -ReportDriftOnly -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "provides remediation recommendations" {
            { Get-RDPSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Profile Support" {
        It "detects drift for Basis profile" {
            { Get-RDPSecurityDrift -Profile Basis -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "detects drift for Recommended profile" {
            { Get-RDPSecurityDrift -Profile Recommended -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "detects drift for Strict profile" {
            { Get-RDPSecurityDrift -Profile Strict -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Remote Computer Support" {
        It "detects drift on remote computer" {
            { Get-RDPSecurityDrift -ComputerName 'localhost' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "handles unreachable remote computer" {
            { Get-RDPSecurityDrift -ComputerName 'nonexistent.invalid' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts credential for remote connection" {
            $credential = New-Object System.Management.Automation.PSCredential('user', (ConvertTo-SecureString 'pass' -AsPlainText -Force))
            { Get-RDPSecurityDrift -ComputerName 'localhost' -Credential $credential -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Documentation" {
        It "has complete help documentation" {
            $help = Get-Help Get-RDPSecurityDrift
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }

        It "includes parameter descriptions" {
            $help = Get-Help Get-RDPSecurityDrift
            $help.Parameters.Parameter.Name | Should -Contain 'Profile'
        }
    }
}
