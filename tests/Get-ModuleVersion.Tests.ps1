BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\Core.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module Core -Force -ErrorAction SilentlyContinue
}

Describe "Get-ModuleVersion" {
    Context "Return type and structure" {
        It "returns a hashtable" {
            $version = Get-ModuleVersion
            $version | Should -BeOfType [hashtable]
        }

        It "returns hashtable with exactly 6 keys" {
            $version = Get-ModuleVersion
            $version.Keys.Count | Should -Be 6
        }

        It "contains all required keys" {
            $version = Get-ModuleVersion
            $version.Keys | Should -Contain 'Module'
            $version.Keys | Should -Contain 'Version'
            $version.Keys | Should -Contain 'PowerShellVersion'
            $version.Keys | Should -Contain 'BuildDate'
            $version.Keys | Should -Contain 'Infrastructure'
            $version.Keys | Should -Contain 'Phase'
        }
    }

    Context "Module value validation" {
        It "Module key is 'WinHarden'" {
            $version = Get-ModuleVersion
            $version.Module | Should -Be 'WinHarden'
        }

        It "Version follows semantic versioning format" {
            $version = Get-ModuleVersion
            $version.Version | Should -Match '^\d+\.\d+\.\d+$'
        }

        It "Current version is 0.1.0" {
            $version = Get-ModuleVersion
            $version.Version | Should -Be '0.1.0'
        }
    }

    Context "PowerShell compatibility information" {
        It "PowerShellVersion is formatted string" {
            $version = Get-ModuleVersion
            $version.PowerShellVersion | Should -BeOfType [string]
        }

        It "PowerShellVersion matches version pattern" {
            $version = Get-ModuleVersion
            $version.PowerShellVersion | Should -Match '^\d+\.\d+\.\d+\.\d+$'
        }

        It "PowerShellVersion matches current PSVersion" {
            $version = Get-ModuleVersion
            $version.PowerShellVersion | Should -Be $PSVersionTable.PSVersion.ToString()
        }
    }

    Context "Build and phase information" {
        It "BuildDate follows yyyy-MM-dd format" {
            $version = Get-ModuleVersion
            $version.BuildDate | Should -Match '^\d{4}-\d{2}-\d{2}$'
        }

        It "BuildDate is today's date" {
            $version = Get-ModuleVersion
            $today = (Get-Date).ToString('yyyy-MM-dd')
            $version.BuildDate | Should -Be $today
        }

        It "Infrastructure describes current status" {
            $version = Get-ModuleVersion
            $version.Infrastructure | Should -Be 'Complete (9 ADRs)'
        }

        It "Phase indicates implementation status" {
            $version = Get-ModuleVersion
            $version.Phase | Should -Be 'Implementation'
        }
    }

    Context "Consistency across multiple calls" {
        It "returns same Module and Version on consecutive calls" {
            $v1 = Get-ModuleVersion
            $v2 = Get-ModuleVersion
            $v1.Module | Should -Be $v2.Module
            $v1.Version | Should -Be $v2.Version
        }

        It "returns consistent Infrastructure and Phase" {
            $v1 = Get-ModuleVersion
            $v2 = Get-ModuleVersion
            $v1.Infrastructure | Should -Be $v2.Infrastructure
            $v1.Phase | Should -Be $v2.Phase
        }
    }
}
