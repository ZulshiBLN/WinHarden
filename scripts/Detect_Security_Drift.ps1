<#
.SYNOPSIS
Detects configuration drift in Windows security hardening settings.

.DESCRIPTION
Comprehensive security drift detection script that checks multiple hardening categories:
- Account Policies (password length, complexity)
- Network Security (SMB1, NTLMv2)
- RDP Security (encryption, NLA)
- Firewall Status (all profiles enabled)
- Audit Policies (logon, privilege use)
- Windows Updates (automatic updates)
- Service Security (dangerous services disabled)

Generates and exports CSV report with detailed drift findings.

.PARAMETER OutputDirectory
Output directory for CSV report (default: logs/).

.EXAMPLE
.\Detect_Security_Drift.ps1
.\Detect_Security_Drift.ps1 -OutputDirectory "C:\Reports"

.NOTES
AUTHOR: WinHarden Team
VERSION: 1.0
REQUIRES: PowerShell 5.1+
RUN AS: SYSTEM (Highest Privileges recommended)
SCHEDULE: Weekly (e.g., Monday @ 10:00 AM via Task Scheduler)
DEPENDENCIES: Core Module (Write-Log), System Module (Drift functions)
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$OutputDirectory = "$(Split-Path $PSScriptRoot -Parent)\logs"
)

$ErrorActionPreference = "Stop"

# Load Core Module (Write-Log, validation helpers)
$corePath = Join-Path (Split-Path $PSScriptRoot -Parent) "modules\Core.psm1"
if (-not (Test-Path $corePath)) {
    Write-Error "Core module not found at: $corePath" -ErrorAction Stop
}
. $corePath

Write-Output ""
Write-Output "=============================================================="
Write-Output "     WINHARDEN CONFIGURATION DRIFT DETECTION"
Write-Output "=============================================================="
Write-Output ""
Write-Output "Start Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

$driftFindings = @()
$startTime = Get-Date

try {
    # Load Drift Detection Functions dynamically
    $driftFunctionsPath = Join-Path (Split-Path $PSScriptRoot -Parent) "functions\System\Drift"
    if (-not (Test-Path $driftFunctionsPath)) {
        throw "Drift functions directory not found at: $driftFunctionsPath"
    }

    # Required drift detection functions
    $requiredFunctions = @(
        'Get-AccountPoliciesDrift',
        'Get-NetworkSecurityDrift',
        'Get-RDPSecurityDrift',
        'Get-FirewallStatusDrift',
        'Get-AuditPoliciesDrift',
        'Get-UpdateStatusDrift',
        'Get-ServiceSecurityDrift',
        'New-SecurityDriftReport'
    )

    # Load all Get-*.ps1 files
    Get-ChildItem -Path $driftFunctionsPath -Filter "Get-*.ps1" | ForEach-Object {
        Write-Verbose "Loading drift detection function: $($_.BaseName)"
        . $_.FullName
    }

    # Load New-SecurityDriftReport helper
    $reportFuncPath = Join-Path $driftFunctionsPath "New-SecurityDriftReport.ps1"
    if (Test-Path $reportFuncPath) {
        . $reportFuncPath
    }

    # Validate that all required functions are loaded
    $missingFunctions = @()
    foreach ($funcName in $requiredFunctions) {
        if (-not (Get-Command $funcName -ErrorAction SilentlyContinue)) {
            $missingFunctions += $funcName
        }
    }

    if ($missingFunctions.Count -gt 0) {
        throw "Required drift detection functions not loaded: $($missingFunctions -join ', ')"
    }

    # [1] Account Policies
    Write-Output ""
    Write-Output "[1] CHECKING ACCOUNT POLICIES"
    Write-Output "=============================================================="
    $accountDrifts = Get-AccountPoliciesDrift
    $driftFindings += $accountDrifts
    if ($accountDrifts.Count -eq 0) {
        Write-Output "[OK] Account policies: COMPLIANT"
    }
    else {
        Write-Output "[ERROR] Account policy drift detected: $($accountDrifts.Count) issue(s)"
        $accountDrifts | Write-Output
    }

    # [2] Network Security
    Write-Output ""
    Write-Output "[2] CHECKING NETWORK SECURITY"
    Write-Output "=============================================================="
    $networkDrifts = Get-NetworkSecurityDrift
    $driftFindings += $networkDrifts
    if ($networkDrifts.Count -eq 0) {
        Write-Output "[OK] Network security: COMPLIANT"
    }
    else {
        Write-Output "[ERROR] Network security drift detected: $($networkDrifts.Count) issue(s)"
        $networkDrifts | Write-Output
    }

    # [3] RDP Security
    Write-Output ""
    Write-Output "[3] CHECKING RDP SECURITY"
    Write-Output "=============================================================="
    $rdpDrifts = Get-RDPSecurityDrift
    $driftFindings += $rdpDrifts
    if ($rdpDrifts.Count -eq 0) {
        Write-Output "[OK] RDP security: COMPLIANT"
    }
    else {
        Write-Output "[ERROR] RDP security drift detected: $($rdpDrifts.Count) issue(s)"
        $rdpDrifts | Write-Output
    }

    # [4] Firewall Status
    Write-Output ""
    Write-Output "[4] CHECKING FIREWALL STATUS"
    Write-Output "=============================================================="
    $firewallDrifts = Get-FirewallStatusDrift
    $driftFindings += $firewallDrifts
    if ($firewallDrifts.Count -eq 0) {
        Write-Output "[OK] Firewall status: COMPLIANT"
    }
    else {
        Write-Output "[ERROR] Firewall drift detected: $($firewallDrifts.Count) issue(s)"
        $firewallDrifts | Write-Output
    }

    # [5] Audit Policies
    Write-Output ""
    Write-Output "[5] CHECKING AUDIT POLICIES"
    Write-Output "=============================================================="
    $auditDrifts = Get-AuditPoliciesDrift
    $driftFindings += $auditDrifts
    if ($auditDrifts.Count -eq 0) {
        Write-Output "[OK] Audit policies: COMPLIANT"
    }
    else {
        Write-Output "[ERROR] Audit policy drift detected: $($auditDrifts.Count) issue(s)"
        $auditDrifts | Write-Output
    }

    # [6] Windows Update
    Write-Output ""
    Write-Output "[6] CHECKING WINDOWS UPDATE"
    Write-Output "=============================================================="
    $updateDrifts = Get-UpdateStatusDrift
    $driftFindings += $updateDrifts
    if ($updateDrifts.Count -eq 0) {
        Write-Output "[OK] Windows update: COMPLIANT"
    }
    else {
        Write-Output "[ERROR] Update status drift detected: $($updateDrifts.Count) issue(s)"
        $updateDrifts | Write-Output
    }

    # [7] Service Security
    Write-Output ""
    Write-Output "[7] CHECKING SERVICE SECURITY"
    Write-Output "=============================================================="
    $serviceDrifts = Get-ServiceSecurityDrift
    $driftFindings += $serviceDrifts
    if ($serviceDrifts.Count -eq 0) {
        Write-Output "[OK] Service security: COMPLIANT"
    }
    else {
        Write-Output "[ERROR] Service security drift detected: $($serviceDrifts.Count) issue(s)"
        $serviceDrifts | Write-Output
    }

    # Summary
    Write-Output ""
    Write-Output "=============================================================="
    Write-Output ""
    Write-Output "[DRIFT ANALYSIS SUMMARY]"
    Write-Output "=============================================================="
    if ($driftFindings.Count -eq 0) {
        Write-Output ""
        Write-Output "[OK] NO CONFIGURATION DRIFT DETECTED"
        Write-Output "All hardening settings are intact and active."
    }
    else {
        Write-Output ""
        Write-Output "[WARN] CONFIGURATION DRIFT DETECTED!"
        Write-Output "Found $($driftFindings.Count) settings that differ from hardening baseline."
        Write-Output ""
        Write-Output "Detailed Findings:"
        $driftFindings | Format-Table -AutoSize
    }

    # Generate Report
    Write-Output ""
    Write-Output "[REPORT OUTPUT]"
    Write-Output "=============================================================="
    $report = New-SecurityDriftReport -DriftFindings $driftFindings -OutputDirectory $OutputDirectory
    Write-Output ""
    Write-Output "[OK] Report saved: $($report.ReportPath)"
    Write-Output "Status: $($report.Status) | Drifts: $($report.DriftCount) | Severity: $($report.Severity)"

    # Action Items
    if ($driftFindings.Count -gt 0) {
        Write-Output ""
        Write-Output "[ACTION REQUIRED]"
        Write-Output "  1. Review detected drift findings above"
        Write-Output "  2. Investigate cause of changes (unauthorized or accidental)"
        Write-Output "  3. Re-apply hardening rules if necessary"
        Write-Output "  4. Document changes and approvals"
    }

    Write-Log -Message "Security drift detection completed. Status: $($report.Status) | Drifts: $($report.DriftCount)" `
        -Level Info -Caller $MyInvocation.MyCommand.Name
}
catch {
    Write-Error "Script error: $_" -ErrorAction Continue
    Write-Log -Message "Security drift detection failed: $_" -Level Error -Caller $MyInvocation.MyCommand.Name
    exit 1
}

Write-Output ""
Write-Output "End Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Output "Duration: $(((Get-Date) - $startTime).TotalSeconds) seconds"
Write-Output "=============================================================="
exit 0
