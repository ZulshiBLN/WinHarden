BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\System.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module System -Force -ErrorAction SilentlyContinue
}

Describe "System Module - Hardening Functions" {
    Context "New-HardeningSession - Parameter Validation" {
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

    Context "New-HardeningSession - Session Creation" {
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

    Context "Get-HardeningProfile - Profile Loading" {
        It "loads Basis profile successfully" {
            $profile = Get-HardeningProfile -ProfileName Basis -TargetSystem Client
            $profile | Should -Not -BeNullOrEmpty
            $profile.ProfileName | Should -Be 'Basis'
        }

        It "loads Recommended profile successfully" {
            $profile = Get-HardeningProfile -ProfileName Recommended -TargetSystem Server
            $profile | Should -Not -BeNullOrEmpty
            $profile.ProfileName | Should -Be 'Recommended'
        }

        It "loads Strict profile successfully" {
            $profile = Get-HardeningProfile -ProfileName Strict -TargetSystem Client
            $profile | Should -Not -BeNullOrEmpty
            $profile.ProfileName | Should -Be 'Strict'
        }

        It "rejects invalid profile names" {
            { Get-HardeningProfile -ProfileName 'InvalidProfile' -TargetSystem Client } | Should -Throw
        }

        It "returns profile with metadata" {
            $profile = Get-HardeningProfile -ProfileName Basis -TargetSystem Client
            $profile | Should -HaveProperty ProfileMetadata
            $profile.ProfileMetadata | Should -HaveProperty Name
            $profile.ProfileMetadata | Should -HaveProperty Description
        }

        It "returns profile with rules" {
            $profile = Get-HardeningProfile -ProfileName Basis -TargetSystem Client
            $profile | Should -HaveProperty Rules
            $profile.Rules | Should -Not -BeNullOrEmpty
        }

        It "returns rule count" {
            $profile = Get-HardeningProfile -ProfileName Basis -TargetSystem Client
            $profile | Should -HaveProperty RuleCount
            $profile.RuleCount -gt 0 | Should -Be $true
        }

        It "Strict profile contains more rules than Basis" {
            $basisProfile = Get-HardeningProfile -ProfileName Basis -TargetSystem Client
            $strictProfile = Get-HardeningProfile -ProfileName Strict -TargetSystem Client
            $strictProfile.RuleCount | Should -BeGreaterThan $basisProfile.RuleCount
        }

        It "Recommended profile contains more rules than Basis" {
            $basisProfile = Get-HardeningProfile -ProfileName Basis -TargetSystem Client
            $recommendedProfile = Get-HardeningProfile -ProfileName Recommended -TargetSystem Client
            $recommendedProfile.RuleCount | Should -BeGreaterThan $basisProfile.RuleCount
        }

        It "loads only rules compatible with Client systems" {
            $profile = Get-HardeningProfile -ProfileName Basis -TargetSystem Client -OSVersion 11
            foreach ($rule in $profile.Rules) {
                if ($rule.OSSupport) {
                    $rule.OSSupport.Client -contains 11 | Should -Be $true
                }
            }
        }

        It "loads only rules compatible with Server systems" {
            $profile = Get-HardeningProfile -ProfileName Basis -TargetSystem Server -OSVersion 2022
            foreach ($rule in $profile.Rules) {
                if ($rule.OSSupport) {
                    $rule.OSSupport.Server -contains 2022 | Should -Be $true
                }
            }
        }
    }

    Context "Hardening Profile Structure - Basis" {
        It "Basis profile contains Account.Policy rules" {
            $profile = Get-HardeningProfile -ProfileName Basis -TargetSystem Client
            $accountRules = @($profile.Rules | Where-Object { $_.Category -eq 'Account.Policy' })
            $accountRules.Count -gt 0 | Should -Be $true
        }

        It "Basis profile contains Firewall.Policy rules" {
            $profile = Get-HardeningProfile -ProfileName Basis -TargetSystem Client
            $firewallRules = @($profile.Rules | Where-Object { $_.Category -eq 'Firewall.Policy' })
            $firewallRules.Count -gt 0 | Should -Be $true
        }

        It "Basis profile contains SMB.Hardening rules" {
            $profile = Get-HardeningProfile -ProfileName Basis -TargetSystem Client
            $smbRules = @($profile.Rules | Where-Object { $_.Category -eq 'SMB.Hardening' })
            $smbRules.Count -gt 0 | Should -Be $true
        }

        It "Basis profile contains RDP.Security rules" {
            $profile = Get-HardeningProfile -ProfileName Basis -TargetSystem Client
            $rdpRules = @($profile.Rules | Where-Object { $_.Category -eq 'RDP.Security' })
            $rdpRules.Count -gt 0 | Should -Be $true
        }

        It "all rules have required properties" {
            $profile = Get-HardeningProfile -ProfileName Basis -TargetSystem Client
            foreach ($rule in $profile.Rules) {
                $rule | Should -HaveProperty Name
                $rule | Should -HaveProperty Description
                $rule | Should -HaveProperty Category
                $rule | Should -HaveProperty Severity
                $rule | Should -HaveProperty Type
                $rule | Should -HaveProperty RuleDefinition
                $rule | Should -HaveProperty Verification
            }
        }

        It "all rules have valid severity levels" {
            $profile = Get-HardeningProfile -ProfileName Basis -TargetSystem Client
            $validSeverities = @('Critical', 'High', 'Medium', 'Low')
            foreach ($rule in $profile.Rules) {
                $rule.Severity -in $validSeverities | Should -Be $true
            }
        }
    }

    Context "Hardening Profile Inheritance" {
        It "Recommended profile contains all Basis rules" {
            $basisProfile = Get-HardeningProfile -ProfileName Basis -TargetSystem Client
            $recommendedProfile = Get-HardeningProfile -ProfileName Recommended -TargetSystem Client

            foreach ($basisRule in $basisProfile.Rules) {
                $recommendedProfile.Rules | Where-Object { $_.Name -eq $basisRule.Name } | Should -Not -BeNullOrEmpty
            }
        }

        It "Strict profile is superset of Recommended profile" {
            $recommendedProfile = Get-HardeningProfile -ProfileName Recommended -TargetSystem Client
            $strictProfile = Get-HardeningProfile -ProfileName Strict -TargetSystem Client

            foreach ($recommendedRule in $recommendedProfile.Rules) {
                $strictProfile.Rules | Where-Object { $_.Name -eq $recommendedRule.Name } | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context "Session Integration" {
        It "New-HardeningSession can load profile data via Get-HardeningProfile" {
            $session = New-HardeningSession -Profile Recommended -TargetSystem Client -OSVersion 11 -WhatIf
            $profile = Get-HardeningProfile -ProfileName $session.Profile -TargetSystem $session.TargetSystem
            $profile | Should -Not -BeNullOrEmpty
            $profile.RuleCount | Should -Be $session.State.TotalRules
        }
    }
}

Describe "System Module - Hardening Functions - Documentation" {
    Context "Function Help" {
        It "New-HardeningSession has complete help" {
            $help = Get-Help New-HardeningSession
            $help.Synopsis | Should -Not -BeNullOrEmpty
            $help.Parameters | Should -Not -BeNullOrEmpty
        }

        It "Get-HardeningProfile has complete help" {
            $help = Get-Help Get-HardeningProfile
            $help.Synopsis | Should -Not -BeNullOrEmpty
            $help.Parameters | Should -Not -BeNullOrEmpty
        }
    }
}
