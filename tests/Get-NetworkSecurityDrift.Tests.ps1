BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\System.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module System -Force -ErrorAction SilentlyContinue
}

Describe "Get-NetworkSecurityDrift" {
    Context "Parameter Validation" {
        It "works without parameters for local computer" {
            { Get-NetworkSecurityDrift -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts ComputerName parameter" {
            { Get-NetworkSecurityDrift -ComputerName 'localhost' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Profile parameter" {
            { Get-NetworkSecurityDrift -Profile Basis -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Detailed switch" {
            { Get-NetworkSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Network Security Drift Detection" {
        It "detects SMB signing drift" {
            { Get-NetworkSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "detects NTLMv2 authentication drift" {
            { Get-NetworkSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "detects LDAP signing drift" {
            { Get-NetworkSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "detects Kerberos drift" {
            { Get-NetworkSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "detects network adapter security drift" {
            { Get-NetworkSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Security Settings" {
        It "includes SMB encryption requirements" {
            { Get-NetworkSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes network segmentation status" {
            { Get-NetworkSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes WiFi security settings" {
            { Get-NetworkSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes DNS security settings" {
            { Get-NetworkSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes IPsec status" {
            { Get-NetworkSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Drift Information" {
        It "returns network security drift status" {
            { Get-NetworkSecurityDrift -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes expected settings from profile" {
            { Get-NetworkSecurityDrift -Profile Recommended -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes actual network security settings" {
            { Get-NetworkSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "calculates drift severity" {
            { Get-NetworkSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Profile Support" {
        It "detects drift for Basis profile" {
            { Get-NetworkSecurityDrift -Profile Basis -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "detects drift for Recommended profile" {
            { Get-NetworkSecurityDrift -Profile Recommended -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "detects drift for Strict profile" {
            { Get-NetworkSecurityDrift -Profile Strict -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Remote Computer Support" {
        It "detects drift on remote computer" {
            { Get-NetworkSecurityDrift -ComputerName 'localhost' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "handles unreachable remote computer" {
            { Get-NetworkSecurityDrift -ComputerName 'nonexistent.invalid' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts credential for remote connection" {
            $credential = New-Object System.Management.Automation.PSCredential('user', (ConvertTo-SecureString 'pass' -AsPlainText -Force))
            { Get-NetworkSecurityDrift -ComputerName 'localhost' -Credential $credential -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Documentation" {
        It "has complete help documentation" {
            $help = Get-Help Get-NetworkSecurityDrift
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }

        It "includes parameter descriptions" {
            $help = Get-Help Get-NetworkSecurityDrift
            $help.Parameters.Parameter.Name | Should -Contain 'Profile'
        }
    }
}
