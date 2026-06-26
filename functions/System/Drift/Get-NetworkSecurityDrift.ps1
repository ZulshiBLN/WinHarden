<#
.SYNOPSIS
Detects configuration drift in network security settings (SMB1, NTLMv2).

.DESCRIPTION
Checks if SMB1 protocol is disabled and NTLMv2 is enforced as per security baseline.
Returns PSCustomObject array with drift findings.

.PARAMETER NTLMv2Level
Expected NTLM compatibility level (default: 5 = NTLMv2 Only).

.EXAMPLE
$drifts = Get-NetworkSecurityDrift
if ($drifts.Count -gt 0) { $drifts | Format-Table }

.NOTES
DEPENDENCIES: Write-Log (Core)
APPLIES TO: Windows Server 2016+
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [int]$NTLMv2Level = 5
)

$findings = @()

try {
    # Check SMB1 Protocol
    $smb1Feature = Get-WindowsOptionalFeature -FeatureName SMB1Protocol -Online -ErrorAction SilentlyContinue
    $smb1Protocol = $smb1Feature.State
    if ($smb1Protocol -eq "Enabled") {
        $findings += [PSCustomObject]@{
            Category = "Network Security"
            Setting = "SMB1 Protocol"
            Expected = "Disabled"
            Actual = "Enabled"
            Status = "DRIFT"
            Severity = "CRITICAL"
        }
        Write-Log -Message "Network Security drift: SMB1 Protocol is ENABLED (should be disabled)" `
            -Level Error -Caller $MyInvocation.MyCommand.Name
    }

    # Check NTLMv2
    $ntlmPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
    $ntlmProperty = Get-ItemProperty -Path $ntlmPath -Name LmCompatibilityLevel -ErrorAction SilentlyContinue
    $ntlmLevel = $ntlmProperty.LmCompatibilityLevel
    if ($ntlmLevel -lt $NTLMv2Level) {
        $findings += [PSCustomObject]@{
            Category = "Network Security"
            Setting = "NTLM Compatibility Level"
            Expected = "$NTLMv2Level (NTLMv2 Only)"
            Actual = "$ntlmLevel"
            Status = "DRIFT"
            Severity = "HIGH"
        }
        Write-Log -Message "Network Security drift: NTLM level is $ntlmLevel (expected $NTLMv2Level)" `
            -Level Warning -Caller $MyInvocation.MyCommand.Name
    }
}
catch {
    Write-Log -Message "Error checking network security: $_" -Level Error -Caller $MyInvocation.MyCommand.Name
    throw
}

return $findings
