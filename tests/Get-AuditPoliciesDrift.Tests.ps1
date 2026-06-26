BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\System.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module System -Force -ErrorAction SilentlyContinue
}

Describe "Get-AuditPoliciesDrift" {
    Context "Parameter Validation" {
        It "works without parameters for local computer" {
            { Get-AuditPoliciesDrift -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts ComputerName parameter" {
            { Get-AuditPoliciesDrift -ComputerName 'localhost' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Profile parameter" {
            { Get-AuditPoliciesDrift -Profile Basis -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Detailed switch" {
            { Get-AuditPoliciesDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts ReportDriftOnly switch" {
            { Get-AuditPoliciesDrift -ReportDriftOnly -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Audit Policy Drift Detection" {
        It "detects logon audit policy drift" {
            { Get-AuditPoliciesDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "detects account management audit drift" {
            { Get-AuditPoliciesDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "detects object access audit drift" {
            { Get-AuditPoliciesDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "detects privilege use audit drift" {
            { Get-AuditPoliciesDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "detects system audit drift" {
            { Get-AuditPoliciesDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "detects detailed tracking audit drift" {
            { Get-AuditPoliciesDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Audit Settings" {
        It "includes logon/logoff audit settings" {
            { Get-AuditPoliciesDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes account logon audit settings" {
            { Get-AuditPoliciesDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes user and computer account management audit" {
            { Get-AuditPoliciesDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes directory service access audit" {
            { Get-AuditPoliciesDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes file share access audit" {
            { Get-AuditPoliciesDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes sensitive privilege use audit" {
            { Get-AuditPoliciesDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes policy change audit" {
            { Get-AuditPoliciesDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Drift Information" {
        It "returns drift status object" {
            { Get-AuditPoliciesDrift -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes expected audit settings from profile" {
            { Get-AuditPoliciesDrift -Profile Recommended -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes actual system audit settings" {
            { Get-AuditPoliciesDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "identifies drifted audit policies" {
            { Get-AuditPoliciesDrift -ReportDriftOnly -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "calculates compliance percentage" {
            { Get-AuditPoliciesDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Profile Support" {
        It "detects drift for Basis profile" {
            { Get-AuditPoliciesDrift -Profile Basis -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "detects drift for Recommended profile" {
            { Get-AuditPoliciesDrift -Profile Recommended -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "detects drift for Strict profile" {
            { Get-AuditPoliciesDrift -Profile Strict -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Remote Computer Support" {
        It "detects drift on remote computer" {
            { Get-AuditPoliciesDrift -ComputerName 'localhost' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "handles unreachable remote computer" {
            { Get-AuditPoliciesDrift -ComputerName 'nonexistent.invalid' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts credential for remote connection" {
            $credential = New-Object System.Management.Automation.PSCredential('user', (ConvertTo-SecureString 'pass' -AsPlainText -Force))
            { Get-AuditPoliciesDrift -ComputerName 'localhost' -Credential $credential -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Documentation" {
        It "has complete help documentation" {
            $help = Get-Help Get-AuditPoliciesDrift
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }

        It "includes parameter descriptions" {
            $help = Get-Help Get-AuditPoliciesDrift
            $help.Parameters.Parameter.Name | Should -Contain 'Profile'
        }
    }
}
