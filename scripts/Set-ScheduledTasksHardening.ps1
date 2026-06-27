<#
.SYNOPSIS
Deploys centralized scheduled tasks for WinHarden automation in Task Scheduler.

.DESCRIPTION
Creates automated tasks in a "Hardening" folder for monthly compliance audits, daily security
monitoring, and weekly drift detection. Supports cleanup of legacy task naming schemes.

.PARAMETER Force
Force cleanup and recreation of existing tasks.

.PARAMETER Cleanup
Remove old-format tasks (WinHarden-* naming) before creating new tasks.

.EXAMPLE
Set-ScheduledTasksHardening -Force

.NOTES
Requires: Administrator rights, PowerShell 5.1+
DEPENDS ON: Core.psm1 (Write-Log function)
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Force,
    [switch]$Cleanup
)

$ErrorActionPreference = "Stop"

# [INIT] Import Core Module (must be first)
$corePath = Join-Path (Split-Path $PSScriptRoot -Parent) "modules\Core.psm1"
if (-not (Test-Path $corePath)) {
    Write-Error "Core.psm1 not found at: $corePath" -ErrorAction Stop
}
Import-Module $corePath -Force -ErrorAction Stop

Write-Output "`n==========================================================="
Write-Output "      WINHARDEN - CENTRALIZED SCHEDULED TASKS SETUP"
Write-Output "==========================================================="
Write-Output "`nScript: Set-ScheduledTasksHardening"
Write-Output "Purpose: Create all WinHarden automation tasks in Task Scheduler"
Write-Output "Run Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# [STEP 1] Admin Rights Check
Write-Output "`n[STEP 1] VERIFYING ADMIN RIGHTS"
Write-Output "==========================================================="
$windowsIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal $windowsIdentity
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Log -Message "This script must run as ADMINISTRATOR" -Level Error -Caller "Admin Rights Check"
    Write-Output "`n[ERROR] This script must run as ADMINISTRATOR"
    Write-Output "Please restart PowerShell with Admin rights:"
    Write-Output "  Win + X - Terminal (Admin) or PowerShell (Admin)"
    exit 1
}

Write-Log -Message "Admin rights confirmed" -Level Info -Caller "Admin Rights Check"
Write-Output "[OK] Admin rights confirmed"

# [STEP 2] Verify Script Paths
Write-Output "`n[STEP 2] VERIFYING AUTOMATION SCRIPTS EXIST"
Write-Output "==========================================================="
$scriptsPath = $PSScriptRoot
$requiredScripts = @(
    "Monthly_Compliance_Audit.ps1",
    "Archive_Old_Reports.ps1",
    "Detect_Security_Drift.ps1",
    "Monitor_Windows_Updates.ps1"
)

$allScriptsFound = $true
foreach ($script in $requiredScripts) {
    $scriptPath = Join-Path $scriptsPath $script
    if (Test-Path $scriptPath) {
        Write-Output "[OK] Found: $script"
    }
    else {
        Write-Log -Message "Missing required script: $script at $scriptPath" -Level Error -Caller "Script Verification"
        Write-Output "[ERROR] Missing: $script"
        $allScriptsFound = $false
    }
}

if (-not $allScriptsFound) {
    Write-Log -Message "Some required scripts are missing. Cannot proceed." -Level Error -Caller "Script Verification"
    Write-Output "`n[ERROR] Some scripts are missing. Cannot proceed."
    exit 1
}

Write-Output "`n[OK] All required scripts found"

# [STEP 3] Define Scheduled Tasks
Write-Output "`n[STEP 3] DEFINING SCHEDULED TASKS"
Write-Output "==========================================================="
$tasks = @(
    @{
        Name = "Monthly-Compliance-Audit"
        DisplayName = "WinHarden Monthly Compliance Audit"
        Script = "Monthly_Compliance_Audit.ps1"
        Schedule = "MONTHLY"
        Day = "1"
        Time = "08:00"
        Description = "Monthly hardening compliance verification and audit"
    },
    @{
        Name = "Archive-Old-Reports"
        DisplayName = "WinHarden Archive Old Reports"
        Script = "Archive_Old_Reports.ps1"
        Schedule = "MONTHLY"
        Day = "2"
        Time = "09:00"
        Description = "Archive monthly audit reports older than 6 months to ZIP files"
    },
    @{
        Name = "Detect-Configuration-Drift"
        DisplayName = "WinHarden Detect Configuration Drift"
        Script = "Detect_Security_Drift.ps1"
        Schedule = "WEEKLY"
        Day = "MON"
        Time = "10:00"
        Description = "Weekly scan for unauthorized changes to hardening settings"
    },
    @{
        Name = "Monitor-Windows-Updates"
        DisplayName = "WinHarden Monitor Windows Updates"
        Script = "Monitor_Windows_Updates.ps1"
        Schedule = "WEEKLY"
        Day = "MON"
        Time = "08:00"
        Description = "Weekly check for available Windows security updates"
    }
)

Write-Output "Found $($tasks.Count) automation tasks to deploy:"
$tasks | ForEach-Object {
    Write-Output "  - $($_.DisplayName)"
}

# [STEP 4] Cleanup Old Tasks (Optional)
if ($Cleanup -or $Force) {
    Write-Output "`n[STEP 4] CLEANING UP OLD TASKS"
    Write-Output "==========================================================="
    $oldTaskNames = @(
        "WinHarden-Monthly-Compliance-Audit",
        "WinHarden-Daily-Security-Monitor",
        "WinHarden-Archive-Reports",
        "WinHarden-Detect-Drift",
        "WinHarden-Monitor-Updates"
    )

    foreach ($taskName in $oldTaskNames) {
        $existingTask = Get-ScheduledTask -TaskName $taskName -TaskPath "\Hardening\" -ErrorAction SilentlyContinue
        if ($existingTask) {
            if ($PSCmdlet.ShouldProcess($taskName, "Remove old scheduled task")) {
                Write-Output "Removing old task: $taskName"
                Unregister-ScheduledTask -TaskName $taskName -TaskPath "\Hardening\" -Confirm:$false -ErrorAction SilentlyContinue
                Write-Log -Message "Removed old task: $taskName" -Level Info -Caller "Task Cleanup"
            }
        }
    }

    Write-Output "[OK] Old tasks cleaned up"
}

# [STEP 5] Create Scheduled Tasks in Hardening Folder
Write-Output "`n[STEP 5] CREATING SCHEDULED TASKS"
Write-Output "==========================================================="
$createdTasks = @()
$failedTasks = @()

foreach ($task in $tasks) {
    $taskPath = "Hardening\$($task.Name)"
    $scriptFullPath = Join-Path $scriptsPath $task.Script

    Write-Output "`nCreating: $($task.DisplayName)"
    Write-Output "  Path: $taskPath"
    Write-Output "  Schedule: $($task.Schedule)"

    if (-not $PSCmdlet.ShouldProcess($taskPath, "Create scheduled task")) {
        Write-Output "  [WHATIF] Task creation skipped"
        continue
    }

    try {
        # Build schtasks parameters as array
        $scriptArg = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$scriptFullPath`""

        $schtasksParams = @(
            "/create",
            "/tn", $taskPath,
            "/tr", $scriptArg,
            "/sc", $task.Schedule,
            "/st", $task.Time,
            "/ru", "SYSTEM",
            "/f"
        )

        # Add day parameter for MONTHLY and WEEKLY schedules
        if ($task.Schedule -eq "MONTHLY" -or $task.Schedule -eq "WEEKLY") {
            $schtasksParams += "/d"
            $schtasksParams += $task.Day
        }

        # Execute task creation using call operator
        $result = & schtasks.exe $schtasksParams 2>&1

        # Verify task was created
        Start-Sleep -Milliseconds 500
        $taskExists = Get-ScheduledTask -TaskName $task.Name -TaskPath "\Hardening\" -ErrorAction SilentlyContinue

        if ($taskExists) {
            Write-Output "  [OK] Created successfully"
            Write-Log -Message "Created scheduled task: $taskPath ($($task.Schedule))" -Level Info -Caller "Task Creation"
            $createdTasks += $task
        }
        else {
            Write-Output "  [ERROR] Task verification failed"
            Write-Log -Message "Failed to create scheduled task $taskPath" -Level Error -Caller "Task Creation"
            $failedTasks += $task
        }
    }
    catch {
        Write-Output "  [ERROR] Error: $_"
        Write-Log -Message "Error creating scheduled task $taskPath : $_" -Level Error -Caller "Task Creation"
        $failedTasks += $task
    }
}

# [STEP 6] Verification
Write-Output "`n[STEP 6] VERIFICATION & SUMMARY"
Write-Output "==========================================================="
Write-Output "`nScheduled Tasks in 'Hardening' Folder:"
$allHardeningTasks = Get-ScheduledTask -TaskPath "\Hardening\*" -ErrorAction SilentlyContinue

if ($allHardeningTasks) {
    $allHardeningTasks | Select-Object TaskName, @{ Name = "State"; Expression = { $_.State } }, @{ Name = "Enabled"; Expression = { $_.Enabled } } | Format-Table -AutoSize

    Write-Output "`n[OK] Task Scheduler Status:"
    Write-Output "  Total Tasks Created: $($allHardeningTasks.Count)"
    Write-Output "  Location: Task Scheduler Library - Hardening folder"
}
else {
    Write-Output "[ERROR] No tasks found in Hardening folder"
}

# [STEP 7] Summary Report
Write-Output "`n[STEP 7] DEPLOYMENT SUMMARY"
Write-Output "==========================================================="
Write-Output "`nDeployment Results:"
Write-Output "  Total Tasks: $($tasks.Count)"
Write-Output "  Created Successfully: $($createdTasks.Count)"
Write-Output "  Failed: $($failedTasks.Count)"

if ($failedTasks.Count -gt 0) {
    Write-Output "`n[ERROR] Failed Tasks:"
    $failedTasks | ForEach-Object {
        Write-Output "  - $($_.DisplayName)"
    }
}

Write-Output "`n[AUTOMATION SCHEDULE]"
Write-Output "==========================================================="
$scheduleTable = @(
    [PSCustomObject]@{
        'Task' = 'Windows Update Monitor'
        'Schedule' = 'Weekly (Monday)'
        'Time' = '08:00 AM'
        'Purpose' = 'Check for security updates'
    },
    [PSCustomObject]@{
        'Task' = 'Drift Detection'
        'Schedule' = 'Weekly (Monday)'
        'Time' = '10:00 AM'
        'Purpose' = 'Check for unauthorized changes'
    },
    [PSCustomObject]@{
        'Task' = 'Monthly Compliance Audit'
        'Schedule' = 'Monthly (1st day)'
        'Time' = '08:00 AM'
        'Purpose' = 'Verify compliance status'
    },
    [PSCustomObject]@{
        'Task' = 'Archive Old Reports'
        'Schedule' = 'Monthly (2nd day)'
        'Time' = '09:00 AM'
        'Purpose' = 'Cleanup and storage optimization'
    }
)

$scheduleTable | Format-Table -AutoSize

Write-Output "`n[NEXT STEPS]"
Write-Output "==========================================================="
Write-Output "`n1. View Tasks in Task Scheduler:"
Write-Output "   taskschd.msc - Expand 'Task Scheduler Library' - Find 'Hardening' folder"
Write-Output "`n2. Verify Tasks via PowerShell:"
Write-Output "   Get-ScheduledTask -TaskPath '\Hardening\*' | Format-Table TaskName, State"
Write-Output "`n3. Run a Task Manually (for testing):"
Write-Output "   Start-ScheduledTask -TaskName 'Monthly-Compliance-Audit' -TaskPath '\Hardening\'"
Write-Output "`n4. View Task History/Logs:"
Write-Output "   Event Viewer - Windows Logs - System (filter for Task Scheduler)"
Write-Output "`n5. Monitor Reports:"
Write-Output "   Reports saved to: c:\Repos\WinHarden\logs\"
Write-Output "`n[OPTIONAL: ADVANCED SETTINGS]"
Write-Output "==========================================================="
Write-Output "`nTo further configure tasks (optional):"
Write-Output "  - Set retry on failure: Right-click Task - Properties - History"
Write-Output "  - Add email alerts: Right-click Task - Properties - Actions"
Write-Output "  - Adjust schedule: Right-click Task - Properties - Triggers"
Write-Output "`n[UNINSTALL (if needed)]"
Write-Output "==========================================================="
Write-Output "`nTo remove all WinHarden tasks:"
Write-Output "  PowerShell (Admin):"
Write-Output "  Get-ScheduledTask -TaskPath '\Hardening\*' | Unregister-ScheduledTask -Confirm:`$false"
Write-Output "`n==========================================================="

if ($createdTasks.Count -eq $tasks.Count) {
    Write-Output "[OK] DEPLOYMENT SUCCESSFUL"
    Write-Output "All $($tasks.Count) WinHarden automation tasks have been created!"
    Write-Log -Message "Deployment successful: All $($tasks.Count) tasks created" -Level Info -Caller "Deployment Summary"
    exit 0
}
else {
    Write-Output "[WARN] DEPLOYMENT COMPLETED WITH ISSUES"
    Write-Output "Created: $($createdTasks.Count)/$($tasks.Count) | Failed: $($failedTasks.Count)"
    Write-Log -Message "Deployment completed with issues: $($createdTasks.Count)/$($tasks.Count) tasks created, $($failedTasks.Count) failed" -Level Warning -Caller "Deployment Summary"
    exit 1
}
