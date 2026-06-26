@{
    Profile = @{
        Name = 'Strict'
        Description = 'Strict security hardening for maximum security in sensitive environments'
        Severity = 'Critical'
        Version = '1.0.0'
        LastUpdated = '2026-06-27'
        InheritsFrom = 'Recommended'
    }

    Rules = @(
        # Include all Recommended rules (21 rules)
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
            Name = 'Account-AccountLockoutDuration'
            Description = 'Set account lockout duration to 15 minutes'
            Category = 'Account.Policy'
            Severity = 'High'
            Type = 'Registry'
            OSSupport = @{
                'Client' = @(11)
                'Server' = @(2019, 2022, 2025)
            }
            RuleDefinition = @{
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters'
                Name = 'LockoutDuration'
                Value = 15
                ValueType = 'DWord'
            }
            Verification = @{
                Command = 'Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" -Name LockoutDuration -ErrorAction SilentlyContinue'
                Expected = 15
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
            Name = 'Firewall-DisableICMPEcho'
            Description = 'Disable ICMP echo requests'
            Category = 'Firewall.Policy'
            Severity = 'Medium'
            Type = 'Firewall'
            OSSupport = @{
                'Client' = @(11)
                'Server' = @(2019, 2022, 2025)
            }
            RuleDefinition = @{
                Name = 'Disable ICMP Echo'
                Direction = 'Inbound'
                Protocol = 'ICMPv4'
                IcmpType = 8
                Action = 'Block'
            }
            Verification = @{
                Command = 'Get-NetFirewallRule -Name "Disable ICMP Echo" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Enabled'
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
            Name = 'Service-DisableUnnecessaryServices'
            Description = 'Disable unnecessary services (WinRM, Telnet, etc.)'
            Category = 'Service.Hardening'
            Severity = 'High'
            Type = 'Service'
            OSSupport = @{
                'Client' = @(11)
                'Server' = @(2019, 2022, 2025)
            }
            RuleDefinition = @{
                Services = @('WinRM', 'TlntSvr', 'irmon')
                StartType = 'Disabled'
            }
            Verification = @{
                Command = 'Get-Service -Name WinRM, TlntSvr, irmon -ErrorAction SilentlyContinue | Select-Object -ExpandProperty StartType'
                Expected = @('Disabled', 'Disabled', 'Disabled')
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
            Name = 'Registry-EnableDEP'
            Description = 'Enable Data Execution Prevention (DEP)'
            Category = 'Registry.Hardening'
            Severity = 'High'
            Type = 'Registry'
            OSSupport = @{
                'Client' = @(11)
                'Server' = @(2019, 2022, 2025)
            }
            RuleDefinition = @{
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'
                Name = 'NullPageProtection'
                Value = 1
                ValueType = 'DWord'
            }
            Verification = @{
                Command = 'Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name NullPageProtection -ErrorAction SilentlyContinue'
                Expected = 1
            }
        }

        @{
            Name = 'Registry-EnforceSMBSigning'
            Description = 'Enforce SMB2/3 signing'
            Category = 'SMB.Hardening'
            Severity = 'High'
            Type = 'Registry'
            OSSupport = @{
                'Client' = @(11)
                'Server' = @(2019, 2022, 2025)
            }
            RuleDefinition = @{
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters'
                Name = 'RequireSecuritySignature'
                Value = 1
                ValueType = 'DWord'
            }
            Verification = @{
                Command = 'Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name RequireSecuritySignature -ErrorAction SilentlyContinue'
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
            Name = 'RDP-SetEncryptionLevel'
            Description = 'Set RDP encryption level to high'
            Category = 'RDP.Security'
            Severity = 'High'
            Type = 'Registry'
            OSSupport = @{
                'Client' = @(11)
                'Server' = @(2019, 2022, 2025)
            }
            RuleDefinition = @{
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp'
                Name = 'MinEncryptionLevel'
                Value = 3
                ValueType = 'DWord'
            }
            Verification = @{
                Command = 'Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name MinEncryptionLevel -ErrorAction SilentlyContinue'
                Expected = 3
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
                Type = 'RegistryMultiple'
                Paths = @(
                    'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0\Client',
                    'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0\Client',
                    'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1\Client'
                )
                PropertyName = 'Enabled'
                ExpectedValues = @(0, 0, 0)
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
            Name = 'Network-DisableIPSourceRouting'
            Description = 'Disable IP source routing'
            Category = 'Network.Security'
            Severity = 'Medium'
            Type = 'Registry'
            OSSupport = @{
                'Client' = @(11)
                'Server' = @(2019, 2022, 2025)
            }
            RuleDefinition = @{
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters'
                Name = 'DisableIPSourceRouting'
                Value = 2
                ValueType = 'DWord'
            }
            Verification = @{
                Command = 'Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name DisableIPSourceRouting -ErrorAction SilentlyContinue'
                Expected = 2
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
            Name = 'Audit-EnablePrivilegeUseAuditing'
            Description = 'Enable privilege use auditing'
            Category = 'Audit.Policy'
            Severity = 'Medium'
            Type = 'Audit'
            OSSupport = @{
                'Client' = @(11)
                'Server' = @(2019, 2022, 2025)
            }
            RuleDefinition = @{
                Category = 'Privilege Use'
                Success = $true
                Failure = $true
            }
            Verification = @{
                Command = 'auditpol /get /category:"Privilege Use" | Select-String "Success and Failure"'
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

        @{
            Name = 'Registry-EnforceNTLMv2'
            Description = 'Enforce NTLMv2 authentication'
            Category = 'Account.Policy'
            Severity = 'High'
            Type = 'Registry'
            OSSupport = @{
                'Client' = @(11)
                'Server' = @(2019, 2022, 2025)
            }
            RuleDefinition = @{
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa'
                Name = 'LmCompatibilityLevel'
                Value = 5
                ValueType = 'DWord'
            }
            Verification = @{
                Command = 'Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name LmCompatibilityLevel -ErrorAction SilentlyContinue'
                Expected = 5
            }
        }

        # Strict-specific rules (15 additional rules)
        @{
            Name = 'Account-MinimumPasswordLength-Strict'
            Description = 'Set minimum password length to 14 characters for Strict profile'
            Category = 'Account.Policy'
            Severity = 'Critical'
            Type = 'Registry'
            OSSupport = @{
                'Client' = @(11)
                'Server' = @(2019, 2022, 2025)
            }
            RuleDefinition = @{
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters'
                Name = 'RequiredPasswordLength'
                Value = 14
                ValueType = 'DWord'
            }
            Verification = @{
                Command = 'Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" -Name RequiredPasswordLength -ErrorAction SilentlyContinue'
                Expected = 14
            }
        }

        @{
            Name = 'Account-StrictAccountLockout'
            Description = 'Enforce strict account lockout (5 attempts, 30 min lockout)'
            Category = 'Account.Policy'
            Severity = 'Critical'
            Type = 'Registry'
            OSSupport = @{
                'Client' = @(11)
                'Server' = @(2019, 2022, 2025)
            }
            RuleDefinition = @{
                LockoutThreshold = 5
                LockoutDuration = 30
                LockoutWindow = 15
            }
            Verification = @{
                Command = 'Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters" | Select-Object BadPwdCount, LockoutDuration'
                Expected = @{ BadPwdCount = 5; LockoutDuration = 30 }
            }
        }

        @{
            Name = 'Firewall-StrictInboundPolicy'
            Description = 'Set firewall inbound policy to block all by default (explicit allow only)'
            Category = 'Firewall.Policy'
            Severity = 'Critical'
            Type = 'Firewall'
            OSSupport = @{
                'Client' = @(11)
                'Server' = @(2019, 2022, 2025)
            }
            RuleDefinition = @{
                Profiles = @('Domain', 'Private', 'Public')
                DefaultInboundAction = 'Block'
                DefaultOutboundAction = 'Allow'
            }
            Verification = @{
                Command = 'Get-NetFirewallProfile | Select-Object -ExpandProperty DefaultInboundAction'
                Expected = 'Block'
            }
        }

        @{
            Name = 'Encryption-EnableBitLocker'
            Description = 'Enable BitLocker for OS drive (Client) or all drives (Server)'
            Category = 'Encryption.Policy'
            Severity = 'Critical'
            Type = 'Encryption'
            OSSupport = @{
                'Client' = @(11)
                'Server' = @(2019, 2022, 2025)
            }
            RuleDefinition = @{
                DriveType = 'OS'
                EncryptionMethod = 'AES256'
                RequireTPM = $true
            }
            Verification = @{
                Command = 'Get-BitLockerVolume -MountPoint C: -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ProtectionStatus'
                Expected = 'On'
            }
        }

        @{
            Name = 'Encryption-DisableTLSBelowOnePointTwo'
            Description = 'Completely disable all TLS versions below 1.2'
            Category = 'Encryption.Policy'
            Severity = 'Critical'
            Type = 'Registry'
            OSSupport = @{
                'Client' = @(11)
                'Server' = @(2019, 2022, 2025)
            }
            RuleDefinition = @{
                DisabledProtocols = @('SSL3.0', 'TLS1.0', 'TLS1.1')
                ClientSide = $true
                ServerSide = $true
            }
            Verification = @{
                Command = 'Get-ChildItem -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols" | Select-Object -ExpandProperty PSChildName'
                Expected = @('SSL 3.0', 'TLS 1.0', 'TLS 1.1')
            }
        }

        @{
            Name = 'RDP-DisableClipboardRedirection'
            Description = 'Disable RDP clipboard redirection in strict mode'
            Category = 'RDP.Security'
            Severity = 'High'
            Type = 'Registry'
            OSSupport = @{
                'Client' = @(11)
                'Server' = @(2019, 2022, 2025)
            }
            RuleDefinition = @{
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
                Name = 'fDisableClip'
                Value = 1
                ValueType = 'DWord'
            }
            Verification = @{
                Command = 'Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -Name fDisableClip -ErrorAction SilentlyContinue'
                Expected = 1
            }
        }

        @{
            Name = 'RDP-DisableDriveRedirection'
            Description = 'Disable RDP drive redirection'
            Category = 'RDP.Security'
            Severity = 'High'
            Type = 'Registry'
            OSSupport = @{
                'Client' = @(11)
                'Server' = @(2019, 2022, 2025)
            }
            RuleDefinition = @{
                Path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services'
                Name = 'fDisableCdm'
                Value = 1
                ValueType = 'DWord'
            }
            Verification = @{
                Command = 'Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -Name fDisableCdm -ErrorAction SilentlyContinue'
                Expected = 1
            }
        }

        @{
            Name = 'RDP-RandomizePort'
            Description = 'Randomize RDP listening port'
            Category = 'RDP.Security'
            Severity = 'Medium'
            Type = 'Registry'
            OSSupport = @{
                'Client' = @(11)
                'Server' = @(2019, 2022, 2025)
            }
            RuleDefinition = @{
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp'
                Name = 'PortNumber'
                Value = 3399
                ValueType = 'DWord'
            }
            Verification = @{
                Command = 'Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name PortNumber -ErrorAction SilentlyContinue'
                Expected = 3399
            }
        }

        @{
            Name = 'SMB-RequireSigning'
            Description = 'Require SMB signing on all communications'
            Category = 'SMB.Hardening'
            Severity = 'Critical'
            Type = 'Registry'
            OSSupport = @{
                'Client' = @(11)
                'Server' = @(2019, 2022, 2025)
            }
            RuleDefinition = @{
                ClientRequire = 1
                ServerRequire = 1
            }
            Verification = @{
                Command = @"
`$client = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name RequireSecuritySignature -ErrorAction SilentlyContinue
`$server = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name RequireSecuritySignature -ErrorAction SilentlyContinue
@(`$client.RequireSecuritySignature, `$server.RequireSecuritySignature)
"@
                Expected = @(1, 1)
            }
        }

        @{
            Name = 'Service-MinimalServices'
            Description = 'Disable additional services beyond Recommended'
            Category = 'Service.Hardening'
            Severity = 'High'
            Type = 'Service'
            OSSupport = @{
                'Client' = @(11)
                'Server' = @(2019, 2022, 2025)
            }
            RuleDefinition = @{
                Services = @('Netlogon', 'SNMP', 'SNMPTRAP', 'WMIC')
                StartType = 'Disabled'
            }
            Verification = @{
                Command = 'Get-Service -Name Netlogon, SNMP, SNMPTRAP, WMIC -ErrorAction SilentlyContinue | Select-Object -ExpandProperty StartType'
                Expected = @('Disabled', 'Disabled', 'Disabled', 'Disabled')
            }
        }

        @{
            Name = 'UAC-AllChecksEnabled'
            Description = 'Enable all UAC checks including app installations'
            Category = 'UAC.Policy'
            Severity = 'High'
            Type = 'Registry'
            OSSupport = @{
                'Client' = @(11)
                'Server' = @(2019, 2022, 2025)
            }
            RuleDefinition = @{
                EnableLUA = 1
                PromptOnSecureDesktop = 1
                ConsentPromptBehaviorAdmin = 2
                DetectInstalledUAC = 1
            }
            Verification = @{
                Command = @"
`$path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
Get-ItemProperty -Path `$path | Select-Object EnableLUA, PromptOnSecureDesktop, ConsentPromptBehaviorAdmin
"@
                Expected = @{ EnableLUA = 1; PromptOnSecureDesktop = 1; ConsentPromptBehaviorAdmin = 2 }
            }
        }

        @{
            Name = 'Audit-ExtendedLogging'
            Description = 'Enable extended audit logging for sensitive operations'
            Category = 'Audit.Policy'
            Severity = 'High'
            Type = 'Audit'
            OSSupport = @{
                'Client' = @(11)
                'Server' = @(2019, 2022, 2025)
            }
            RuleDefinition = @{
                Categories = @('Account Logon', 'Logon/Logoff', 'Object Access', 'Privilege Use', 'Detailed Tracking')
                Success = $true
                Failure = $true
            }
            Verification = @{
                Command = 'auditpol /get /category:* | Select-String "Success and Failure" | Measure-Object -Line'
                Expected = 5
            }
        }

        @{
            Name = 'Registry-DisableAutorun'
            Description = 'Disable Autorun for all drives'
            Category = 'Registry.Hardening'
            Severity = 'High'
            Type = 'Registry'
            OSSupport = @{
                'Client' = @(11)
                'Server' = @(2019, 2022, 2025)
            }
            RuleDefinition = @{
                Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'
                Name = 'NoDriveTypeAutoRun'
                Value = 255
                ValueType = 'DWord'
            }
            Verification = @{
                Command = 'Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name NoDriveTypeAutoRun -ErrorAction SilentlyContinue'
                Expected = 255
            }
        }

        @{
            Name = 'Network-DisableICMPRedirects'
            Description = 'Disable ICMP redirects'
            Category = 'Network.Security'
            Severity = 'Medium'
            Type = 'Registry'
            OSSupport = @{
                'Client' = @(11)
                'Server' = @(2019, 2022, 2025)
            }
            RuleDefinition = @{
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters'
                Name = 'EnableICMPRedirect'
                Value = 0
                ValueType = 'DWord'
            }
            Verification = @{
                Command = 'Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name EnableICMPRedirect -ErrorAction SilentlyContinue'
                Expected = 0
            }
        }

        @{
            Name = 'Registry-CredentialGuard-Server'
            Description = 'Enable Credential Guard for Servers (virtualization-based security)'
            Category = 'Registry.Hardening'
            Severity = 'High'
            Type = 'Registry'
            OSSupport = @{
                'Server' = @(2019, 2022, 2025)
            }
            RuleDefinition = @{
                Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa'
                Name = 'LsaCfgFlags'
                Value = 1
                ValueType = 'DWord'
            }
            Verification = @{
                Command = 'Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name LsaCfgFlags -ErrorAction SilentlyContinue'
                Expected = 1
            }
        }
    )
}
