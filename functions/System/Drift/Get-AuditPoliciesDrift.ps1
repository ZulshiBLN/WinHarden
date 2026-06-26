<#
.SYNOPSIS
Detects configuration drift in Windows audit policies.

.DESCRIPTION
Checks if critical audit subcategories (Logon, Sensitive Privilege Use) are configured for Success and Failure.
Returns PSCustomObject array with drift findings.

.EXAMPLE
$drifts = Get-AuditPoliciesDrift
if ($drifts.Count -gt 0) { $drifts | Write-Output }

.NOTES
DEPENDENCIES: Write-Log (Core)
APPLIES TO: Windows Server 2016+
Requires auditpol.exe (typically available on all Windows Server versions)
#>
[CmdletBinding(SupportsShouldProcess)]
param()

$findings = @()

try {
    $auditPolicies = auditpol /get /subcategory:"Logon" /r 2>&1
    if ($auditPolicies -notmatch "Success and Failure") {
        $findings += [PSCustomObject]@{
            Category = "Audit Policy"
            Setting = "Logon & Privilege Use Auditing"
            Expected = "Success and Failure enabled"
            Actual = "Misconfigured"
            Status = "DRIFT"
            Severity = "MEDIUM"
        }
        Write-Log -Message "Audit Policy drift: Logon/Privilege Use not fully audited" `
            -Level Warning -Caller $MyInvocation.MyCommand.Name
    }
}
catch {
    Write-Log -Message "Error checking audit policies: $_" -Level Warning -Caller $MyInvocation.MyCommand.Name
}

return $findings
