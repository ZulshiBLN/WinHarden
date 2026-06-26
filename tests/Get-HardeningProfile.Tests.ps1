BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\System.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module System -Force -ErrorAction SilentlyContinue
}

Describe "Get-HardeningProfile" {
    Context "Profile Loading" {
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
    }

    Context "Profile Structure" {
        It "returns profile with metadata" {
            $profile = Get-HardeningProfile -ProfileName Basis -TargetSystem Client
            $profile.PSObject.Properties.Name -contains 'ProfileMetadata' | Should -Be $true
            $profile.ProfileMetadata.Keys -contains 'Name' | Should -Be $true
            $profile.ProfileMetadata.Keys -contains 'Description' | Should -Be $true
        }

        It "returns profile with rules" {
            $profile = Get-HardeningProfile -ProfileName Basis -TargetSystem Client
            $profile.PSObject.Properties.Name -contains 'Rules' | Should -Be $true
            $profile.Rules | Should -Not -BeNullOrEmpty
        }

        It "returns rule count" {
            $profile = Get-HardeningProfile -ProfileName Basis -TargetSystem Client
            $profile.PSObject.Properties.Name -contains 'RuleCount' | Should -Be $true
            $profile.RuleCount -gt 0 | Should -Be $true
        }
    }

    Context "Profile Comparison" {
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
    }

    Context "OS Compatibility" {
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

    Context "Profile Structure - Basis" {
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
    }

    Context "Rule Properties" {
        It "all rules have required properties" {
            $profile = Get-HardeningProfile -ProfileName Basis -TargetSystem Client
            foreach ($rule in $profile.Rules) {
                $rule.Keys -contains 'Name' | Should -Be $true
                $rule.Keys -contains 'Description' | Should -Be $true
                $rule.Keys -contains 'Category' | Should -Be $true
                $rule.Keys -contains 'Severity' | Should -Be $true
                $rule.Keys -contains 'Type' | Should -Be $true
                $rule.Keys -contains 'RuleDefinition' | Should -Be $true
                $rule.Keys -contains 'Verification' | Should -Be $true
            }
        }

        It "all rules have valid severity levels" {
            $profile = Get-HardeningProfile -ProfileName Basis -TargetSystem Client
            $validSeverities = @('Critical', 'High', 'Medium', 'Low')
            foreach ($rule in $profile.Rules) {
                $rule.Severity -in $validSeverities | Should -Be $true
            }
        }

        It "all rules have non-empty descriptions" {
            $profile = Get-HardeningProfile -ProfileName Basis -TargetSystem Client
            foreach ($rule in $profile.Rules) {
                $rule.Description | Should -Not -BeNullOrEmpty
            }
        }

        It "all rules have valid categories" {
            $profile = Get-HardeningProfile -ProfileName Basis -TargetSystem Client
            $validCategories = @('Account.Policy', 'Audit.Policy', 'Encryption.Policy', 'Firewall.Policy', 'Network.Security', 'RDP.Security', 'Service.Hardening', 'SMB.Hardening', 'UAC.Policy', 'Update.Policy')
            foreach ($rule in $profile.Rules) {
                $rule.Category -in $validCategories | Should -Be $true
            }
        }
    }

    Context "Profile Metadata" {
        It "Basis profile metadata contains expected fields" {
            $profile = Get-HardeningProfile -ProfileName Basis -TargetSystem Client
            $profile.ProfileMetadata.Keys -contains 'Name' | Should -Be $true
            $profile.ProfileMetadata.Keys -contains 'Description' | Should -Be $true
            $profile.ProfileMetadata.Keys -contains 'Version' | Should -Be $true
        }

        It "Recommended profile metadata contains expected fields" {
            $profile = Get-HardeningProfile -ProfileName Recommended -TargetSystem Server
            $profile.ProfileMetadata.Keys -contains 'Name' | Should -Be $true
            $profile.ProfileMetadata.Keys -contains 'Description' | Should -Be $true
            $profile.ProfileMetadata.Keys -contains 'Version' | Should -Be $true
        }

        It "Strict profile metadata contains expected fields" {
            $profile = Get-HardeningProfile -ProfileName Strict -TargetSystem Client
            $profile.ProfileMetadata.Keys -contains 'Name' | Should -Be $true
            $profile.ProfileMetadata.Keys -contains 'Description' | Should -Be $true
            $profile.ProfileMetadata.Keys -contains 'Version' | Should -Be $true
        }
    }

    Context "Target System Support" {
        It "loads profile for Client target system" {
            $profile = Get-HardeningProfile -ProfileName Basis -TargetSystem Client
            $profile | Should -Not -BeNullOrEmpty
            $profile.TargetSystem | Should -Be 'Client'
        }

        It "loads profile for Server target system" {
            $profile = Get-HardeningProfile -ProfileName Basis -TargetSystem Server
            $profile | Should -Not -BeNullOrEmpty
            $profile.TargetSystem | Should -Be 'Server'
        }

        It "both Client and Server profiles load rules" {
            $clientProfile = Get-HardeningProfile -ProfileName Basis -TargetSystem Client
            $serverProfile = Get-HardeningProfile -ProfileName Basis -TargetSystem Server
            $clientProfile.RuleCount | Should -BeGreaterThan 0
            $serverProfile.RuleCount | Should -BeGreaterThan 0
        }
    }

    Context "Rule Filtering and Categories" {
        It "can retrieve rules by category" {
            $profile = Get-HardeningProfile -ProfileName Recommended -TargetSystem Client
            $accountRules = @($profile.Rules | Where-Object { $_.Category -eq 'Account.Policy' })
            $accountRules.Count | Should -BeGreaterThan 0
        }

        It "can retrieve rules by severity" {
            $profile = Get-HardeningProfile -ProfileName Basis -TargetSystem Client
            $allRules = @($profile.Rules)
            $allRules.Count | Should -BeGreaterThan 0
        }

        It "profile contains mix of severity levels" {
            $profile = Get-HardeningProfile -ProfileName Strict -TargetSystem Client
            $severities = @($profile.Rules | ForEach-Object { $_.Severity } | Select-Object -Unique)
            $severities.Count | Should -BeGreaterThan 1
        }
    }
}
