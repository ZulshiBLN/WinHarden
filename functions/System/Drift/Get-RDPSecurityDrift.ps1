<#
.SYNOPSIS
Detects configuration drift in RDP security settings (encryption, NLA).

.DESCRIPTION
Checks if RDP encryption level and Network Level Authentication match security baseline.
Returns PSCustomObject array with drift findings.

.PARAMETER MinRDPEncryptionLevel
Minimum RDP encryption level (default: 3 = High/128-bit). Levels: 1=Low, 2=Medium, 3=High.

.PARAMETER RequireNLA
Whether RDP NLA should be enabled (default: $true).

.EXAMPLE
$drifts = Get-RDPSecurityDrift
if ($drifts.Count -gt 0) { $drifts | Write-Output }

.NOTES
DEPENDENCIES: Write-Log (Core)
APPLIES TO: Windows Server 2016+ with RDP enabled
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [int]$MinRDPEncryptionLevel = 3,
    [bool]$RequireNLA = $true
)

$rdpPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
$findings = @()

try {
    # Check RDP Encryption Level
    $encProperty = Get-ItemProperty -Path $rdpPath -Name MinEncryptionLevel -ErrorAction SilentlyContinue
    $rdpEncryption = $encProperty.MinEncryptionLevel
    if ($rdpEncryption -lt $MinRDPEncryptionLevel) {
        $findings += [PSCustomObject]@{
            Category = "RDP Security"
            Setting = "Encryption Level"
            Expected = "$MinRDPEncryptionLevel (High - 128-bit)"
            Actual = "$rdpEncryption"
            Status = "DRIFT"
            Severity = "HIGH"
        }
        Write-Log -Message "RDP Security drift: Encryption level is $rdpEncryption (expected $MinRDPEncryptionLevel)" `
            -Level Warning -Caller $MyInvocation.MyCommand.Name
    }

    # Check RDP NLA
    $nlaProperty = Get-ItemProperty -Path $rdpPath -Name SecurityLayer -ErrorAction SilentlyContinue
    $rdpNLA = $nlaProperty.SecurityLayer
    $nlaEnabled = $rdpNLA -eq 2
    if ($nlaEnabled -ne $RequireNLA) {
        if ($RequireNLA) {
            $expectedNLA = "2 (Enabled)"
        }
        else {
            $expectedNLA = "1 (Disabled)"
        }
        $findings += [PSCustomObject]@{
            Category = "RDP Security"
            Setting = "Network Level Authentication"
            Expected = $expectedNLA
            Actual = "$rdpNLA"
            Status = "DRIFT"
            Severity = "HIGH"
        }
        if ($nlaEnabled) {
            $nlaStatus = 'enabled'
        }
        else {
            $nlaStatus = 'disabled'
        }
        if ($RequireNLA) {
            $nlaExpected = 'enabled'
        }
        else {
            $nlaExpected = 'disabled'
        }
        Write-Log -Message "RDP Security drift: NLA is $nlaStatus (expected $nlaExpected)" `
            -Level Warning -Caller $MyInvocation.MyCommand.Name
    }
}
catch {
    Write-Log -Message "Error checking RDP security: $_" -Level Error -Caller $MyInvocation.MyCommand.Name
    throw
}

return $findings
