function New-HardeningSchedule {
    <#
    .SYNOPSIS
    Creates a scheduled task for automated hardening compliance verification.

    .DESCRIPTION
    Sets up recurring compliance checks via Windows Task Scheduler.
    Monitors system hardening status and generates reports at specified intervals.

    Supports:
    - One-time execution
    - Recurring schedules (daily, weekly, monthly)
    - Custom time intervals
    - Automated remediation on non-compliance
    - Report generation in multiple formats
    - Email notifications (with email service available)

    Tasks run with SYSTEM privilege level for full access to security settings.

    .PARAMETER TaskName
    Name for the scheduled task.
    Default: "WinHarden-HardeningCompliance"

    .PARAMETER Profile
    Hardening profile for scheduled verification: Basis, Recommended, Strict.
    Mandatory.

    .PARAMETER Schedule
    Schedule frequency: OneTime, Daily, Weekly, Monthly.
    Mandatory.

    .PARAMETER Time
    Time of day for task execution (HH:mm format).
    Default: 02:00 (2 AM)

    .PARAMETER DayOfWeek
    Day of week for weekly schedules (e.g., Monday, Friday).
    Required for Weekly schedule.

    .PARAMETER DayOfMonth
    Day of month for monthly schedules (1-31).
    Required for Monthly schedule.

    .PARAMETER AutoRemediate
    If specified, automatically remediate non-compliant rules.
    Requires admin rights.

    .PARAMETER GenerateReport
    If specified, generates compliance report after each check.
    Report saved to specified path.

    .PARAMETER ReportFormat
    Format for generated reports: JSON, CSV, HTML, Text.
    Default: HTML

    .PARAMETER ReportPath
    Directory path for saving compliance reports.
    Default: C:\ProgramData\WinHarden\Reports

    .EXAMPLE
    New-HardeningSchedule -Profile Recommended -Schedule Daily -Time 03:00

    Creates daily compliance check at 3 AM for Recommended profile.

    .EXAMPLE
    New-HardeningSchedule -Profile Strict -Schedule Weekly -DayOfWeek Monday -AutoRemediate -GenerateReport -ReportFormat HTML

    Creates weekly Monday check with auto-remediation and HTML report generation.

    .EXAMPLE
    New-HardeningSchedule -Profile Basis -Schedule Monthly -DayOfMonth 1 -GenerateReport

    Creates monthly compliance check on the 1st of each month.

    .NOTES
    DEPENDENCIES: Write-Log (Core), Test-HardeningCompliance, Export-HardeningReport
    ADMIN: Requires administrative rights to create scheduled tasks
    TASK SCHEDULER: Uses Windows Task Scheduler for execution
    REPORTS: Generated in C:\ProgramData\WinHarden\Reports by default
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $false)]
        [string]
        $TaskName = "WinHarden-HardeningCompliance",

        [Parameter(Mandatory = $true)]
        [ValidateSet('Basis', 'Recommended', 'Strict')]
        [string]
        $Profile,

        [Parameter(Mandatory = $true)]
        [ValidateSet('OneTime', 'Daily', 'Weekly', 'Monthly')]
        [string]
        $Schedule,

        [Parameter(Mandatory = $false)]
        [string]
        $Time = '02:00',

        [Parameter(Mandatory = $false)]
        [ValidateSet('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday')]
        [string]
        $DayOfWeek,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 31)]
        [int]
        $DayOfMonth,

        [switch]
        $AutoRemediate,

        [switch]
        $GenerateReport,

        [Parameter(Mandatory = $false)]
        [ValidateSet('JSON', 'CSV', 'HTML', 'Text')]
        [string]
        $ReportFormat = 'HTML',

        [Parameter(Mandatory = $false)]
        [string]
        $ReportPath = 'C:\ProgramData\WinHarden\Reports'
    )

    $ErrorActionPreference = 'Stop'

    try {
        # Validate schedule parameters
        if ($Schedule -eq 'Weekly' -and -not $DayOfWeek) {
            throw "DayOfWeek required for Weekly schedule"
        }

        if ($Schedule -eq 'Monthly' -and -not $DayOfMonth) {
            throw "DayOfMonth required for Monthly schedule"
        }

        Write-Log -Message "Creating hardening schedule: Task=$TaskName, Profile=$Profile, Schedule=$Schedule" -Level Info

        # Create report directory if generating reports
        if ($GenerateReport) {
            if (-not (Test-Path -Path $ReportPath)) {
                New-Item -ItemType Directory -Path $ReportPath -Force | Out-Null
            }
        }

        # Build PowerShell script block for task
        $scriptBlock = @"
# WinHarden Hardening Compliance Check
Import-Module '$(Split-Path -Path $PSScriptRoot -Parent)\modules\System.psm1' -Force

`$session = New-HardeningSession -Profile '$Profile' -TargetSystem Client -SkipPrerequisiteCheck
`$hardening = Invoke-SecurityHardening -Session `$session
`$compliance = Test-HardeningCompliance -Session `$session

Write-Output "Compliance: `$(`$compliance.CompliancePercentage)% - `$(`$compliance.Status)"
"@

        if ($AutoRemediate) {
            $scriptBlock += @"
`
if (`$compliance.NonCompliantRules -gt 0) {
    `$remediation = Test-HardeningCompliance -Session `$session -Remediate
    Write-Output "Remediated `$(`$remediation.RemediatedRules.Count) non-compliant rules"
}
"@
        }

        if ($GenerateReport) {
            $scriptBlock += @"
`
Export-HardeningReport -ComplianceReport `$compliance -Format '$ReportFormat' -OutputPath '$ReportPath\compliance-`$(Get-Date -Format "yyyy-MM-dd-HHmmss").$($ReportFormat.ToLower())'
"@
        }

        # Create scheduled task
        $taskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -Command `"$scriptBlock`""

        $taskTrigger = switch ($Schedule) {
            'OneTime' {
                $triggerTime = [DateTime]::ParseExact($Time, 'HH:mm', $null)
                New-ScheduledTaskTrigger -Once -At $triggerTime
            }
            'Daily' {
                $triggerTime = [DateTime]::ParseExact($Time, 'HH:mm', $null)
                New-ScheduledTaskTrigger -Daily -At $triggerTime
            }
            'Weekly' {
                $triggerTime = [DateTime]::ParseExact($Time, 'HH:mm', $null)
                New-ScheduledTaskTrigger -Weekly -DaysOfWeek $DayOfWeek -At $triggerTime
            }
            'Monthly' {
                $triggerTime = [DateTime]::ParseExact($Time, 'HH:mm', $null)
                New-ScheduledTaskTrigger -Monthly -DaysOfMonth $DayOfMonth -At $triggerTime
            }
        }

        # Create principal (SYSTEM account)
        $taskPrincipal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

        # Create task settings
        $taskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

        # Register task
        if ($PSCmdlet.ShouldProcess($TaskName, "Create scheduled hardening task")) {
            Register-ScheduledTask -TaskName $TaskName `
                -Action $taskAction `
                -Trigger $taskTrigger `
                -Principal $taskPrincipal `
                -Settings $taskSettings `
                -Force | Out-Null
        }
        else {
            Write-Log -Message "Scheduled task creation cancelled by user" -Level Info
            return
        }

        Write-Log -Message "Hardening schedule created: $TaskName" -Level Info

        Get-ScheduledTask -TaskName $TaskName
    }
    catch {
        Write-ErrorLog -Message "Failed to create hardening schedule: $($_.Exception.Message)" -Caller $MyInvocation.MyCommand.Name
        throw
    }
}
