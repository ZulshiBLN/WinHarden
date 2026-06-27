function Get-AuditPoliciesDrift {
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
    [CmdletBinding()]
    param()

    $findings = @()

    try {
        # Check Logon audit policy
        $logonAudit = _GetAuditPolicyOutput -SubcategoryName "Logon"
        if ($logonAudit -notmatch "Success and Failure") {
            $findings += [PSCustomObject]@{
                Category = "Audit Policy"
                Setting = "Logon Auditing"
                Expected = "Success and Failure enabled"
                Actual = "Misconfigured"
                Status = "DRIFT"
                Severity = "MEDIUM"
            }
            Write-Log -Message "Audit Policy drift: Logon not fully audited" `
                -Level Warning -Caller $MyInvocation.MyCommand.Name
        }

        # Check Sensitive Privilege Use audit policy
        $privilegeAudit = _GetAuditPolicyOutput -SubcategoryName "Sensitive Privilege Use"
        if ($privilegeAudit -notmatch "Success and Failure") {
            $findings += [PSCustomObject]@{
                Category = "Audit Policy"
                Setting = "Sensitive Privilege Use Auditing"
                Expected = "Success and Failure enabled"
                Actual = "Misconfigured"
                Status = "DRIFT"
                Severity = "MEDIUM"
            }
            Write-Log -Message "Audit Policy drift: Sensitive Privilege Use not fully audited" `
                -Level Warning -Caller $MyInvocation.MyCommand.Name
        }
    }
    catch {
        Write-Log -Message "Error checking audit policies: $_" -Level Error -Caller $MyInvocation.MyCommand.Name
    }

    return $findings
}

function _GetAuditPolicyOutput {
    <#
    .SYNOPSIS
    Internal helper: Executes auditpol command and returns output.

    .PARAMETER SubcategoryName
    The audit policy subcategory name (e.g., "Logon", "Sensitive Privilege Use").
    #>
    param(
        [Parameter(Mandatory)]
        [string]$SubcategoryName
    )

    & auditpol /get /subcategory:"$SubcategoryName" /r 2>&1
}
