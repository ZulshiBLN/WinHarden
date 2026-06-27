function Set-TaskScheduleCatchup {
    <#
    .SYNOPSIS
    Configures WinHarden scheduled tasks with advanced catchup & recovery settings.

    .DESCRIPTION
    Applies reliable task execution settings to all WinHarden scheduled tasks:
    - Start when available (catchup on missed schedules)
    - Execution timeout limits (prevents runaway tasks)
    - Battery/offline execution (continuous security monitoring)
    - Hard termination (forces stuck tasks to stop)

    Requires admin rights. Uses COM-based Task Scheduler API for advanced configuration.

    .PARAMETER EnableCatchup
    Enable automatic task execution when system comes online (default: $true).

    .PARAMETER MaxTaskDurationHours
    Maximum execution time per task in hours (default: 2 hours).

    .PARAMETER EnableRetry
    Enable retry behavior documentation in output (default: $true).

    .PARAMETER RetryIntervalMinutes
    Suggested retry interval in minutes. Note: Actual retry config requires manual Task Scheduler UI setup (default: 15).

    .PARAMETER MaxRetries
    Maximum retry attempts. Documented for reference; applies to triggers via manual UI (default: 3).

    .EXAMPLE
    Set-TaskScheduleCatchup -EnableCatchup $true -MaxTaskDurationHours 2

    Configures all WinHarden tasks with 2-hour timeout and catchup enabled.

    .NOTES
    DEPENDENCIES: Requires Core module (Write-Log, Write-ErrorLog, Test-NotNullOrEmpty)
    REQUIRES: Administrator privileges
    MODIFIES: Scheduled Tasks in \Hardening\ folder
    ADR REFERENCE: ADR-004 (Error Handling), ADR-005 (Logging)
    #>

    param(
        [Parameter(Mandatory = $false)]
        [bool]$EnableCatchup = $true,

        [Parameter(Mandatory = $false)]
        [bool]$EnableRetry = $true,

        [Parameter(Mandatory = $false)]
        [int]$MaxTaskDurationHours = 2,

        [Parameter(Mandatory = $false)]
        [int]$RetryIntervalMinutes = 15,

        [Parameter(Mandatory = $false)]
        [int]$MaxRetries = 3
    )

    $ErrorActionPreference = 'Continue'

    function _CheckAdminRights {
        $windowsIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal $windowsIdentity
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    function _GetTaskScheduler {
        $scheduler = New-Object -ComObject Schedule.Service
        $scheduler.Connect()
        return $scheduler
    }

    function _GetTaskSettings {
        param(
            [Parameter(Mandatory = $true)]
            [object]$Scheduler,

            [Parameter(Mandatory = $true)]
            [string]$TaskPath,

            [Parameter(Mandatory = $true)]
            [string]$TaskName
        )

        try {
            $folder = $Scheduler.GetFolder($TaskPath)
            $task = $folder.GetTask($TaskName)
            return $task.Definition.Settings
        }
        catch {
            Write-ErrorLog -Message "Failed to get settings for task [$TaskName]" -ErrorRecord $_
            return $null
        }
    }

    function _ApplyTaskSettings {
        param(
            [Parameter(Mandatory = $true)]
            [object]$Settings,

            [Parameter(Mandatory = $true)]
            [bool]$EnableCatchup,

            [Parameter(Mandatory = $true)]
            [int]$MaxTaskDurationHours
        )

        try {
            $Settings.StartWhenAvailable = $EnableCatchup
            $timeSpan = New-TimeSpan -Hours $MaxTaskDurationHours
            $Settings.ExecutionTimeLimit = $timeSpan.ToString()
            $Settings.RunOnlyIfNetworkAvailable = $false
            $Settings.DisallowStartIfOnBatteries = $false
            $Settings.Compatibility = 2
            $Settings.AllowHardTerminate = $true
            return $true
        }
        catch {
            Write-ErrorLog -Message 'Failed to apply task settings' -ErrorRecord $_
            return $false
        }
    }

    function _UpdateTaskDefinition {
        param(
            [Parameter(Mandatory = $true)]
            [object]$Scheduler,

            [Parameter(Mandatory = $true)]
            [string]$TaskPath,

            [Parameter(Mandatory = $true)]
            [string]$TaskName,

            [Parameter(Mandatory = $true)]
            [object]$TaskDefinition
        )

        try {
            $folder = $Scheduler.GetFolder($TaskPath)
            $folder.UpdateDefinition($TaskName, $TaskDefinition)
            return $true
        }
        catch {
            Write-ErrorLog -Message "Failed to update task definition for [$TaskName]" -ErrorRecord $_
            return $false
        }
    }

    function _DiscoverWinHardenTasks {
        try {
            $tasks = @()
            $allTasks = Get-ScheduledTask -TaskPath '\Hardening\*' -ErrorAction SilentlyContinue
            $tasks = $allTasks | Where-Object { $_.TaskPath -like '*Hardening*' }
            return $tasks
        }
        catch {
            Write-ErrorLog -Message 'Failed to discover WinHarden tasks' -ErrorRecord $_
            return @()
        }
    }

    function _VerifyTaskSettings {
        param(
            [Parameter(Mandatory = $true)]
            [object]$Scheduler,

            [Parameter(Mandatory = $true)]
            [string]$TaskPath,

            [Parameter(Mandatory = $true)]
            [string]$TaskName
        )

        try {
            $settings = _GetTaskSettings -Scheduler $Scheduler -TaskPath $TaskPath -TaskName $TaskName
            if ($settings) {
                $catchupStatus = if ($settings.StartWhenAvailable) {
                    'ENABLED'
                }
                else {
                    'DISABLED'
                }
                $timeoutHours = [int]([timespan]::Parse($settings.ExecutionTimeLimit).TotalHours)
                return @{ Catchup = $catchupStatus; TimeoutHours = $timeoutHours }
            }
            return $null
        }
        catch {
            Write-ErrorLog -Message "Failed to verify settings for task [$TaskName]" -ErrorRecord $_
            return $null
        }
    }

    if (-not (_CheckAdminRights)) {
        Write-ErrorLog -Message 'This function requires administrator privileges' -Severity ERROR
        return 1
    }

    Write-Log -Message 'Starting WinHarden task catchup configuration' -Level INFO

    $tasks = _DiscoverWinHardenTasks
    if ($tasks.Count -eq 0) {
        Write-ErrorLog -Message 'No WinHarden tasks found in Hardening folder. Run Set-ScheduledTasksHardening.ps1 first.' -Severity WARN
        return 1
    }

    Write-Log -Message "Discovered $($tasks.Count) WinHarden tasks" -Level INFO

    $configuredCount = 0
    $failureCount = 0

    try {
        $scheduler = _GetTaskScheduler

        foreach ($task in $tasks) {
            $taskName = $task.TaskName
            $taskPath = $task.TaskPath

            try {
                $settings = _GetTaskSettings -Scheduler $scheduler -TaskPath $taskPath -TaskName $taskName
                if ($null -eq $settings) {
                    $failureCount++
                    continue
                }

                if (_ApplyTaskSettings -Settings $settings -EnableCatchup $EnableCatchup -MaxTaskDurationHours $MaxTaskDurationHours) {
                    $taskDef = $scheduler.GetFolder($taskPath).GetTask($taskName).Definition
                    if (_UpdateTaskDefinition -Scheduler $scheduler -TaskPath $taskPath -TaskName $taskName -TaskDefinition $taskDef) {
                        Write-Log -Message "Configured task [$taskName] with catchup enabled (timeout: $MaxTaskDurationHours hours)" -Level INFO
                        $configuredCount++
                    }
                    else {
                        Write-ErrorLog -Message "Failed to update task [$taskName]" -Severity WARN
                        $failureCount++
                    }
                }
                else {
                    $failureCount++
                }
            }
            catch {
                Write-ErrorLog -Message "Error configuring task [$taskName]" -ErrorRecord $_
                $failureCount++
            }
        }

        Write-Log -Message "Task catchup configuration complete: $configuredCount success, $failureCount failed" -Level INFO

        Write-Log -Message 'Verifying task configuration' -Level INFO
        foreach ($task in $tasks) {
            $verification = _VerifyTaskSettings -Scheduler $scheduler -TaskPath $task.TaskPath -TaskName $task.TaskName
            if ($verification) {
                Write-Log -Message "Verified [$($task.TaskName)] - Catchup: $($verification.Catchup), Timeout: $($verification.TimeoutHours)h" -Level INFO
            }
        }

        if ($configuredCount -eq $tasks.Count) {
            Write-Log -Message "All $($tasks.Count) tasks configured successfully with catchup enabled" -Level INFO
            return 0
        }
        else {
            Write-ErrorLog -Message "Configuration completed with warnings: $configuredCount/$($tasks.Count) tasks successful" -Severity WARN
            return 1
        }
    }
    catch {
        Write-ErrorLog -Message 'Unexpected error during task configuration' -ErrorRecord $_
        return 1
    }
}
