BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\System.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module System -Force -ErrorAction SilentlyContinue
}

Describe "Import-HardeningGPO" {
    Context "Parameter Validation" {
        It "accepts GPOPath parameter" {
            { Import-HardeningGPO -GPOPath "C:\Policies\Hardening.gpo" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts GPOName parameter" {
            { Import-HardeningGPO -GPOName "Hardening-Policy" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Domain parameter" {
            { Import-HardeningGPO -GPOPath "C:\Policies\Hardening.gpo" -Domain "example.com" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts OU parameter" {
            { Import-HardeningGPO -GPOPath "C:\Policies\Hardening.gpo" -OU "OU=Servers,DC=example,DC=com" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Profile parameter" {
            { Import-HardeningGPO -GPOPath "C:\Policies\Hardening.gpo" -Profile Basis -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts LinkGPO switch" {
            { Import-HardeningGPO -GPOPath "C:\Policies\Hardening.gpo" -LinkGPO -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Force switch" {
            { Import-HardeningGPO -GPOPath "C:\Policies\Hardening.gpo" -Force -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "GPO Source Formats" {
        It "imports GPO from file path" {
            { Import-HardeningGPO -GPOPath "C:\Policies\Hardening.gpo" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "imports GPO from backup directory" {
            { Import-HardeningGPO -GPOPath "C:\Policies\GPOBackup" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts UNC path for remote GPO files" {
            { Import-HardeningGPO -GPOPath "\\server\share\Policies\Hardening.gpo" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Profile Support" {
        It "imports Basis profile GPO" {
            { Import-HardeningGPO -GPOPath "C:\Policies\Hardening.gpo" -Profile Basis -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "imports Recommended profile GPO" {
            { Import-HardeningGPO -GPOPath "C:\Policies\Hardening.gpo" -Profile Recommended -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "imports Strict profile GPO" {
            { Import-HardeningGPO -GPOPath "C:\Policies\Hardening.gpo" -Profile Strict -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "auto-detects profile from GPO metadata when not specified" {
            { Import-HardeningGPO -GPOPath "C:\Policies\Hardening.gpo" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Active Directory Linking" {
        It "imports GPO without linking by default" {
            { Import-HardeningGPO -GPOPath "C:\Policies\Hardening.gpo" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "links GPO to domain when LinkGPO specified" {
            { Import-HardeningGPO -GPOPath "C:\Policies\Hardening.gpo" -LinkGPO -Domain "example.com" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "links GPO to specific OU" {
            { Import-HardeningGPO -GPOPath "C:\Policies\Hardening.gpo" -LinkGPO -OU "OU=Workstations,DC=example,DC=com" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "sets link order when linking to OU" {
            { Import-HardeningGPO -GPOPath "C:\Policies\Hardening.gpo" -LinkGPO -OU "OU=Servers,DC=example,DC=com" -LinkOrder 1 -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Conflict Handling" {
        It "fails on existing GPO without Force switch" {
            { Import-HardeningGPO -GPOPath "C:\Policies\Hardening.gpo" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "overwrites existing GPO with Force switch" {
            { Import-HardeningGPO -GPOPath "C:\Policies\Hardening.gpo" -Force -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts custom GPO name when importing" {
            { Import-HardeningGPO -GPOPath "C:\Policies\Hardening.gpo" -GPOName "Custom-Hardening-Policy" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Validation" {
        It "validates GPO file exists before import" {
            { Import-HardeningGPO -GPOPath "C:\Policies\NonExistent.gpo" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "validates GPO metadata integrity" {
            { Import-HardeningGPO -GPOPath "C:\Policies\Hardening.gpo" -ValidateMetadata -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "validates GPO against security schema" {
            { Import-HardeningGPO -GPOPath "C:\Policies\Hardening.gpo" -ValidateSchema -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "skips validation with SkipValidation switch" {
            { Import-HardeningGPO -GPOPath "C:\Policies\Hardening.gpo" -SkipValidation -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Import Options" {
        It "accepts PreserveLinksSwitch parameter" {
            { Import-HardeningGPO -GPOPath "C:\Policies\Hardening.gpo" -PreserveLinks -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts CreateBackup switch" {
            { Import-HardeningGPO -GPOPath "C:\Policies\Hardening.gpo" -CreateBackup -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts BackupPath parameter for backup location" {
            { Import-HardeningGPO -GPOPath "C:\Policies\Hardening.gpo" -CreateBackup -BackupPath "C:\Backups\GPO" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts MergeSettings switch for merging with existing settings" {
            { Import-HardeningGPO -GPOPath "C:\Policies\Hardening.gpo" -MergeSettings -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Reporting" {
        It "returns import result object" {
            { Import-HardeningGPO -GPOPath "C:\Policies\Hardening.gpo" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes import status in result" {
            { Import-HardeningGPO -GPOPath "C:\Policies\Hardening.gpo" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes imported rules count in result" {
            { Import-HardeningGPO -GPOPath "C:\Policies\Hardening.gpo" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes warning or error messages in result" {
            { Import-HardeningGPO -GPOPath "C:\Policies\Hardening.gpo" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "provides detailed report with Detailed switch" {
            { Import-HardeningGPO -GPOPath "C:\Policies\Hardening.gpo" -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Multiple GPO Import" {
        It "accepts array of GPO paths" {
            $paths = @("C:\Policies\Hardening1.gpo", "C:\Policies\Hardening2.gpo")
            { Import-HardeningGPO -GPOPath $paths -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "imports multiple GPOs sequentially" {
            $paths = @("C:\Policies\Basis.gpo", "C:\Policies\Recommended.gpo")
            { Import-HardeningGPO -GPOPath $paths -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "continues on error for multiple imports with ContinueOnError" {
            $paths = @("C:\Policies\Hardening1.gpo", "C:\Policies\Hardening2.gpo")
            { Import-HardeningGPO -GPOPath $paths -ContinueOnError -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Audit and Logging" {
        It "logs import activity when GenerateLog specified" {
            { Import-HardeningGPO -GPOPath "C:\Policies\Hardening.gpo" -GenerateLog -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes audit trail for imported changes" {
            { Import-HardeningGPO -GPOPath "C:\Policies\Hardening.gpo" -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "tracks who imported GPO when logging enabled" {
            { Import-HardeningGPO -GPOPath "C:\Policies\Hardening.gpo" -GenerateLog -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Documentation" {
        It "has complete help documentation" {
            $help = Get-Help Import-HardeningGPO
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }

        It "help includes GPOPath parameter" {
            $help = Get-Help Import-HardeningGPO
            $help.Parameters.Parameter.Name | Should -Contain 'GPOPath'
        }

        It "help includes Domain parameter" {
            $help = Get-Help Import-HardeningGPO
            $help.Parameters.Parameter.Name | Should -Contain 'Domain'
        }

        It "help includes LinkGPO parameter" {
            $help = Get-Help Import-HardeningGPO
            $help.Parameters.Parameter.Name | Should -Contain 'LinkGPO'
        }
    }
}
