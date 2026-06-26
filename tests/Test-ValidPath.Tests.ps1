BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\Core.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module Core -Force -ErrorAction SilentlyContinue
}

Describe "Test-ValidPath" {
    Context "Valid path" {
        It "returns true for existing path" {
            $testPath = $PSScriptRoot
            { Test-ValidPath -Path $testPath -Name "TestPath" } | Should -Not -Throw
        }
    }

    Context "Invalid path" {
        It "throws error for non-existent path" {
            $invalidPath = "C:\NonExistent\Path\That\Does\Not\Exist"
            { Test-ValidPath -Path $invalidPath -Name "TestPath" } | Should -Throw
        }

        It "includes path in error message" {
            $invalidPath = "C:\InvalidPath"
            { Test-ValidPath -Path $invalidPath -Name "TestPath" } | Should -Throw "*$invalidPath*"
        }
    }
}
