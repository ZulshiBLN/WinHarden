<#
.SYNOPSIS
Monitors Windows Update status and generates monitoring reports.

.DESCRIPTION
Comprehensive Windows Update monitoring script that checks available updates,
auto-update configuration, installation history, and reboot status.
Generates CSV reports and logs all findings through central logging system.

.PARAMETER OutputDir
Output directory for CSV reports (default: logs/).

.PARAMETER WhatIf
Show what would be done without making changes.

.EXAMPLE
.\Monitor_Windows_Updates.ps1
.\Monitor_Windows_Updates.ps1 -OutputDir "C:\Reports"
.\Monitor_Windows_Updates.ps1 -WhatIf

.NOTES
SCHEDULE: Weekly (e.g., Monday @ 08:00 AM)
RUN AS: SYSTEM (Highest Privileges)
DEPENDENCIES: Core module, System module functions
#>

param(
    [string]$OutputDir,
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Determine project root and output directory
$scriptRoot = Split-Path -Path $PSScriptRoot -Parent
$projectRoot = Split-Path -Path $scriptRoot -Parent

if (-not $OutputDir) {
    $OutputDir = Join-Path -Path $projectRoot -ChildPath "logs"
}

# Import Core module for logging and error handling
$corePath = Join-Path -Path $projectRoot -ChildPath "modules\Core.psm1"
if (-not (Test-Path $corePath)) {
    Write-Error "Core module not found at $corePath" -ErrorAction Stop
    exit 1
}

Import-Module $corePath -Force -ErrorAction Stop

# Import System module for Update functions
$systemPath = Join-Path -Path $projectRoot -ChildPath "modules\System.psm1"
if (Test-Path $systemPath) {
    try {
        Import-Module $systemPath -Force -ErrorAction Stop
    }
    catch {
        Write-Log -Message "System module failed to load: $($_.Exception.Message)" `
            -Level Warning -Caller $MyInvocation.MyCommand.Name
        Write-Output "[WARN] System functions unavailable - Update checks may fail"
    }
}

Write-Output ""
Write-Output "=============================================================="
Write-Output "       WINHARDEN WINDOWS UPDATE MONITORING"
Write-Output "=============================================================="
Write-Output ""
Write-Output "Start Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

Write-Output ""
Write-Output "[1] CHECKING WINDOWS UPDATE STATUS"
Write-Output "=============================================================="

$status = "UP-TO-DATE"
$updateCount = 0
$securityCount = 0
$criticalCount = 0

try {
    $updateStatus = Get-WindowsUpdateStatus
    $updateCount = $updateStatus.AvailableUpdates
    $securityCount = $updateStatus.SecurityUpdates
    $criticalCount = $updateStatus.CriticalUpdates

    Write-Output ""
    Write-Output "[OK] Search completed: Found $updateCount available updates"

    if ($updateCount -eq 0) {
        Write-Output "[OK] No updates pending"
        $status = "UP-TO-DATE"
    }
    else {
        Write-Output ""
        Write-Output "[WARN] UPDATES AVAILABLE"
        $status = "UPDATES-PENDING"

        Write-Output ""
        Write-Output "Update Breakdown:"
        Write-Output "  Security Updates: $securityCount"
        Write-Output "  Critical Updates: $criticalCount"
        Write-Output "  Other Updates: $($updateStatus.OtherUpdates)"

        # Show important updates
        Write-Output ""
        Write-Output "Top 5 Important Updates:"
        $importantUpdates = @($updateStatus.SecurityUpdatesList) + @($updateStatus.CriticalUpdatesList) |
            Select-Object -First 5

        foreach ($update in $importantUpdates) {
            $kbNumber = $update.KBArticleIDs[0]
            $kbPrefix = if ($kbNumber) {
                "KB$kbNumber"
            }
            else {
                "[No KB]"
            }
            Write-Output "  * $kbPrefix : $($update.Title)"
        }
    }
}
catch {
    Write-Output "[WARN] Could not check Windows Update directly: $($_.Exception.Message)"
    Write-Log -Message "Failed to check Windows Update status: $($_.Exception.Message)" `
        -Level Warning -Caller $MyInvocation.MyCommand.Name
    $status = "CHECK-FAILED"
}

Write-Output ""
Write-Output "[2] CHECKING AUTO-UPDATE CONFIGURATION"
Write-Output "=============================================================="

$autoUpdateConfig = $null

try {
    $autoUpdateConfig = Get-AutoUpdateConfiguration
    if ($autoUpdateConfig.PolicyValue) {
        Write-Output "[OK] Auto-Update Configuration: $($autoUpdateConfig.Description)"
    }
    else {
        Write-Output "[INFO] Auto-Update uses default Windows settings"
    }
}
catch {
    Write-Output "[WARN] Could not retrieve Auto-Update configuration: $($_.Exception.Message)"
    Write-Log -Message "Failed to retrieve Auto-Update configuration: $($_.Exception.Message)" `
        -Level Warning -Caller $MyInvocation.MyCommand.Name
}

Write-Output ""
Write-Output "[3] CHECKING LAST UPDATE INSTALLATION"
Write-Output "=============================================================="

try {
    $updateHistory = Get-UpdateHistory -Count 5

    if ($updateHistory) {
        Write-Output "[OK] Recent updates installed:"
        foreach ($hotfix in $updateHistory) {
            $installDate = if ($hotfix.InstalledOn) {
                (Get-Date $hotfix.InstalledOn -Format "yyyy-MM-dd")
            }
            else {
                "Unknown"
            }
            Write-Output "  * KB$($hotfix.HotFixID): $installDate"
        }
    }
    else {
        Write-Output "[WARN] Could not retrieve update history"
        Write-Log -Message "No update history found on system" -Level Warning -Caller $MyInvocation.MyCommand.Name
    }
}
catch {
    Write-Output "[WARN] Error retrieving update history: $($_.Exception.Message)"
    Write-Log -Message "Error retrieving update history: $($_.Exception.Message)" `
        -Level Warning -Caller $MyInvocation.MyCommand.Name
}

Write-Output ""
Write-Output "[4] SYSTEM REBOOT STATUS"
Write-Output "=============================================================="

$pendingReboot = $false

try {
    $rebootStatus = Get-PendingRebootStatus
    $pendingReboot = $rebootStatus.IsPending

    if ($pendingReboot) {
        Write-Output "[WARN] PENDING REBOOT DETECTED"
        Write-Output $rebootStatus.Message
        if ($status -ne "CHECK-FAILED") {
            $status = "REBOOT-REQUIRED"
        }
    }
    else {
        Write-Output "[OK] No reboot required"
    }
}
catch {
    Write-Output "[WARN] Could not check reboot status: $($_.Exception.Message)"
    Write-Log -Message "Error checking reboot status: $($_.Exception.Message)" `
        -Level Warning -Caller $MyInvocation.MyCommand.Name
}

Write-Output ""
Write-Output "[5] UPDATE RECOMMENDATIONS"
Write-Output "=============================================================="
if ($updateCount -gt 0) {
    Write-Output ""
    Write-Output "[ACTION RECOMMENDED]"
    Write-Output "  1. Review the available updates listed above"
    Write-Output "  2. Install security/critical updates as soon as possible"
    Write-Output "  3. Schedule reboot during maintenance window"
    Write-Output "  4. Test system after updates are installed"
}
else {
    Write-Output ""
    Write-Output "[OK] System is current with all latest updates"
}

Write-Output ""
Write-Output "[REPORT SUMMARY]"
Write-Output "=============================================================="

$reportSummary = @{
    'Scan_Date' = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    'Status' = $status
    'Updates_Available' = $updateCount
    'Security_Updates' = $securityCount
    'Critical_Updates' = $criticalCount
    'Reboot_Pending' = $pendingReboot
    'Auto_Updates_Enabled' = if ($autoUpdateConfig -and $autoUpdateConfig.IsEnabled) {
        $true
    }
    else {
        $false
    }
}

Write-Output ""
Write-Output "Scan Results:"
$reportSummary | Format-Table -AutoSize

Write-Log -Message "Windows Update monitoring scan completed. Status: $status (Updates: $updateCount, Security: $securityCount, Critical: $criticalCount, Reboot: $pendingReboot)" `
    -Level Info -Caller $MyInvocation.MyCommand.Name

# Save detailed report (unless -WhatIf is used)
if (-not $WhatIf) {
    try {
        # Create output directory if needed
        if (-not (Test-Path $OutputDir -PathType Container)) {
            $null = New-Item -ItemType Directory -Path $OutputDir -Force -ErrorAction Stop
        }

        $reportDate = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        $reportFile = Join-Path $OutputDir "Windows_Updates_$reportDate.csv"

        $reportSummary | Export-Csv -Path $reportFile -NoTypeInformation -ErrorAction Stop
        Write-Output ""
        Write-Output "[OK] Detailed report saved: $reportFile"
        Write-Log -Message "Report exported to: $reportFile" -Level Info -Caller $MyInvocation.MyCommand.Name
    }
    catch {
        Write-Output ""
        Write-Output "[WARN] Failed to save report: $($_.Exception.Message)"
        Write-Log -Message "Failed to export report: $($_.Exception.Message)" -Level Error -Caller $MyInvocation.MyCommand.Name
    }
}
else {
    Write-Output ""
    Write-Output "[WhatIf] Report would be saved to: $(Join-Path $OutputDir "Windows_Updates_*.csv")"
}

Write-Output ""
Write-Output "End Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Output "=============================================================="

# Exit with appropriate code based on status
$exitCode = switch ($status) {
    'UP-TO-DATE' {
        0
    }
    'UPDATES-PENDING' {
        1
    }
    'REBOOT-REQUIRED' {
        2
    }
    'CHECK-FAILED' {
        3
    }
    default {
        1
    }
}

Write-Log -Message "Script exiting with code: $exitCode" -Level Info -Caller $MyInvocation.MyCommand.Name
exit $exitCode
