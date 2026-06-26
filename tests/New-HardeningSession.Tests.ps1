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
            $profiles = @('Basis', 'Recommended', 'Strict')
            foreach ($profile in $profiles) {
                { New-HardeningSession -Profile $profile -TargetSystem Client -OSVersion 11 -WhatIf } | Should -Not -Throw
            }
        }

        It "rejects invalid profile names" {
            { New-HardeningSession -Profile 'InvalidProfile' -TargetSystem Client -OSVersion 11 -WhatIf } | Should -Throw
        }

        It "accepts valid target systems" {
            { New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf } | Should -Not -Throw
            { New-HardeningSession -Profile Basis -TargetSystem Server -OSVersion 2022 -WhatIf } | Should -Not -Throw
        }

        It "validates Client OS version as 11 only" {
            { New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf } | Should -Not -Throw
            { New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 2022 -WhatIf } | Should -Throw
        }

        It "validates Server OS versions as 2019, 2022, or 2025 only" {
            $validVersions = @(2019, 2022, 2025)
            foreach ($version in $validVersions) {
                { New-HardeningSession -Profile Basis -TargetSystem Server -OSVersion $version -WhatIf } | Should -Not -Throw
            }
            { New-HardeningSession -Profile Basis -TargetSystem Server -OSVersion 11 -WhatIf } | Should -Throw
        }
    }

    Context "Session Creation" {
        It "returns a session object with required properties" {
            $session = New-HardeningSession -Profile Recommended -TargetSystem Client -OSVersion 11 -WhatIf
            $session | Should -Not -BeNullOrEmpty
            $session | Should -HaveProperty SessionId
            $session | Should -HaveProperty CreatedTime
            $session | Should -HaveProperty Profile
            $session | Should -HaveProperty TargetSystem
            $session | Should -HaveProperty OSVersion
        }

        It "sets profile correctly in session" {
            $session = New-HardeningSession -Profile Strict -TargetSystem Server -OSVersion 2025 -WhatIf
            $session.Profile | Should -Be 'Strict'
        }

        It "sets target system correctly in session" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
            $session.TargetSystem | Should -Be 'Client'
        }

        It "initializes state object with proper structure" {
            $session = New-HardeningSession -Profile Recommended -TargetSystem Client -OSVersion 11 -WhatIf
            $session.State | Should -HaveProperty TotalRules
            $session.State | Should -HaveProperty AppliedRules
            $session.State | Should -HaveProperty FailedRules
            $session.State | Should -HaveProperty ComplianceStatus
        }

        It "generates unique SessionId for each session" {
            $session1 = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
            $session2 = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
            $session1.SessionId | Should -Not -Be $session2.SessionId
        }

        It "respects WhatIfPreference parameter" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Server -OSVersion 2022 -WhatIf
            $session.WhatIfMode | Should -Be $true
        }

        It "sets correct computer name" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
            $session.ComputerName | Should -Be $env:COMPUTERNAME
        }
    }

    Context "Profile Initialization" {
        It "initializes Basis profile with expected rule count" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
            $session.State.TotalRules | Should -BeGreaterThan 0
        }

        It "initializes Recommended profile with more rules than Basis" {
            $basisSession = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
            $recommendedSession = New-HardeningSession -Profile Recommended -TargetSystem Client -OSVersion 11 -WhatIf
            $recommendedSession.State.TotalRules | Should -BeGreaterThan $basisSession.State.TotalRules
        }

        It "initializes Strict profile with more rules than Recommended" {
            $recommendedSession = New-HardeningSession -Profile Recommended -TargetSystem Client -OSVersion 11 -WhatIf
            $strictSession = New-HardeningSession -Profile Strict -TargetSystem Client -OSVersion 11 -WhatIf
            $strictSession.State.TotalRules | Should -BeGreaterThan $recommendedSession.State.TotalRules
        }
    }

    Context "Server vs Client Initialization" {
        It "creates session for Windows 11 Client" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
            $session.OSVersion | Should -Be 11
            $session.TargetSystem | Should -Be 'Client'
        }

        It "creates session for Windows Server 2019" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Server -OSVersion 2019 -WhatIf
            $session.OSVersion | Should -Be 2019
            $session.TargetSystem | Should -Be 'Server'
        }

        It "creates session for Windows Server 2022" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Server -OSVersion 2022 -WhatIf
            $session.OSVersion | Should -Be 2022
            $session.TargetSystem | Should -Be 'Server'
        }

        It "creates session for Windows Server 2025" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Server -OSVersion 2025 -WhatIf
            $session.OSVersion | Should -Be 2025
            $session.TargetSystem | Should -Be 'Server'
        }
    }

    Context "Session State Initialization" {
        It "initializes applied rules count to zero" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
            $session.State.AppliedRules | Should -Be 0
        }

        It "initializes failed rules count to zero" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
            $session.State.FailedRules | Should -Be 0
        }

        It "initializes compliance status to NotStarted" {
            $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf
            $session.State.ComplianceStatus | Should -Be 'NotStarted'
        }
    }

    Context "Optional Parameters" {
        It "accepts SkipPrerequisiteCheck parameter" {
            { New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck } | Should -Not -Throw
        }

        It "accepts WhatIf parameter" {
            { New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11 -WhatIf } | Should -Not -Throw
        }
    }
}
