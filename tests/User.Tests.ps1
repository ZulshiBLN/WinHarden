BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\User.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module User -Force -ErrorAction SilentlyContinue
}

Describe "User Module - Skeleton Status" {
    Context "Module Loading" {
        It "User.psm1 module loads successfully" {
            { Get-Module User } | Should -Not -BeNullOrEmpty
        }

        It "module depends on Core module" {
            $moduleCode = Get-Content -Path "$PSScriptRoot\..\modules\User.psm1" -Raw
            $moduleCode | Should -Match "Core.psm1"
        }
    }

    Context "Function Directory Structure" {
        It "functions/User directory exists" {
            Test-Path "$PSScriptRoot\..\functions\User" -PathType Container | Should -Be $true
        }
    }

    Context "Module Compliance" {
        It "follows ADR-008 Module Import Strategy" {
            $moduleCode = Get-Content -Path "$PSScriptRoot\..\modules\User.psm1" -Raw
            $moduleCode | Should -Match "ADR-008"
        }

        It "implements ADR-009 Dependency Hierarchy" {
            $moduleCode = Get-Content -Path "$PSScriptRoot\..\modules\User.psm1" -Raw
            $moduleCode | Should -Match "ADR-009"
        }
    }
}
