<#
.SYNOPSIS
Detects configuration drift in dangerous Windows services.

.DESCRIPTION
Checks if risky services (e.g., Print Spooler) are disabled per security baseline.
Returns PSCustomObject array with drift findings.

.PARAMETER DangerousServices
Array of service names that should be disabled (default: @('Spooler')).

.EXAMPLE
$drifts = Get-ServiceSecurityDrift
if ($drifts.Count -gt 0) { $drifts | Write-Output }

.NOTES
DEPENDENCIES: Write-Log (Core)
APPLIES TO: Windows Server 2016+
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string[]]$DangerousServices = @('Spooler')
)

$findings = @()

try {
    foreach ($serviceName in $DangerousServices) {
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if ($null -ne $service -and $service.StartType -ne "Disabled") {
            $findings += [PSCustomObject]@{
                Category = "Services"
                Setting = "$serviceName Service"
                Expected = "Disabled"
                Actual = "$($service.StartType)"
                Status = "DRIFT"
                Severity = "MEDIUM"
            }
            Write-Log -Message "Service Security drift detected: $serviceName is $($service.StartType) (should be Disabled)" `
                -Level Warning -Caller $MyInvocation.MyCommand.Name
        }
    }
}
catch {
    Write-Log -Message "Error checking service security: $_" -Level Error -Caller $MyInvocation.MyCommand.Name
    throw
}

return $findings
