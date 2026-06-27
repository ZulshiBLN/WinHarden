BeforeAll {
    # Load Core module first (ADR-008: Module Import Strategy)
    $coreModulePath = (Resolve-Path "$PSScriptRoot\..\modules\Core.psm1").Path
    Import-Module $coreModulePath -Force

    # Then load System module (which depends on Core)
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\System.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module System -Force -ErrorAction SilentlyContinue
    Remove-Module Core -Force -ErrorAction SilentlyContinue
}

Describe "Get-NetworkSecurityDrift" {
    Context "Function Exists and Help" {
        It "function exists and can be called" {
            { Get-NetworkSecurityDrift -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "has complete help documentation" {
            $help = Get-Help Get-NetworkSecurityDrift
            $help.Synopsis | Should -Not -BeNullOrEmpty
            $help.Description | Should -Not -BeNullOrEmpty
        }

        It "includes parameter descriptions" {
            $help = Get-Help Get-NetworkSecurityDrift
            $help.Parameters.Parameter.Name | Should -Contain 'Profile'
            $help.Parameters.Parameter.Name | Should -Contain 'ComputerName'
            $help.Parameters.Parameter.Name | Should -Contain 'Detailed'
        }

        It "includes example usage" {
            $help = Get-Help Get-NetworkSecurityDrift
            $help.Examples.Example.Count | Should -BeGreaterThan 0
        }
    }

    Context "Parameter Validation" {
        BeforeEach {
            Mock Get-WindowsOptionalFeature { [PSCustomObject]@{ FeatureName = 'SMB1Protocol'; State = 'Disabled' } }
            Mock Get-ItemProperty { [PSCustomObject]@{ } }
            Mock Write-Log { }
        }

        It "works without parameters for local computer" {
            { Get-NetworkSecurityDrift -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts ComputerName parameter" {
            { Get-NetworkSecurityDrift -ComputerName 'localhost' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Profile parameter with valid value" {
            { Get-NetworkSecurityDrift -Profile Recommended -ErrorAction SilentlyContinue } | Should -Not -Throw
            { Get-NetworkSecurityDrift -Profile Basis -ErrorAction SilentlyContinue } | Should -Not -Throw
            { Get-NetworkSecurityDrift -Profile Strict -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "rejects invalid Profile parameter" {
            { Get-NetworkSecurityDrift -Profile 'InvalidProfile' -ErrorAction Stop } | Should -Throw
        }

        It "accepts Detailed switch" {
            { Get-NetworkSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts NTLMv2Level parameter with valid range" {
            { Get-NetworkSecurityDrift -NTLMv2Level 5 -ErrorAction SilentlyContinue } | Should -Not -Throw
            { Get-NetworkSecurityDrift -NTLMv2Level 0 -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Output Structure" {
        BeforeEach {
            Mock Get-WindowsOptionalFeature { [PSCustomObject]@{ FeatureName = 'SMB1Protocol'; State = 'Disabled' } }
            Mock Get-ItemProperty { [PSCustomObject]@{ LmCompatibilityLevel = 5 } }
            Mock Write-Log { }
        }

        It "returns array of PSCustomObjects" {
            $result = Get-NetworkSecurityDrift -ErrorAction SilentlyContinue
            $result | Should -BeOfType [PSCustomObject]
        }

        It "includes Category property" {
            $result = Get-NetworkSecurityDrift -ErrorAction SilentlyContinue
            $result[0].Category | Should -Be 'Network Security'
        }

        It "includes Setting property" {
            $result = Get-NetworkSecurityDrift -ErrorAction SilentlyContinue
            $result[0].Setting | Should -Not -BeNullOrEmpty
        }

        It "includes Expected property" {
            $result = Get-NetworkSecurityDrift -ErrorAction SilentlyContinue
            $result[0].Expected | Should -Not -BeNullOrEmpty
        }

        It "includes Actual property" {
            $result = Get-NetworkSecurityDrift -ErrorAction SilentlyContinue
            $result[0].Actual | Should -Not -BeNullOrEmpty
        }

        It "includes Status property with valid values" {
            $result = Get-NetworkSecurityDrift -ErrorAction SilentlyContinue
            $result[0].Status | Should -Match '^(DRIFT|COMPLIANT|EXEMPT)$'
        }

        It "includes Severity property with valid values" {
            $result = Get-NetworkSecurityDrift -ErrorAction SilentlyContinue
            $result[0].Severity | Should -Match '^(CRITICAL|HIGH|MEDIUM|LOW|INFO)$'
        }

        It "includes ComputerName property" {
            $result = Get-NetworkSecurityDrift -ErrorAction SilentlyContinue
            $result[0].ComputerName | Should -Not -BeNullOrEmpty
        }
    }

    Context "Basis Profile" {
        BeforeEach {
            Mock Get-WindowsOptionalFeature { [PSCustomObject]@{ FeatureName = 'SMB1Protocol'; State = 'Disabled' } }
            Mock Get-ItemProperty { [PSCustomObject]@{ LmCompatibilityLevel = 5 } }
            Mock Write-Log { }
        }

        It "includes SMB1 Protocol check" {
            $result = Get-NetworkSecurityDrift -Profile Basis -ErrorAction SilentlyContinue
            $result | Where-Object { $_.Setting -eq 'SMB1 Protocol' } | Should -Not -BeNullOrEmpty
        }

        It "includes NTLMv2 check" {
            $result = Get-NetworkSecurityDrift -Profile Basis -ErrorAction SilentlyContinue
            $result | Where-Object { $_.Setting -eq 'NTLM Compatibility Level' } | Should -Not -BeNullOrEmpty
        }

        It "does not include SMB Signing check" {
            $result = Get-NetworkSecurityDrift -Profile Basis -ErrorAction SilentlyContinue
            $result | Where-Object { $_.Setting -eq 'SMB Signing Enforcement' } | Should -BeNullOrEmpty
        }

        It "does not include LDAP Signing check" {
            $result = Get-NetworkSecurityDrift -Profile Basis -ErrorAction SilentlyContinue
            $result | Where-Object { $_.Setting -eq 'LDAP Signing' } | Should -BeNullOrEmpty
        }

        It "returns expected values for Basis profile" {
            $result = Get-NetworkSecurityDrift -Profile Basis -ErrorAction SilentlyContinue
            $smb1 = $result | Where-Object { $_.Setting -eq 'SMB1 Protocol' }
            $smb1.Expected | Should -Be 'Disabled'
        }
    }

    Context "Recommended Profile" {
        BeforeEach {
            Mock Get-WindowsOptionalFeature { [PSCustomObject]@{ FeatureName = 'SMB1Protocol'; State = 'Disabled' } }
            Mock Get-ItemProperty {
                param($Path, $Name)
                switch ($Name) {
                    'LmCompatibilityLevel' {
                        [PSCustomObject]@{ LmCompatibilityLevel = 5 }
                    }
                    'RequireSecuritySignature' {
                        [PSCustomObject]@{ RequireSecuritySignature = 1 }
                    }
                    'LDAPClientIntegrity' {
                        [PSCustomObject]@{ LDAPClientIntegrity = 1 }
                    }
                    'EnableMulticast' {
                        [PSCustomObject]@{ EnableMulticast = 0 }
                    }
                    default {
                        [PSCustomObject]@{ }
                    }
                }
            }
            Mock Write-Log { }
        }

        It "includes all Basis checks" {
            $result = Get-NetworkSecurityDrift -Profile Recommended -ErrorAction SilentlyContinue
            $result | Where-Object { $_.Setting -eq 'SMB1 Protocol' } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.Setting -eq 'NTLM Compatibility Level' } | Should -Not -BeNullOrEmpty
        }

        It "includes SMB Signing check" {
            $result = Get-NetworkSecurityDrift -Profile Recommended -ErrorAction SilentlyContinue
            $result | Where-Object { $_.Setting -eq 'SMB Signing Enforcement' } | Should -Not -BeNullOrEmpty
        }

        It "includes LDAP Signing check" {
            $result = Get-NetworkSecurityDrift -Profile Recommended -ErrorAction SilentlyContinue
            $result | Where-Object { $_.Setting -eq 'LDAP Signing' } | Should -Not -BeNullOrEmpty
        }

        It "includes LLMNR check" {
            $result = Get-NetworkSecurityDrift -Profile Recommended -ErrorAction SilentlyContinue
            $result | Where-Object { $_.Setting -Match 'LLMNR' } | Should -Not -BeNullOrEmpty
        }

        It "does not include Kerberos check by default" {
            $result = Get-NetworkSecurityDrift -Profile Recommended -ErrorAction SilentlyContinue
            $result | Where-Object { $_.Setting -Match 'Kerberos' } | Should -BeNullOrEmpty
        }

        It "enforces NTLMv2 level 5" {
            $result = Get-NetworkSecurityDrift -Profile Recommended -ErrorAction SilentlyContinue
            $ntlm = $result | Where-Object { $_.Setting -eq 'NTLM Compatibility Level' }
            $ntlm.Expected | Should -Match '5'
        }
    }

    Context "Strict Profile" {
        BeforeEach {
            Mock Get-WindowsOptionalFeature { [PSCustomObject]@{ FeatureName = 'SMB1Protocol'; State = 'Disabled' } }
            Mock Get-ItemProperty {
                param($Path, $Name)
                switch ($Name) {
                    'LmCompatibilityLevel' {
                        [PSCustomObject]@{ LmCompatibilityLevel = 5 }
                    }
                    'RequireSecuritySignature' {
                        [PSCustomObject]@{ RequireSecuritySignature = 1 }
                    }
                    'LDAPClientIntegrity' {
                        [PSCustomObject]@{ LDAPClientIntegrity = 1 }
                    }
                    'EnableMulticast' {
                        [PSCustomObject]@{ EnableMulticast = 0 }
                    }
                    'SMBEncryptionRequired' {
                        [PSCustomObject]@{ SMBEncryptionRequired = 1 }
                    }
                    'SupportedEncryptionTypes' {
                        [PSCustomObject]@{ SupportedEncryptionTypes = 0xFFFFFFFF }
                    }
                    default {
                        [PSCustomObject]@{ }
                    }
                }
            }
            Mock Get-NetFirewallProfile { [PSCustomObject]@{ Name = 'Domain'; PolicyStore = 'PersistentStore' } }
            Mock Write-Log { }
        }

        It "includes all Recommended checks" {
            $result = Get-NetworkSecurityDrift -Profile Strict -ErrorAction SilentlyContinue
            $result | Where-Object { $_.Setting -eq 'SMB Signing Enforcement' } | Should -Not -BeNullOrEmpty
            $result | Where-Object { $_.Setting -eq 'LDAP Signing' } | Should -Not -BeNullOrEmpty
        }

        It "includes SMB Encryption check" {
            $result = Get-NetworkSecurityDrift -Profile Strict -ErrorAction SilentlyContinue
            $result | Where-Object { $_.Setting -eq 'SMB Encryption' } | Should -Not -BeNullOrEmpty
        }

        It "includes Kerberos check" {
            $result = Get-NetworkSecurityDrift -Profile Strict -ErrorAction SilentlyContinue
            $result | Where-Object { $_.Setting -Match 'Kerberos' } | Should -Not -BeNullOrEmpty
        }

        It "includes TLS check with -Detailed" {
            $result = Get-NetworkSecurityDrift -Profile Strict -Detailed -ErrorAction SilentlyContinue
            $result | Where-Object { $_.Setting -Match 'TLS' } | Should -Not -BeNullOrEmpty
        }

        It "includes IPsec check with -Detailed" {
            $result = Get-NetworkSecurityDrift -Profile Strict -Detailed -ErrorAction SilentlyContinue
            $result | Where-Object { $_.Setting -Match 'IPsec' } | Should -Not -BeNullOrEmpty
        }
    }

    Context "Detailed Output" {
        BeforeEach {
            Mock Get-WindowsOptionalFeature { [PSCustomObject]@{ FeatureName = 'SMB1Protocol'; State = 'Enabled' } }
            Mock Get-ItemProperty { [PSCustomObject]@{ } }
            Mock Write-Log { }
        }

        It "-Detailed flag is accepted" {
            { Get-NetworkSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "detects drift items when present" {
            $result = Get-NetworkSecurityDrift -Profile Recommended -ErrorAction SilentlyContinue
            $result | Where-Object { $_.Status -eq 'DRIFT' } | Should -Not -BeNullOrEmpty
        }
    }

    Context "ReportDriftOnly Flag" {
        BeforeEach {
            Mock Get-WindowsOptionalFeature { [PSCustomObject]@{ FeatureName = 'SMB1Protocol'; State = 'Enabled' } }
            Mock Get-ItemProperty { [PSCustomObject]@{ LmCompatibilityLevel = 5 } }
            Mock Write-Log { }
        }

        It "returns only DRIFT status items when ReportDriftOnly specified" {
            $result = Get-NetworkSecurityDrift -ReportDriftOnly -ErrorAction SilentlyContinue
            if ($result.Count -gt 0) {
                $result | Where-Object { $_.Status -ne 'DRIFT' } | Should -BeNullOrEmpty
            }
        }

        It "filters out COMPLIANT items correctly" {
            $result = Get-NetworkSecurityDrift -ReportDriftOnly -ErrorAction SilentlyContinue
            if ($result.Count -gt 0) {
                $result | ForEach-Object { $_.Status | Should -Be 'DRIFT' }
            }
        }
    }

    Context "WhatIf Support" {
        BeforeEach {
            Mock Get-WindowsOptionalFeature { [PSCustomObject]@{ FeatureName = 'SMB1Protocol'; State = 'Disabled' } }
            Mock Get-ItemProperty { [PSCustomObject]@{ } }
            Mock Write-Log { }
        }

        It "supports -WhatIf parameter" {
            { Get-NetworkSecurityDrift -WhatIf -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "executes without error with -WhatIf" {
            $result = Get-NetworkSecurityDrift -WhatIf -ErrorAction SilentlyContinue
            $result | Should -Not -BeNull
        }
    }

    Context "Default Parameters" {
        BeforeEach {
            Mock Get-WindowsOptionalFeature { [PSCustomObject]@{ FeatureName = 'SMB1Protocol'; State = 'Disabled' } }
            Mock Get-ItemProperty { [PSCustomObject]@{ } }
            Mock Write-Log { }
        }

        It "uses 'localhost' as default ComputerName" {
            $result = Get-NetworkSecurityDrift -ErrorAction SilentlyContinue
            $result[0].ComputerName | Should -Be 'localhost'
        }

        It "uses 'Recommended' as default Profile" {
            Mock Get-ItemProperty {
                param($Path, $Name)
                if ($Name -eq 'RequireSecuritySignature') {
                    [PSCustomObject]@{ RequireSecuritySignature = $null }
                }
                else {
                    [PSCustomObject]@{ }
                }
            }
            $result = Get-NetworkSecurityDrift -ErrorAction SilentlyContinue
            $smbSigning = $result | Where-Object { $_.Setting -eq 'SMB Signing Enforcement' }
            $smbSigning | Should -Not -BeNullOrEmpty
        }
    }

    Context "Drift Detection Accuracy" {
        It "detects SMB1 Protocol drift" {
            Mock Get-WindowsOptionalFeature { [PSCustomObject]@{ FeatureName = 'SMB1Protocol'; State = 'Enabled' } }
            Mock Get-ItemProperty { [PSCustomObject]@{ } }
            Mock Write-Log { }

            $result = Get-NetworkSecurityDrift -Profile Basis -ErrorAction SilentlyContinue
            $smb1 = $result | Where-Object { $_.Setting -eq 'SMB1 Protocol' }
            $smb1.Status | Should -Be 'DRIFT'
            $smb1.Severity | Should -Be 'CRITICAL'
        }

        It "detects NTLMv2 drift when level too low" {
            Mock Get-WindowsOptionalFeature { [PSCustomObject]@{ FeatureName = 'SMB1Protocol'; State = 'Disabled' } }
            Mock Get-ItemProperty { [PSCustomObject]@{ LmCompatibilityLevel = 3 } }
            Mock Write-Log { }

            $result = Get-NetworkSecurityDrift -Profile Recommended -ErrorAction SilentlyContinue
            $ntlm = $result | Where-Object { $_.Setting -eq 'NTLM Compatibility Level' }
            $ntlm.Status | Should -Be 'DRIFT'
        }

        It "marks compliant SMB1 as COMPLIANT" {
            Mock Get-WindowsOptionalFeature { [PSCustomObject]@{ FeatureName = 'SMB1Protocol'; State = 'Disabled' } }
            Mock Get-ItemProperty { [PSCustomObject]@{ } }
            Mock Write-Log { }

            $result = Get-NetworkSecurityDrift -Profile Basis -ErrorAction SilentlyContinue
            $smb1 = $result | Where-Object { $_.Setting -eq 'SMB1 Protocol' }
            $smb1.Status | Should -Be 'COMPLIANT'
        }
    }

    Context "Severity Classification" {
        BeforeEach {
            Mock Get-WindowsOptionalFeature { [PSCustomObject]@{ FeatureName = 'SMB1Protocol'; State = 'Enabled' } }
            Mock Get-ItemProperty { [PSCustomObject]@{ } }
            Mock Write-Log { }
        }

        It "assigns CRITICAL severity to SMB1" {
            $result = Get-NetworkSecurityDrift -ErrorAction SilentlyContinue
            $smb1 = $result | Where-Object { $_.Setting -eq 'SMB1 Protocol' }
            $smb1.Severity | Should -Be 'CRITICAL'
        }

        It "assigns HIGH severity to NTLMv2" {
            $result = Get-NetworkSecurityDrift -ErrorAction SilentlyContinue
            $ntlm = $result | Where-Object { $_.Setting -eq 'NTLM Compatibility Level' }
            $ntlm.Severity | Should -Be 'HIGH'
        }

        It "assigns appropriate severity to each check" {
            $result = Get-NetworkSecurityDrift -Profile Strict -Detailed -ErrorAction SilentlyContinue
            $result | ForEach-Object {
                $_.Severity | Should -Match '^(CRITICAL|HIGH|MEDIUM|LOW|INFO)$'
            }
        }
    }

    Context "Error Handling" {
        It "continues processing after individual check failure" {
            Mock Get-WindowsOptionalFeature { throw "Access denied" }
            Mock Get-ItemProperty { [PSCustomObject]@{ LmCompatibilityLevel = 5 } }
            Mock Write-Log { }

            { Get-NetworkSecurityDrift -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "returns results even when some checks fail" {
            Mock Get-WindowsOptionalFeature { throw "Error" }
            Mock Get-ItemProperty { [PSCustomObject]@{ LmCompatibilityLevel = 5 } }
            Mock Write-Log { }

            $result = Get-NetworkSecurityDrift -ErrorAction SilentlyContinue
            $result | Should -Not -BeNull
        }
    }
}
