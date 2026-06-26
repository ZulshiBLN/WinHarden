BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\System.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module System -Force -ErrorAction SilentlyContinue
}

Describe "System Module - Hardening Functions" {
    Context "Module Loading" {
        It "loads System module successfully" {
            { Import-Module -Name $modulePath -Force } | Should -Not -Throw
        }

        It "exports hardening functions" {
            $functions = Get-Command -Module System | Select-Object -ExpandProperty Name
            $functions | Should -Contain "New-HardeningSession"
            $functions | Should -Contain "Invoke-SecurityHardening"
            $functions | Should -Contain "Test-HardeningCompliance"
        }
    }
}
