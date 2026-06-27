BeforeAll {
    # Load Core module first (ADR-008: Module Import Strategy)
    $coreModulePath = (Resolve-Path "$PSScriptRoot\..\modules\Core.psm1").Path
    Import-Module $coreModulePath -Force

    # Load System module (which depends on Core)
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\System.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module System -Force -ErrorAction SilentlyContinue
    Remove-Module Core -Force -ErrorAction SilentlyContinue
}

Describe "Get-UpdateHistory" {
    Context "Function Exists and Help" {
        It "function exists and can be called" {
            Get-Command Get-UpdateHistory | Should -Not -BeNullOrEmpty
        }

        It "has complete help documentation" {
            $help = Get-Help Get-UpdateHistory
            $help.Synopsis | Should -Not -BeNullOrEmpty
            $help.Description | Should -Not -BeNullOrEmpty
        }

        It "includes parameter descriptions" {
            $help = Get-Help Get-UpdateHistory
            $help.Parameters.Parameter.Name | Should -Contain 'Count'
        }

        It "includes example usage" {
            $help = Get-Help Get-UpdateHistory
            $help.Examples | Should -Not -BeNullOrEmpty
        }
    }

    Context "Parameter Validation" {
        It "accepts Count parameter" {
            Get-Command Get-UpdateHistory | Select-Object -ExpandProperty Parameters | Select-Object -ExpandProperty Keys | Should -Contain 'Count'
        }
    }

    Context "Function Metadata" {
        It "is exported from System module" {
            (Get-Module System).ExportedFunctions.Keys | Should -Contain 'Get-UpdateHistory'
        }

        It "has ErrorActionPreference" {
            $funcSource = Get-Command Get-UpdateHistory | Select-Object -ExpandProperty Definition
            $funcSource | Should -Match 'ErrorActionPreference'
        }

        It "has try-catch block" {
            $funcSource = Get-Command Get-UpdateHistory | Select-Object -ExpandProperty Definition
            $funcSource | Should -Match 'try \{'
        }
    }
}
