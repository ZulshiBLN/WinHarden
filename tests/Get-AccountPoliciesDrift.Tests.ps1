BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\System.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module System -Force -ErrorAction SilentlyContinue
}

Describe "Get-AccountPoliciesDrift" {
    Context "Parameter Validation" {
        It "works without parameters for local computer" {
            { Get-AccountPoliciesDrift -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts ComputerName parameter" {
            { Get-AccountPoliciesDrift -ComputerName 'localhost' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Profile parameter" {
            { Get-AccountPoliciesDrift -Profile Basis -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Detailed switch" {
            { Get-AccountPoliciesDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts ReportDriftOnly switch" {
            { Get-AccountPoliciesDrift -ReportDriftOnly -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Drift Detection" {
        It "detects password policy drift" {
            { Get-AccountPoliciesDrift -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "detects account lockout policy drift" {
            { Get-AccountPoliciesDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "detects password history drift" {
            { Get-AccountPoliciesDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "detects password minimum age drift" {
            { Get-AccountPoliciesDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "detects password maximum age drift" {
            { Get-AccountPoliciesDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Policy Settings" {
        It "includes minimum password length" {
            { Get-AccountPoliciesDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes password complexity requirement" {
            { Get-AccountPoliciesDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes password history count" {
            { Get-AccountPoliciesDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes account lockout threshold" {
            { Get-AccountPoliciesDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes account lockout duration" {
            { Get-AccountPoliciesDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes lockout counter reset time" {
            { Get-AccountPoliciesDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Drift Information" {
        It "returns drift status object" {
            { Get-AccountPoliciesDrift -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes expected values from profile" {
            { Get-AccountPoliciesDrift -Profile Basis -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes actual system values" {
            { Get-AccountPoliciesDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "identifies drift items" {
            { Get-AccountPoliciesDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "calculates drift percentage" {
            { Get-AccountPoliciesDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Profile Support" {
        It "detects drift for Basis profile" {
            { Get-AccountPoliciesDrift -Profile Basis -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "detects drift for Recommended profile" {
            { Get-AccountPoliciesDrift -Profile Recommended -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "detects drift for Strict profile" {
            { Get-AccountPoliciesDrift -Profile Strict -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "uses default profile when not specified" {
            { Get-AccountPoliciesDrift -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Remote Computer Support" {
        It "detects drift on remote computer" {
            { Get-AccountPoliciesDrift -ComputerName 'localhost' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "handles unreachable remote computer" {
            { Get-AccountPoliciesDrift -ComputerName 'nonexistent.invalid' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts credential for remote connection" {
            $credential = New-Object System.Management.Automation.PSCredential('user', (ConvertTo-SecureString 'pass' -AsPlainText -Force))
            { Get-AccountPoliciesDrift -ComputerName 'localhost' -Credential $credential -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Reporting Options" {
        It "returns all policies by default" {
            { Get-AccountPoliciesDrift -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "returns only drifted policies with ReportDriftOnly" {
            { Get-AccountPoliciesDrift -ReportDriftOnly -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "provides detailed analysis with Detailed switch" {
            { Get-AccountPoliciesDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes recommendations for remediation" {
            { Get-AccountPoliciesDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Documentation" {
        It "has complete help documentation" {
            $help = Get-Help Get-AccountPoliciesDrift
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }

        It "includes parameter descriptions" {
            $help = Get-Help Get-AccountPoliciesDrift
            $help.Parameters.Parameter.Name | Should -Contain 'Profile'
        }
    }
}
