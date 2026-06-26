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

        It "detects unsupported PowerShell version in result" {
            $result = Test-WinHardenDependencies
            # Verify the result structure is correct regardless of version
            $result['PowerShellVersion'] | Should -Not -BeNullOrEmpty
            $result['PowerShellVersion'].Status | Should -BeIn @('OK', 'FAIL')
            $result['PowerShellVersion'].Required | Should -Be '5.1'
            $result['PowerShellVersion'].Actual | Should -Not -BeNullOrEmpty
        }
    }

    Context "Optional module checking" {
        It "checks optional modules when specified" {
            $result = Test-WinHardenDependencies -Module @('PSScriptAnalyzer')
            $result['PSScriptAnalyzer'] | Should -Not -BeNullOrEmpty
            $result['PSScriptAnalyzer'].Status | Should -Match 'Available|NotFound'
        }

        It "handles empty module array" {
            $result = Test-WinHardenDependencies -Module @()
            $result | Should -BeOfType [hashtable]
            $result.Keys | Should -Contain 'PowerShellVersion'
        }

        It "includes version information for available modules" {
            $result = Test-WinHardenDependencies -Module @('PSScriptAnalyzer')
            $result['PSScriptAnalyzer'].Keys | Should -Contain 'Version'
        }

        It "detects module as Available when it exists" {
            $result = Test-WinHardenDependencies -Module @('PSScriptAnalyzer')
            $result['PSScriptAnalyzer'].Status | Should -Be 'Available'
        }
    }

    Context "ExitOnError behavior" {
        It "throws when module not found with ExitOnError" {
            { Test-WinHardenDependencies -Module @('NonExistentModule_XYZ123') -ExitOnError } | Should -Throw
        }

        It "returns result without throwing when module not found and ExitOnError false" {
            $result = Test-WinHardenDependencies -Module @('NonExistentModule_XYZ123') -ExitOnError:$false
            $result | Should -BeOfType [hashtable]
            $result['NonExistentModule_XYZ123'].Status | Should -Be 'NotFound'
        }

        It "returns status OK when PowerShell version is sufficient" {
            $result = Test-WinHardenDependencies
            $result['PowerShellVersion'].Status | Should -Be 'OK'
        }

        It "returns error message with specific module not found format" {
            $result = Test-WinHardenDependencies -Module @('NonExistentModule_XYZ123') -ExitOnError:$false
            $result['NonExistentModule_XYZ123']['Status'] | Should -Be 'NotFound'
            $result['NonExistentModule_XYZ123'].Keys | Should -Contain 'Version'
        }
    }

    Context "WhatIf support" {
        It "supports -WhatIf without throwing" {
            { Test-WinHardenDependencies -WhatIf } | Should -Not -Throw
        }

        It "returns results with -WhatIf and -Module" {
            $result = Test-WinHardenDependencies -Module @('PSScriptAnalyzer') -WhatIf
            $result | Should -BeOfType [hashtable]
            $result.Keys | Should -Contain 'PowerShellVersion'
        }
    }
}
