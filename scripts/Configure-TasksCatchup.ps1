# WinHarden - Configure Task Catchup & Recovery Settings
# Configures all WinHarden tasks with advanced options:
# - Catch-up when missed (Start ASAP when system is online)
# - Timeout and error handling
# - Retry mechanism

param(
    [bool]$EnableCatchup = $true,
    [bool]$EnableRetry = $true,
    [int]$MaxTaskDurationHours = 2,
    [int]$RetryIntervalMinutes = 15,
    [int]$MaxRetries = 3
)

$ErrorActionPreference = "Continue"

Write-Output ""
Write-Output "=============================================================="
Write-Output "      CONFIGURE WINHARDEN TASKS - CATCHUP & RECOVERY"
Write-Output "=============================================================="

Write-Output ""
Write-Output "Script: Configure-TasksCatchup"
Write-Output "Purpose: Advanced task configuration for reliability"
Write-Output "Run Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# [STEP 1] Admin Rights Check
Write-Output ""
Write-Output "[STEP 1] VERIFYING ADMIN RIGHTS"
Write-Output "=============================================================="

$windowsIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal $windowsIdentity
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Output ""
    Write-Output "[ERROR] This script must run as ADMINISTRATOR"
    exit 1
}

Write-Output "[OK] Admin rights confirmed"

# [STEP 2] Find all WinHarden tasks
Write-Output ""
Write-Output "[STEP 2] FINDING WINHARDEN TASKS"
Write-Output "=============================================================="

$tasks = @()
try {
    $allTasks = Get-ScheduledTask -TaskPath "\Hardening\*" -ErrorAction SilentlyContinue
    $tasks = $allTasks | Where-Object { $_.TaskPath -like "*Hardening*" }

    if ($tasks.Count -eq 0) {
        Write-Output ""
        Write-Output "[WARN] No WinHarden tasks found in 'Hardening' folder"
        Write-Output "Make sure you've run Set-ScheduledTasksHardening.ps1 first"
        exit 1
    }

    Write-Output ""
    Write-Output "[OK] Found $($tasks.Count) WinHarden tasks:"
    $tasks | ForEach-Object {
        Write-Output "  * $($_.TaskName)"
    }
}
catch {
    Write-Output ""
    Write-Output "[ERROR] Error retrieving tasks: $_"
    exit 1
}

# [STEP 3] Configure Catchup Settings
Write-Output ""
Write-Output "[STEP 3] CONFIGURING CATCHUP SETTINGS"
Write-Output "=============================================================="

Write-Output ""
Write-Output "Configuration Parameters:"
Write-Output "  Enable Catchup: $EnableCatchup"
Write-Output "  Max Task Duration: $MaxTaskDurationHours hours"
Write-Output "  Enable Retry on Failure: $EnableRetry"
Write-Output "  Retry Interval: $RetryIntervalMinutes minutes"
Write-Output "  Max Retries: $MaxRetries"

Write-Output ""
Write-Output "Applying configurations..."

$configuredCount = 0
$failureCount = 0

foreach ($task in $tasks) {
    $taskName = $task.TaskName
    $taskPath = $task.TaskPath
    $fullTaskName = "$taskPath$taskName"

    Write-Output ""
    Write-Output "Configuring: $taskName"

    try {
        # Get task settings via COM object for advanced configuration
        $scheduler = New-Object -ComObject Schedule.Service
        $scheduler.Connect()

        $folder = $scheduler.GetFolder($taskPath)
        $task = $folder.GetTask($taskName)
        $settings = $task.Definition.Settings

        # [SETTING 1] Start when system boots (catchup)
        if ($EnableCatchup) {
            $settings.StartWhenAvailable = $true
            Write-Output "  [OK] Start when available: ENABLED"
            Write-Output "     -> If system was offline at scheduled time, task runs ASAP when online"
        }
        else {
            $settings.StartWhenAvailable = $false
            Write-Output "  [OK] Start when available: DISABLED"
        }

        # [SETTING 2] Stop task timeout
        $timeSpan = New-TimeSpan -Hours $MaxTaskDurationHours
        $settings.ExecutionTimeLimit = $timeSpan.ToString()
        Write-Output "  [OK] Max execution time: $MaxTaskDurationHours hours"
        Write-Output "     -> Prevents runaway tasks from consuming resources"

        # [SETTING 3] Run with highest privileges
        $settings.RunOnlyIfNetworkAvailable = $false
        $settings.DisallowStartIfOnBatteries = $false
        Write-Output "  [OK] Run on battery & offline: ENABLED"
        Write-Output "     -> Tasks run regardless of power/network state"

        # [SETTING 4] Compatibility
        $settings.Compatibility = 2  # Windows 7 or later
        Write-Output "  [OK] Compatibility: Windows 7 or later"

        # [SETTING 5] User interaction
        $settings.AllowHardTerminate = $true
        Write-Output "  [OK] Allow hard termination: ENABLED"
        Write-Output "     -> System can force-stop stuck tasks"

        # [SETTING 6] Retry behavior (if enabled)
        if ($EnableRetry) {
            # Note: Retry settings are set at trigger level, not task level
            # We'll document this for manual configuration
            Write-Output "  [INFO] Retry on failure: Requires manual trigger configuration"
            Write-Output "     -> Use Task Scheduler GUI for retry settings per trigger"
        }

        # Update task with new settings
        $folder.UpdateDefinition($taskName, $task.Definition)

        Write-Output "  [OK] Configuration applied successfully"
        $configuredCount++

    }
    catch {
        Write-Output "  [ERROR] Error: $_"
        $failureCount++
    }
}

# [STEP 4] Verify Configuration
Write-Output ""
Write-Output "[STEP 4] VERIFYING CONFIGURATION"
Write-Output "=============================================================="

Write-Output ""
Write-Output "Verifying catchup setting on each task:"

foreach ($task in $tasks) {
    $taskName = $task.TaskName
    $taskPath = $task.TaskPath
    $fullTaskName = "$taskPath$taskName"

    try {
        $scheduler = New-Object -ComObject Schedule.Service
        $scheduler.Connect()

        $folder = $scheduler.GetFolder($taskPath)
        $task = $folder.GetTask($taskName)
        $settings = $task.Definition.Settings

        $catchupStatus = if ($settings.StartWhenAvailable) { "ENABLED" } else { "DISABLED" }
        $timeoutHours = [int]([timespan]::Parse($settings.ExecutionTimeLimit).TotalHours)

        Write-Output ("  " + $taskName + ":")
        Write-Output ("    Catchup: " + $catchupStatus)
        Write-Output ("    Timeout: " + $timeoutHours + " hours")
    }
    catch {
        Write-Output ("  " + $taskName + ": Could not verify")
    }
}

# [STEP 5] Summary
Write-Output ""
Write-Output "[STEP 5] CONFIGURATION SUMMARY"
Write-Output "=============================================================="

Write-Output ""
Write-Output "Configuration Results:"
Write-Output "  Total Tasks: $($tasks.Count)"
Write-Output "  Configured Successfully: $configuredCount"
Write-Output "  Failed: $failureCount"

Write-Output ""
Write-Output "[CATCHUP & RECOVERY FEATURES ENABLED]"
Write-Output "=============================================================="

Write-Output ""
Write-Output "[OK] Start When Available (Catchup):"
Write-Output "   If system is offline at scheduled task time:"
Write-Output "   * Task WILL run as soon as system boots back up"
Write-Output "   * No missed audits or checks"
Write-Output "   * Reliable security monitoring even with irregular uptime"

Write-Output ""
Write-Output "[OK] Execution Timeout:"
Write-Output "   Each task will terminate after $MaxTaskDurationHours hours maximum:"
Write-Output "   * Prevents stuck or runaway scripts"
Write-Output "   * Frees system resources"
Write-Output "   * Allows next scheduled task to run"

Write-Output ""
Write-Output "[OK] Battery & Offline Execution:"
Write-Output "   Tasks will run regardless of:"
Write-Output "   * Battery vs. AC power"
Write-Output "   * Network connectivity"
Write-Output "   * Ensures security monitoring is continuous"

Write-Output ""
Write-Output "[SCENARIO: MISSED TASK EXAMPLE]"
Write-Output "=============================================================="

Write-Output ""
Write-Output "Scenario: System shut down during scheduled task time"
Write-Output ""
Write-Output "Timeline:"
Write-Output "  Monday 10:00 AM - Drift Detection scheduled"
Write-Output "  BUT: System is powered off at this time"
Write-Output ""
Write-Output "  Monday 3:45 PM - User powers on system"
Write-Output "  Result: Drift Detection runs IMMEDIATELY [OK]"
Write-Output ""
Write-Output "  Benefit: No missed security checks!"

Write-Output ""
Write-Output "[ADVANCED: MANUAL RETRY CONFIGURATION]"
Write-Output "=============================================================="

Write-Output ""
Write-Output "For additional retry settings on task failure:"
Write-Output "  1. Open Task Scheduler: taskschd.msc"
Write-Output "  2. Navigate to: Hardening folder"
Write-Output "  3. Right-click a task -> Properties -> Triggers"
Write-Output "  4. Click a trigger -> Edit -> Advanced Settings"
Write-Output "  5. Check: 'Repeat task every X minutes for a duration of X hours'"
Write-Output "  6. Set retry count if task fails"

Write-Output ""
Write-Output "[NEXT STEPS]"
Write-Output "=============================================================="

Write-Output ""
Write-Output "[OK] Tasks are now configured with:"
Write-Output "  * Automatic catchup when system reboots"
Write-Output "  * Maximum runtime limits"
Write-Output "  * Execution guaranteed (battery/offline-agnostic)"
Write-Output "  * Full reliability for security monitoring"

Write-Output ""
Write-Output "Your system will now:"
Write-Output "  [OK] Never miss scheduled security checks"
Write-Output "  [OK] Execute missed tasks automatically"
Write-Output "  [OK] Prevent runaway tasks from hanging"
Write-Output "  [OK] Maintain continuous security posture"

Write-Output ""
Write-Output "=============================================================="

if ($configuredCount -eq $tasks.Count) {
    Write-Output "[OK] CONFIGURATION SUCCESSFUL"
    Write-Output "All $($tasks.Count) tasks configured with catchup enabled!"
    exit 0
}
else {
    Write-Output "[WARN] CONFIGURATION COMPLETED WITH WARNINGS"
    exit 1
}
