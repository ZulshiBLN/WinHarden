BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\System.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module System -Force -ErrorAction SilentlyContinue
}

Describe "Get-AutoUpdateConfiguration" {
    Context "Successful Registry Read" {
        It "returns a PSCustomObject with required properties" {
            InModuleScope System {
                Mock Get-ItemProperty -ParameterFilter { $Path -eq "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" } `
                    -MockWith { return @{ AUOptions = 4 } }
                Mock Write-Log -MockWith { }

                $config = Get-AutoUpdateConfiguration
                $config | Should -Not -BeNullOrEmpty
                $config -is [PSCustomObject] | Should -Be $true
            }
        }

        It "includes PolicyValue, Description, and IsEnabled properties" {
            InModuleScope System {
                Mock Get-ItemProperty -MockWith { return @{ AUOptions = 4 } }
                Mock Write-Log -MockWith { }

                $config = Get-AutoUpdateConfiguration
                $config.PSObject.Properties.Name | Should -Contain 'PolicyValue'
                $config.PSObject.Properties.Name | Should -Contain 'Description'
                $config.PSObject.Properties.Name | Should -Contain 'IsEnabled'
            }
        }

        It "sets PolicyValue to registry AUOptions value" {
            InModuleScope System {
                Mock Get-ItemProperty -MockWith { return @{ AUOptions = 4 } }
                Mock Write-Log -MockWith { }

                $config = Get-AutoUpdateConfiguration
                $config.PolicyValue | Should -Be 4
            }
        }

        It "calls Write-Log with Info level on successful read" {
            InModuleScope System {
                Mock Get-ItemProperty -MockWith { return @{ AUOptions = 4 } }
                Mock Write-Log -MockWith { }

                Get-AutoUpdateConfiguration
                Should -Invoke Write-Log -ParameterFilter { $Level -eq 'Info' } -Times 1
            }
        }
    }

    Context "Update Type Mapping" {
        It "maps policy value 1 to Disabled description" {
            InModuleScope System {
                Mock Get-ItemProperty -MockWith { return @{ AUOptions = 1 } }
                Mock Write-Log -MockWith { }

                $config = Get-AutoUpdateConfiguration
                $config.Description | Should -Be "Keep my computer current is disabled"
            }
        }

        It "maps policy value 2 to Notify for download and auto install" {
            InModuleScope System {
                Mock Get-ItemProperty -MockWith { return @{ AUOptions = 2 } }
                Mock Write-Log -MockWith { }

                $config = Get-AutoUpdateConfiguration
                $config.Description | Should -Be "Notify for download and auto install"
            }
        }

        It "maps policy value 3 to Auto download and notify for install" {
            InModuleScope System {
                Mock Get-ItemProperty -MockWith { return @{ AUOptions = 3 } }
                Mock Write-Log -MockWith { }

                $config = Get-AutoUpdateConfiguration
                $config.Description | Should -Be "Auto download and notify for install"
            }
        }

        It "maps policy value 4 to Auto download and schedule install" {
            InModuleScope System {
                Mock Get-ItemProperty -MockWith { return @{ AUOptions = 4 } }
                Mock Write-Log -MockWith { }

                $config = Get-AutoUpdateConfiguration
                $config.Description | Should -Be "Auto download and schedule install"
            }
        }

        It "maps policy value 5 to Automatic Updates required, auto install at 3:00 AM" {
            InModuleScope System {
                Mock Get-ItemProperty -MockWith { return @{ AUOptions = 5 } }
                Mock Write-Log -MockWith { }

                $config = Get-AutoUpdateConfiguration
                $config.Description | Should -Be "Automatic Updates required, auto install at 3:00 AM"
            }
        }
    }

    Context "IsEnabled Flag Logic" {
        It "sets IsEnabled to false when AUOptions is 1 (Disabled)" {
            InModuleScope System {
                Mock Get-ItemProperty -MockWith { return @{ AUOptions = 1 } }
                Mock Write-Log -MockWith { }

                $config = Get-AutoUpdateConfiguration
                $config.IsEnabled | Should -Be $false
            }
        }

        It "sets IsEnabled to true when AUOptions is not 1" {
            InModuleScope System {
                Mock Get-ItemProperty -MockWith { return @{ AUOptions = 2 } }
                Mock Write-Log -MockWith { }

                $config = Get-AutoUpdateConfiguration
                $config.IsEnabled | Should -Be $true
            }
        }
    }

    Context "Default Windows Settings (No Group Policy)" {
        It "returns object when registry key is not configured" {
            InModuleScope System {
                Mock Get-ItemProperty -ParameterFilter { $Path -eq "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" } `
                    -MockWith { return $null }
                Mock Write-Log -MockWith { }

                $config = Get-AutoUpdateConfiguration
                $config | Should -Not -BeNullOrEmpty
            }
        }

        It "sets PolicyValue to null when no Group Policy override exists" {
            InModuleScope System {
                Mock Get-ItemProperty -MockWith { return $null }
                Mock Write-Log -MockWith { }

                $config = Get-AutoUpdateConfiguration
                $config.PolicyValue | Should -Be $null
            }
        }

        It "returns Default Windows settings description" {
            InModuleScope System {
                Mock Get-ItemProperty -MockWith { return $null }
                Mock Write-Log -MockWith { }

                $config = Get-AutoUpdateConfiguration
                $config.Description | Should -Be "Default Windows settings (no Group Policy override)"
            }
        }

        It "sets IsEnabled to true for default settings" {
            InModuleScope System {
                Mock Get-ItemProperty -MockWith { return $null }
                Mock Write-Log -MockWith { }

                $config = Get-AutoUpdateConfiguration
                $config.IsEnabled | Should -Be $true
            }
        }
    }

    Context "Error Handling" {
        It "throws exception when registry access fails" {
            InModuleScope System {
                Mock Get-ItemProperty -MockWith { throw "Access denied" }
                Mock Write-Log -MockWith { }

                { Get-AutoUpdateConfiguration } | Should -Throw
            }
        }

        It "calls Write-Log with Error level when registry read fails" {
            InModuleScope System {
                Mock Get-ItemProperty -MockWith { throw "Access denied" }
                Mock Write-Log -MockWith { }

                { Get-AutoUpdateConfiguration -ErrorAction SilentlyContinue } | Should -Throw
                Should -Invoke Write-Log -ParameterFilter { $Level -eq 'Error' } -Scope It
            }
        }
    }

    Context "Documentation" {
        It "has complete help documentation with synopsis" {
            $help = Get-Help Get-AutoUpdateConfiguration
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }

        It "includes description in help" {
            $help = Get-Help Get-AutoUpdateConfiguration
            $help.Description.Text | Should -Not -BeNullOrEmpty
        }

        It "includes examples in help" {
            $help = Get-Help Get-AutoUpdateConfiguration
            $help.Examples | Should -Not -BeNullOrEmpty
        }

        It "includes notes section" {
            $help = Get-Help Get-AutoUpdateConfiguration
            $help.AlertSet | Should -Not -BeNullOrEmpty
        }
    }
}
