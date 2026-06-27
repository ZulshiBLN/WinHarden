function Get-RDPSecurityDrift {
    <#
    .SYNOPSIS
    Detects configuration drift in RDP security settings.

    .DESCRIPTION
    Comprehensive RDP security drift detection covering encryption level, NLA, port configuration,
    certificate requirements, and idle session timeout. Returns PSCustomObject array with drift findings.

    .PARAMETER MinRDPEncryptionLevel
    Minimum RDP encryption level (default: 3 = High/128-bit). Levels: 1=Low, 2=Medium, 3=High.

    .PARAMETER RequireNLA
    Whether RDP Network Level Authentication should be enabled (default: $true).

    .PARAMETER RequireCertificate
    Whether RDP certificate authentication should be required (default: $false).

    .PARAMETER MaxIdleTimeMinutes
    Maximum RDP idle timeout in minutes (default: 15). 0 means no timeout.

    .EXAMPLE
    $drifts = Get-RDPSecurityDrift
    if ($drifts.Count -gt 0) { $drifts | Write-Output }

    .EXAMPLE
    $drifts = Get-RDPSecurityDrift -MinRDPEncryptionLevel 3 -RequireNLA $true -MaxIdleTimeMinutes 10

    .NOTES
    DEPENDENCIES: Write-Log (Core)
    APPLIES TO: Windows Server 2016+ with RDP enabled
    #>
    param(
        [ValidateRange(1, 3)]
        [int]$MinRDPEncryptionLevel = 3,

        [bool]$RequireNLA = $true,

        [bool]$RequireCertificate = $false,

        [ValidateRange(0, 1440)]
        [int]$MaxIdleTimeMinutes = 15
    )

    $rdpPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
    $tsPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server"
    $findings = @()
    
    try {
        # Check RDP Service enabled
        $rdpEnabled = (Get-ItemProperty -Path $tsPath -Name fDenyTSConnections -ErrorAction SilentlyContinue).fDenyTSConnections
        if ($rdpEnabled -eq 1) {
            $findings += [PSCustomObject]@{
                Category = "RDP Security"
                Setting = "RDP Service Enabled"
                Expected = "Enabled"
                Actual = "Disabled"
                Status = "DRIFT"
                Severity = "HIGH"
            }
            Write-Log -Message "RDP Security drift: RDP service is disabled" -Level Warning -Caller $MyInvocation.MyCommand.Name
        }
    
        # Check RDP Encryption Level
        $encProperty = Get-ItemProperty -Path $rdpPath -Name MinEncryptionLevel -ErrorAction SilentlyContinue
        $rdpEncryption = $encProperty.MinEncryptionLevel
        if ($null -eq $rdpEncryption) {
            $rdpEncryption = 1
        }
        if ($rdpEncryption -lt $MinRDPEncryptionLevel) {
            $encLevelNames = @{ 1 = "Low"; 2 = "Medium"; 3 = "High (128-bit)" }
            $findings += [PSCustomObject]@{
                Category = "RDP Security"
                Setting = "Encryption Level"
                Expected = "$MinRDPEncryptionLevel ($($encLevelNames[$MinRDPEncryptionLevel]))"
                Actual = "$rdpEncryption ($($encLevelNames[$rdpEncryption]))"
                Status = "DRIFT"
                Severity = "HIGH"
            }
            Write-Log -Message "RDP Security drift: Encryption level is $rdpEncryption (expected $MinRDPEncryptionLevel)" -Level Warning -Caller $MyInvocation.MyCommand.Name
        }
    
        # Check RDP NLA
        $nlaProperty = Get-ItemProperty -Path $rdpPath -Name SecurityLayer -ErrorAction SilentlyContinue
        $rdpNLA = $nlaProperty.SecurityLayer
        if ($null -eq $rdpNLA) {
            $rdpNLA = 1
        }
        $nlaEnabled = $rdpNLA -eq 2
        if ($nlaEnabled -ne $RequireNLA) {
            $expectedNLA = if ($RequireNLA) {
                "2 (Enabled)"
            }
            else {
                "1 (Disabled)"
            }
            $nlaStatus = if ($nlaEnabled) {
                'enabled'
            }
            else {
                'disabled'
            }
            $nlaExpected = if ($RequireNLA) {
                'enabled'
            }
            else {
                'disabled'
            }
            $findings += [PSCustomObject]@{
                Category = "RDP Security"
                Setting = "Network Level Authentication"
                Expected = $expectedNLA
                Actual = "$rdpNLA ($nlaStatus)"
                Status = "DRIFT"
                Severity = "HIGH"
            }
            Write-Log -Message "RDP Security drift: NLA is $nlaStatus (expected $nlaExpected)" -Level Warning -Caller $MyInvocation.MyCommand.Name
        }
    
        # Check RDP Port
        $portProperty = Get-ItemProperty -Path $rdpPath -Name PortNumber -ErrorAction SilentlyContinue
        $rdpPort = $portProperty.PortNumber
        if ($null -eq $rdpPort) {
            $rdpPort = 3389
        }
        if ($rdpPort -ne 3389) {
            $findings += [PSCustomObject]@{
                Category = "RDP Security"
                Setting = "RDP Port"
                Expected = "3389 (Standard)"
                Actual = "$rdpPort (Non-standard)"
                Status = "DRIFT"
                Severity = "MEDIUM"
            }
            Write-Log -Message "RDP Security drift: RDP port is $rdpPort (expected 3389)" -Level Warning -Caller $MyInvocation.MyCommand.Name
        }
    
        # Check RDP Certificate requirement
        $certProperty = Get-ItemProperty -Path $rdpPath -Name SSLCertificateSHA1Hash -ErrorAction SilentlyContinue
        $hasCert = -not [string]::IsNullOrEmpty($certProperty.SSLCertificateSHA1Hash)
        if ($RequireCertificate -and -not $hasCert) {
            $findings += [PSCustomObject]@{
                Category = "RDP Security"
                Setting = "SSL Certificate"
                Expected = "Configured"
                Actual = "Not Configured"
                Status = "DRIFT"
                Severity = "MEDIUM"
            }
            Write-Log -Message "RDP Security drift: SSL certificate not configured" -Level Warning -Caller $MyInvocation.MyCommand.Name
        }
    
        # Check Idle Session Timeout
        $idleProperty = Get-ItemProperty -Path $rdpPath -Name MaxIdleTime -ErrorAction SilentlyContinue
        $maxIdleMs = $idleProperty.MaxIdleTime
        if ($null -eq $maxIdleMs) {
            $maxIdleMs = 0
        }
        $maxIdleMin = [math]::Floor($maxIdleMs / 60000)
        if ($MaxIdleTimeMinutes -gt 0 -and ($maxIdleMs -eq 0 -or $maxIdleMin -gt $MaxIdleTimeMinutes)) {
            $actualStatus = if ($maxIdleMs -eq 0) {
                "No timeout"
            }
            else {
                "$maxIdleMin minutes"
            }
            $findings += [PSCustomObject]@{
                Category = "RDP Security"
                Setting = "Idle Session Timeout"
                Expected = "$MaxIdleTimeMinutes minutes"
                Actual = $actualStatus
                Status = "DRIFT"
                Severity = "LOW"
            }
            Write-Log -Message "RDP Security drift: Idle timeout is $actualStatus (expected $MaxIdleTimeMinutes min)" -Level Warning -Caller $MyInvocation.MyCommand.Name
        }
    }
    catch {
        Write-Log -Message "Error checking RDP security: $_" -Level Error -Caller $MyInvocation.MyCommand.Name
        throw
    }
    
    return $findings
}
