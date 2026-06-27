BeforeAll {
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\modules\System.psm1'
    Import-Module $modulePath -Force -InformationAction SilentlyContinue
}

Describe 'Set-TaskScheduleCatchup' {
    Context 'Admin Rights Validation' {
        It 'should fail when not running as administrator' {
            InModuleScope -ModuleName System {
                Mock _CheckAdminRights { return $false }
                Mock Write-ErrorLog { }

                $result = Set-TaskScheduleCatchup -EnableCatchup $true
                $result | Should -Be 1
                Should -Invoke Write-ErrorLog -Times 1
            }
        }
    }

    Context 'Task Discovery' {
        BeforeEach {
            InModuleScope -ModuleName System {
                Mock _CheckAdminRights { return $true }
                Mock Write-Log { }
                Mock Write-ErrorLog { }
            }
        }

        It 'should fail if no tasks are found' {
            InModuleScope -ModuleName System {
                Mock _DiscoverWinHardenTasks { return @() }

                $result = Set-TaskScheduleCatchup -EnableCatchup $true
                $result | Should -Be 1
            }
        }

        It 'should succeed when tasks are discovered' {
            InModuleScope -ModuleName System {
                $mockTasks = @(
                    [PSCustomObject]@{ TaskName = 'Task1'; TaskPath = '\Hardening\A\' },
                    [PSCustomObject]@{ TaskName = 'Task2'; TaskPath = '\Hardening\B\' }
                )
                Mock _DiscoverWinHardenTasks { return $mockTasks }
                Mock _GetTaskScheduler { return [PSCustomObject]@{ } }
                Mock _GetTaskSettings { return [PSCustomObject]@{ StartWhenAvailable = $false; ExecutionTimeLimit = '00:01:00' } }
                Mock _ApplyTaskSettings { return $true }
                Mock _UpdateTaskDefinition { return $true }
                Mock _VerifyTaskSettings { return @{ Catchup = 'ENABLED'; TimeoutHours = 2 } }

                $result = Set-TaskScheduleCatchup -EnableCatchup $true
                $result | Should -Be 0
            }
        }
    }

    Context 'Task Configuration' {
        BeforeEach {
            InModuleScope -ModuleName System {
                Mock _CheckAdminRights { return $true }
                Mock _GetTaskScheduler { return [PSCustomObject]@{ } }
                Mock Write-Log { }
                Mock Write-ErrorLog { }
            }
        }

        It 'should apply catchup settings when enabled' {
            InModuleScope -ModuleName System {
                $mockTasks = @( [PSCustomObject]@{ TaskName = 'Test'; TaskPath = '\Hardening\Test\' } )
                Mock _DiscoverWinHardenTasks { return $mockTasks }
                Mock _GetTaskSettings { return [PSCustomObject]@{ } }
                Mock _ApplyTaskSettings { return $true }
                Mock _UpdateTaskDefinition { return $true }
                Mock _VerifyTaskSettings { return @{ Catchup = 'ENABLED'; TimeoutHours = 2 } }

                $result = Set-TaskScheduleCatchup -EnableCatchup $true
                Should -Invoke _ApplyTaskSettings -Times 1
                $result | Should -Be 0
            }
        }

        It 'should apply timeout hours parameter' {
            InModuleScope -ModuleName System {
                $mockTasks = @( [PSCustomObject]@{ TaskName = 'Test'; TaskPath = '\Hardening\Test\' } )
                Mock _DiscoverWinHardenTasks { return $mockTasks }
                Mock _GetTaskSettings { return [PSCustomObject]@{ } }
                Mock _ApplyTaskSettings { return $true }
                Mock _UpdateTaskDefinition { return $true }
                Mock _VerifyTaskSettings { return @{ Catchup = 'ENABLED'; TimeoutHours = 4 } }

                $result = Set-TaskScheduleCatchup -EnableCatchup $true -MaxTaskDurationHours 4
                Should -Invoke _ApplyTaskSettings -Times 1 -ParameterFilter { $_.MaxTaskDurationHours -eq 4 }
            }
        }

        It 'should configure multiple tasks successfully' {
            InModuleScope -ModuleName System {
                $mockTasks = @(
                    [PSCustomObject]@{ TaskName = 'Task1'; TaskPath = '\Hardening\A\' },
                    [PSCustomObject]@{ TaskName = 'Task2'; TaskPath = '\Hardening\B\' },
                    [PSCustomObject]@{ TaskName = 'Task3'; TaskPath = '\Hardening\C\' }
                )
                Mock _DiscoverWinHardenTasks { return $mockTasks }
                Mock _GetTaskSettings { return [PSCustomObject]@{ } }
                Mock _ApplyTaskSettings { return $true }
                Mock _UpdateTaskDefinition { return $true }
                Mock _VerifyTaskSettings { return @{ Catchup = 'ENABLED'; TimeoutHours = 2 } }

                $result = Set-TaskScheduleCatchup -EnableCatchup $true
                Should -Invoke _ApplyTaskSettings -Times 3
                $result | Should -Be 0
            }
        }
    }

    Context 'Error Handling' {
        BeforeEach {
            InModuleScope -ModuleName System {
                Mock _CheckAdminRights { return $true }
                Mock _GetTaskScheduler { return [PSCustomObject]@{ } }
                Mock Write-Log { }
                Mock Write-ErrorLog { }
            }
        }

        It 'should handle partial configuration failures' {
            InModuleScope -ModuleName System {
                $mockTasks = @(
                    [PSCustomObject]@{ TaskName = 'Task1'; TaskPath = '\Hardening\A\' },
                    [PSCustomObject]@{ TaskName = 'Task2'; TaskPath = '\Hardening\B\' }
                )
                Mock _DiscoverWinHardenTasks { return $mockTasks }
                Mock _GetTaskSettings { return [PSCustomObject]@{ }; return $null }
                Mock _ApplyTaskSettings { return $true }
                Mock _UpdateTaskDefinition { return $true }
                Mock _VerifyTaskSettings { return @{ Catchup = 'ENABLED'; TimeoutHours = 2 } }

                $result = Set-TaskScheduleCatchup -EnableCatchup $true
                $result | Should -Be 1
            }
        }

        It 'should return error code on task discovery failure' {
            InModuleScope -ModuleName System {
                Mock _CheckAdminRights { return $true }
                Mock _DiscoverWinHardenTasks { return @() }
                Mock Write-ErrorLog { }

                $result = Set-TaskScheduleCatchup -EnableCatchup $true
                $result | Should -Be 1
            }
        }
    }

    Context 'Task Verification' {
        BeforeEach {
            InModuleScope -ModuleName System {
                Mock _CheckAdminRights { return $true }
                Mock _GetTaskScheduler { return [PSCustomObject]@{ } }
                Mock Write-Log { }
                Mock Write-ErrorLog { }
            }
        }

        It 'should verify task configuration after apply' {
            InModuleScope -ModuleName System {
                $mockTasks = @( [PSCustomObject]@{ TaskName = 'Test'; TaskPath = '\Hardening\Test\' } )
                Mock _DiscoverWinHardenTasks { return $mockTasks }
                Mock _GetTaskSettings { return [PSCustomObject]@{ } }
                Mock _ApplyTaskSettings { return $true }
                Mock _UpdateTaskDefinition { return $true }
                Mock _VerifyTaskSettings { return @{ Catchup = 'ENABLED'; TimeoutHours = 2 } }

                $result = Set-TaskScheduleCatchup -EnableCatchup $true
                Should -Invoke _VerifyTaskSettings -Times 1
                $result | Should -Be 0
            }
        }
    }

    Context 'Parameter Defaults' {
        It 'should use default parameters correctly' {
            InModuleScope -ModuleName System {
                Mock _CheckAdminRights { return $true }
                Mock _DiscoverWinHardenTasks { return @( [PSCustomObject]@{ TaskName = 'Test'; TaskPath = '\Hardening\' } ) }
                Mock _GetTaskSettings { return [PSCustomObject]@{ } }
                Mock _ApplyTaskSettings { return $true }
                Mock _UpdateTaskDefinition { return $true }
                Mock _VerifyTaskSettings { return @{ Catchup = 'ENABLED'; TimeoutHours = 2 } }
                Mock Write-Log { }
                Mock Write-ErrorLog { }

                $result = Set-TaskScheduleCatchup
                $result | Should -Be 0
            }
        }
    }

    Context 'Logging & Messaging' {
        It 'should log task configuration lifecycle' {
            InModuleScope -ModuleName System {
                Mock _CheckAdminRights { return $true }
                Mock _GetTaskScheduler { return [PSCustomObject]@{ } }
                Mock Write-Log { }
                Mock Write-ErrorLog { }
                Mock _DiscoverWinHardenTasks { return @( [PSCustomObject]@{ TaskName = 'Test'; TaskPath = '\Hardening\' } ) }
                Mock _GetTaskSettings { return [PSCustomObject]@{ } }
                Mock _ApplyTaskSettings { return $true }
                Mock _UpdateTaskDefinition { return $true }
                Mock _VerifyTaskSettings { return @{ Catchup = 'ENABLED'; TimeoutHours = 2 } }

                $result = Set-TaskScheduleCatchup
                Should -Invoke Write-Log -ParameterFilter { $_.Message -like '*Starting*' }
                Should -Invoke Write-Log -ParameterFilter { $_.Message -like '*Discovered*' }
                Should -Invoke Write-Log -ParameterFilter { $_.Message -like '*complete*' }
            }
        }
    }
}
