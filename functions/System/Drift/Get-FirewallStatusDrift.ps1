<#
.SYNOPSIS
Detects configuration drift in Windows Firewall settings.

.DESCRIPTION
Checks if all firewall profiles (Domain, Private, Public) are enabled.
Returns PSCustomObject array with drift findings.

.PARAMETER RequireAllProfilesEnabled
Whether all firewall profiles should be enabled (default: $true).

.EXAMPLE
$drifts = Get-FirewallStatusDrift
if ($drifts.Count -gt 0) { $drifts | Write-Output }

.NOTES
DEPENDENCIES: Write-Log (Core)
APPLIES TO: Windows Server 2016+
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [bool]$RequireAllProfilesEnabled = $true
)

$findings = @()

try {
    $domainFW = (Get-NetFirewallProfile -Name Domain -ErrorAction SilentlyContinue).Enabled
    $privateFW = (Get-NetFirewallProfile -Name Private -ErrorAction SilentlyContinue).Enabled
    $publicFW = (Get-NetFirewallProfile -Name Public -ErrorAction SilentlyContinue).Enabled

    $anyDisabled = -not $domainFW -or -not $privateFW -or -not $publicFW

    if ($anyDisabled -eq $RequireAllProfilesEnabled) {
        $findings += [PSCustomObject]@{
            Category = "Firewall"
            Setting = "Firewall Profiles"
            Expected = "All Enabled"
            Actual = "Domain:$domainFW, Private:$privateFW, Public:$publicFW"
            Status = "DRIFT"
            Severity = "HIGH"
        }
        Write-Log -Message "Firewall drift detected: Not all profiles enabled. Domain=$domainFW, Private=$privateFW, Public=$publicFW" `
            -Level Warning -Caller $MyInvocation.MyCommand.Name
    }
}
catch {
    Write-Log -Message "Error checking firewall status: $_" -Level Error -Caller $MyInvocation.MyCommand.Name
    throw
}

return $findings
