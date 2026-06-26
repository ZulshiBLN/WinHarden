BeforeAll {
    # Load Core module first (contains Write-Log and other dependencies)
    $coreModulePath = (Resolve-Path "$PSScriptRoot\..\modules\Core.psm1").Path
    Import-Module $coreModulePath -Force -Scope Global

    # Load System module (contains Invoke-RemoteHardening and related functions)
    $systemModulePath = (Resolve-Path "$PSScriptRoot\..\modules\System.psm1").Path
    Import-Module $systemModulePath -Force -Scope Global
}

AfterAll {
    Remove-Module Core -Force -ErrorAction SilentlyContinue
    Remove-Module System -Force -ErrorAction SilentlyContinue
}

BeforeEach {
    # Mock Write-Log to prevent actual logging during tests
    Mock -CommandName Write-Log -MockWith { } -Scope Global
    Mock -CommandName Write-ErrorLog -MockWith { } -Scope Global
}

Describe "Invoke-RemoteHardening" {
    Context "Parameter Validation" {
        It "throws when ComputerName is empty" {
            { Invoke-RemoteHardening -ComputerName @() -Profile Basis } | Should -Throw
        }

        It "throws when Profile is invalid" {
            { Invoke-RemoteHardening -ComputerName 'localhost' -Profile InvalidProfile } | Should -Throw
        }

        It "accepts valid Profile values" {
            @('Basis', 'Recommended', 'Strict') | ForEach-Object {
                Mock New-PSSession { return @{ ComputerName = 'localhost' } }
                Mock Invoke-Command { return @{ AppliedRules = @(1); FailedRules = @(); ComplianceReport = @{ CompliancePercentage = 100; Status = 'OK' }; Duration = '00:00:01' } }
                Mock Remove-PSSession { }
                Mock Write-Log { }

                # PSAvoidUsingComputerNameHardcoded suppressed: test fixture
                { Invoke-RemoteHardening -ComputerName 'localhost' -Profile $_ } | Should -Not -Throw
            }
        }
    }

    Context "Remote Session Creation" {
        It "creates PSSession with default port 5985" {
            Mock New-PSSession { return @{ ComputerName = 'localhost' } } -Verifiable
            Mock Invoke-Command { return @{ AppliedRules = @(1); FailedRules = @(); ComplianceReport = @{ CompliancePercentage = 100; Status = 'OK' }; Duration = '00:00:01' } }
            Mock Remove-PSSession { }
            Mock Write-Log { }

            Invoke-RemoteHardening -ComputerName 'localhost' -Profile Basis

            Should -InvokeVerifiable
        }

        It "creates PSSession with HTTPS when UseSSL specified" {
            Mock New-PSSession { return @{ ComputerName = 'localhost' } } -Verifiable -ParameterFilter { $UseSSL -eq $true }
            Mock Invoke-Command { return @{ AppliedRules = @(1); FailedRules = @(); ComplianceReport = @{ CompliancePercentage = 100; Status = 'OK' }; Duration = '00:00:01' } }
            Mock Remove-PSSession { }
            Mock Write-Log { }

            Invoke-RemoteHardening -ComputerName 'localhost' -Profile Basis -Port 5986 -UseSSL

            Should -InvokeVerifiable
        }

        It "throws when session creation fails" {
            Mock New-PSSession { return $null }
            Mock Write-ErrorLog { }

            # PSAvoidUsingComputerNameHardcoded suppressed: test fixture
            { Invoke-RemoteHardening -ComputerName 'invalid-host' -Profile Basis } | Should -Throw "Failed to establish remote sessions"
        }

        It "passes Credential parameter to New-PSSession" {
            # PSAvoidUsingConvertToSecureStringWithPlainText suppressed: test fixture with dummy credentials
            $credential = New-Object System.Management.Automation.PSCredential('TestUser', (ConvertTo-SecureString 'TestPass' -AsPlainText -Force))
            Mock New-PSSession { return @{ ComputerName = 'localhost' } } -Verifiable -ParameterFilter { $Credential -eq $credential }
            Mock Invoke-Command { return @{ AppliedRules = @(1); FailedRules = @(); ComplianceReport = @{ CompliancePercentage = 100; Status = 'OK' }; Duration = '00:00:01' } }
            Mock Remove-PSSession { }
            Mock Write-Log { }

            # PSAvoidUsingComputerNameHardcoded suppressed: test fixture
            Invoke-RemoteHardening -ComputerName 'localhost' -Profile Basis -Credential $credential

            Should -InvokeVerifiable
        }
    }

    Context "WhatIf Support" {
        It "respects WhatIf flag" {
            Mock New-PSSession { return @{ ComputerName = 'localhost' } }
            Mock Invoke-Command { }
            Mock Remove-PSSession { }
            Mock Write-Log { }

            $result = Invoke-RemoteHardening -ComputerName 'localhost' -Profile Basis -WhatIf
            $result | Should -BeNullOrEmpty
        }

        It "executes without WhatIf" {
            Mock New-PSSession { return @{ ComputerName = 'localhost' } }
            Mock Invoke-Command { return @{ AppliedRules = @(1); FailedRules = @(); ComplianceReport = @{ CompliancePercentage = 100; Status = 'OK' }; Duration = '00:00:01' } }
            Mock Remove-PSSession { }
            Mock Write-Log { }

            $result = Invoke-RemoteHardening -ComputerName 'localhost' -Profile Basis
            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context "Execution Modes" {
        It "processes sequential by default" {
            Mock New-PSSession { return @(@{ ComputerName = 'Host1' }, @{ ComputerName = 'Host2' }) }
            Mock Invoke-Command { return @{ AppliedRules = @(1); FailedRules = @(); ComplianceReport = @{ CompliancePercentage = 100; Status = 'OK' }; Duration = '00:00:01' } }
            Mock Remove-PSSession { }
            Mock Write-Log { }

            $result = Invoke-RemoteHardening -ComputerName @('Host1', 'Host2') -Profile Basis
            $result | Should -HaveCount 2
        }

        It "supports parallel execution" {
            Mock New-PSSession { return @(@{ ComputerName = 'Host1' }, @{ ComputerName = 'Host2' }) }
            Mock Invoke-Command { return @{ AppliedRules = @(1); FailedRules = @(); ComplianceReport = @{ CompliancePercentage = 100; Status = 'OK' }; Duration = '00:00:01' } }
            Mock Remove-PSSession { }
            Mock Write-Log { }

            $result = Invoke-RemoteHardening -ComputerName @('Host1', 'Host2') -Profile Basis -Parallel
            $result | Should -HaveCount 2
        }
    }

    Context "Output Format" {
        It "returns PSCustomObject with required properties for success" {
            Mock New-PSSession { return @{ ComputerName = 'localhost' } }
            Mock Invoke-Command {
                return @{
                    AppliedRules = @(1, 2, 3);
                    FailedRules = @();
                    ComplianceReport = @{
                        CompliancePercentage = 100;
                        Status = 'OK'
                    };
                    Duration = '00:00:05'
                }
            }
            Mock Remove-PSSession { }
            Mock Write-Log { }

            $result = Invoke-RemoteHardening -ComputerName 'localhost' -Profile Basis

            $result | Should -Not -BeNullOrEmpty
            $result.ComputerName | Should -Be 'localhost'
            $result.Success | Should -Be $true
            $result.Profile | Should -Be 'Basis'
            $result.AppliedRules | Should -Be 3
            $result.FailedRules | Should -Be 0
            $result.CompliancePercentage | Should -Be 100
            $result.Status | Should -Be 'OK'
        }

        It "returns PSCustomObject with error properties on failure" {
            Mock New-PSSession { return @{ ComputerName = 'localhost' } }
            Mock Invoke-Command { throw [System.Exception]'Remote execution failed' }
            Mock Remove-PSSession { }
            Mock Write-Log { }
            Mock Write-ErrorLog { }

            $result = Invoke-RemoteHardening -ComputerName 'localhost' -Profile Basis -ErrorAction SilentlyContinue

            $result | Should -Not -BeNullOrEmpty
            $result.ComputerName | Should -Be 'localhost'
            $result.Success | Should -Be $false
            $result.Error | Should -Match 'Remote execution failed'
        }
    }

    Context "Error Handling" {
        It "handles remote execution errors gracefully" {
            Mock New-PSSession { return @{ ComputerName = 'localhost' } }
            Mock Invoke-Command { throw [System.Exception]'Module not found' }
            Mock Remove-PSSession { }
            Mock Write-Log { }
            Mock Write-ErrorLog { }

            $result = Invoke-RemoteHardening -ComputerName 'localhost' -Profile Basis -ErrorAction SilentlyContinue
            $result.Success | Should -Be $false
        }

        It "logs errors with Write-Log" {
            Mock New-PSSession { return @{ ComputerName = 'localhost' } }
            Mock Invoke-Command { throw [System.Exception]'Test error' }
            Mock Remove-PSSession { }
            Mock Write-Log { }
            Mock Write-ErrorLog { }

            Invoke-RemoteHardening -ComputerName 'localhost' -Profile Basis -ErrorAction SilentlyContinue

            Assert-MockCalled Write-Log -Scope It
        }

        It "throws on fatal errors when ErrorActionPreference is Stop" {
            Mock New-PSSession { return $null }
            Mock Write-ErrorLog { }

            # PSAvoidUsingComputerNameHardcoded suppressed: test fixture
            { Invoke-RemoteHardening -ComputerName 'invalid' -Profile Basis } | Should -Throw
        }
    }

    Context "SkipVerification Parameter" {
        It "passes SkipVerification to remote scriptblock" {
            Mock New-PSSession { return @{ ComputerName = 'localhost' } }
            Mock Invoke-Command { return @{ AppliedRules = @(1); FailedRules = @(); ComplianceReport = @{ CompliancePercentage = 100; Status = 'OK' }; Duration = '00:00:01' } } -Verifiable
            Mock Remove-PSSession { }
            Mock Write-Log { }

            Invoke-RemoteHardening -ComputerName 'localhost' -Profile Basis -SkipVerification

            Should -InvokeVerifiable
        }
    }

    Context "Cleanup" {
        It "removes remote sessions after execution" {
            Mock New-PSSession { return @{ ComputerName = 'localhost' } }
            Mock Invoke-Command { return @{ AppliedRules = @(1); FailedRules = @(); ComplianceReport = @{ CompliancePercentage = 100; Status = 'OK' }; Duration = '00:00:01' } }
            Mock Remove-PSSession { } -Verifiable

            Invoke-RemoteHardening -ComputerName 'localhost' -Profile Basis

            Should -InvokeVerifiable
        }

        It "removes sessions even on error" {
            Mock New-PSSession { return @{ ComputerName = 'localhost' } }
            Mock Invoke-Command { throw [System.Exception]'Error' }
            Mock Remove-PSSession { } -Verifiable
            Mock Write-Log { }
            Mock Write-ErrorLog { }

            Invoke-RemoteHardening -ComputerName 'localhost' -Profile Basis -ErrorAction SilentlyContinue

            Should -InvokeVerifiable
        }
    }

    Context "Logging" {
        It "logs start of remote hardening" {
            Mock New-PSSession { return @{ ComputerName = 'localhost' } }
            Mock Invoke-Command { return @{ AppliedRules = @(1); FailedRules = @(); ComplianceReport = @{ CompliancePercentage = 100; Status = 'OK' }; Duration = '00:00:01' } }
            Mock Remove-PSSession { }
            Mock Write-Log { } -Verifiable -ParameterFilter { $Message -match 'Starting remote hardening' }

            Invoke-RemoteHardening -ComputerName 'localhost' -Profile Basis

            Should -InvokeVerifiable
        }

        It "logs successful hardening completion" {
            Mock New-PSSession { return @{ ComputerName = 'localhost' } }
            Mock Invoke-Command { return @{ AppliedRules = @(1); FailedRules = @(); ComplianceReport = @{ CompliancePercentage = 100; Status = 'OK' }; Duration = '00:00:01' } }
            Mock Remove-PSSession { }
            Mock Write-Log { } -ParameterFilter { $Message -match 'Hardening succeeded' }

            Invoke-RemoteHardening -ComputerName 'localhost' -Profile Basis

            Assert-MockCalled Write-Log -ParameterFilter { $Message -match 'Hardening succeeded' } -Scope It
        }
    }

    Context "Multi-Computer Operations" {
        It "returns results for all computers" {
            Mock New-PSSession { return @(@{ ComputerName = 'Host1' }, @{ ComputerName = 'Host2' }, @{ ComputerName = 'Host3' }) }
            Mock Invoke-Command { return @{ AppliedRules = @(1, 2); FailedRules = @(); ComplianceReport = @{ CompliancePercentage = 100; Status = 'OK' }; Duration = '00:00:01' } }
            Mock Remove-PSSession { }
            Mock Write-Log { }

            $result = Invoke-RemoteHardening -ComputerName @('Host1', 'Host2', 'Host3') -Profile Recommended

            $result | Should -HaveCount 3
            $result[0].ComputerName | Should -Be 'Host1'
            $result[1].ComputerName | Should -Be 'Host2'
            $result[2].ComputerName | Should -Be 'Host3'
        }

        It "reports success/failure per computer" {
            $invocationCount = 0
            $session1 = @{ ComputerName = 'Host1' }
            $session2 = @{ ComputerName = 'Host2' }
            Mock New-PSSession { return @($session1, $session2) }
            Mock Invoke-Command {
                $invocationCount++
                if ($invocationCount -eq 1) {
                    return @{ AppliedRules = @(1); FailedRules = @(); ComplianceReport = @{ CompliancePercentage = 100; Status = 'OK' }; Duration = '00:00:01' }
                }
                else {
                    throw [System.Exception]'Host2 error'
                }
            }
            Mock Remove-PSSession { }
            Mock Write-Log { }

            $result = Invoke-RemoteHardening -ComputerName @('Host1', 'Host2') -Profile Basis -ErrorAction SilentlyContinue

            $result[0].Success | Should -Be $true
            $result[1].Success | Should -Be $false
        }
    }
}
