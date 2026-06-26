BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\System.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module System -Force -ErrorAction SilentlyContinue
}

Describe "New-HardeningSession" {
    Context "Parameter Validation" {
        It "accepts valid profile names" {
            InModuleScope System {
                Mock _ValidateHardeningPrerequisites -MockWith { }
                Mock Get-HardeningProfile -MockWith {
                    return @{
                        Rules = @(
                            @{ Name = 'Rule1'; Profile = 'Basis' },
                            @{ Name = 'Rule2'; Profile = 'Basis' },
                            @{ Name = 'Rule3'; Profile = 'Recommended' },
                            @{ Name = 'Rule4'; Profile = 'Strict' }
                        )
                    }
                }
                Mock _ValidateProfileCompatibility -MockWith { }

                $profiles = @('Basis', 'Recommended', 'Strict')
                foreach ($profile in $profiles) {
                    { New-HardeningSession -Profile $profile -TargetSystem Client -OSVersion 11 -WhatIf } | Should -Not -Throw
                }
            }
        }

        It "rejects invalid profile names" {
            InModuleScope System {
                Mock _ValidateHardeningPrerequisites -MockWith { }
                Mock Get-HardeningProfile -MockWith {
                    return @{ Rules = @() }
                }
                Mock _ValidateProfileCompatibility -MockWith { }

                { New-HardeningSession -Profile 'InvalidProfile' -TargetSystem Client -OSVersion 11 -WhatIf } | Should -Throw
            }
        }

        It "accepts valid target systems" {
            InModuleScope System {
                Mock _ValidateHardeningPrerequisites -MockWith { }
                Mock Get-HardeningProfile -MockWith {
                    return @{ Rules = @() }
                }
                Mock _ValidateProfileCompatibility -MockWith { }

                { New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf } | Should -Not -Throw
                { New-HardeningSession -Profile Basis -TargetSystem Server -OSVersion 2022 -WhatIf } | Should -Not -Throw
            }
        }

        It "validates Client OS version as 11 only" {
            InModuleScope System {
                Mock _ValidateHardeningPrerequisites -MockWith { }
                Mock Get-HardeningProfile -MockWith {
                    return @{ Rules = @() }
                }
                Mock _ValidateProfileCompatibility -MockWith { }

                { New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf } | Should -Not -Throw
                { New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 2022 -WhatIf } | Should -Throw
            }
        }

        It "validates Server OS versions as 2019, 2022, or 2025 only" {
            InModuleScope System {
                Mock _ValidateHardeningPrerequisites -MockWith { }
                Mock Get-HardeningProfile -MockWith {
                    return @{ Rules = @() }
                }
                Mock _ValidateProfileCompatibility -MockWith { }

                $validVersions = @(2019, 2022, 2025)
                foreach ($version in $validVersions) {
                    { New-HardeningSession -Profile Basis -TargetSystem Server -OSVersion $version -WhatIf } | Should -Not -Throw
                }
                { New-HardeningSession -Profile Basis -TargetSystem Server -OSVersion 11 -WhatIf } | Should -Throw
            }
        }
    }

    Context "Session Creation" {
        It "returns a session object with required properties" {
            InModuleScope System {
                Mock _ValidateHardeningPrerequisites -MockWith { }
                Mock Get-HardeningProfile -MockWith {
                    return @{ Rules = @() }
                }
                Mock _ValidateProfileCompatibility -MockWith { }

                $session = New-HardeningSession -Profile Recommended -TargetSystem Client -OSVersion 11 -WhatIf
                $session | Should -Not -BeNullOrEmpty
                $session.SessionId | Should -Not -BeNullOrEmpty
                $session.CreatedTime | Should -Not -BeNullOrEmpty
                $session.Profile | Should -Be 'Recommended'
                $session.TargetSystem | Should -Be 'Client'
                $session.OSVersion | Should -Be 11
            }
        }

        It "sets profile correctly in session" {
            InModuleScope System {
                Mock _ValidateHardeningPrerequisites -MockWith { }
                Mock Get-HardeningProfile -MockWith {
                    return @{ Rules = @() }
                }
                Mock _ValidateProfileCompatibility -MockWith { }

                $session = New-HardeningSession -Profile Strict -TargetSystem Server -OSVersion 2025 -WhatIf
                $session.Profile | Should -Be 'Strict'
            }
        }

        It "sets target system correctly in session" {
            InModuleScope System {
                Mock _ValidateHardeningPrerequisites -MockWith { }
                Mock Get-HardeningProfile -MockWith {
                    return @{ Rules = @() }
                }
                Mock _ValidateProfileCompatibility -MockWith { }

                $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
                $session.TargetSystem | Should -Be 'Client'
            }
        }

        It "initializes state object with proper structure" {
            InModuleScope System {
                Mock _ValidateHardeningPrerequisites -MockWith { }
                Mock Get-HardeningProfile -MockWith {
                    return @{ Rules = @() }
                }
                Mock _ValidateProfileCompatibility -MockWith { }

                $session = New-HardeningSession -Profile Recommended -TargetSystem Client -OSVersion 11 -WhatIf
                $session.State | Should -Not -BeNullOrEmpty
                $session.State.TotalRules | Should -Be 0
                $session.State.AppliedRules | Should -HaveCount 0
                $session.State.FailedRules | Should -HaveCount 0
                $session.State.SkippedRules | Should -HaveCount 0
                $session.State.ComplianceStatus | Should -Be 'Pending'
            }
        }

        It "generates unique SessionId for each session" {
            InModuleScope System {
                Mock _ValidateHardeningPrerequisites -MockWith { }
                Mock Get-HardeningProfile -MockWith {
                    return @{ Rules = @() }
                }
                Mock _ValidateProfileCompatibility -MockWith { }

                $session1 = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
                $session2 = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
                $session1.SessionId | Should -Not -Be $session2.SessionId
            }
        }

        It "respects WhatIfPreference parameter" {
            InModuleScope System {
                Mock _ValidateHardeningPrerequisites -MockWith { }
                Mock Get-HardeningProfile -MockWith {
                    return @{ Rules = @() }
                }
                Mock _ValidateProfileCompatibility -MockWith { }

                $session = New-HardeningSession -Profile Basis -TargetSystem Server -OSVersion 2022 -WhatIf
                $session.WhatIfMode | Should -Be $true
            }
        }

        It "sets correct computer name" {
            InModuleScope System {
                Mock _ValidateHardeningPrerequisites -MockWith { }
                Mock Get-HardeningProfile -MockWith {
                    return @{ Rules = @() }
                }
                Mock _ValidateProfileCompatibility -MockWith { }

                $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
                $session.ComputerName | Should -Be $env:COMPUTERNAME
            }
        }

        It "sets session ID with valid GUID format" {
            InModuleScope System {
                Mock _ValidateHardeningPrerequisites -MockWith { }
                Mock Get-HardeningProfile -MockWith {
                    return @{ Rules = @() }
                }
                Mock _ValidateProfileCompatibility -MockWith { }

                $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
                $session.SessionId | Should -Match '^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$'
            }
        }
    }

    Context "Session State Initialization" {
        It "initializes applied rules as empty array" {
            InModuleScope System {
                Mock _ValidateHardeningPrerequisites -MockWith { }
                Mock Get-HardeningProfile -MockWith {
                    return @{ Rules = @() }
                }
                Mock _ValidateProfileCompatibility -MockWith { }

                $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
                $session.State.AppliedRules | Should -HaveCount 0
            }
        }

        It "initializes failed rules as empty array" {
            InModuleScope System {
                Mock _ValidateHardeningPrerequisites -MockWith { }
                Mock Get-HardeningProfile -MockWith {
                    return @{ Rules = @() }
                }
                Mock _ValidateProfileCompatibility -MockWith { }

                $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
                $session.State.FailedRules | Should -HaveCount 0
            }
        }

        It "initializes skipped rules as empty array" {
            InModuleScope System {
                Mock _ValidateHardeningPrerequisites -MockWith { }
                Mock Get-HardeningProfile -MockWith {
                    return @{ Rules = @() }
                }
                Mock _ValidateProfileCompatibility -MockWith { }

                $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
                $session.State.SkippedRules | Should -HaveCount 0
            }
        }

        It "initializes compliance status to Pending" {
            InModuleScope System {
                Mock _ValidateHardeningPrerequisites -MockWith { }
                Mock Get-HardeningProfile -MockWith {
                    return @{ Rules = @() }
                }
                Mock _ValidateProfileCompatibility -MockWith { }

                $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
                $session.State.ComplianceStatus | Should -Be 'Pending'
            }
        }

        It "initializes time tracking as null" {
            InModuleScope System {
                Mock _ValidateHardeningPrerequisites -MockWith { }
                Mock Get-HardeningProfile -MockWith {
                    return @{ Rules = @() }
                }
                Mock _ValidateProfileCompatibility -MockWith { }

                $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
                $session.State.StartTime | Should -BeNullOrEmpty
                $session.State.EndTime | Should -BeNullOrEmpty
                $session.State.Duration | Should -BeNullOrEmpty
            }
        }
    }

    Context "Profile Initialization" {
        It "loads rules for Basis profile" {
            InModuleScope System {
                Mock _ValidateHardeningPrerequisites -MockWith { }
                Mock Get-HardeningProfile -MockWith {
                    return @{ Rules = @(1, 2, 3) }
                }
                Mock _ValidateProfileCompatibility -MockWith { }

                $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
                $session.State.TotalRules | Should -BeGreaterThan 0
            }
        }

        It "loads different rule counts for different profiles" {
            InModuleScope System {
                Mock _ValidateHardeningPrerequisites -MockWith { }
                Mock Get-HardeningProfile -ParameterFilter { $ProfileName -eq 'Basis' } -MockWith {
                    return @{ Rules = @(1, 2) }
                }
                Mock Get-HardeningProfile -ParameterFilter { $ProfileName -eq 'Strict' } -MockWith {
                    return @{ Rules = @(1, 2, 3, 4) }
                }
                Mock _ValidateProfileCompatibility -MockWith { }

                $basisSession = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
                $strictSession = New-HardeningSession -Profile Strict -TargetSystem Client -OSVersion 11 -WhatIf

                $strictSession.State.TotalRules | Should -BeGreaterThan $basisSession.State.TotalRules
            }
        }
    }

    Context "Server vs Client Initialization" {
        It "creates session for Windows 11 Client" {
            InModuleScope System {
                Mock _ValidateHardeningPrerequisites -MockWith { }
                Mock Get-HardeningProfile -MockWith {
                    return @{ Rules = @() }
                }
                Mock _ValidateProfileCompatibility -MockWith { }

                $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
                $session.OSVersion | Should -Be 11
                $session.TargetSystem | Should -Be 'Client'
            }
        }

        It "creates session for Windows Server 2019" {
            InModuleScope System {
                Mock _ValidateHardeningPrerequisites -MockWith { }
                Mock Get-HardeningProfile -MockWith {
                    return @{ Rules = @() }
                }
                Mock _ValidateProfileCompatibility -MockWith { }

                $session = New-HardeningSession -Profile Basis -TargetSystem Server -OSVersion 2019 -WhatIf
                $session.OSVersion | Should -Be 2019
                $session.TargetSystem | Should -Be 'Server'
            }
        }

        It "creates session for Windows Server 2022" {
            InModuleScope System {
                Mock _ValidateHardeningPrerequisites -MockWith { }
                Mock Get-HardeningProfile -MockWith {
                    return @{ Rules = @() }
                }
                Mock _ValidateProfileCompatibility -MockWith { }

                $session = New-HardeningSession -Profile Basis -TargetSystem Server -OSVersion 2022 -WhatIf
                $session.OSVersion | Should -Be 2022
                $session.TargetSystem | Should -Be 'Server'
            }
        }

        It "creates session for Windows Server 2025" {
            InModuleScope System {
                Mock _ValidateHardeningPrerequisites -MockWith { }
                Mock Get-HardeningProfile -MockWith {
                    return @{ Rules = @() }
                }
                Mock _ValidateProfileCompatibility -MockWith { }

                $session = New-HardeningSession -Profile Basis -TargetSystem Server -OSVersion 2025 -WhatIf
                $session.OSVersion | Should -Be 2025
                $session.TargetSystem | Should -Be 'Server'
            }
        }
    }

    Context "Optional Parameters" {
        It "skips prerequisite check when SkipPrerequisiteCheck is set" {
            InModuleScope System {
                Mock _ValidateHardeningPrerequisites -MockWith { }
                Mock Get-HardeningProfile -MockWith {
                    return @{ Rules = @() }
                }
                Mock _ValidateProfileCompatibility -MockWith { }

                New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
                Assert-MockCalled _ValidateHardeningPrerequisites -Times 0
            }
        }

        It "performs prerequisite check when SkipPrerequisiteCheck is not set" {
            InModuleScope System {
                Mock _ValidateHardeningPrerequisites -MockWith { }
                Mock Get-HardeningProfile -MockWith {
                    return @{ Rules = @() }
                }
                Mock _ValidateProfileCompatibility -MockWith { }

                New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
                Assert-MockCalled _ValidateHardeningPrerequisites -Times 1
            }
        }
    }

    Context "Error Handling" {
        It "throws when Get-HardeningProfile fails" {
            InModuleScope System {
                Mock _ValidateHardeningPrerequisites -MockWith { }
                Mock Get-HardeningProfile -MockWith {
                    throw "Failed to load profile"
                }
                Mock _ValidateProfileCompatibility -MockWith { }

                { New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck } | Should -Throw
            }
        }

        It "throws when profile compatibility check fails" {
            InModuleScope System {
                Mock _ValidateHardeningPrerequisites -MockWith { }
                Mock Get-HardeningProfile -MockWith {
                    return @{ Rules = @() }
                }
                Mock _ValidateProfileCompatibility -MockWith {
                    throw "Profile not compatible"
                }

                { New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck } | Should -Throw
            }
        }
    }

    Context "Dependency Calls" {
        It "calls _ValidateHardeningPrerequisites with correct ComputerName" {
            InModuleScope System {
                Mock _ValidateHardeningPrerequisites -MockWith { }
                Mock Get-HardeningProfile -MockWith {
                    return @{ Rules = @() }
                }
                Mock _ValidateProfileCompatibility -MockWith { }

                New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
                Assert-MockCalled _ValidateHardeningPrerequisites -ParameterFilter { $ComputerName -eq $env:COMPUTERNAME }
            }
        }

        It "calls _ValidateProfileCompatibility with session object" {
            InModuleScope System {
                Mock _ValidateHardeningPrerequisites -MockWith { }
                Mock Get-HardeningProfile -MockWith {
                    return @{ Rules = @() }
                }
                Mock _ValidateProfileCompatibility -MockWith { }

                New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
                Assert-MockCalled _ValidateProfileCompatibility -Times 1
            }
        }
    }
}
