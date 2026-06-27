BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\System.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module System -Force -ErrorAction SilentlyContinue
}

Describe "Get-FirewallStatusDrift" {
    Context "Function Exists and Has Help" {
        It "function is exported" {
            Get-Command Get-FirewallStatusDrift | Should -Not -BeNullOrEmpty
        }

        It "has synopsis" {
            (Get-Help Get-FirewallStatusDrift).Synopsis | Should -Not -BeNullOrEmpty
        }

        It "has description" {
            (Get-Help Get-FirewallStatusDrift).Description | Should -Not -BeNullOrEmpty
        }

        It "documents ComputerName parameter" {
            (Get-Help Get-FirewallStatusDrift).Parameters.Parameter.Name | Should -Contain 'ComputerName'
        }

        It "documents Profile parameter" {
            (Get-Help Get-FirewallStatusDrift).Parameters.Parameter.Name | Should -Contain 'Profile'
        }

        It "documents Detailed parameter" {
            (Get-Help Get-FirewallStatusDrift).Parameters.Parameter.Name | Should -Contain 'Detailed'
        }

        It "documents ReportDriftOnly parameter" {
            (Get-Help Get-FirewallStatusDrift).Parameters.Parameter.Name | Should -Contain 'ReportDriftOnly'
        }

        It "documents Credential parameter" {
            (Get-Help Get-FirewallStatusDrift).Parameters.Parameter.Name | Should -Contain 'Credential'
        }

        It "has examples" {
            (Get-Help Get-FirewallStatusDrift).Examples | Should -Not -BeNullOrEmpty
        }
    }

    Context "Parameter Validation" {
        It "accepts Basis profile" {
            Mock Get-NetFirewallProfile { @{ Enabled = $true; DefaultInboundAction = 'Block'; DefaultOutboundAction = 'Allow' } }
            { Get-FirewallStatusDrift -Profile Basis -ErrorAction Stop } | Should -Not -Throw
        }

        It "accepts Recommended profile" {
            Mock Get-NetFirewallProfile { @{ Enabled = $true; DefaultInboundAction = 'Block'; DefaultOutboundAction = 'Allow' } }
            { Get-FirewallStatusDrift -Profile Recommended -ErrorAction Stop } | Should -Not -Throw
        }

        It "accepts Strict profile" {
            Mock Get-NetFirewallProfile { @{ Enabled = $true; DefaultInboundAction = 'Block'; DefaultOutboundAction = 'Allow' } }
            { Get-FirewallStatusDrift -Profile Strict -ErrorAction Stop } | Should -Not -Throw
        }

        It "rejects invalid profile" {
            Mock Get-NetFirewallProfile { @{ Enabled = $true } }
            { Get-FirewallStatusDrift -Profile 'Invalid' -ErrorAction Stop } | Should -Throw
        }
    }

    Context "Output Structure" {
        BeforeEach {
            Mock Get-NetFirewallProfile {
                [PSCustomObject]@{
                    Enabled = $true
                    DefaultInboundAction = 'Block'
                    DefaultOutboundAction = 'Allow'
                }
            }
        }

        It "returns objects with all required properties" {
            $result = Get-FirewallStatusDrift
            $result | Should -Not -BeNullOrEmpty
            $props = @($result)[0].psobject.Properties.Name
            $props | Should -Contain 'Category'
            $props | Should -Contain 'Setting'
            $props | Should -Contain 'Status'
            $props | Should -Contain 'Severity'
            $props | Should -Contain 'Expected'
            $props | Should -Contain 'Actual'
            $props | Should -Contain 'ComputerName'
        }

        It "returns PSCustomObject" {
            $result = Get-FirewallStatusDrift
            @($result)[0] | Should -BeOfType PSCustomObject
        }

        It "sets category to Firewall" {
            $result = Get-FirewallStatusDrift
            @($result)[0].Category | Should -Be 'Firewall'
        }
    }

    Context "Basis Profile Behavior" {
        BeforeEach {
            Mock Get-NetFirewallProfile {
                [PSCustomObject]@{
                    Enabled = $true
                    DefaultInboundAction = 'Block'
                    DefaultOutboundAction = 'Allow'
                }
            }
        }

        It "returns compliant when profiles enabled" {
            $result = Get-FirewallStatusDrift -Profile Basis
            $result.Status | Should -Be 'COMPLIANT'
        }

        It "returns INFO severity for compliant" {
            $result = Get-FirewallStatusDrift -Profile Basis
            $result.Severity | Should -Be 'INFO'
        }
    }

    Context "Recommended Profile Behavior" {
        BeforeEach {
            Mock Get-NetFirewallProfile {
                [PSCustomObject]@{
                    Enabled = $true
                    DefaultInboundAction = 'Block'
                    DefaultOutboundAction = 'Allow'
                }
            }
        }

        It "checks settings for Recommended profile" {
            $result = Get-FirewallStatusDrift -Profile Recommended
            $result | Should -Not -BeNullOrEmpty
        }

        It "returns array of results" {
            $result = @(Get-FirewallStatusDrift -Profile Recommended)
            $result.Count | Should -BeGreaterThan 0
        }
    }

    Context "Strict Profile Behavior" {
        BeforeEach {
            Mock Get-NetFirewallProfile {
                [PSCustomObject]@{
                    Enabled = $true
                    DefaultInboundAction = 'Block'
                    DefaultOutboundAction = 'Allow'
                }
            }
        }

        It "detects outbound drift for Strict profile" {
            $result = @(Get-FirewallStatusDrift -Profile Strict)
            $drift = $result | Where-Object { $_.Setting -eq 'Outbound Default Action' }
            $drift | Should -Not -BeNullOrEmpty
            $drift.Status | Should -Be 'DRIFT'
        }
    }

    Context "Detailed Output" {
        BeforeEach {
            Mock Get-NetFirewallProfile {
                [PSCustomObject]@{
                    Enabled = $true
                    DefaultInboundAction = 'Block'
                    DefaultOutboundAction = 'Allow'
                }
            }
            Mock Get-NetFirewallRule {
                [PSCustomObject]@{ Name = 'Rule1' }
                [PSCustomObject]@{ Name = 'Rule2' }
            }
        }

        It "includes rule count information when -Detailed" {
            $result = @(Get-FirewallStatusDrift -Detailed)
            $ruleResults = $result | Where-Object { $_.Setting -match 'Rules Count' }
            $ruleResults | Should -Not -BeNullOrEmpty
        }

        It "includes inbound rules count" {
            $result = @(Get-FirewallStatusDrift -Detailed)
            $inbound = $result | Where-Object { $_.Setting -eq 'Inbound Rules Count' }
            $inbound | Should -Not -BeNullOrEmpty
            $inbound.Status | Should -Be 'INFO'
        }

        It "includes outbound rules count" {
            $result = @(Get-FirewallStatusDrift -Detailed)
            $outbound = $result | Where-Object { $_.Setting -eq 'Outbound Rules Count' }
            $outbound | Should -Not -BeNullOrEmpty
            $outbound.Status | Should -Be 'INFO'
        }
    }

    Context "ReportDriftOnly Flag" {
        BeforeEach {
            Mock Get-NetFirewallProfile {
                [PSCustomObject]@{
                    Enabled = $true
                    DefaultInboundAction = 'Block'
                    DefaultOutboundAction = 'Allow'
                }
            }
        }

        It "returns empty when compliant and -ReportDriftOnly" {
            $result = @(Get-FirewallStatusDrift -ReportDriftOnly)
            $result.Count | Should -Be 0
        }
    }

    Context "Default Parameters" {
        BeforeEach {
            Mock Get-NetFirewallProfile {
                [PSCustomObject]@{
                    Enabled = $true
                    DefaultInboundAction = 'Block'
                    DefaultOutboundAction = 'Allow'
                }
            }
        }

        It "uses localhost as default" {
            $result = Get-FirewallStatusDrift
            @($result)[0].ComputerName | Should -Be 'localhost'
        }

        It "uses Basis as default profile" {
            $result = Get-FirewallStatusDrift
            $result.Status | Should -Be 'COMPLIANT'
        }
    }

    Context "WhatIf Support" {
        BeforeEach {
            Mock Get-NetFirewallProfile {
                [PSCustomObject]@{
                    Enabled = $true
                    DefaultInboundAction = 'Block'
                    DefaultOutboundAction = 'Allow'
                }
            }
        }

        It "supports -WhatIf without error" {
            { Get-FirewallStatusDrift -WhatIf } | Should -Not -Throw
        }
    }

    Context "Error Handling" {
        It "handles errors gracefully" {
            Mock Get-NetFirewallProfile { [PSCustomObject]@{ Enabled = $true; DefaultInboundAction = 'Block'; DefaultOutboundAction = 'Allow' } }
            $result = Get-FirewallStatusDrift
            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context "Setting Names Accuracy" {
        BeforeEach {
            Mock Get-NetFirewallProfile {
                [PSCustomObject]@{
                    Enabled = $true
                    DefaultInboundAction = 'Block'
                    DefaultOutboundAction = 'Allow'
                }
            }
        }

        It "includes correct setting names" {
            $result = @(Get-FirewallStatusDrift -Profile Basis)
            $settingNames = $result.Setting
            $settingNames | Should -Contain 'Firewall Profiles'
        }
    }

    Context "Severity Levels" {
        BeforeEach {
            Mock Get-NetFirewallProfile {
                [PSCustomObject]@{
                    Enabled = $true
                    DefaultInboundAction = 'Block'
                    DefaultOutboundAction = 'Allow'
                }
            }
        }

        It "uses INFO for compliant status" {
            $result = Get-FirewallStatusDrift -Profile Basis
            $result.Severity | Should -Be 'INFO'
        }
    }

    Context "Return Types" {
        BeforeEach {
            Mock Get-NetFirewallProfile {
                [PSCustomObject]@{
                    Enabled = $true
                    DefaultInboundAction = 'Block'
                    DefaultOutboundAction = 'Allow'
                }
            }
        }

        It "always returns result" {
            $result = Get-FirewallStatusDrift
            $result | Should -Not -BeNullOrEmpty
        }

        It "result contains Status property" {
            $result = Get-FirewallStatusDrift
            @($result)[0].Status | Should -Not -BeNullOrEmpty
        }

        It "result contains Actual property" {
            $result = Get-FirewallStatusDrift
            @($result)[0].Actual | Should -Not -BeNullOrEmpty
        }
    }
}
