# WinHarden Windows Update Monitoring Script
# Checks pending security updates and generates alerts
# Schedule: Weekly (e.g., Monday @ 08:00 AM)
# Run As: SYSTEM (Highest Privileges)

param(
    [string]$OutputDir = "c:\Repos\WinHarden\logs"
)

$ErrorActionPreference = "Continue"

Write-Output ""
Write-Output "=============================================================="
Write-Output "       WINHARDEN WINDOWS UPDATE MONITORING"
Write-Output "=============================================================="
Write-Output ""
Write-Output "Start Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

Write-Output ""
Write-Output "[1] CHECKING WINDOWS UPDATE STATUS"
Write-Output "=============================================================="
# Get Windows Update history
try {
    $updateSession = New-Object -ComObject Microsoft.Update.Session
    $updateSearcher = $updateSession.CreateUpdateSearcher()

    # Search for available updates
    Write-Output ""
    Write-Output "Searching for available updates..."
    $searchResult = $updateSearcher.Search("IsInstalled=0")

    $availableUpdates = $searchResult.Updates
    $updateCount = ($availableUpdates | Measure-Object).Count

    Write-Output "[OK] Search completed: Found $updateCount available updates"
    if ($updateCount -eq 0) {
        Write-Output "[OK] No updates pending"
        $status = "UP-TO-DATE"
    }
    else {
        Write-Output ""
        Write-Output "[WARN] UPDATES AVAILABLE"
        $status = "UPDATES-PENDING"

        # Categorize updates
        $securityUpdates = $availableUpdates | Where-Object { $_.Categories.Name -contains "Security Updates" }
        $criticalUpdates = $availableUpdates | Where-Object { $_.Categories.Name -contains "Critical Updates" }
        $otherUpdates = $availableUpdates | Where-Object {
            $_.Categories.Name -notcontains "Security Updates" `
                -and $_.Categories.Name -notcontains "Critical Updates"
        }

        Write-Output ""
        Write-Output "Update Breakdown:"
        Write-Output "  Security Updates: $(($securityUpdates | Measure-Object).Count)"
        Write-Output "  Critical Updates: $(($criticalUpdates | Measure-Object).Count)"
        Write-Output "  Other Updates: $(($otherUpdates | Measure-Object).Count)"

        # Show important updates
        Write-Output ""
        Write-Output "Top 5 Important Updates:"
        $importantUpdates = $availableUpdates | Where-Object {
            $_.Categories.Name -contains "Security Updates" `
                -or $_.Categories.Name -contains "Critical Updates"
        } | Select-Object -First 5

        foreach ($update in $importantUpdates) {
            Write-Output "  * KB$($update.KBArticleIDs[0]): $($update.Title)"
        }
    }

}
catch {
    Write-Output "[WARN] Could not check Windows Update directly: $_"
    $status = "CHECK-FAILED"
}

Write-Output ""
Write-Output "[2] CHECKING AUTO-UPDATE CONFIGURATION"
Write-Output "=============================================================="
# Check automatic update settings
$auPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
$autoUpdatePolicy = (Get-ItemProperty -Path $auPath -Name AUOptions `
    -ErrorAction SilentlyContinue).AUOptions

$autoUpdateSettings = @{
    1 = "Keep my computer current is disabled"
    2 = "Notify for download and auto install"
    3 = "Auto download and notify for install"
    4 = "Auto download and schedule install"
    5 = "Automatic Updates required, auto install at 3:00 AM"
}

if ($autoUpdatePolicy) {
    $settingDesc = $autoUpdateSettings[[int]$autoUpdatePolicy]
    Write-Output "[OK] Auto-Update Configuration: $settingDesc (Policy: $autoUpdatePolicy)"
}
else {
    Write-Output "[INFO] Auto-Update uses default Windows settings"
}

Write-Output ""
Write-Output "[3] CHECKING LAST UPDATE INSTALLATION"
Write-Output "=============================================================="
# Get Windows Update history from Registry
$updateHistory = Get-HotFix -ErrorAction SilentlyContinue | Sort-Object InstalledOn -Descending | Select-Object -First 5

if ($updateHistory) {
    Write-Output "[OK] Recent updates installed:"
    foreach ($hotfix in $updateHistory) {
        if ($hotfix.InstalledOn) {
            $installDate = (Get-Date $hotfix.InstalledOn -Format "yyyy-MM-dd")
        }
        else {
            $installDate = "Unknown"
        }
        Write-Output "  * KB$($hotfix.HotFixID): $installDate"
    }
}
else {
    Write-Output "[WARN] Could not retrieve update history"
}

Write-Output ""
Write-Output "[4] SYSTEM REBOOT STATUS"
Write-Output "=============================================================="
# Check if reboot is pending
$pendingReboot = $false

# Check registry for pending reboot
$sessionPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager"
if (Test-Path $sessionPath -ErrorAction SilentlyContinue) {
    $sessionManager = Get-Item -Path $sessionPath -ErrorAction SilentlyContinue
    if ($sessionManager.GetValueNames() -contains "PendingFileRenameOperations") {
        $pendingReboot = $true
        Write-Output "[WARN] PENDING REBOOT DETECTED"
        Write-Output "System requires restart for updates to take effect"
        $status = "REBOOT-REQUIRED"
    }
}

if (-not $pendingReboot) {
    Write-Output "[OK] No reboot required"
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
    'Security_Updates' = if ($securityUpdates) { ($securityUpdates | Measure-Object).Count } else { 0 }
    'Critical_Updates' = if ($criticalUpdates) { ($criticalUpdates | Measure-Object).Count } else { 0 }
    'Reboot_Pending' = $pendingReboot
    'Auto_Updates_Enabled' = if ($autoUpdatePolicy) { $true } else { "Default" }
}

Write-Output ""
Write-Output "Scan Results:"
$reportSummary | Format-Table -AutoSize

# Save detailed report
$reportDate = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$reportFile = Join-Path $OutputDir "Windows_Updates_$reportDate.csv"

$reportSummary | Export-Csv -Path $reportFile -NoTypeInformation
Write-Output ""
Write-Output "[OK] Detailed report saved: $reportFile"
Write-Output ""
Write-Output "End Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Output "=============================================================="
exit 0
