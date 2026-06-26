BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\Core.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module Core -Force -ErrorAction SilentlyContinue
}

Describe "Test-NotNullOrEmpty" {
    Context "Valid input" {
        It "returns true for valid value" {
            { Test-NotNullOrEmpty -Value "ValidValue" -Name "TestParam" } | Should -Not -Throw
        }
    }

    Context "Invalid input" {
        It "throws error for null value" {
            { Test-NotNullOrEmpty -Value $null -Name "TestParam" } | Should -Throw
        }

        It "throws error for empty string" {
            { Test-NotNullOrEmpty -Value "" -Name "TestParam" } | Should -Throw
        }

        It "throws error for whitespace-only string" {
            { Test-NotNullOrEmpty -Value "   " -Name "TestParam" } | Should -Throw
        }

        It "includes parameter name in error message" {
            { Test-NotNullOrEmpty -Value "" -Name "ComputerName" } | Should -Throw "*ComputerName*"
        }
    }
}
