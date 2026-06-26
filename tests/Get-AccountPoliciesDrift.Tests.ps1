BeforeAll {
    # Load System.Test module (contains only Get-AccountPoliciesDrift, avoids elevation issues)
    $testModulePath = Resolve-Path "$PSScriptRoot\..\modules\System.Test.psm1"
    Import-Module $testModulePath -Force

    # Load test data
    $fixturesPath = "$PSScriptRoot\fixtures\AccountPoliciesScenarios.json"
    $scenarios = Get-Content -Path $fixturesPath | ConvertFrom-Json
}

AfterAll {
    Remove-Module System.Test -Force -ErrorAction SilentlyContinue
    Remove-Module Core -Force -ErrorAction SilentlyContinue
}

Describe "Get-AccountPoliciesDrift" {
    Context "Compliant System" {
        BeforeEach {
            Mock Get-ItemProperty {
                if ($Name -eq "MinimumPasswordLength") {
                    return [PSCustomObject]@{ MinimumPasswordLength = 12 }
                }
                elseif ($Name -eq "PasswordComplexity") {
                    return [PSCustomObject]@{ PasswordComplexity = 1 }
                }
            } -ModuleName System.Test

            Mock Write-Log -ModuleName System.Test
        }

        It "returns empty array when all policies are compliant" {
            $result = Get-AccountPoliciesDrift

            $result | Should -BeNullOrEmpty
        }

        It "does not log any drift when compliant" {
            Get-AccountPoliciesDrift

            Assert-MockCalled Write-Log -Times 0 -ModuleName System.Test
        }
    }

    Context "Drift Detection - Minimum Password Length" {
        BeforeEach {
            Mock Get-ItemProperty {
                if ($Name -eq "MinimumPasswordLength") {
                    return [PSCustomObject]@{ MinimumPasswordLength = 8 }
                }
                elseif ($Name -eq "PasswordComplexity") {
                    return [PSCustomObject]@{ PasswordComplexity = 1 }
                }
            } -ModuleName System.Test

            Mock Write-Log -ModuleName System.Test
        }

        It "detects password length drift" {
            $result = Get-AccountPoliciesDrift

            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
        }

        It "includes drift setting name in result" {
            $result = Get-AccountPoliciesDrift

            $result.Setting | Should -Contain "Minimum Password Length"
        }

        It "includes expected and actual values" {
            $result = Get-AccountPoliciesDrift

            $result[0].Expected | Should -Match "12 characters"
            $result[0].Actual | Should -Match "8 characters"
        }

        It "marks finding as DRIFT status" {
            $result = Get-AccountPoliciesDrift

            $result[0].Status | Should -Be "DRIFT"
        }

        It "marks finding as HIGH severity" {
            $result = Get-AccountPoliciesDrift

            $result[0].Severity | Should -Be "HIGH"
        }

        It "includes Account Policy category" {
            $result = Get-AccountPoliciesDrift

            $result[0].Category | Should -Be "Account Policy"
        }

        It "logs drift warning message" {
            Get-AccountPoliciesDrift

            Assert-MockCalled Write-Log -ModuleName System.Test -ParameterFilter {
                $Level -eq "Warning" -and $Message -match "Min password length"
            }
        }

        It "accepts custom minimum password length parameter" {
            $result = Get-AccountPoliciesDrift -MinimumPasswordLength 10

            $result | Should -BeNullOrEmpty
        }
    }

    Context "Drift Detection - Password Complexity" {
        BeforeEach {
            Mock Get-ItemProperty {
                if ($Name -eq "MinimumPasswordLength") {
                    return [PSCustomObject]@{ MinimumPasswordLength = 12 }
                }
                elseif ($Name -eq "PasswordComplexity") {
                    return [PSCustomObject]@{ PasswordComplexity = 0 }
                }
            } -ModuleName System.Test

            Mock Write-Log -ModuleName System.Test
        }

        It "detects password complexity drift" {
            $result = Get-AccountPoliciesDrift

            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
        }

        It "indicates complexity is disabled when expected enabled" {
            $result = Get-AccountPoliciesDrift

            $result[0].Expected | Should -Match "Enabled"
            $result[0].Actual | Should -Match "Disabled"
        }

        It "allows disabling complexity requirement" {
            $result = Get-AccountPoliciesDrift -RequirePasswordComplexity $false

            $result | Should -BeNullOrEmpty
        }

        It "logs complexity drift warning" {
            Get-AccountPoliciesDrift

            Assert-MockCalled Write-Log -ModuleName System.Test -ParameterFilter {
                $Level -eq "Warning" -and $Message -match "Password complexity"
            }
        }
    }

    Context "Multiple Drifts" {
        BeforeEach {
            Mock Get-ItemProperty {
                if ($Name -eq "MinimumPasswordLength") {
                    return [PSCustomObject]@{ MinimumPasswordLength = 6 }
                }
                elseif ($Name -eq "PasswordComplexity") {
                    return [PSCustomObject]@{ PasswordComplexity = 0 }
                }
            } -ModuleName System.Test

            Mock Write-Log -ModuleName System.Test
        }

        It "detects multiple policy drifts" {
            $result = Get-AccountPoliciesDrift

            $result.Count | Should -Be 2
        }

        It "includes both password length and complexity drifts" {
            $result = Get-AccountPoliciesDrift

            $result.Setting | Should -Contain "Minimum Password Length"
            $result.Setting | Should -Contain "Password Complexity"
        }

        It "marks all drifts as HIGH severity" {
            $result = Get-AccountPoliciesDrift

            $result | ForEach-Object { $_.Severity | Should -Be "HIGH" }
        }
    }

    Context "Registry Access Failure" {
        BeforeEach {
            Mock Get-ItemProperty {
                throw [System.Management.Automation.ItemNotFoundException]::new("Registry key not found")
            } -ModuleName System.Test

            Mock Write-Log -ModuleName System.Test
        }

        It "throws error when registry access fails" {
            { Get-AccountPoliciesDrift -ErrorAction Stop } | Should -Throw
        }

        It "logs error message" {
            { Get-AccountPoliciesDrift -ErrorAction SilentlyContinue } | Out-Null

            Assert-MockCalled Write-Log -ModuleName System.Test -ParameterFilter {
                $Level -eq "Error"
            }
        }
    }

    Context "Missing Registry Values" {
        BeforeEach {
            Mock Get-ItemProperty {
                return $null
            } -ModuleName System.Test

            Mock Write-Log -ModuleName System.Test
        }

        It "handles missing minimum password length gracefully" {
            $result = Get-AccountPoliciesDrift -ErrorAction SilentlyContinue

            $result.Count | Should -Be 2
        }

        It "detects drift when values are null" {
            $result = Get-AccountPoliciesDrift -ErrorAction SilentlyContinue

            $result[0].Actual | Should -Match "characters"
        }
    }

    Context "Parameter Validation" {
        BeforeEach {
            Mock Get-ItemProperty {
                if ($Name -eq "MinimumPasswordLength") {
                    return [PSCustomObject]@{ MinimumPasswordLength = 12 }
                }
                elseif ($Name -eq "PasswordComplexity") {
                    return [PSCustomObject]@{ PasswordComplexity = 1 }
                }
            } -ModuleName System.Test

            Mock Write-Log -ModuleName System.Test
        }

        It "accepts MinimumPasswordLength parameter" {
            $result = Get-AccountPoliciesDrift -MinimumPasswordLength 14

            $result | Should -Not -BeNullOrEmpty
        }

        It "accepts RequirePasswordComplexity parameter" {
            $result = Get-AccountPoliciesDrift -RequirePasswordComplexity $false

            $result | Should -BeNullOrEmpty
        }

        It "supports WhatIf switch" {
            { Get-AccountPoliciesDrift -WhatIf } | Should -Not -Throw
        }
    }

    Context "Return Object Structure" {
        BeforeEach {
            Mock Get-ItemProperty {
                if ($Name -eq "MinimumPasswordLength") {
                    return [PSCustomObject]@{ MinimumPasswordLength = 8 }
                }
                elseif ($Name -eq "PasswordComplexity") {
                    return [PSCustomObject]@{ PasswordComplexity = 1 }
                }
            } -ModuleName System.Test

            Mock Write-Log -ModuleName System.Test
        }

        It "returns PSCustomObject with required properties" {
            $result = Get-AccountPoliciesDrift

            $result[0] | Should -HaveProperty "Category"
            $result[0] | Should -HaveProperty "Setting"
            $result[0] | Should -HaveProperty "Expected"
            $result[0] | Should -HaveProperty "Actual"
            $result[0] | Should -HaveProperty "Status"
            $result[0] | Should -HaveProperty "Severity"
        }

        It "has valid status values" {
            $result = Get-AccountPoliciesDrift

            @("DRIFT", "COMPLIANT") | Should -Contain $result[0].Status
        }

        It "has valid severity values" {
            $result = Get-AccountPoliciesDrift

            @("LOW", "MEDIUM", "HIGH", "CRITICAL") | Should -Contain $result[0].Severity
        }
    }

    Context "Documentation" {
        It "has complete help documentation" {
            $help = Get-Help Get-AccountPoliciesDrift

            $help.Synopsis | Should -Not -BeNullOrEmpty
            $help.Description | Should -Not -BeNullOrEmpty
        }

        It "includes parameter descriptions" {
            $help = Get-Help Get-AccountPoliciesDrift

            $help.Parameters.Parameter.Name | Should -Contain "MinimumPasswordLength"
            $help.Parameters.Parameter.Name | Should -Contain "RequirePasswordComplexity"
        }

        It "includes usage example" {
            $help = Get-Help Get-AccountPoliciesDrift

            $help.Examples | Should -Not -BeNullOrEmpty
        }
    }
}
