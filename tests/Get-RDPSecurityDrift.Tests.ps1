BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\System.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module System -Force -ErrorAction SilentlyContinue
}

Describe "Get-RDPSecurityDrift" {

    Context "Parameter Validation" {
        It "accepts default parameters" {
            { Get-RDPSecurityDrift -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts MinRDPEncryptionLevel parameter" {
            { Get-RDPSecurityDrift -MinRDPEncryptionLevel 2 -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts RequireNLA parameter" {
            { Get-RDPSecurityDrift -RequireNLA $false -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts RequireCertificate parameter" {
            { Get-RDPSecurityDrift -RequireCertificate $true -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts MaxIdleTimeMinutes parameter" {
            { Get-RDPSecurityDrift -MaxIdleTimeMinutes 20 -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "rejects invalid encryption level (0)" {
            { Get-RDPSecurityDrift -MinRDPEncryptionLevel 0 -ErrorAction Stop } | Should -Throw
        }

        It "rejects invalid encryption level (4)" {
            { Get-RDPSecurityDrift -MinRDPEncryptionLevel 4 -ErrorAction Stop } | Should -Throw
        }

        It "rejects invalid idle timeout (-1)" {
            { Get-RDPSecurityDrift -MaxIdleTimeMinutes -1 -ErrorAction Stop } | Should -Throw
        }

        It "accepts idle timeout value 0 (no timeout)" {
            { Get-RDPSecurityDrift -MaxIdleTimeMinutes 0 -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "RDP Service Status Check" {
        It "detects when RDP service is disabled" {
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
            $result | Where-Object { $_.Setting -eq 'RDP Service Enabled' } | Should -Not -BeNullOrEmpty
        }

        It "does not report drift when RDP service is enabled" {
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

            $result = Get-RDPSecurityDrift -ErrorAction SilentlyContinue
            $result | Where-Object { $_.Setting -eq 'RDP Service Enabled' } | Should -BeNullOrEmpty
        }
    }

    Context "RDP Encryption Level Check" {
        It "detects encryption drift when level too low" {
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
            $encDrift.Status | Should -Be 'DRIFT'
            $encDrift.Actual | Should -Match '1'
        }

        It "does not report drift when encryption level meets requirement" {
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

            $result = Get-RDPSecurityDrift -MinRDPEncryptionLevel 3 -ErrorAction SilentlyContinue
            $result | Where-Object { $_.Setting -eq 'Encryption Level' } | Should -BeNullOrEmpty
        }

        It "handles missing encryption level (defaults to 1)" {
            Mock Get-ItemProperty {
                if ($Name -eq 'fDenyTSConnections') {
                    [PSCustomObject]@{ fDenyTSConnections = 0 }
                }
                else {
                    [PSCustomObject]@{
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

    Context "RDP Network Level Authentication Check" {
        It "detects NLA drift when disabled but required" {
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
            $nlaDrift.Status | Should -Be 'DRIFT'
        }

        It "does not report NLA drift when enabled and required" {
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

            $result = Get-RDPSecurityDrift -RequireNLA $true -ErrorAction SilentlyContinue
            $result | Where-Object { $_.Setting -eq 'Network Level Authentication' } | Should -BeNullOrEmpty
        }

        It "detects NLA drift when enabled but not required" {
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

            $result = Get-RDPSecurityDrift -RequireNLA $false -ErrorAction SilentlyContinue
            $nlaDrift = $result | Where-Object { $_.Setting -eq 'Network Level Authentication' }
            $nlaDrift | Should -Not -BeNullOrEmpty
        }

        It "handles missing SecurityLayer (defaults to 1)" {
            Mock Get-ItemProperty {
                if ($Name -eq 'fDenyTSConnections') {
                    [PSCustomObject]@{ fDenyTSConnections = 0 }
                }
                else {
                    [PSCustomObject]@{
                        MinEncryptionLevel = 3
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

    Context "RDP Port Check" {
        It "detects port drift when non-standard" {
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
            $portDrift.Actual | Should -Match '5555'
        }

        It "does not report port drift on standard port 3389" {
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

            $result = Get-RDPSecurityDrift -ErrorAction SilentlyContinue
            $result | Where-Object { $_.Setting -eq 'RDP Port' } | Should -BeNullOrEmpty
        }

        It "handles missing port (defaults to 3389)" {
            Mock Get-ItemProperty {
                if ($Name -eq 'fDenyTSConnections') {
                    [PSCustomObject]@{ fDenyTSConnections = 0 }
                }
                else {
                    [PSCustomObject]@{
                        MinEncryptionLevel = 3
                        SecurityLayer = 2
                        SSLCertificateSHA1Hash = ''
                        MaxIdleTime = 0
                    }
                }
            }

            $result = Get-RDPSecurityDrift -ErrorAction SilentlyContinue
            $result | Where-Object { $_.Setting -eq 'RDP Port' } | Should -BeNullOrEmpty
        }
    }

    Context "RDP SSL Certificate Check" {
        It "detects certificate drift when required but missing" {
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
            $certDrift.Status | Should -Be 'DRIFT'
        }

        It "does not report certificate drift when configured" {
            Mock Get-ItemProperty {
                if ($Name -eq 'fDenyTSConnections') {
                    [PSCustomObject]@{ fDenyTSConnections = 0 }
                }
                else {
                    [PSCustomObject]@{
                        MinEncryptionLevel = 3
                        SecurityLayer = 2
                        PortNumber = 3389
                        SSLCertificateSHA1Hash = 'ABC123DEF456'
                        MaxIdleTime = 0
                    }
                }
            }

            $result = Get-RDPSecurityDrift -RequireCertificate $true -ErrorAction SilentlyContinue
            $result | Where-Object { $_.Setting -eq 'SSL Certificate' } | Should -BeNullOrEmpty
        }

        It "does not report certificate drift when not required" {
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

            $result = Get-RDPSecurityDrift -RequireCertificate $false -ErrorAction SilentlyContinue
            $result | Where-Object { $_.Setting -eq 'SSL Certificate' } | Should -BeNullOrEmpty
        }
    }

    Context "RDP Idle Session Timeout Check" {
        It "detects timeout drift when not configured" {
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

            $result = Get-RDPSecurityDrift -MaxIdleTimeMinutes 15 -ErrorAction SilentlyContinue
            $timeoutDrift = $result | Where-Object { $_.Setting -eq 'Idle Session Timeout' }
            $timeoutDrift | Should -Not -BeNullOrEmpty
            $timeoutDrift.Actual | Should -Match 'No timeout'
        }

        It "detects timeout drift when exceeds maximum" {
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
                        MaxIdleTime = 1800000
                    }
                }
            }

            $result = Get-RDPSecurityDrift -MaxIdleTimeMinutes 15 -ErrorAction SilentlyContinue
            $timeoutDrift = $result | Where-Object { $_.Setting -eq 'Idle Session Timeout' }
            $timeoutDrift | Should -Not -BeNullOrEmpty
            $timeoutDrift.Actual | Should -Match '30 minutes'
        }

        It "does not report timeout drift when within limits" {
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
                        MaxIdleTime = 600000
                    }
                }
            }

            $result = Get-RDPSecurityDrift -MaxIdleTimeMinutes 15 -ErrorAction SilentlyContinue
            $result | Where-Object { $_.Setting -eq 'Idle Session Timeout' } | Should -BeNullOrEmpty
        }

        It "ignores timeout check when MaxIdleTimeMinutes is 0" {
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

            $result = Get-RDPSecurityDrift -MaxIdleTimeMinutes 0 -ErrorAction SilentlyContinue
            $result | Where-Object { $_.Setting -eq 'Idle Session Timeout' } | Should -BeNullOrEmpty
        }
    }

    Context "Return Value Structure" {
        It "returns PSCustomObject array" {
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

            $result = Get-RDPSecurityDrift -MinRDPEncryptionLevel 3 -RequireNLA $true -ErrorAction SilentlyContinue
            $result | Should -BeOfType [PSCustomObject]
        }

        It "includes required properties in drift findings" {
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
            $drift = $result[0]
            $drift | Should -Have -Property Category
            $drift | Should -Have -Property Setting
            $drift | Should -Have -Property Expected
            $drift | Should -Have -Property Actual
            $drift | Should -Have -Property Status
            $drift | Should -Have -Property Severity
        }

        It "sets correct severity levels" {
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
                        MaxIdleTime = 3600000
                    }
                }
            }

            $result = Get-RDPSecurityDrift -MinRDPEncryptionLevel 3 -MaxIdleTimeMinutes 15 -ErrorAction SilentlyContinue
            ($result | Where-Object { $_.Setting -eq 'Encryption Level' }).Severity | Should -Be 'HIGH'
            ($result | Where-Object { $_.Setting -eq 'RDP Port' }).Severity | Should -Be 'MEDIUM'
            ($result | Where-Object { $_.Setting -eq 'Idle Session Timeout' }).Severity | Should -Be 'LOW'
        }
    }

    Context "Error Handling" {
        It "throws on registry access error" {
            Mock Get-ItemProperty { throw "Access denied" }

            { Get-RDPSecurityDrift -ErrorAction Stop } | Should -Throw
        }

        It "continues with other checks if some registry access fails" {
            Mock Get-ItemProperty {
                if ($Name -eq 'fDenyTSConnections') {
                    [PSCustomObject]@{ fDenyTSConnections = 0 }
                }
                elseif ($Name -eq 'MinEncryptionLevel') {
                    throw "Access denied"
                }
                else {
                    [PSCustomObject]@{
                        SecurityLayer = 2
                        PortNumber = 3389
                        SSLCertificateSHA1Hash = ''
                        MaxIdleTime = 0
                    }
                }
            }

            { Get-RDPSecurityDrift -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Complete Compliance Check" {
        It "identifies all drifts in non-compliant system" {
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

            $result = Get-RDPSecurityDrift -MinRDPEncryptionLevel 3 -RequireNLA $true -RequireCertificate $true -MaxIdleTimeMinutes 15 -ErrorAction SilentlyContinue
            $result.Count | Should -Be 6
        }

        It "returns empty array when fully compliant" {
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
                        MaxIdleTime = 900000
                    }
                }
            }

            $result = Get-RDPSecurityDrift -MinRDPEncryptionLevel 3 -RequireNLA $true -RequireCertificate $true -MaxIdleTimeMinutes 15 -ErrorAction SilentlyContinue
            $result | Should -BeNullOrEmpty
        }
    }

    Context "Documentation" {
        It "has complete help documentation" {
            $help = Get-Help Get-RDPSecurityDrift
            $help.Synopsis | Should -Not -BeNullOrEmpty
            $help.Description | Should -Not -BeNullOrEmpty
        }

        It "documents all parameters" {
            $help = Get-Help Get-RDPSecurityDrift -Full
            $help.Parameters.Parameter.Name | Should -Contain 'MinRDPEncryptionLevel'
            $help.Parameters.Parameter.Name | Should -Contain 'RequireNLA'
            $help.Parameters.Parameter.Name | Should -Contain 'RequireCertificate'
            $help.Parameters.Parameter.Name | Should -Contain 'MaxIdleTimeMinutes'
        }

        It "includes usage examples" {
            $help = Get-Help Get-RDPSecurityDrift -Full
            $help.Examples | Should -Not -BeNullOrEmpty
        }
    }

}
