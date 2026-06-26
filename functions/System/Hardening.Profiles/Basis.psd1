@{
    Profile = @{
        Name = 'Basis'
        Description = 'Basic security hardening with minimum security requirements'
        Severity = 'Medium'
        Version = '1.0.0'
        LastUpdated = '2026-06-26'
    }

    Rules = @(
        @{
            Name = 'Account-MinimumPasswordLength'
            Description = 'Set minimum password length to 12 characters'
            Category = 'Account.Policy'
            Severity = 'High'
            Type = 'Registry'
            OSSupport = @{
                'Client' = @(11)
                'Server' = @(2019, 2022, 2025)
            }
            RuleDefinition = @{
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters'
                Name = 'RequiredPasswordLength'
                Value = 12
                ValueType = 'DWord'
            }
            Verification = @{
                Command = 'Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" -Name RequiredPasswordLength -ErrorAction SilentlyContinue'
                Expected = 12
            }
        }

        @{
            Name = 'Account-PasswordComplexity'
            Description = 'Enable password complexity requirements'
            Category = 'Account.Policy'
            Severity = 'High'
            Type = 'Registry'
            OSSupport = @{
                'Client' = @(11)
                'Server' = @(2019, 2022, 2025)
            }
            RuleDefinition = @{
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters'
                Name = 'PasswordComplexity'
                Value = 1
                ValueType = 'DWord'
            }
            Verification = @{
                Command = 'Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" -Name PasswordComplexity -ErrorAction SilentlyContinue'
                Expected = 1
            }
        }

        @{
            Name = 'Firewall-EnableWindowsDefender'
            Description = 'Enable Windows Defender Firewall on all profiles'
            Category = 'Firewall.Policy'
            Severity = 'Critical'
            Type = 'Firewall'
            OSSupport = @{
                'Client' = @(11)
                'Server' = @(2019, 2022, 2025)
            }
            RuleDefinition = @{
                Profiles = @('Domain', 'Private', 'Public')
                Enabled = $true
            }
            Verification = @{
                Command = 'Get-NetFirewallProfile | Select-Object -ExpandProperty Enabled'
                Expected = $true
            }
        }

        @{
            Name = 'Service-DisableSMB1'
            Description = 'Disable SMB v1 protocol'
            Category = 'SMB.Hardening'
            Severity = 'Critical'
            Type = 'Service'
            OSSupport = @{
                'Client' = @(11)
                'Server' = @(2019, 2022, 2025)
            }
            RuleDefinition = @{
                FeatureName = 'SMB1Protocol'
                State = 'Disabled'
            }
            Verification = @{
                Command = 'Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -ErrorAction SilentlyContinue | Select-Object -ExpandProperty State'
                Expected = 'Disabled'
            }
        }

        @{
            Name = 'UAC-ElevationPrompt'
            Description = 'Enable UAC elevation prompt for administrators'
            Category = 'UAC.Policy'
            Severity = 'High'
            Type = 'Registry'
            OSSupport = @{
                'Client' = @(11)
                'Server' = @(2019, 2022, 2025)
            }
            RuleDefinition = @{
                Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
                Name = 'PromptOnSecureDesktop'
                Value = 1
                ValueType = 'DWord'
            }
            Verification = @{
                Command = 'Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name PromptOnSecureDesktop -ErrorAction SilentlyContinue'
                Expected = 1
            }
        }

        @{
            Name = 'RDP-EnableNetworkLevelAuthentication'
            Description = 'Enable Network Level Authentication for RDP'
            Category = 'RDP.Security'
            Severity = 'High'
            Type = 'Registry'
            OSSupport = @{
                'Client' = @(11)
                'Server' = @(2019, 2022, 2025)
            }
            RuleDefinition = @{
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp'
                Name = 'SecurityLayer'
                Value = 2
                ValueType = 'DWord'
            }
            Verification = @{
                Command = 'Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name SecurityLayer -ErrorAction SilentlyContinue'
                Expected = 2
            }
        }

        @{
            Name = 'Encryption-DisableObsoleteCiphers'
            Description = 'Disable obsolete cipher suites and enforce TLS 1.2 minimum'
            Category = 'Encryption.Policy'
            Severity = 'High'
            Type = 'Registry'
            OSSupport = @{
                'Client' = @(11)
                'Server' = @(2019, 2022, 2025)
            }
            RuleDefinition = @{
                RegKeys = @(
                    @{
                        Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client'
                        Name = 'Enabled'
                        Value = 0
                    },
                    @{
                        Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client'
                        Name = 'Enabled'
                        Value = 0
                    },
                    @{
                        Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client'
                        Name = 'Enabled'
                        Value = 0
                    }
                )
            }
            Verification = @{
                Command = @"
                `$paths = @(
                    'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client',
                    'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client',
                    'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client'
                )
                `$results = @()
                foreach (`$path in `$paths) {
                    `$results += Get-ItemProperty -Path `$path -Name Enabled -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Enabled
                }
                `$results
"@
                Expected = @(0, 0, 0)
            }
        }

        @{
            Name = 'Network-DisableIPv6'
            Description = 'Disable IPv6 if not required'
            Category = 'Network.Security'
            Severity = 'Low'
            Type = 'Registry'
            OSSupport = @{
                'Client' = @(11)
                'Server' = @(2019, 2022, 2025)
            }
            RuleDefinition = @{
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\TCPIP6\Parameters'
                Name = 'DisabledComponents'
                Value = 255
                ValueType = 'DWord'
            }
            Verification = @{
                Command = 'Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\TCPIP6\Parameters" -Name DisabledComponents -ErrorAction SilentlyContinue'
                Expected = 255
            }
        }

        @{
            Name = 'Updates-EnableAutoSecurityUpdates'
            Description = 'Enable automatic security updates'
            Category = 'Update.Policy'
            Severity = 'Critical'
            Type = 'Registry'
            OSSupport = @{
                'Client' = @(11)
                'Server' = @(2019, 2022, 2025)
            }
            RuleDefinition = @{
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
                Name = 'NoAutoUpdate'
                Value = 0
                ValueType = 'DWord'
            }
            Verification = @{
                Command = 'Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name NoAutoUpdate -ErrorAction SilentlyContinue'
                Expected = 0
            }
        }

        @{
            Name = 'Audit-EnableLogonAuditing'
            Description = 'Enable logon/logoff auditing'
            Category = 'Audit.Policy'
            Severity = 'Medium'
            Type = 'Audit'
            OSSupport = @{
                'Client' = @(11)
                'Server' = @(2019, 2022, 2025)
            }
            RuleDefinition = @{
                Category = 'Logon/Logoff'
                Success = $true
                Failure = $true
            }
            Verification = @{
                Command = 'auditpol /get /category:"Logon/Logoff" | Select-String "Success and Failure"'
                Expected = 'Success and Failure'
            }
        }

        @{
            Name = 'Registry-DisableLLMNR'
            Description = 'Disable LLMNR protocol'
            Category = 'Network.Security'
            Severity = 'Medium'
            Type = 'Registry'
            OSSupport = @{
                'Client' = @(11)
                'Server' = @(2019, 2022, 2025)
            }
            RuleDefinition = @{
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient'
                Name = 'EnableMulticast'
                Value = 0
                ValueType = 'DWord'
            }
            Verification = @{
                Command = 'Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -Name EnableMulticast -ErrorAction SilentlyContinue'
                Expected = 0
            }
        }

        @{
            Name = 'Service-DisablePrintSpooler'
            Description = 'Disable Print Spooler service if not required'
            Category = 'Service.Hardening'
            Severity = 'Medium'
            Type = 'Service'
            OSSupport = @{
                'Client' = @(11)
                'Server' = @(2019, 2022, 2025)
            }
            RuleDefinition = @{
                ServiceName = 'spooler'
                StartType = 'Disabled'
            }
            Verification = @{
                Command = 'Get-Service -Name spooler -ErrorAction SilentlyContinue | Select-Object -ExpandProperty StartType'
                Expected = 'Disabled'
            }
        }
    )
}
