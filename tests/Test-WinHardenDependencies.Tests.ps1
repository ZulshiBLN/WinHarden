BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\Core.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module Core -Force -ErrorAction SilentlyContinue
}

Describe "Test-WinHardenDependencies" {
    Context "Dependency validation" {
        It "returns hashtable with PowerShell version" {
            $result = Test-WinHardenDependencies
            $result | Should -BeOfType [hashtable]
            $result.Keys | Should -Contain 'PowerShellVersion'
        }

        It "checks PowerShell version requirement" {
            $result = Test-WinHardenDependencies
            $result.PowerShellVersion.Status | Should -Match 'OK|FAIL'
            $result.PowerShellVersion.Required | Should -Be '5.1'
        }
    }

    Context "Optional module checking" {
        It "checks optional modules when specified" {
            $result = Test-WinHardenDependencies -Module @('Pester')
            $result['Pester'] | Should -Not -BeNullOrEmpty
            $result['Pester'].Status | Should -Match 'Available|NotFound'
        }

        It "handles empty module array" {
            $result = Test-WinHardenDependencies -Module @()
            $result | Should -BeOfType [hashtable]
            $result.Keys | Should -Contain 'PowerShellVersion'
        }
    }
}
