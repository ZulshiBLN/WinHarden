BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\Maintenance.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module Maintenance -Force -ErrorAction SilentlyContinue
}

Describe "Maintenance Module - Skeleton Status" {
    Context "Module Loading" {
        It "Maintenance.psm1 module loads successfully" {
            { Get-Module Maintenance } | Should -Not -BeNullOrEmpty
        }

        It "module depends on Core module" {
            $moduleCode = Get-Content -Path "$PSScriptRoot\..\modules\Maintenance.psm1" -Raw
            $moduleCode | Should -Match "Core.psm1"
        }

        It "optionally depends on System and User modules" {
            $moduleCode = Get-Content -Path "$PSScriptRoot\..\modules\Maintenance.psm1" -Raw
            $moduleCode | Should -Match "System.psm1"
            $moduleCode | Should -Match "User.psm1"
        }
    }

    Context "Function Directory Structure" {
        It "functions/Maintenance directory exists" {
            Test-Path "$PSScriptRoot\..\functions\Maintenance" -PathType Container | Should -Be $true
        }
    }

    Context "Module Compliance" {
        It "follows ADR-008 Module Import Strategy" {
            $moduleCode = Get-Content -Path "$PSScriptRoot\..\modules\Maintenance.psm1" -Raw
            $moduleCode | Should -Match "ADR-008"
        }

        It "implements ADR-009 Dependency Hierarchy" {
            $moduleCode = Get-Content -Path "$PSScriptRoot\..\modules\Maintenance.psm1" -Raw
            $moduleCode | Should -Match "ADR-009"
        }
    }
}
