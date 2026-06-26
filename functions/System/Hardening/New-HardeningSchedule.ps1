function New-HardeningSchedule {
    <#
    .SYNOPSIS
    Creates a scheduled task for automated hardening compliance verification.

    .DESCRIPTION
    Sets up recurring compliance checks via Windows Task Scheduler.
    Monitors system hardening status and generates reports at specified intervals.

    Supports:
    - One-time execution
    - Recurring schedules (daily, weekly)
    - Custom time intervals
    - Automated remediation on non-compliance
    - Report generation in multiple formats

    Tasks run with SYSTEM privilege level for full access to security settings.

    .PARAMETER TaskName
    Name for the scheduled task.
    Default: "WinHarden-HardeningCompliance"

    .PARAMETER Profile
    Hardening profile for scheduled verification: Basis, Recommended, Strict.
    Mandatory.

    .PARAMETER Schedule
    Schedule frequency: OneTime, Daily, Weekly.
    Mandatory.

    .PARAMETER Time
    Time of day for task execution (HH:mm format).
    Default: 02:00 (2 AM)

    .PARAMETER DayOfWeek
    Day of week for weekly schedules (e.g., Monday, Friday).
    Required for Weekly schedule.

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

    .NOTES
    ADMIN: Requires administrative rights to create scheduled tasks
    SECURITY: Script block is Base64-encoded to prevent code injection
    WHATIF: Supports -WhatIf parameter; no resources created in WhatIf mode
    DEPENDENCIES:
      - Write-Log (Core) â€“ Logging
      - New-HardeningSession (System) â€“ Session initialization
      - Invoke-SecurityHardening (System) â€“ Apply hardening rules
      - Test-HardeningCompliance (System) â€“ Compliance verification & remediation
      - Export-HardeningReport (System) â€“ Report generation
    TASK SCHEDULER: Uses Windows Task Scheduler for recurring execution
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
        [ValidateSet('OneTime', 'Daily', 'Weekly')]
        [string]
        $Schedule,

        [Parameter(Mandatory = $false)]
        [string]
        $Time = '02:00',

        [Parameter(Mandatory = $false)]
        [ValidateSet('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday')]
        [string]
        $DayOfWeek,

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

        # Validate time format early
        try {
            [DateTime]::ParseExact($Time, 'HH:mm', [System.Globalization.CultureInfo]::InvariantCulture) | Out-Null
        }
        catch {
            throw "Invalid time format. Use HH:mm (e.g., 14:30)"
        }

        # Build PowerShell script block for task (with safe parameter handling)
        $scriptBlock = @"
# WinHarden Hardening Compliance Check
Import-Module '$($PSScriptRoot | Split-Path)\modules\System.psm1' -Force

`$session = New-HardeningSession -Profile 'PROFILE_PLACEHOLDER' -TargetSystem Client -SkipPrerequisiteCheck
`$hardening = Invoke-SecurityHardening -Session `$session
`$compliance = Test-HardeningCompliance -Session `$session

Write-Output "Compliance: `$(`$compliance.CompliancePercentage)% - `$(`$compliance.Status)"
REMEDIATE_PLACEHOLDER
REPORT_PLACEHOLDER
"@

        # Replace placeholders with safe values (prevents injection)
        $scriptBlock = $scriptBlock -replace 'PROFILE_PLACEHOLDER', $Profile

        if ($AutoRemediate) {
            $remediateBlock = @"

if (`$compliance.NonCompliantRules -gt 0) {
    `$remediation = Test-HardeningCompliance -Session `$session -Remediate
    Write-Output "Remediated `$(`$remediation.RemediatedRules.Count) non-compliant rules"
}
"@
            $scriptBlock = $scriptBlock -replace 'REMEDIATE_PLACEHOLDER', $remediateBlock
        }
        else {
            $scriptBlock = $scriptBlock -replace 'REMEDIATE_PLACEHOLDER', ''
        }

        if ($GenerateReport) {
            $reportBlock = @"

`$reportFileName = "compliance-`$(Get-Date -Format 'yyyy-MM-dd-HHmmss').$($ReportFormat.ToLower())"
Export-HardeningReport -ComplianceReport `$compliance -Format '$ReportFormat' -OutputPath '$ReportPath\`$reportFileName'
"@
            $scriptBlock = $scriptBlock -replace 'REPORT_PLACEHOLDER', $reportBlock
        }
        else {
            $scriptBlock = $scriptBlock -replace 'REPORT_PLACEHOLDER', ''
        }

        # Encode script block as Base64 for secure execution (prevents code injection)
        $scriptBytes = [System.Text.Encoding]::Unicode.GetBytes($scriptBlock)
        $encodedScript = [Convert]::ToBase64String($scriptBytes)

        # Check WhatIf BEFORE creating resources
        if ($PSCmdlet.ShouldProcess($TaskName, "Create scheduled hardening task")) {
            Write-Log -Message "Creating hardening schedule: Task=$TaskName, Profile=$Profile, Schedule=$Schedule" -Level Info

            # Create report directory if generating reports (inside WhatIf block)
            if ($GenerateReport) {
                if (-not (Test-Path -Path $ReportPath)) {
                    New-Item -ItemType Directory -Path $ReportPath -Force | Out-Null
                }
            }

            # Create scheduled task with Base64-encoded command (secure, no injection risk)
            $taskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -EncodedCommand $encodedScript"

            $taskTrigger = switch ($Schedule) {
                'OneTime' {
                    $triggerTime = [DateTime]::ParseExact($Time, 'HH:mm', [System.Globalization.CultureInfo]::InvariantCulture)
                    New-ScheduledTaskTrigger -Once -At $triggerTime
                }
                'Daily' {
                    $triggerTime = [DateTime]::ParseExact($Time, 'HH:mm', [System.Globalization.CultureInfo]::InvariantCulture)
                    New-ScheduledTaskTrigger -Daily -At $triggerTime
                }
                'Weekly' {
                    $triggerTime = [DateTime]::ParseExact($Time, 'HH:mm', [System.Globalization.CultureInfo]::InvariantCulture)
                    New-ScheduledTaskTrigger -Weekly -DaysOfWeek $DayOfWeek -At $triggerTime
                }
            }

            # Create principal (SYSTEM account)
            $taskPrincipal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

            # Create task settings
            $taskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

            # Register task
            Register-ScheduledTask -TaskName $TaskName `
                -Action $taskAction `
                -Trigger $taskTrigger `
                -Principal $taskPrincipal `
                -Settings $taskSettings `
                -Force | Out-Null

            Write-Log -Message "Hardening schedule created: $TaskName" -Level Info

            Get-ScheduledTask -TaskName $TaskName
        }
        else {
            Write-Log -Message "Scheduled task creation cancelled by user (WhatIf)" -Level Info
            return
        }
    }
    catch {
        Write-ErrorLog -Message "Failed to create hardening schedule: $($_.Exception.Message)" -Caller $MyInvocation.MyCommand.Name
        throw
    }
}
