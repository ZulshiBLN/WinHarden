@{
    Profile = @{
        Name = 'Strict'
        Description = 'Strict security hardening for maximum security in sensitive environments'
        Severity = 'Critical'
        Version = '1.0.0'
        LastUpdated = '2026-06-26'
        InheritsFrom = 'Recommended'
    }

    Rules = @(
        # All Recommended rules plus additional strict rules
        # (Copy all Recommended rules here, then add the following strict-only rules)

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
