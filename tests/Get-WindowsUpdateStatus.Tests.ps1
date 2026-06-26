BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\System.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module System -Force -ErrorAction SilentlyContinue
}

Describe "Get-WindowsUpdateStatus" {
    Context "Successful Update Search" {
        It "returns PSCustomObject with update counts when updates available" {
            InModuleScope System {
                $mockUpdate1 = New-Object PSObject -Property @{
                    Categories = New-Object PSObject -Property @{
                        Name = @('Security Updates')
                    }
                }

                $mockUpdate2 = New-Object PSObject -Property @{
                    Categories = New-Object PSObject -Property @{
                        Name = @('Critical Updates')
                    }
                }

                $mockUpdate3 = New-Object PSObject -Property @{
                    Categories = New-Object PSObject -Property @{
                        Name = @('Updates')
                    }
                }

                $mockSearchResult = New-Object PSObject -Property @{
                    Updates = @($mockUpdate1, $mockUpdate2, $mockUpdate3)
                }

                $mockUpdateSearcher = New-Object PSObject
                $mockUpdateSearcher | Add-Member -MemberType ScriptMethod -Name "Search" -Value {
                    param($query)
                    return $mockSearchResult
                }

                $mockUpdateSession = New-Object PSObject
                $mockUpdateSession | Add-Member -MemberType ScriptMethod -Name "CreateUpdateSearcher" -Value {
                    return $mockUpdateSearcher
                }

                Mock -CommandName New-Object -MockWith {
                    param($ComObject)
                    if ($ComObject -eq 'Microsoft.Update.Session') {
                        return $mockUpdateSession
                    }
                    return & $true @args
                } -ParameterFilter { $ComObject -eq 'Microsoft.Update.Session' }

                Mock -CommandName Write-Log

                $result = Get-WindowsUpdateStatus

                $result | Should -Not -BeNullOrEmpty
                $result.AvailableUpdates | Should -Be 3
                $result.SecurityUpdates | Should -Be 1
                $result.CriticalUpdates | Should -Be 1
                $result.OtherUpdates | Should -Be 1
            }
        }

        It "returns zero counts when no updates available" {
            InModuleScope System {
                $mockSearchResult = New-Object PSObject -Property @{
                    Updates = @()
                }

                $mockUpdateSearcher = New-Object PSObject
                $mockUpdateSearcher | Add-Member -MemberType ScriptMethod -Name "Search" -Value {
                    param($query)
                    return $mockSearchResult
                }

                $mockUpdateSession = New-Object PSObject
                $mockUpdateSession | Add-Member -MemberType ScriptMethod -Name "CreateUpdateSearcher" -Value {
                    return $mockUpdateSearcher
                }

                Mock -CommandName New-Object -MockWith {
                    param($ComObject)
                    if ($ComObject -eq 'Microsoft.Update.Session') {
                        return $mockUpdateSession
                    }
                    return & $true @args
                } -ParameterFilter { $ComObject -eq 'Microsoft.Update.Session' }

                Mock -CommandName Write-Log

                $result = Get-WindowsUpdateStatus

                $result.AvailableUpdates | Should -Be 0
                $result.SecurityUpdates | Should -Be 0
                $result.CriticalUpdates | Should -Be 0
            }
        }

        It "logs search completion message" {
            InModuleScope System {
                $mockSearchResult = New-Object PSObject -Property @{
                    Updates = @()
                }

                $mockUpdateSearcher = New-Object PSObject
                $mockUpdateSearcher | Add-Member -MemberType ScriptMethod -Name "Search" -Value {
                    param($query)
                    return $mockSearchResult
                }

                $mockUpdateSession = New-Object PSObject
                $mockUpdateSession | Add-Member -MemberType ScriptMethod -Name "CreateUpdateSearcher" -Value {
                    return $mockUpdateSearcher
                }

                Mock -CommandName New-Object -MockWith {
                    param($ComObject)
                    if ($ComObject -eq 'Microsoft.Update.Session') {
                        return $mockUpdateSession
                    }
                    return & $true @args
                } -ParameterFilter { $ComObject -eq 'Microsoft.Update.Session' }

                Mock -CommandName Write-Log

                Get-WindowsUpdateStatus

                Assert-MockCalled -CommandName Write-Log -Times 2
            }
        }
    }

    Context "Error Handling" {
        It "logs and throws error when COM object creation fails" {
            InModuleScope System {
                Mock -CommandName New-Object -MockWith {
                    throw [System.Exception]::new("COM object not available")
                } -ParameterFilter { $ComObject -eq 'Microsoft.Update.Session' }

                Mock -CommandName Write-Log

                { Get-WindowsUpdateStatus } | Should -Throw "COM object not available"
            }
        }

        It "throws terminating error on exception" {
            InModuleScope System {
                Mock -CommandName New-Object -MockWith {
                    throw [System.Exception]::new("Test error")
                } -ParameterFilter { $ComObject -eq 'Microsoft.Update.Session' }

                Mock -CommandName Write-Log

                { Get-WindowsUpdateStatus } | Should -Throw "Test error"
            }
        }
    }

    Context "Update Categorization" {
        It "correctly identifies security updates" {
            InModuleScope System {
                $mockSecurityUpdate = New-Object PSObject -Property @{
                    Categories = New-Object PSObject -Property @{
                        Name = @('Security Updates')
                    }
                }

                $mockSearchResult = New-Object PSObject -Property @{
                    Updates = @($mockSecurityUpdate)
                }

                $mockUpdateSearcher = New-Object PSObject
                $mockUpdateSearcher | Add-Member -MemberType ScriptMethod -Name "Search" -Value {
                    param($query)
                    return $mockSearchResult
                }

                $mockUpdateSession = New-Object PSObject
                $mockUpdateSession | Add-Member -MemberType ScriptMethod -Name "CreateUpdateSearcher" -Value {
                    return $mockUpdateSearcher
                }

                Mock -CommandName New-Object -MockWith {
                    param($ComObject)
                    if ($ComObject -eq 'Microsoft.Update.Session') {
                        return $mockUpdateSession
                    }
                    return & $true @args
                } -ParameterFilter { $ComObject -eq 'Microsoft.Update.Session' }

                Mock -CommandName Write-Log

                $result = Get-WindowsUpdateStatus

                $result.SecurityUpdates | Should -Be 1
                $result.CriticalUpdates | Should -Be 0
                $result.SecurityUpdatesList | Should -Not -BeNullOrEmpty
                @($result.SecurityUpdatesList).Count | Should -Be 1
            }
        }

        It "correctly identifies critical updates" {
            InModuleScope System {
                $mockCriticalUpdate = New-Object PSObject -Property @{
                    Categories = New-Object PSObject -Property @{
                        Name = @('Critical Updates')
                    }
                }

                $mockSearchResult = New-Object PSObject -Property @{
                    Updates = @($mockCriticalUpdate)
                }

                $mockUpdateSearcher = New-Object PSObject
                $mockUpdateSearcher | Add-Member -MemberType ScriptMethod -Name "Search" -Value {
                    param($query)
                    return $mockSearchResult
                }

                $mockUpdateSession = New-Object PSObject
                $mockUpdateSession | Add-Member -MemberType ScriptMethod -Name "CreateUpdateSearcher" -Value {
                    return $mockUpdateSearcher
                }

                Mock -CommandName New-Object -MockWith {
                    param($ComObject)
                    if ($ComObject -eq 'Microsoft.Update.Session') {
                        return $mockUpdateSession
                    }
                    return & $true @args
                } -ParameterFilter { $ComObject -eq 'Microsoft.Update.Session' }

                Mock -CommandName Write-Log

                $result = Get-WindowsUpdateStatus

                $result.CriticalUpdates | Should -Be 1
                $result.SecurityUpdates | Should -Be 0
                $result.CriticalUpdatesList | Should -Not -BeNullOrEmpty
                @($result.CriticalUpdatesList).Count | Should -Be 1
            }
        }

        It "separates other updates from security and critical" {
            InModuleScope System {
                $mockOtherUpdate = New-Object PSObject -Property @{
                    Categories = New-Object PSObject -Property @{
                        Name = @('Updates')
                    }
                }

                $mockSearchResult = New-Object PSObject -Property @{
                    Updates = @($mockOtherUpdate)
                }

                $mockUpdateSearcher = New-Object PSObject
                $mockUpdateSearcher | Add-Member -MemberType ScriptMethod -Name "Search" -Value {
                    param($query)
                    return $mockSearchResult
                }

                $mockUpdateSession = New-Object PSObject
                $mockUpdateSession | Add-Member -MemberType ScriptMethod -Name "CreateUpdateSearcher" -Value {
                    return $mockUpdateSearcher
                }

                Mock -CommandName New-Object -MockWith {
                    param($ComObject)
                    if ($ComObject -eq 'Microsoft.Update.Session') {
                        return $mockUpdateSession
                    }
                    return & $true @args
                } -ParameterFilter { $ComObject -eq 'Microsoft.Update.Session' }

                Mock -CommandName Write-Log

                $result = Get-WindowsUpdateStatus

                $result.OtherUpdates | Should -Be 1
                $result.SecurityUpdates | Should -Be 0
                $result.CriticalUpdates | Should -Be 0
            }
        }
    }

    Context "WhatIf Support" {
        It "supports -WhatIf parameter" {
            InModuleScope System {
                $mockSearchResult = New-Object PSObject -Property @{
                    Updates = @()
                }

                $mockUpdateSearcher = New-Object PSObject
                $mockUpdateSearcher | Add-Member -MemberType ScriptMethod -Name "Search" -Value {
                    param($query)
                    return $mockSearchResult
                }

                $mockUpdateSession = New-Object PSObject
                $mockUpdateSession | Add-Member -MemberType ScriptMethod -Name "CreateUpdateSearcher" -Value {
                    return $mockUpdateSearcher
                }

                Mock -CommandName New-Object -MockWith {
                    param($ComObject)
                    if ($ComObject -eq 'Microsoft.Update.Session') {
                        return $mockUpdateSession
                    }
                    return & $true @args
                } -ParameterFilter { $ComObject -eq 'Microsoft.Update.Session' }

                Mock -CommandName Write-Log

                $result = Get-WindowsUpdateStatus -WhatIf

                $result | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context "Output Format" {
        It "returns object with required properties" {
            InModuleScope System {
                $mockSearchResult = New-Object PSObject -Property @{
                    Updates = @()
                }

                $mockUpdateSearcher = New-Object PSObject
                $mockUpdateSearcher | Add-Member -MemberType ScriptMethod -Name "Search" -Value {
                    param($query)
                    return $mockSearchResult
                }

                $mockUpdateSession = New-Object PSObject
                $mockUpdateSession | Add-Member -MemberType ScriptMethod -Name "CreateUpdateSearcher" -Value {
                    return $mockUpdateSearcher
                }

                Mock -CommandName New-Object -MockWith {
                    param($ComObject)
                    if ($ComObject -eq 'Microsoft.Update.Session') {
                        return $mockUpdateSession
                    }
                    return & $true @args
                } -ParameterFilter { $ComObject -eq 'Microsoft.Update.Session' }

                Mock -CommandName Write-Log

                $result = Get-WindowsUpdateStatus

                $result.PSObject.Properties.Name | Should -Contain 'AvailableUpdates'
                $result.PSObject.Properties.Name | Should -Contain 'SecurityUpdates'
                $result.PSObject.Properties.Name | Should -Contain 'CriticalUpdates'
                $result.PSObject.Properties.Name | Should -Contain 'OtherUpdates'
                $result.PSObject.Properties.Name | Should -Contain 'AllUpdates'
                $result.PSObject.Properties.Name | Should -Contain 'SecurityUpdatesList'
                $result.PSObject.Properties.Name | Should -Contain 'CriticalUpdatesList'
            }
        }
    }
}
