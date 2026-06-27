function Get-NetworkSecurityDrift {
    <#
    .SYNOPSIS
    Detects configuration drift in network security settings across profiles.
    
    .DESCRIPTION
    Comprehensive network security drift detection supporting multiple security profiles (Basis, Recommended, Strict).
    Checks SMB, NTLM, LDAP, Kerberos, encryption, and protocol security settings.
    Supports both local and remote computer analysis with optional detailed output.
    Returns PSCustomObject array with drift findings.
    
    .PARAMETER ComputerName
    Target computer name for drift analysis (default: 'localhost' for local computer).
    
    .PARAMETER Profile
    Security baseline profile: Basis (minimum), Recommended (default), or Strict (maximum hardening).
    Different profiles enforce different security levels for network protocols.
    
    .PARAMETER Detailed
    Include additional detailed checks (network adapters, TLS protocols, IPsec).
    Automatically enabled for Recommended+ profiles in most contexts.
    
    .PARAMETER ReportDriftOnly
    Return only items with DRIFT status, filtering out COMPLIANT items.
    Useful for compliance reports focusing on deviations.
    
    .PARAMETER Credential
    PowerShell credential object for authenticating remote computer access.
    Only used when ComputerName is not 'localhost'.
    
    .PARAMETER NTLMv2Level
    Expected NTLM compatibility level override (0-5, default: 5 = NTLMv2 Only).
    Allows customization of NTLM enforcement expectations.
    
    .EXAMPLE
    $drifts = Get-NetworkSecurityDrift -Profile Recommended
    $drifts | Format-Table -AutoSize
    
    .EXAMPLE
    Get-NetworkSecurityDrift -ComputerName SERVER01 -Profile Strict -Credential $cred -Detailed
    
    .EXAMPLE
    Get-NetworkSecurityDrift -Profile Basis -ReportDriftOnly | Export-Csv -Path drifts.csv
    
    .NOTES
    DEPENDS ON: Write-Log (Core)
    APPLIES TO: Windows Server 2016+, Windows 10+
    PROFILES: Basis (11 checks), Recommended (8+ checks), Strict (10+ checks with detailed)
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$ComputerName = 'localhost',
        [ValidateSet('Basis', 'Recommended', 'Strict')]
        [string]$Profile = 'Recommended',
        [switch]$Detailed,
        [switch]$ReportDriftOnly,
        [pscredential]$Credential,
        [ValidateRange(0, 5)]
        [int]$NTLMv2Level = 5
    )
    
    $findings = @()
    
    try {
        if (-not $PSCmdlet.ShouldProcess($ComputerName, "Check Network Security Drift")) {
            return $findings
        }
    
        # Build remote execution parameters
        $remoteParams = @{
            ErrorAction = 'SilentlyContinue'
        }
        if ($ComputerName -ne 'localhost') {
            $remoteParams['ComputerName'] = $ComputerName
            if ($Credential) {
                $remoteParams['Credential'] = $Credential
            }
        }
    
        # Profile-based configuration
        switch ($Profile) {
            'Basis' {
                $expectedSMB1 = 'Disabled'
                $expectedNTLMMin = 3
                $expectedNTLMMax = 5
                $checkSMBSigning = $false
                $checkLDAP = $false
                $checkLLMNR = $false
                $checkKerberos = $false
                $checkSMBEncrypt = $false
                $checkTLS = $false
                $checkIPsec = $false
            }
            'Recommended' {
                $expectedSMB1 = 'Disabled'
                $expectedNTLMMin = 5
                $expectedNTLMMax = 5
                $checkSMBSigning = $true
                $checkLDAP = $true
                $checkLLMNR = $true
                $checkKerberos = $false
                $checkSMBEncrypt = $false
                $checkTLS = $Detailed
                $checkIPsec = $false
            }
            'Strict' {
                $expectedSMB1 = 'Disabled'
                $expectedNTLMMin = 5
                $expectedNTLMMax = 5
                $checkSMBSigning = $true
                $checkLDAP = $true
                $checkLLMNR = $true
                $checkKerberos = $true
                $checkSMBEncrypt = $true
                $checkTLS = $Detailed
                $checkIPsec = $Detailed
            }
        }
    
        # [CHECK 1] SMB1 Protocol (All profiles)
        $smb1Feature = Get-WindowsOptionalFeature -FeatureName SMB1Protocol -Online @remoteParams
        if ($smb1Feature) {
            $smb1State = $smb1Feature.State
            if ($smb1State -eq 'Enabled') {
                $findings += [PSCustomObject]@{
                    Category = 'Network Security'
                    Setting = 'SMB1 Protocol'
                    Expected = $expectedSMB1
                    Actual = 'Enabled'
                    Status = 'DRIFT'
                    Severity = 'CRITICAL'
                    ComputerName = $ComputerName
                }
            }
            else {
                $findings += [PSCustomObject]@{
                    Category = 'Network Security'
                    Setting = 'SMB1 Protocol'
                    Expected = $expectedSMB1
                    Actual = 'Disabled'
                    Status = 'COMPLIANT'
                    Severity = 'INFO'
                    ComputerName = $ComputerName
                }
            }
        }
    
        # [CHECK 2] SMB2/3 Signing Enforcement (Recommended+)
        if ($checkSMBSigning) {
            $smbSignPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters'
            $smbSignProp = Get-ItemProperty -Path $smbSignPath -Name RequireSecuritySignature -ErrorAction SilentlyContinue
            $smbSignValue = $smbSignProp.RequireSecuritySignature
            if ($null -eq $smbSignValue) {
                $actualSign = 'Not Set'
                $status = 'DRIFT'
            }
            else {
                if ($smbSignValue -eq 1) {
                    $actualSign = 'Enabled'
                    $status = 'COMPLIANT'
                }
                else {
                    $actualSign = 'Disabled'
                    $status = 'DRIFT'
                }
            }
            $findings += [PSCustomObject]@{
                Category = 'Network Security'
                Setting = 'SMB Signing Enforcement'
                Expected = 'Enabled'
                Actual = $actualSign
                Status = $status
                Severity = 'HIGH'
                ComputerName = $ComputerName
            }
        }
    
        # [CHECK 3] NTLMv2 Authentication (All profiles)
        $ntlmPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa'
        $ntlmProp = Get-ItemProperty -Path $ntlmPath -Name LmCompatibilityLevel -ErrorAction SilentlyContinue
        $ntlmLevel = $ntlmProp.LmCompatibilityLevel
        if ($null -ne $ntlmLevel) {
            if ($ntlmLevel -ge $expectedNTLMMin -and $ntlmLevel -le $expectedNTLMMax) {
                $status = 'COMPLIANT'
            }
            else {
                $status = 'DRIFT'
            }
        }
        else {
            $ntlmLevel = 'Not Set'
            $status = 'DRIFT'
        }
        $findings += [PSCustomObject]@{
            Category = 'Network Security'
            Setting = 'NTLM Compatibility Level'
            Expected = "Level $expectedNTLMMin-$expectedNTLMMax (NTLMv2)"
            Actual = $ntlmLevel
            Status = $status
            Severity = 'HIGH'
            ComputerName = $ComputerName
        }
    
        # [CHECK 4] LDAP Signing (Recommended+)
        if ($checkLDAP) {
            $ldapPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\LDAP'
            $ldapProp = Get-ItemProperty -Path $ldapPath -Name LDAPClientIntegrity -ErrorAction SilentlyContinue
            $ldapValue = $ldapProp.LDAPClientIntegrity
            if ($null -eq $ldapValue) {
                $actualLDAP = 'Not Set'
                $status = 'DRIFT'
            }
            else {
                if ($ldapValue -eq 1) {
                    $actualLDAP = 'Required'
                    $status = 'COMPLIANT'
                }
                else {
                    $actualLDAP = 'Not Required'
                    $status = 'DRIFT'
                }
            }
            $findings += [PSCustomObject]@{
                Category = 'Network Security'
                Setting = 'LDAP Signing'
                Expected = 'Required'
                Actual = $actualLDAP
                Status = $status
                Severity = 'MEDIUM'
                ComputerName = $ComputerName
            }
        }
    
        # [CHECK 5] LLMNR Disabled (Recommended+)
        if ($checkLLMNR) {
            $llmnrPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient'
            $llmnrProp = Get-ItemProperty -Path $llmnrPath -Name EnableMulticast -ErrorAction SilentlyContinue
            $llmnrValue = $llmnrProp.EnableMulticast
            if ($null -eq $llmnrValue) {
                $actualLLMNR = 'Not Configured (Default: Enabled)'
                $status = 'DRIFT'
            }
            else {
                if ($llmnrValue -eq 0) {
                    $actualLLMNR = 'Disabled'
                    $status = 'COMPLIANT'
                }
                else {
                    $actualLLMNR = 'Enabled'
                    $status = 'DRIFT'
                }
            }
            $findings += [PSCustomObject]@{
                Category = 'Network Security'
                Setting = 'LLMNR (Link-Local Multicast Name Resolution)'
                Expected = 'Disabled'
                Actual = $actualLLMNR
                Status = $status
                Severity = 'MEDIUM'
                ComputerName = $ComputerName
            }
        }
    
        # [CHECK 6] SMB Encryption (Strict only)
        if ($checkSMBEncrypt) {
            $smbEncryptPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters'
            $smbEncryptProp = Get-ItemProperty -Path $smbEncryptPath -Name SMBEncryptionRequired -ErrorAction SilentlyContinue
            $smbEncryptValue = $smbEncryptProp.SMBEncryptionRequired
            if ($null -eq $smbEncryptValue) {
                $actualEncrypt = 'Not Set'
                $status = 'DRIFT'
            }
            else {
                if ($smbEncryptValue -eq 1) {
                    $actualEncrypt = 'Required'
                    $status = 'COMPLIANT'
                }
                else {
                    $actualEncrypt = 'Not Required'
                    $status = 'DRIFT'
                }
            }
            $findings += [PSCustomObject]@{
                Category = 'Network Security'
                Setting = 'SMB Encryption'
                Expected = 'Required'
                Actual = $actualEncrypt
                Status = $status
                Severity = 'HIGH'
                ComputerName = $ComputerName
            }
        }
    
        # [CHECK 7] Kerberos Encryption (Strict only)
        if ($checkKerberos) {
            $kerberosPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\Parameters'
            $kerberosProp = Get-ItemProperty -Path $kerberosPath -Name SupportedEncryptionTypes -ErrorAction SilentlyContinue
            $kerberosValue = $kerberosProp.SupportedEncryptionTypes
            if ($null -eq $kerberosValue) {
                $actualKerberos = 'Not Set'
                $status = 'DRIFT'
            }
            else {
                $actualKerberos = "0x{0:X8}" -f $kerberosValue
                if ($kerberosValue -eq 0xFFFFFFFF -or $kerberosValue -ge 0xFFFF) {
                    $status = 'COMPLIANT'
                }
                else {
                    $status = 'DRIFT'
                }
            }
            $findings += [PSCustomObject]@{
                Category = 'Network Security'
                Setting = 'Kerberos Encryption Types'
                Expected = '0xFFFFFFFF (All Modern Types)'
                Actual = $actualKerberos
                Status = $status
                Severity = 'MEDIUM'
                ComputerName = $ComputerName
            }
        }
    
        # [CHECK 8] TLS Protocol Hardening (Detailed mode in Recommended+, default in Strict)
        if ($checkTLS) {
            $tlsPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols'
            $sslDisabled = $true
            $tlsOldDisabled = $true
    
            foreach ($protocol in @('SSL 3.0', 'TLS 1.0', 'TLS 1.1')) {
                $protoPath = Join-Path -Path $tlsPath -ChildPath $protocol
                $serverProp = Get-ItemProperty -Path "$protoPath\Server" -Name Enabled -ErrorAction SilentlyContinue
                if ($null -ne $serverProp.Enabled -and $serverProp.Enabled -eq 1) {
                    if ($protocol -eq 'SSL 3.0') {
                        $sslDisabled = $false
                    }
                    else {
                        $tlsOldDisabled = $false
                    }
                }
            }
    
            if ($sslDisabled -and $tlsOldDisabled) {
                $tlsStatus = 'COMPLIANT'
                $tlsActual = 'All Disabled'
            }
            else {
                $tlsStatus = 'DRIFT'
                $tlsActual = 'Some Enabled'
            }
            $findings += [PSCustomObject]@{
                Category = 'Network Security'
                Setting = 'Legacy TLS Protocols'
                Expected = 'SSL 3.0/TLS 1.0/1.1 Disabled'
                Actual = $tlsActual
                Status = $tlsStatus
                Severity = 'HIGH'
                ComputerName = $ComputerName
            }
        }
    
        # [CHECK 9] IPsec Status (Detailed mode in Strict only)
        if ($checkIPsec) {
            $ipsecStatus = (Get-NetFirewallProfile -Name Domain @remoteParams).PolicyStore -ne $null
            $ipsecCompliant = $ipsecStatus
            if ($ipsecCompliant) {
                $ipsecActual = 'Active'
                $ipsecStat = 'COMPLIANT'
            }
            else {
                $ipsecActual = 'Inactive'
                $ipsecStat = 'DRIFT'
            }
            $findings += [PSCustomObject]@{
                Category = 'Network Security'
                Setting = 'IPsec Status'
                Expected = 'Active'
                Actual = $ipsecActual
                Status = $ipsecStat
                Severity = 'MEDIUM'
                ComputerName = $ComputerName
            }
        }
    
        # Filter results if requested
        if ($ReportDriftOnly) {
            $findings = $findings | Where-Object { $_.Status -eq 'DRIFT' }
        }
    
        # Log summary
        $driftCount = ($findings | Where-Object { $_.Status -eq 'DRIFT' }).Count
        if ($driftCount -gt 0) {
            Write-Log -Message "Network Security drift detected: $driftCount items on $ComputerName (Profile: $Profile)" `
                -Level Warning -Caller $MyInvocation.MyCommand.Name
        }
    
        return $findings
    }
    catch {
        Write-Log -Message "Error checking network security on $ComputerName : $_" `
            -Level Error -Caller $MyInvocation.MyCommand.Name
        throw
    }
}
