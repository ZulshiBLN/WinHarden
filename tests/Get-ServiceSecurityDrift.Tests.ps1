BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\System.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module System -Force -ErrorAction SilentlyContinue
}

Describe "Get-ServiceSecurityDrift" {

    Context "Parameter Validation" {
        It "accepts default parameters" {
            InModuleScope System {
                Mock Get-HardeningProfile {
                    return [PSCustomObject]@{
                        ProfileName = 'Recommended'
                        TargetSystem = 'Server'
                        Rules = @(
                            @{ Type = 'Service'; Name = 'Service-Test'; Severity = 'HIGH'; RuleDefinition = @{ ServiceName = 'spooler'; StartType = 'Disabled' } }
                        )
                    }
                }
                Mock Get-Service { }
                Mock Get-CimInstance { return [PSCustomObject]@{ ProductType = 3 } }
                Mock Write-Log { }

                { Get-ServiceSecurityDrift -ErrorAction SilentlyContinue } | Should -Not -Throw
            }
        }

        It "accepts Profile parameter with Basis" {
            InModuleScope System {
                Mock Get-HardeningProfile {
                    return [PSCustomObject]@{
                        ProfileName = 'Basis'
                        TargetSystem = 'Server'
                        Rules = @()
                    }
                }
                Mock Get-Service { }
                Mock Get-CimInstance { return [PSCustomObject]@{ ProductType = 3 } }
                Mock Write-Log { }

                { Get-ServiceSecurityDrift -Profile Basis -ErrorAction SilentlyContinue } | Should -Not -Throw
            }
        }

        It "accepts Profile parameter with Recommended" {
            InModuleScope System {
                Mock Get-HardeningProfile {
                    return [PSCustomObject]@{
                        ProfileName = 'Recommended'
                        TargetSystem = 'Server'
                        Rules = @()
                    }
                }
                Mock Get-Service { }
                Mock Get-CimInstance { return [PSCustomObject]@{ ProductType = 3 } }
                Mock Write-Log { }

                { Get-ServiceSecurityDrift -Profile Recommended -ErrorAction SilentlyContinue } | Should -Not -Throw
            }
        }

        It "accepts Profile parameter with Strict" {
            InModuleScope System {
                Mock Get-HardeningProfile {
                    return [PSCustomObject]@{
                        ProfileName = 'Strict'
                        TargetSystem = 'Server'
                        Rules = @()
                    }
                }
                Mock Get-Service { }
                Mock Get-CimInstance { return [PSCustomObject]@{ ProductType = 3 } }
                Mock Write-Log { }

                { Get-ServiceSecurityDrift -Profile Strict -ErrorAction SilentlyContinue } | Should -Not -Throw
            }
        }

        It "accepts ComputerName parameter" {
            InModuleScope System {
                Mock Get-HardeningProfile {
                    return [PSCustomObject]@{
                        ProfileName = 'Recommended'
                        TargetSystem = 'Server'
                        Rules = @()
                    }
                }
                Mock Get-Service { }
                Mock Invoke-Command { }
                Mock Write-Log { }

                { Get-ServiceSecurityDrift -ComputerName 'testserver' -ErrorAction SilentlyContinue } | Should -Not -Throw
            }
        }

        It "accepts Credential parameter" {
            InModuleScope System {
                Mock Get-HardeningProfile {
                    return [PSCustomObject]@{
                        ProfileName = 'Recommended'
                        TargetSystem = 'Server'
                        Rules = @()
                    }
                }
                Mock Get-Service { }
                Mock Invoke-Command { }
                Mock Write-Log { }

                # PSScriptAnalyzer ignore: Test credentials
                $credential = New-Object System.Management.Automation.PSCredential('user', (ConvertTo-SecureString 'pass' -AsPlainText -Force)) # PSScriptAnalyzer ignore [PSAvoidUsingConvertToSecureStringWithPlainText]
                { Get-ServiceSecurityDrift -ComputerName 'testserver' -Credential $credential -ErrorAction SilentlyContinue } | Should -Not -Throw
            }
        }

        It "accepts Detailed switch" {
            InModuleScope System {
                Mock Get-HardeningProfile {
                    return [PSCustomObject]@{
                        ProfileName = 'Recommended'
                        TargetSystem = 'Server'
                        Rules = @()
                    }
                }
                Mock Get-Service { }
                Mock Get-CimInstance { return [PSCustomObject]@{ ProductType = 3 } }
                Mock Write-Log { }

                { Get-ServiceSecurityDrift -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
            }
        }

        It "accepts ReportDriftOnly switch" {
            InModuleScope System {
                Mock Get-HardeningProfile {
                    return [PSCustomObject]@{
                        ProfileName = 'Recommended'
                        TargetSystem = 'Server'
                        Rules = @()
                    }
                }
                Mock Get-Service { }
                Mock Get-CimInstance { return [PSCustomObject]@{ ProductType = 3 } }
                Mock Write-Log { }

                { Get-ServiceSecurityDrift -ReportDriftOnly -ErrorAction SilentlyContinue } | Should -Not -Throw
            }
        }

        It "rejects invalid Profile value" {
            InModuleScope System {
                Mock Get-HardeningProfile { }
                Mock Get-Service { }
                Mock Write-Log { }

                { Get-ServiceSecurityDrift -Profile Invalid -ErrorAction Stop } | Should -Throw
            }
        }

        It "rejects empty ComputerName" {
            InModuleScope System {
                Mock Get-HardeningProfile { }
                Mock Get-Service { }
                Mock Write-Log { }

                { Get-ServiceSecurityDrift -ComputerName '' -ErrorAction Stop } | Should -Throw
            }
        }
    }

    Context "Service Drift Detection - Basic" {
        It "detects when service startup type is incorrect" {
            InModuleScope System {
                Mock Get-HardeningProfile {
                    return [PSCustomObject]@{
                        ProfileName = 'Recommended'
                        TargetSystem = 'Server'
                        Rules = @(
                            @{ Type = 'Service'; Name = 'Service-Test'; Severity = 'HIGH'; RuleDefinition = @{ ServiceName = 'spooler'; StartType = 'Disabled' } }
                        )
                    }
                }
                Mock Get-Service {
                    return [PSCustomObject]@{ Name = 'spooler'; DisplayName = 'Print Spooler'; StartType = 'Automatic'; Status = 'Running' }
                }
                Mock Get-CimInstance { return [PSCustomObject]@{ ProductType = 3 } }
                Mock Write-Log { }

                $result = Get-ServiceSecurityDrift -ErrorAction SilentlyContinue
                $result | Should -Not -BeNullOrEmpty
                $result.Status | Should -Contain 'DRIFT'
                $result[0].Actual | Should -Be 'Automatic'
                $result[0].Expected | Should -Be 'Disabled'
            }
        }

        It "detects when service is not found" {
            InModuleScope System {
                Mock Get-HardeningProfile {
                    return [PSCustomObject]@{
                        ProfileName = 'Recommended'
                        TargetSystem = 'Server'
                        Rules = @(
                            @{ Type = 'Service'; Name = 'Service-Test'; Severity = 'HIGH'; RuleDefinition = @{ ServiceName = 'nonexistent'; StartType = 'Disabled' } }
                        )
                    }
                }
                Mock Get-Service { return $null }
                Mock Get-CimInstance { return [PSCustomObject]@{ ProductType = 3 } }
                Mock Write-Log { }

                $result = Get-ServiceSecurityDrift -ErrorAction SilentlyContinue
                $notFound = $result | Where-Object { $_.ServiceName -eq 'nonexistent' }
                $notFound | Should -Not -BeNullOrEmpty
                $notFound.Status | Should -Be 'DRIFT'
                $notFound.Actual | Should -Be 'NOT_FOUND'
            }
        }

        It "returns no drift when service complies" {
            InModuleScope System {
                Mock Get-HardeningProfile {
                    return [PSCustomObject]@{
                        ProfileName = 'Recommended'
                        TargetSystem = 'Server'
                        Rules = @(
                            @{ Type = 'Service'; Name = 'Service-Test'; Severity = 'HIGH'; RuleDefinition = @{ ServiceName = 'spooler'; StartType = 'Disabled' } }
                        )
                    }
                }
                Mock Get-Service {
                    param($Name)
                    return $Name | ForEach-Object {
                        if ($_ -eq 'spooler') {
                            [PSCustomObject]@{ Name = $_; DisplayName = 'Print Spooler'; StartType = 'Disabled'; Status = 'Stopped' }
                        }
                    }
                }
                Mock Get-CimInstance { return [PSCustomObject]@{ ProductType = 3 } }
                Mock Write-Log { }

                $result = Get-ServiceSecurityDrift -ErrorAction SilentlyContinue
                $drift = $result | Where-Object { $_.ServiceName -eq 'spooler' -and $_.Status -eq 'DRIFT' }
                $drift | Should -BeNullOrEmpty
            }
        }
    }

    Context "Service Drift Detection - Multiple Services" {
        It "checks multiple services from profile" {
            InModuleScope System {
                Mock Get-HardeningProfile {
                    return [PSCustomObject]@{
                        ProfileName = 'Recommended'
                        TargetSystem = 'Server'
                        Rules = @(
                            @{ Type = 'Service'; Name = 'Service-Dangerous'; Severity = 'HIGH'; RuleDefinition = @{ ServiceName = 'spooler'; StartType = 'Disabled' } },
                            @{ Type = 'Service'; Name = 'Service-Unnecessary'; Severity = 'MEDIUM'; RuleDefinition = @{ Services = @('WinRM', 'TlntSvr'); StartType = 'Disabled' } }
                        )
                    }
                }
                Mock Get-Service {
                    param($Name)
                    return $Name | ForEach-Object {
                        [PSCustomObject]@{ Name = $_; DisplayName = $_; StartType = 'Automatic'; Status = 'Running' }
                    }
                }
                Mock Get-CimInstance { return [PSCustomObject]@{ ProductType = 3 } }
                Mock Write-Log { }

                $result = Get-ServiceSecurityDrift -ErrorAction SilentlyContinue
                $result.Count | Should -BeGreaterThan 0
                $result | Where-Object { $_.ServiceName -eq 'spooler' } | Should -Not -BeNullOrEmpty
                $result | Where-Object { $_.ServiceName -eq 'WinRM' } | Should -Not -BeNullOrEmpty
            }
        }

        It "detects drift in multiple services simultaneously" {
            InModuleScope System {
                Mock Get-HardeningProfile {
                    return [PSCustomObject]@{
                        ProfileName = 'Recommended'
                        TargetSystem = 'Server'
                        Rules = @(
                            @{ Type = 'Service'; Name = 'Service-Test1'; Severity = 'HIGH'; RuleDefinition = @{ Services = @('spooler', 'WinRM'); StartType = 'Disabled' } }
                        )
                    }
                }
                Mock Get-Service {
                    param($Name)
                    return $Name | ForEach-Object {
                        [PSCustomObject]@{ Name = $_; DisplayName = $_; StartType = 'Automatic'; Status = 'Running' }
                    }
                }
                Mock Get-CimInstance { return [PSCustomObject]@{ ProductType = 3 } }
                Mock Write-Log { }

                $result = Get-ServiceSecurityDrift -ErrorAction SilentlyContinue
                $driftCount = ($result | Where-Object { $_.Status -eq 'DRIFT' }).Count
                $driftCount | Should -BeGreaterThan 1
            }
        }
    }

    Context "Critical Services Monitoring" {
        It "includes Windows Update service in checks" {
            InModuleScope System {
                Mock Get-HardeningProfile {
                    return [PSCustomObject]@{
                        ProfileName = 'Recommended'
                        TargetSystem = 'Server'
                        Rules = @()
                    }
                }
                Mock Get-Service {
                    param($Name)
                    if ($Name -contains 'wuauserv') {
                        return [PSCustomObject]@{ Name = 'wuauserv'; DisplayName = 'Windows Update'; StartType = 'Automatic'; Status = 'Running' }
                    }
                }
                Mock Get-CimInstance { return [PSCustomObject]@{ ProductType = 3 } }
                Mock Write-Log { }

                $result = Get-ServiceSecurityDrift -Detailed -ErrorAction SilentlyContinue
                $result | Where-Object { $_.ServiceName -eq 'wuauserv' } | Should -Not -BeNullOrEmpty
            }
        }

        It "includes Windows Defender service in checks" {
            InModuleScope System {
                Mock Get-HardeningProfile {
                    return [PSCustomObject]@{
                        ProfileName = 'Recommended'
                        TargetSystem = 'Server'
                        Rules = @()
                    }
                }
                Mock Get-Service {
                    param($Name)
                    if ($Name -contains 'WinDefend') {
                        return [PSCustomObject]@{ Name = 'WinDefend'; DisplayName = 'Windows Defender'; StartType = 'Automatic'; Status = 'Running' }
                    }
                }
                Mock Get-CimInstance { return [PSCustomObject]@{ ProductType = 3 } }
                Mock Write-Log { }

                $result = Get-ServiceSecurityDrift -Detailed -ErrorAction SilentlyContinue
                $result | Where-Object { $_.ServiceName -eq 'WinDefend' } | Should -Not -BeNullOrEmpty
            }
        }

        It "includes Firewall service in checks" {
            InModuleScope System {
                Mock Get-HardeningProfile {
                    return [PSCustomObject]@{
                        ProfileName = 'Recommended'
                        TargetSystem = 'Server'
                        Rules = @()
                    }
                }
                Mock Get-Service {
                    param($Name)
                    if ($Name -contains 'mpssvc') {
                        return [PSCustomObject]@{ Name = 'mpssvc'; DisplayName = 'Windows Defender Firewall'; StartType = 'Automatic'; Status = 'Running' }
                    }
                }
                Mock Get-CimInstance { return [PSCustomObject]@{ ProductType = 3 } }
                Mock Write-Log { }

                $result = Get-ServiceSecurityDrift -Detailed -ErrorAction SilentlyContinue
                $result | Where-Object { $_.ServiceName -eq 'mpssvc' } | Should -Not -BeNullOrEmpty
            }
        }

        It "includes Telemetry service in checks" {
            InModuleScope System {
                Mock Get-HardeningProfile {
                    return [PSCustomObject]@{
                        ProfileName = 'Recommended'
                        TargetSystem = 'Server'
                        Rules = @()
                    }
                }
                Mock Get-Service {
                    param($Name)
                    if ($Name -contains 'DiagTrack') {
                        return [PSCustomObject]@{ Name = 'DiagTrack'; DisplayName = 'DiagTrack'; StartType = 'Disabled'; Status = 'Stopped' }
                    }
                }
                Mock Get-CimInstance { return [PSCustomObject]@{ ProductType = 3 } }
                Mock Write-Log { }

                $result = Get-ServiceSecurityDrift -Detailed -ErrorAction SilentlyContinue
                $result | Where-Object { $_.ServiceName -eq 'DiagTrack' } | Should -Not -BeNullOrEmpty
            }
        }

        It "includes Remote Desktop service in checks" {
            InModuleScope System {
                Mock Get-HardeningProfile {
                    return [PSCustomObject]@{
                        ProfileName = 'Recommended'
                        TargetSystem = 'Server'
                        Rules = @()
                    }
                }
                Mock Get-Service {
                    param($Name)
                    if ($Name -contains 'TermService') {
                        return [PSCustomObject]@{ Name = 'TermService'; DisplayName = 'Remote Desktop Services'; StartType = 'Manual'; Status = 'Stopped' }
                    }
                }
                Mock Get-CimInstance { return [PSCustomObject]@{ ProductType = 3 } }
                Mock Write-Log { }

                $result = Get-ServiceSecurityDrift -Detailed -ErrorAction SilentlyContinue
                $result | Where-Object { $_.ServiceName -eq 'TermService' } | Should -Not -BeNullOrEmpty
            }
        }
    }

    Context "Profile Support" {
        It "loads Basis profile correctly" {
            InModuleScope System {
                Mock Get-HardeningProfile {
                    return [PSCustomObject]@{
                        ProfileName = 'Basis'
                        TargetSystem = 'Server'
                        Rules = @()
                    }
                }
                Mock Get-Service { }
                Mock Get-CimInstance { return [PSCustomObject]@{ ProductType = 3 } }
                Mock Write-Log { }

                { Get-ServiceSecurityDrift -Profile Basis -ErrorAction SilentlyContinue } | Should -Not -Throw
                Assert-MockCalled Get-HardeningProfile -ParameterFilter { $ProfileName -eq 'Basis' }
            }
        }

        It "loads Recommended profile correctly" {
            InModuleScope System {
                Mock Get-HardeningProfile {
                    return [PSCustomObject]@{
                        ProfileName = 'Recommended'
                        TargetSystem = 'Server'
                        Rules = @()
                    }
                }
                Mock Get-Service { }
                Mock Get-CimInstance { return [PSCustomObject]@{ ProductType = 3 } }
                Mock Write-Log { }

                { Get-ServiceSecurityDrift -Profile Recommended -ErrorAction SilentlyContinue } | Should -Not -Throw
                Assert-MockCalled Get-HardeningProfile -ParameterFilter { $ProfileName -eq 'Recommended' }
            }
        }

        It "loads Strict profile correctly" {
            InModuleScope System {
                Mock Get-HardeningProfile {
                    return [PSCustomObject]@{
                        ProfileName = 'Strict'
                        TargetSystem = 'Server'
                        Rules = @()
                    }
                }
                Mock Get-Service { }
                Mock Get-CimInstance { return [PSCustomObject]@{ ProductType = 3 } }
                Mock Write-Log { }

                { Get-ServiceSecurityDrift -Profile Strict -ErrorAction SilentlyContinue } | Should -Not -Throw
                Assert-MockCalled Get-HardeningProfile -ParameterFilter { $ProfileName -eq 'Strict' }
            }
        }
    }

    Context "Detailed Output" {
        It "includes basic properties in output" {
            InModuleScope System {
                Mock Get-HardeningProfile {
                    return [PSCustomObject]@{
                        ProfileName = 'Recommended'
                        TargetSystem = 'Server'
                        Rules = @(
                            @{ Type = 'Service'; Name = 'Service-Test'; Severity = 'HIGH'; RuleDefinition = @{ ServiceName = 'spooler'; StartType = 'Disabled' } }
                        )
                    }
                }
                Mock Get-Service {
                    return [PSCustomObject]@{ Name = 'spooler'; DisplayName = 'Print Spooler'; StartType = 'Automatic'; Status = 'Running' }
                }
                Mock Get-CimInstance { return [PSCustomObject]@{ ProductType = 3 } }
                Mock Write-Log { }

                $result = Get-ServiceSecurityDrift -ErrorAction SilentlyContinue
                $result[0] | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Should -Contain 'ServiceName'
                $result[0] | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Should -Contain 'Expected'
                $result[0] | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Should -Contain 'Actual'
                $result[0] | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Should -Contain 'Status'
            }
        }

        It "includes Severity in output" {
            InModuleScope System {
                Mock Get-HardeningProfile {
                    return [PSCustomObject]@{
                        ProfileName = 'Recommended'
                        TargetSystem = 'Server'
                        Rules = @(
                            @{ Type = 'Service'; Name = 'Service-Test'; Severity = 'CRITICAL'; RuleDefinition = @{ ServiceName = 'spooler'; StartType = 'Disabled' } }
                        )
                    }
                }
                Mock Get-Service {
                    return [PSCustomObject]@{ Name = 'spooler'; DisplayName = 'Print Spooler'; StartType = 'Automatic'; Status = 'Running' }
                }
                Mock Get-CimInstance { return [PSCustomObject]@{ ProductType = 3 } }
                Mock Write-Log { }

                $result = Get-ServiceSecurityDrift -ErrorAction SilentlyContinue
                $result[0].Severity | Should -Be 'CRITICAL'
            }
        }

        It "includes Remediation in output" {
            InModuleScope System {
                Mock Get-HardeningProfile {
                    return [PSCustomObject]@{
                        ProfileName = 'Recommended'
                        TargetSystem = 'Server'
                        Rules = @(
                            @{ Type = 'Service'; Name = 'Service-Test'; Severity = 'HIGH'; RuleDefinition = @{ ServiceName = 'spooler'; StartType = 'Disabled' } }
                        )
                    }
                }
                Mock Get-Service {
                    return [PSCustomObject]@{ Name = 'spooler'; DisplayName = 'Print Spooler'; StartType = 'Automatic'; Status = 'Running' }
                }
                Mock Get-CimInstance { return [PSCustomObject]@{ ProductType = 3 } }
                Mock Write-Log { }

                $result = Get-ServiceSecurityDrift -ErrorAction SilentlyContinue
                $result[0] | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Should -Contain 'Remediation'
                $result[0].Remediation | Should -Match 'Set-Service'
            }
        }

        It "includes DisplayName when available" {
            InModuleScope System {
                Mock Get-HardeningProfile {
                    return [PSCustomObject]@{
                        ProfileName = 'Recommended'
                        TargetSystem = 'Server'
                        Rules = @(
                            @{ Type = 'Service'; Name = 'Service-Test'; Severity = 'HIGH'; RuleDefinition = @{ ServiceName = 'spooler'; StartType = 'Disabled' } }
                        )
                    }
                }
                Mock Get-Service {
                    return [PSCustomObject]@{ Name = 'spooler'; DisplayName = 'Print Spooler'; StartType = 'Automatic'; Status = 'Running' }
                }
                Mock Get-CimInstance { return [PSCustomObject]@{ ProductType = 3 } }
                Mock Write-Log { }

                $result = Get-ServiceSecurityDrift -ErrorAction SilentlyContinue
                $result[0].DisplayName | Should -Be 'Print Spooler'
            }
        }

        It "includes CurrentStatus with Detailed switch" {
            InModuleScope System {
                Mock Get-HardeningProfile {
                    return [PSCustomObject]@{
                        ProfileName = 'Recommended'
                        TargetSystem = 'Server'
                        Rules = @(
                            @{ Type = 'Service'; Name = 'Service-Test'; Severity = 'HIGH'; RuleDefinition = @{ ServiceName = 'spooler'; StartType = 'Disabled' } }
                        )
                    }
                }
                Mock Get-Service {
                    return [PSCustomObject]@{ Name = 'spooler'; DisplayName = 'Print Spooler'; StartType = 'Automatic'; Status = 'Running' }
                }
                Mock Get-CimInstance { return [PSCustomObject]@{ ProductType = 3 } }
                Mock Write-Log { }

                $result = Get-ServiceSecurityDrift -Detailed -ErrorAction SilentlyContinue
                $result[0] | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name | Should -Contain 'CurrentStatus'
            }
        }
    }

    Context "ReportDriftOnly Switch" {
        It "returns only drifted services when ReportDriftOnly is set" {
            InModuleScope System {
                Mock Get-HardeningProfile {
                    return [PSCustomObject]@{
                        ProfileName = 'Recommended'
                        TargetSystem = 'Server'
                        Rules = @(
                            @{ Type = 'Service'; Name = 'Service-Test'; Severity = 'HIGH'; RuleDefinition = @{ Services = @('spooler', 'WinRM'); StartType = 'Disabled' } }
                        )
                    }
                }
                Mock Get-Service {
                    param($Name)
                    return $Name | ForEach-Object {
                        if ($_ -eq 'spooler') {
                            [PSCustomObject]@{ Name = $_; DisplayName = 'Print Spooler'; StartType = 'Disabled'; Status = 'Stopped' }
                        }
                        else {
                            [PSCustomObject]@{ Name = $_; DisplayName = 'Windows Remote Management'; StartType = 'Automatic'; Status = 'Running' }
                        }
                    }
                }
                Mock Get-CimInstance { return [PSCustomObject]@{ ProductType = 3 } }
                Mock Write-Log { }

                $result = Get-ServiceSecurityDrift -ReportDriftOnly -ErrorAction SilentlyContinue
                $result | Where-Object { $_.ServiceName -eq 'spooler' } | Should -BeNullOrEmpty
                $result | Where-Object { $_.ServiceName -eq 'WinRM' } | Should -Not -BeNullOrEmpty
            }
        }

        It "filters to drift-only services with ReportDriftOnly" {
            InModuleScope System {
                Mock Get-HardeningProfile {
                    return [PSCustomObject]@{
                        ProfileName = 'Recommended'
                        TargetSystem = 'Server'
                        Rules = @(
                            @{ Type = 'Service'; Name = 'Service-Test'; Severity = 'HIGH'; RuleDefinition = @{ ServiceName = 'spooler'; StartType = 'Disabled' } }
                        )
                    }
                }
                Mock Get-Service {
                    param($Name)
                    return $Name | ForEach-Object {
                        if ($_ -eq 'spooler') {
                            [PSCustomObject]@{ Name = $_; DisplayName = 'Print Spooler'; StartType = 'Disabled'; Status = 'Stopped' }
                        }
                        else {
                            [PSCustomObject]@{ Name = $_; DisplayName = $_; StartType = 'Automatic'; Status = 'Running' }
                        }
                    }
                }
                Mock Get-CimInstance { return [PSCustomObject]@{ ProductType = 3 } }
                Mock Write-Log { }

                $result = Get-ServiceSecurityDrift -ReportDriftOnly -ErrorAction SilentlyContinue
                # All results should have Status = 'DRIFT'
                $result | Where-Object { $_.Status -ne 'DRIFT' } | Should -BeNullOrEmpty
            }
        }
    }

    Context "Detailed Switch" {
        It "includes compliant services with Detailed switch" {
            InModuleScope System {
                Mock Get-HardeningProfile {
                    return [PSCustomObject]@{
                        ProfileName = 'Recommended'
                        TargetSystem = 'Server'
                        Rules = @(
                            @{ Type = 'Service'; Name = 'Service-Test'; Severity = 'HIGH'; RuleDefinition = @{ ServiceName = 'spooler'; StartType = 'Disabled' } }
                        )
                    }
                }
                Mock Get-Service {
                    return [PSCustomObject]@{ Name = 'spooler'; DisplayName = 'Print Spooler'; StartType = 'Disabled'; Status = 'Stopped' }
                }
                Mock Get-CimInstance { return [PSCustomObject]@{ ProductType = 3 } }
                Mock Write-Log { }

                $result = Get-ServiceSecurityDrift -Detailed -ErrorAction SilentlyContinue
                $result | Should -Not -BeNullOrEmpty
                $result[0].Status | Should -Be 'COMPLIANT'
            }
        }

        It "marks compliant services as COMPLIANT" {
            InModuleScope System {
                Mock Get-HardeningProfile {
                    return [PSCustomObject]@{
                        ProfileName = 'Recommended'
                        TargetSystem = 'Server'
                        Rules = @(
                            @{ Type = 'Service'; Name = 'Service-Test'; Severity = 'HIGH'; RuleDefinition = @{ ServiceName = 'spooler'; StartType = 'Disabled' } }
                        )
                    }
                }
                Mock Get-Service {
                    return [PSCustomObject]@{ Name = 'spooler'; DisplayName = 'Print Spooler'; StartType = 'Disabled'; Status = 'Stopped' }
                }
                Mock Get-CimInstance { return [PSCustomObject]@{ ProductType = 3 } }
                Mock Write-Log { }

                $result = Get-ServiceSecurityDrift -Detailed -ErrorAction SilentlyContinue
                $result[0].Status | Should -Be 'COMPLIANT'
                $result[0].Remediation | Should -Be 'None'
            }
        }
    }

    Context "Remote Computer Support" {
        It "calls Invoke-Command for remote computer without credential" {
            InModuleScope System {
                Mock Get-HardeningProfile {
                    return [PSCustomObject]@{
                        ProfileName = 'Recommended'
                        TargetSystem = 'Server'
                        Rules = @()
                    }
                }
                Mock Invoke-Command { return @() }
                Mock Write-Log { }

                Get-ServiceSecurityDrift -ComputerName 'testserver' -ErrorAction SilentlyContinue
                Assert-MockCalled Invoke-Command -ParameterFilter { $ComputerName -eq 'testserver' }
            }
        }

        It "includes ComputerName in drift results for remote system" {
            InModuleScope System {
                Mock Get-HardeningProfile {
                    return [PSCustomObject]@{
                        ProfileName = 'Recommended'
                        TargetSystem = 'Server'
                        Rules = @(
                            @{ Type = 'Service'; Name = 'Service-Test'; Severity = 'HIGH'; RuleDefinition = @{ ServiceName = 'spooler'; StartType = 'Disabled' } }
                        )
                    }
                }
                Mock Invoke-Command {
                    param($ComputerName, $ScriptBlock)
                    return & $ScriptBlock -serviceNames @('spooler')
                }
                Mock Get-Service {
                    param($Name)
                    return [PSCustomObject]@{ Name = 'spooler'; DisplayName = 'Print Spooler'; StartType = 'Automatic'; Status = 'Running' }
                }
                Mock Write-Log { }

                $result = Get-ServiceSecurityDrift -ComputerName 'testserver' -ErrorAction SilentlyContinue
                $spooler = $result | Where-Object { $_.ServiceName -eq 'spooler' }
                $spooler.ComputerName | Should -Be 'testserver'
            }
        }

        It "handles remote connection with credentials" {
            InModuleScope System {
                Mock Get-HardeningProfile {
                    return [PSCustomObject]@{
                        ProfileName = 'Recommended'
                        TargetSystem = 'Server'
                        Rules = @()
                    }
                }
                Mock Invoke-Command { return @() }
                Mock Write-Log { }

                # PSScriptAnalyzer ignore: Test credentials
                $credential = New-Object System.Management.Automation.PSCredential('user', (ConvertTo-SecureString 'pass' -AsPlainText -Force)) # PSScriptAnalyzer ignore [PSAvoidUsingConvertToSecureStringWithPlainText]
                Get-ServiceSecurityDrift -ComputerName 'testserver' -Credential $credential -ErrorAction SilentlyContinue
                Assert-MockCalled Invoke-Command -ParameterFilter { $Credential -ne $null }
            }
        }
    }

    Context "WhatIf Support" {
        It "supports WhatIf parameter" {
            InModuleScope System {
                Mock Get-HardeningProfile {
                    return [PSCustomObject]@{
                        ProfileName = 'Recommended'
                        TargetSystem = 'Server'
                        Rules = @()
                    }
                }
                Mock Get-Service { }
                Mock Get-CimInstance { return [PSCustomObject]@{ ProductType = 3 } }
                Mock Write-Log { }

                { Get-ServiceSecurityDrift -WhatIf } | Should -Not -Throw
            }
        }

        It "respects WhatIf without executing Get-Service" {
            InModuleScope System {
                Mock Get-HardeningProfile {
                    return [PSCustomObject]@{
                        ProfileName = 'Recommended'
                        TargetSystem = 'Server'
                        Rules = @()
                    }
                }
                Mock Get-Service { }
                Mock Get-CimInstance { return [PSCustomObject]@{ ProductType = 3 } }
                Mock Write-Log { }

                Get-ServiceSecurityDrift -WhatIf -ErrorAction SilentlyContinue
                # WhatIf should still try to query services through ShouldProcess
                Assert-MockCalled Get-Service -Times 0 -Scope It
            }
        }
    }

    Context "Logging" {
        It "logs drift detection start" {
            InModuleScope System {
                Mock Get-HardeningProfile {
                    return [PSCustomObject]@{
                        ProfileName = 'Recommended'
                        TargetSystem = 'Server'
                        Rules = @()
                    }
                }
                Mock Get-Service { }
                Mock Get-CimInstance { return [PSCustomObject]@{ ProductType = 3 } }
                Mock Write-Log { }

                Get-ServiceSecurityDrift -ErrorAction SilentlyContinue
                Assert-MockCalled Write-Log -ParameterFilter { $Message -match 'Starting service security drift' }
            }
        }

        It "logs drift detection completion" {
            InModuleScope System {
                Mock Get-HardeningProfile {
                    return [PSCustomObject]@{
                        ProfileName = 'Recommended'
                        TargetSystem = 'Server'
                        Rules = @()
                    }
                }
                Mock Get-Service { }
                Mock Get-CimInstance { return [PSCustomObject]@{ ProductType = 3 } }
                Mock Write-Log { }

                Get-ServiceSecurityDrift -ErrorAction SilentlyContinue
                Assert-MockCalled Write-Log -ParameterFilter { $Message -match 'complete' }
            }
        }

        It "logs service drift warnings" {
            InModuleScope System {
                Mock Get-HardeningProfile {
                    return [PSCustomObject]@{
                        ProfileName = 'Recommended'
                        TargetSystem = 'Server'
                        Rules = @(
                            @{ Type = 'Service'; Name = 'Service-Test'; Severity = 'HIGH'; RuleDefinition = @{ ServiceName = 'spooler'; StartType = 'Disabled' } }
                        )
                    }
                }
                Mock Get-Service {
                    return [PSCustomObject]@{ Name = 'spooler'; DisplayName = 'Print Spooler'; StartType = 'Automatic'; Status = 'Running' }
                }
                Mock Get-CimInstance { return [PSCustomObject]@{ ProductType = 3 } }
                Mock Write-Log { }

                Get-ServiceSecurityDrift -ErrorAction SilentlyContinue
                Assert-MockCalled Write-Log -ParameterFilter { $Message -match 'drift' -and $Level -eq 'Warning' }
            }
        }
    }

    Context "System Type Detection" {
        It "detects Client system type" {
            InModuleScope System {
                Mock Get-HardeningProfile {
                    return [PSCustomObject]@{
                        ProfileName = 'Recommended'
                        TargetSystem = 'Client'
                        Rules = @()
                    }
                }
                Mock Get-Service { }
                Mock Get-CimInstance { return [PSCustomObject]@{ ProductType = 1 } }
                Mock Write-Log { }

                Get-ServiceSecurityDrift -ErrorAction SilentlyContinue
                Assert-MockCalled Get-HardeningProfile -ParameterFilter { $TargetSystem -eq 'Client' }
            }
        }

        It "detects Server system type" {
            InModuleScope System {
                Mock Get-HardeningProfile {
                    return [PSCustomObject]@{
                        ProfileName = 'Recommended'
                        TargetSystem = 'Server'
                        Rules = @()
                    }
                }
                Mock Get-Service { }
                Mock Get-CimInstance { return [PSCustomObject]@{ ProductType = 3 } }
                Mock Write-Log { }

                Get-ServiceSecurityDrift -ErrorAction SilentlyContinue
                Assert-MockCalled Get-HardeningProfile -ParameterFilter { $TargetSystem -eq 'Server' }
            }
        }
    }

    Context "Error Handling" {
        It "throws when profile loading fails" {
            InModuleScope System {
                Mock Get-HardeningProfile { return $null }
                Mock Write-Log { }
                Mock Write-ErrorLog { }

                { Get-ServiceSecurityDrift -ErrorAction Stop } | Should -Throw
            }
        }

        It "logs errors with Write-ErrorLog" {
            InModuleScope System {
                Mock Get-HardeningProfile { throw "Test error" }
                Mock Write-ErrorLog { }
                Mock Write-Log { }

                { Get-ServiceSecurityDrift -ErrorAction Stop } | Should -Throw
                Assert-MockCalled Write-ErrorLog
            }
        }
    }

    Context "Documentation" {
        It "has complete help documentation" {
            $help = Get-Help Get-ServiceSecurityDrift
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }

        It "includes all parameters in help" {
            $help = Get-Help Get-ServiceSecurityDrift
            $help.Parameters.Parameter.Name | Should -Contain 'Profile'
            $help.Parameters.Parameter.Name | Should -Contain 'ComputerName'
            $help.Parameters.Parameter.Name | Should -Contain 'Credential'
            $help.Parameters.Parameter.Name | Should -Contain 'Detailed'
            $help.Parameters.Parameter.Name | Should -Contain 'ReportDriftOnly'
        }

        It "includes examples in help" {
            $help = Get-Help Get-ServiceSecurityDrift
            $help.Examples | Should -Not -BeNullOrEmpty
        }
    }
}
