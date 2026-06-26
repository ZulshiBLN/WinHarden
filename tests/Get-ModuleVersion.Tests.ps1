BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\Core.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module Core -Force -ErrorAction SilentlyContinue
}

Describe "Get-ModuleVersion" {
    Context "Version information retrieval" {
        It "returns version information" {
            $version = Get-ModuleVersion
            $version | Should -Not -BeNullOrEmpty
            $version.Module | Should -Be 'WinHarden'
            $version.Version | Should -Not -BeNullOrEmpty
            $version.PowerShellVersion | Should -Not -BeNullOrEmpty
        }

        It "returns hashtable with expected keys" {
            $version = Get-ModuleVersion
            $version.Keys | Should -Contain 'Module'
            $version.Keys | Should -Contain 'Version'
            $version.Keys | Should -Contain 'PowerShellVersion'
            $version.Keys | Should -Contain 'BuildDate'
            $version.Keys | Should -Contain 'Phase'
        }
    }
}
