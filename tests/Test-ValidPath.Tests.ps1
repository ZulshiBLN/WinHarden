BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\Core.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module Core -Force -ErrorAction SilentlyContinue
}

Describe "Test-ValidPath" {
    BeforeEach {
        # Mock Write-Log to prevent file I/O during tests
        Mock -CommandName Write-Log -ModuleName Core -MockWith {}
    }
    Context "Valid path" {
        It "returns true for existing path" {
            $testPath = $PSScriptRoot
            $result = Test-ValidPath -Path $testPath -Name "TestPath"
            $result | Should -Be $true
        }

        It "returns true for existing file" {
            $testFile = $PSCommandPath
            $result = Test-ValidPath -Path $testFile -Name "TestFile"
            $result | Should -Be $true
        }

        It "uses default name parameter when not specified" {
            $testPath = $PSScriptRoot
            $result = Test-ValidPath -Path $testPath
            $result | Should -Be $true
        }

        It "does not log when path validation succeeds" {
            $testPath = $PSScriptRoot
            Test-ValidPath -Path $testPath -Name "TestPath"
            # Write-Log should not be called on success
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

        It "includes custom name in error message" {
            $invalidPath = "C:\InvalidPath"
            $customName = "MyCustomPath"
            { Test-ValidPath -Path $invalidPath -Name $customName } | Should -Throw "*$customName*"
        }

        It "calls Write-Log when path validation fails" {
            $invalidPath = "C:\NonExistent\Path\That\Does\Not\Exist"
            { Test-ValidPath -Path $invalidPath -Name "TestPath" } | Should -Throw
            Assert-MockCalled -CommandName Write-Log -ModuleName Core -Times 1 -ParameterFilter {
                $Level -eq 'Error'
            }
        }
    }

    Context "Parameter validation" {
        It "rejects null path" {
            { Test-ValidPath -Path $null -Name "TestPath" } | Should -Throw
        }

        It "rejects empty path" {
            { Test-ValidPath -Path '' -Name "TestPath" } | Should -Throw
        }
    }
}
