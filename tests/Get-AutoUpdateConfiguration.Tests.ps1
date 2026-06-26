BeforeAll {
    $functionPath = Join-Path -Path $PSScriptRoot -ChildPath '../functions/System/Get-AutoUpdateConfiguration.ps1'

    # Load function
    if (Test-Path $functionPath) {
        . $functionPath
    }

    # Create minimal Write-Log mock for testing
    function Write-Log {
        param(
            [string]$Message,
            [string]$Level = "Info",
            [string]$Caller
        )
    }
}

Describe "Get-AutoUpdateConfiguration" {
    Context "When Group Policy override exists with valid policy values" {
        It "Returns policy value 1 with correct description" {
            Mock Get-ItemProperty {
                return [PSCustomObject]@{ AUOptions = 1 }
            }
            Mock Write-Log

            $result = Get-AutoUpdateConfiguration

            $result.PolicyValue | Should -Be 1
            $result.Description | Should -Be "Keep my computer current is disabled"
            $result.IsEnabled | Should -Be $false
        }

        It "Returns policy value 2 with correct description" {
            Mock Get-ItemProperty {
                return [PSCustomObject]@{ AUOptions = 2 }
            }
            Mock Write-Log

            $result = Get-AutoUpdateConfiguration

            $result.PolicyValue | Should -Be 2
            $result.Description | Should -Be "Notify for download and auto install"
            $result.IsEnabled | Should -Be $true
        }

        It "Returns policy value 3 with correct description" {
            Mock Get-ItemProperty {
                return [PSCustomObject]@{ AUOptions = 3 }
            }
            Mock Write-Log

            $result = Get-AutoUpdateConfiguration

            $result.PolicyValue | Should -Be 3
            $result.Description | Should -Be "Auto download and notify for install"
            $result.IsEnabled | Should -Be $true
        }

        It "Returns policy value 4 with correct description" {
            Mock Get-ItemProperty {
                return [PSCustomObject]@{ AUOptions = 4 }
            }
            Mock Write-Log

            $result = Get-AutoUpdateConfiguration

            $result.PolicyValue | Should -Be 4
            $result.Description | Should -Be "Auto download and schedule install"
            $result.IsEnabled | Should -Be $true
        }

        It "Returns policy value 5 with correct description" {
            Mock Get-ItemProperty {
                return [PSCustomObject]@{ AUOptions = 5 }
            }
            Mock Write-Log

            $result = Get-AutoUpdateConfiguration

            $result.PolicyValue | Should -Be 5
            $result.Description | Should -Be "Automatic Updates required, auto install at 3:00 AM"
            $result.IsEnabled | Should -Be $true
        }

        It "Logs successful retrieval with Info level" {
            Mock Get-ItemProperty {
                return [PSCustomObject]@{ AUOptions = 3 }
            }
            Mock Write-Log

            Get-AutoUpdateConfiguration

            Assert-MockCalled Write-Log -Times 1 -ParameterFilter {
                $Message -match "Auto-Update Configuration retrieved" -and $Level -eq "Info"
            }
        }

        It "Logs with correct caller name" {
            Mock Get-ItemProperty {
                return [PSCustomObject]@{ AUOptions = 2 }
            }
            Mock Write-Log

            Get-AutoUpdateConfiguration

            Assert-MockCalled Write-Log -ParameterFilter {
                $Caller -eq "Get-AutoUpdateConfiguration"
            }
        }
    }

    Context "When Group Policy override does not exist (null policy)" {
        It "Returns null policy value with default description" {
            Mock Get-ItemProperty {
                return $null
            }
            Mock Write-Log

            $result = Get-AutoUpdateConfiguration

            $result.PolicyValue | Should -BeNullOrEmpty
            $result.Description | Should -Be "Default Windows settings (no Group Policy override)"
            $result.IsEnabled | Should -Be $true
        }

        It "Logs default configuration message" {
            Mock Get-ItemProperty {
                return $null
            }
            Mock Write-Log

            Get-AutoUpdateConfiguration

            Assert-MockCalled Write-Log -Times 1 -ParameterFilter {
                $Message -match "default Windows settings" -and $Level -eq "Info"
            }
        }
    }

    Context "When registry access fails" {
        It "Throws exception and logs error" {
            Mock Get-ItemProperty {
                throw [System.ComponentModel.Win32Exception]::new("Access Denied")
            }
            Mock Write-Log

            {
                Get-AutoUpdateConfiguration
            } | Should -Throw

            Assert-MockCalled Write-Log -Times 1 -ParameterFilter {
                $Level -eq "Error" -and $Message -match "Error retrieving"
            }
        }
    }

    Context "WhatIf support" {
        It "Supports -WhatIf parameter" {
            Mock Get-ItemProperty {
                return [PSCustomObject]@{ AUOptions = 2 }
            }
            Mock Write-Log

            {
                Get-AutoUpdateConfiguration -WhatIf
            } | Should -Not -Throw
        }

        It "Supports -Confirm parameter" {
            Mock Get-ItemProperty {
                return [PSCustomObject]@{ AUOptions = 2 }
            }
            Mock Write-Log

            {
                Get-AutoUpdateConfiguration -Confirm:$false
            } | Should -Not -Throw
        }
    }

    Context "Return value structure and types" {
        It "Returns PSCustomObject with correct properties" {
            Mock Get-ItemProperty {
                return [PSCustomObject]@{ AUOptions = 2 }
            }
            Mock Write-Log

            $result = Get-AutoUpdateConfiguration

            $result | Should -BeOfType [PSCustomObject]
            $result.PSObject.Properties.Name | Should -Contain "PolicyValue"
            $result.PSObject.Properties.Name | Should -Contain "Description"
            $result.PSObject.Properties.Name | Should -Contain "IsEnabled"
        }

        It "Returns three custom properties" {
            Mock Get-ItemProperty {
                return [PSCustomObject]@{ AUOptions = 2 }
            }
            Mock Write-Log

            $result = Get-AutoUpdateConfiguration

            $result.PSObject.Properties.Name | Should -Contain "PolicyValue"
            $result.PSObject.Properties.Name | Should -Contain "Description"
            $result.PSObject.Properties.Name | Should -Contain "IsEnabled"
        }

        It "PolicyValue can be integer or null" {
            Mock Get-ItemProperty {
                return [PSCustomObject]@{ AUOptions = 2 }
            }
            Mock Write-Log

            $result = Get-AutoUpdateConfiguration

            ($result.PolicyValue -is [int] -or $null -eq $result.PolicyValue) | Should -Be $true
        }

        It "Description is always string" {
            Mock Get-ItemProperty {
                return [PSCustomObject]@{ AUOptions = 4 }
            }
            Mock Write-Log

            $result = Get-AutoUpdateConfiguration

            $result.Description | Should -BeOfType [string]
        }

        It "IsEnabled is always boolean" {
            Mock Get-ItemProperty {
                return [PSCustomObject]@{ AUOptions = 2 }
            }
            Mock Write-Log

            $result = Get-AutoUpdateConfiguration

            $result.IsEnabled | Should -BeOfType [bool]
        }
    }

    Context "Edge cases and robustness" {
        It "Handles string policy value conversion" {
            Mock Get-ItemProperty {
                return [PSCustomObject]@{ AUOptions = "3" }
            }
            Mock Write-Log

            $result = Get-AutoUpdateConfiguration

            $result.PolicyValue | Should -Be 3
            $result.Description | Should -Be "Auto download and notify for install"
        }

        It "Returns null description for unknown policy value" {
            Mock Get-ItemProperty {
                return [PSCustomObject]@{ AUOptions = 99 }
            }
            Mock Write-Log

            $result = Get-AutoUpdateConfiguration

            $result.PolicyValue | Should -Be 99
            $result.Description | Should -BeNullOrEmpty
            $result.IsEnabled | Should -Be $true
        }

        It "IsEnabled is false only for policy value 1" {
            $testValues = 1, 2, 3, 4, 5
            foreach ($value in $testValues) {
                Mock Get-ItemProperty {
                    return [PSCustomObject]@{ AUOptions = $value }
                }
                Mock Write-Log

                $result = Get-AutoUpdateConfiguration

                if ($value -eq 1) {
                    $result.IsEnabled | Should -Be $false -Because "Policy 1 disables updates"
                }
                else {
                    $result.IsEnabled | Should -Be $true -Because "Policy $value enables updates"
                }
            }
        }
    }

    Context "Error handling behavior" {
        It "Uses ErrorActionPreference Stop" {
            $function = Get-Command Get-AutoUpdateConfiguration
            $script = $function.Definition
            $script | Should -Match 'ErrorActionPreference.*Stop'
        }

        It "Has try-catch-throw structure" {
            $function = Get-Command Get-AutoUpdateConfiguration
            $script = $function.Definition
            $script | Should -Match 'try\s*\{'
            $script | Should -Match 'catch\s*\{'
            $script | Should -Match 'throw'
        }

        It "Logs all errors before throwing" {
            Mock Get-ItemProperty {
                throw "Registry unavailable"
            }
            Mock Write-Log

            try {
                Get-AutoUpdateConfiguration
            }
            catch {
                # Expected
            }

            Assert-MockCalled Write-Log -ParameterFilter {
                $Level -eq "Error"
            }
        }
    }

    Context "Function metadata" {
        It "Has SupportsShouldProcess enabled" {
            $function = Get-Command Get-AutoUpdateConfiguration
            $function.CmdletBinding | Should -Be $true
        }

        It "Accepts no explicit parameters (only implicit CmdletBinding params)" {
            $function = Get-Command Get-AutoUpdateConfiguration
            # CmdletBinding adds WhatIf, Confirm, Verbose, Debug, ErrorAction, etc.
            $function.Parameters.Keys | Should -Contain "WhatIf"
            $function.Parameters.Keys | Should -Contain "Confirm"
        }

        It "Has proper comment-based help" {
            $help = Get-Help Get-AutoUpdateConfiguration -Full
            $help.Synopsis | Should -Not -BeNullOrEmpty
            $help.Description | Should -Not -BeNullOrEmpty
        }
    }
}
