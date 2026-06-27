BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\System.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module System -Force -ErrorAction SilentlyContinue
}

Describe "Get-RDPSecurityDrift" {

    Context "Parameter Validation" -Fixture {
        It "accepts default parameters" {
            InModuleScope System {
                { Get-RDPSecurityDrift -ErrorAction SilentlyContinue } | Should -Not -Throw
            }
        }

        It "accepts MinRDPEncryptionLevel parameter" {
            InModuleScope System {
                { Get-RDPSecurityDrift -MinRDPEncryptionLevel 2 -ErrorAction SilentlyContinue } | Should -Not -Throw
            }
        }

        It "accepts RequireNLA parameter" {
            InModuleScope System {
                { Get-RDPSecurityDrift -RequireNLA $false -ErrorAction SilentlyContinue } | Should -Not -Throw
            }
        }

        It "accepts RequireCertificate parameter" {
            InModuleScope System {
                { Get-RDPSecurityDrift -RequireCertificate $true -ErrorAction SilentlyContinue } | Should -Not -Throw
            }
        }

        It "accepts MaxIdleTimeMinutes parameter" {
            InModuleScope System {
                { Get-RDPSecurityDrift -MaxIdleTimeMinutes 20 -ErrorAction SilentlyContinue } | Should -Not -Throw
            }
        }

        It "rejects invalid encryption level (0)" {
            InModuleScope System {
                { Get-RDPSecurityDrift -MinRDPEncryptionLevel 0 -ErrorAction Stop } | Should -Throw
            }
        }

        It "rejects invalid encryption level (4)" {
            InModuleScope System {
                { Get-RDPSecurityDrift -MinRDPEncryptionLevel 4 -ErrorAction Stop } | Should -Throw
            }
        }

        It "rejects invalid idle timeout (-1)" {
            InModuleScope System {
                { Get-RDPSecurityDrift -MaxIdleTimeMinutes -1 -ErrorAction Stop } | Should -Throw
            }
        }

        It "accepts idle timeout value 0 (no timeout)" {
            InModuleScope System {
                { Get-RDPSecurityDrift -MaxIdleTimeMinutes 0 -ErrorAction SilentlyContinue } | Should -Not -Throw
            }
        }
    }

    Context "Function Execution" {
        It "returns results without error" {
            InModuleScope System {
                { Get-RDPSecurityDrift -ErrorAction SilentlyContinue } | Should -Not -Throw
            }
        }

        It "returns a collection or null" {
            InModuleScope System {
                $result = Get-RDPSecurityDrift -ErrorAction SilentlyContinue
                ($result -is [System.Collections.IEnumerable] -or $null -eq $result) | Should -Be $true
            }
        }
    }

    Context "Return Value Structure" {
        It "includes Category property in drift findings" {
            InModuleScope System {
                Mock Get-ItemProperty {
                    if ($Name -eq 'fDenyTSConnections') {
                        [PSCustomObject]@{ fDenyTSConnections = 1 }
                    }
                    else {
                        [PSCustomObject]@{
                            MinEncryptionLevel = 1
                            SecurityLayer = 1
                            PortNumber = 5555
                            SSLCertificateSHA1Hash = ''
                            MaxIdleTime = 0
                        }
                    }
                }

                $result = Get-RDPSecurityDrift -MinRDPEncryptionLevel 3 -ErrorAction SilentlyContinue
                $result[0].Category | Should -Not -BeNullOrEmpty
            }
        }

        It "includes Setting property in drift findings" {
            InModuleScope System {
                Mock Get-ItemProperty {
                    if ($Name -eq 'fDenyTSConnections') {
                        [PSCustomObject]@{ fDenyTSConnections = 1 }
                    }
                    else {
                        [PSCustomObject]@{
                            MinEncryptionLevel = 3
                            SecurityLayer = 2
                            PortNumber = 3389
                            SSLCertificateSHA1Hash = ''
                            MaxIdleTime = 0
                        }
                    }
                }

                $result = Get-RDPSecurityDrift -ErrorAction SilentlyContinue
                ($result.Setting -contains 'RDP Service Enabled') | Should -Be $true
            }
        }

        It "includes Expected property in drift findings" {
            InModuleScope System {
                Mock Get-ItemProperty {
                    if ($Name -eq 'fDenyTSConnections') {
                        [PSCustomObject]@{ fDenyTSConnections = 0 }
                    }
                    else {
                        [PSCustomObject]@{
                            MinEncryptionLevel = 1
                            SecurityLayer = 2
                            PortNumber = 3389
                            SSLCertificateSHA1Hash = ''
                            MaxIdleTime = 0
                        }
                    }
                }

                $result = Get-RDPSecurityDrift -MinRDPEncryptionLevel 3 -ErrorAction SilentlyContinue
                $encResult = $result | Where-Object { $_.Setting -eq 'Encryption Level' }
                $encResult.Expected | Should -Not -BeNullOrEmpty
            }
        }

        It "includes Status property" {
            InModuleScope System {
                Mock Get-ItemProperty {
                    if ($Name -eq 'fDenyTSConnections') {
                        [PSCustomObject]@{ fDenyTSConnections = 0 }
                    }
                    else {
                        [PSCustomObject]@{
                            MinEncryptionLevel = 1
                            SecurityLayer = 2
                            PortNumber = 3389
                            SSLCertificateSHA1Hash = ''
                            MaxIdleTime = 0
                        }
                    }
                }

                $result = Get-RDPSecurityDrift -MinRDPEncryptionLevel 3 -ErrorAction SilentlyContinue
                $result[0].Status | Should -Be 'DRIFT'
            }
        }

        It "includes Severity property" {
            InModuleScope System {
                Mock Get-ItemProperty {
                    if ($Name -eq 'fDenyTSConnections') {
                        [PSCustomObject]@{ fDenyTSConnections = 0 }
                    }
                    else {
                        [PSCustomObject]@{
                            MinEncryptionLevel = 3
                            SecurityLayer = 2
                            PortNumber = 5555
                            SSLCertificateSHA1Hash = ''
                            MaxIdleTime = 0
                        }
                    }
                }

                $result = Get-RDPSecurityDrift -ErrorAction SilentlyContinue
                $portResult = $result | Where-Object { $_.Setting -eq 'RDP Port' }
                $portResult.Severity | Should -Match 'HIGH|MEDIUM|LOW'
            }
        }
    }

    Context "Drift Detection" {
        It "detects encryption drift" {
            InModuleScope System {
                Mock Get-ItemProperty {
                    if ($Name -eq 'fDenyTSConnections') {
                        [PSCustomObject]@{ fDenyTSConnections = 0 }
                    }
                    else {
                        [PSCustomObject]@{
                            MinEncryptionLevel = 1
                            SecurityLayer = 2
                            PortNumber = 3389
                            SSLCertificateSHA1Hash = ''
                            MaxIdleTime = 0
                        }
                    }
                }

                $result = Get-RDPSecurityDrift -MinRDPEncryptionLevel 3 -ErrorAction SilentlyContinue
                $encDrift = $result | Where-Object { $_.Setting -eq 'Encryption Level' }
                $encDrift | Should -Not -BeNullOrEmpty
            }
        }

        It "detects NLA drift" {
            InModuleScope System {
                Mock Get-ItemProperty {
                    if ($Name -eq 'fDenyTSConnections') {
                        [PSCustomObject]@{ fDenyTSConnections = 0 }
                    }
                    else {
                        [PSCustomObject]@{
                            MinEncryptionLevel = 3
                            SecurityLayer = 1
                            PortNumber = 3389
                            SSLCertificateSHA1Hash = ''
                            MaxIdleTime = 0
                        }
                    }
                }

                $result = Get-RDPSecurityDrift -RequireNLA $true -ErrorAction SilentlyContinue
                $nlaDrift = $result | Where-Object { $_.Setting -eq 'Network Level Authentication' }
                $nlaDrift | Should -Not -BeNullOrEmpty
            }
        }

        It "detects port drift" {
            InModuleScope System {
                Mock Get-ItemProperty {
                    if ($Name -eq 'fDenyTSConnections') {
                        [PSCustomObject]@{ fDenyTSConnections = 0 }
                    }
                    else {
                        [PSCustomObject]@{
                            MinEncryptionLevel = 3
                            SecurityLayer = 2
                            PortNumber = 5555
                            SSLCertificateSHA1Hash = ''
                            MaxIdleTime = 0
                        }
                    }
                }

                $result = Get-RDPSecurityDrift -ErrorAction SilentlyContinue
                $portDrift = $result | Where-Object { $_.Setting -eq 'RDP Port' }
                $portDrift | Should -Not -BeNullOrEmpty
            }
        }

        It "detects certificate drift when required" {
            InModuleScope System {
                Mock Get-ItemProperty {
                    if ($Name -eq 'fDenyTSConnections') {
                        [PSCustomObject]@{ fDenyTSConnections = 0 }
                    }
                    else {
                        [PSCustomObject]@{
                            MinEncryptionLevel = 3
                            SecurityLayer = 2
                            PortNumber = 3389
                            SSLCertificateSHA1Hash = ''
                            MaxIdleTime = 0
                        }
                    }
                }

                $result = Get-RDPSecurityDrift -RequireCertificate $true -ErrorAction SilentlyContinue
                $certDrift = $result | Where-Object { $_.Setting -eq 'SSL Certificate' }
                $certDrift | Should -Not -BeNullOrEmpty
            }
        }

        It "returns empty when no drifts" {
            InModuleScope System {
                Mock Get-ItemProperty {
                    if ($Name -eq 'fDenyTSConnections') {
                        [PSCustomObject]@{ fDenyTSConnections = 0 }
                    }
                    else {
                        [PSCustomObject]@{
                            MinEncryptionLevel = 3
                            SecurityLayer = 2
                            PortNumber = 3389
                            SSLCertificateSHA1Hash = 'ABC123'
                            MaxIdleTime = 0
                        }
                    }
                }

                $result = Get-RDPSecurityDrift -RequireCertificate $true -MaxIdleTimeMinutes 0 -ErrorAction SilentlyContinue
                ($result -eq $null -or @($result).Count -eq 0) | Should -Be $true
            }
        }
    }

    Context "Error Handling" {
        It "throws terminating error on registry access failure" {
            InModuleScope System {
                Mock Get-ItemProperty { throw "Access denied" }

                { Get-RDPSecurityDrift -ErrorAction Stop } | Should -Throw
            }
        }
    }

    Context "Documentation" {
        It "has complete help documentation" {
            $help = Get-Help Get-RDPSecurityDrift
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }

        It "documents MinRDPEncryptionLevel parameter" {
            $help = Get-Help Get-RDPSecurityDrift -Full
            $help.Parameters.Parameter.Name | Should -Contain 'MinRDPEncryptionLevel'
        }

        It "documents RequireNLA parameter" {
            $help = Get-Help Get-RDPSecurityDrift -Full
            $help.Parameters.Parameter.Name | Should -Contain 'RequireNLA'
        }

        It "documents RequireCertificate parameter" {
            $help = Get-Help Get-RDPSecurityDrift -Full
            $help.Parameters.Parameter.Name | Should -Contain 'RequireCertificate'
        }

        It "documents MaxIdleTimeMinutes parameter" {
            $help = Get-Help Get-RDPSecurityDrift -Full
            $help.Parameters.Parameter.Name | Should -Contain 'MaxIdleTimeMinutes'
        }

        It "includes usage examples" {
            $help = Get-Help Get-RDPSecurityDrift -Full
            $help.Examples | Should -Not -BeNullOrEmpty
        }
    }

}
