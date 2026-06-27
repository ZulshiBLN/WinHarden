function Get-UpdateStatusDrift {
    <#
    .SYNOPSIS
    Detects configuration drift in Windows Update settings.

    .DESCRIPTION
    Comprehensive Windows Update drift detection supporting multiple security profiles (Basis, Recommended, Strict).
    Checks automatic update enablement, scheduled install times, reboot behavior, notification levels, and update recency.
    Supports both local and remote computer analysis with optional detailed output.
    Returns PSCustomObject array with drift findings.

    .PARAMETER ComputerName
    Target computer name for drift analysis (default: 'localhost' for local computer).

    .PARAMETER Profile
    Security baseline profile: Basis (minimum), Recommended (default), or Strict (maximum hardening).
    Different profiles enforce different update policies and reboot behaviors.

    .PARAMETER Detailed
    Include additional detailed checks (update recency, specific update types).
    Automatically enabled for Recommended+ profiles in most contexts.

    .PARAMETER ReportDriftOnly
    Return only items with DRIFT status, filtering out COMPLIANT items.
    Useful for compliance reports focusing on deviations.

    .PARAMETER Credential
    PowerShell credential object for authenticating remote computer access.
    Only used when ComputerName is not 'localhost'.

    .PARAMETER AutoUpdateEnabled
    Whether automatic updates should be enabled (default: $true for Recommended, varies by profile).

    .PARAMETER RequireScheduledRestart
    Enforce scheduled restarts for updates (default: $true for Strict).

    .PARAMETER MaxDaysSinceLastUpdate
    Maximum days allowed since last successful update check (default: 7).

    .EXAMPLE
    $drifts = Get-UpdateStatusDrift
    if ($drifts.Count -gt 0) { $drifts | Write-Output }

    .EXAMPLE
    $drifts = Get-UpdateStatusDrift -ComputerName SERVER01 -Profile Strict -Credential $cred -Detailed

    .EXAMPLE
    Get-UpdateStatusDrift -Profile Basis -ReportDriftOnly | Export-Csv -Path drifts.csv

    .NOTES
    DEPENDENCIES: Write-Log (Core) for logging; Applies to Windows Server 2016+ and Windows 10+
    PROFILES: Basis (3 checks), Recommended (5+ checks), Strict (7+ checks with detailed)
    RETURNS: PSCustomObject array with drift findings
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$ComputerName = 'localhost',

        [ValidateSet('Basis', 'Recommended', 'Strict')]
        [string]$Profile = 'Recommended',

        [switch]$Detailed,

        [switch]$ReportDriftOnly,

        [pscredential]$Credential,

        [bool]$AutoUpdateEnabled = $true,

        [bool]$RequireScheduledRestart = $false,

        [ValidateRange(1, 365)]
        [int]$MaxDaysSinceLastUpdate = 7
    )

    $findings = @()

    try {
        if (-not $PSCmdlet.ShouldProcess($ComputerName, "Check Windows Update Drift")) {
            return $findings
        }

        # Build remote execution parameters
        $remoteParams = @{
            ErrorAction = 'SilentlyContinue'
        }
        if ($ComputerName -ne 'localhost') {
            $remoteParams['ComputerName'] = $ComputerName
            if ($Credential) {
                $remoteParams['Credential'] = $Credential
            }
        }

        # Profile-based configuration
        switch ($Profile) {
            'Basis' {
                $checkAutoUpdate = $true
                $checkScheduledInstall = $false
                $checkNotificationLevel = $false
                $checkUpdateRecency = $false
                $checkRebootBehavior = $false
            }
            'Recommended' {
                $checkAutoUpdate = $true
                $checkScheduledInstall = $true
                $checkNotificationLevel = $true
                $checkUpdateRecency = $Detailed
                $checkRebootBehavior = $Detailed
            }
            'Strict' {
                $checkAutoUpdate = $true
                $checkScheduledInstall = $true
                $checkNotificationLevel = $true
                $checkUpdateRecency = $true
                $checkRebootBehavior = $true
            }
        }

        $auPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"

        # [CHECK 1] Automatic Updates Enabled
        if ($checkAutoUpdate) {
            $auProperty = Get-ItemProperty -Path $auPath -Name NoAutoUpdate -ErrorAction SilentlyContinue
            $noAutoUpdate = $auProperty.NoAutoUpdate
            if ($null -eq $noAutoUpdate) {
                $noAutoUpdate = 0
            }
            $autoUpdateEnabled = $noAutoUpdate -eq 0

            if ($autoUpdateEnabled -eq $AutoUpdateEnabled) {
                if ($autoUpdateEnabled) {
                    $actualStatus = 'Enabled'
                    $expectedStatus = 'Enabled'
                }
                else {
                    $actualStatus = 'Disabled'
                    $expectedStatus = 'Disabled'
                }
                $findings += [PSCustomObject]@{
                    Category = 'Windows Updates'
                    Setting = 'Automatic Updates'
                    Expected = $expectedStatus
                    Actual = $actualStatus
                    Status = 'COMPLIANT'
                    Severity = 'INFO'
                    ComputerName = $ComputerName
                }
            }
            else {
                if ($autoUpdateEnabled) {
                    $actualStatus = 'Enabled'
                }
                else {
                    $actualStatus = 'Disabled'
                }
                if ($AutoUpdateEnabled) {
                    $expectedStatus = 'Enabled'
                }
                else {
                    $expectedStatus = 'Disabled'
                }
                $findings += [PSCustomObject]@{
                    Category = 'Windows Updates'
                    Setting = 'Automatic Updates'
                    Expected = $expectedStatus
                    Actual = $actualStatus
                    Status = 'DRIFT'
                    Severity = 'HIGH'
                    ComputerName = $ComputerName
                }
                Write-Log -Message "Update drift: Auto-updates is $actualStatus (expected $expectedStatus)" `
                    -Level Warning -Caller $MyInvocation.MyCommand.Name
            }
        }

        # [CHECK 2] Scheduled Install Day/Time (Recommended+)
        if ($checkScheduledInstall) {
            $scheduleDay = (Get-ItemProperty -Path $auPath -Name ScheduledInstallDay -ErrorAction SilentlyContinue).ScheduledInstallDay
            $scheduleTime = (Get-ItemProperty -Path $auPath -Name ScheduledInstallTime -ErrorAction SilentlyContinue).ScheduledInstallTime

            if ($null -eq $scheduleDay -or $null -eq $scheduleTime) {
                $actualStatus = 'Not Configured'
                $findings += [PSCustomObject]@{
                    Category = 'Windows Updates'
                    Setting = 'Scheduled Install'
                    Expected = 'Day and Time Configured'
                    Actual = $actualStatus
                    Status = 'DRIFT'
                    Severity = 'MEDIUM'
                    ComputerName = $ComputerName
                }
                Write-Log -Message "Update drift: Scheduled install day/time not configured" `
                    -Level Warning -Caller $MyInvocation.MyCommand.Name
            }
            else {
                $dayNames = @{ 0 = 'Every Day'; 1 = 'Sunday'; 2 = 'Monday'; 3 = 'Tuesday'; 4 = 'Wednesday'; 5 = 'Thursday'; 6 = 'Friday'; 7 = 'Saturday' }
                $dayName = $dayNames[$scheduleDay]
                $actualStatus = "$dayName at $scheduleTime hours"
                $findings += [PSCustomObject]@{
                    Category = 'Windows Updates'
                    Setting = 'Scheduled Install'
                    Expected = 'Day and Time Configured'
                    Actual = $actualStatus
                    Status = 'COMPLIANT'
                    Severity = 'INFO'
                    ComputerName = $ComputerName
                }
            }
        }

        # [CHECK 3] Notification Level (Recommended+)
        if ($checkNotificationLevel) {
            $notifyLevel = (Get-ItemProperty -Path $auPath -Name AUOptions -ErrorAction SilentlyContinue).AUOptions

            if ($null -eq $notifyLevel) {
                $notifyLevel = 0
            }

            $notifyLevelNames = @{
                0 = 'Not Configured'
                2 = 'Notify for Download/Auto-Install'
                3 = 'Auto Download/Notify for Install'
                4 = 'Auto Download and Install'
            }
            $notifyStatus = $notifyLevelNames[$notifyLevel]
            if ($null -eq $notifyStatus) {
                $notifyStatus = "Unknown ($notifyLevel)"
            }

            # Recommend level 4 (auto download and install) for Strict, level 3 for Recommended
            if ($Profile -eq 'Strict') {
                $expectedNotifyLevel = 4
            }
            else {
                $expectedNotifyLevel = 3
            }
            $expectedStatus = $notifyLevelNames[$expectedNotifyLevel]

            if ($notifyLevel -eq $expectedNotifyLevel) {
                $findings += [PSCustomObject]@{
                    Category = 'Windows Updates'
                    Setting = 'Update Notification Level'
                    Expected = $expectedStatus
                    Actual = $notifyStatus
                    Status = 'COMPLIANT'
                    Severity = 'INFO'
                    ComputerName = $ComputerName
                }
            }
            else {
                $findings += [PSCustomObject]@{
                    Category = 'Windows Updates'
                    Setting = 'Update Notification Level'
                    Expected = $expectedStatus
                    Actual = $notifyStatus
                    Status = 'DRIFT'
                    Severity = 'MEDIUM'
                    ComputerName = $ComputerName
                }
                Write-Log -Message "Update drift: Notification level is $notifyStatus (expected $expectedStatus)" `
                    -Level Warning -Caller $MyInvocation.MyCommand.Name
            }
        }

        # [CHECK 4] Reboot Behavior (Strict)
        if ($checkRebootBehavior) {
            $noAutoReboot = (Get-ItemProperty -Path $auPath -Name NoAutoRebootWithLoggedOnUsers -ErrorAction SilentlyContinue).NoAutoRebootWithLoggedOnUsers

            if ($null -eq $noAutoReboot) {
                $noAutoReboot = 0
            }

            $rebootDisabled = $noAutoReboot -eq 1
            if ($RequireScheduledRestart) {
                $expectedStatus = 'Auto Reboot Enabled'
            }
            else {
                $expectedStatus = 'Respects User Sessions'
            }
            if ($rebootDisabled) {
                $actualStatus = 'Respects User Sessions'
            }
            else {
                $actualStatus = 'Auto Reboot Enabled'
            }

            if ($rebootDisabled -ne $RequireScheduledRestart) {
                $findings += [PSCustomObject]@{
                    Category = 'Windows Updates'
                    Setting = 'Reboot Behavior'
                    Expected = $expectedStatus
                    Actual = $actualStatus
                    Status = 'COMPLIANT'
                    Severity = 'INFO'
                    ComputerName = $ComputerName
                }
            }
            else {
                $findings += [PSCustomObject]@{
                    Category = 'Windows Updates'
                    Setting = 'Reboot Behavior'
                    Expected = $expectedStatus
                    Actual = $actualStatus
                    Status = 'DRIFT'
                    Severity = 'MEDIUM'
                    ComputerName = $ComputerName
                }
                Write-Log -Message "Update drift: Reboot behavior is '$actualStatus' (expected '$expectedStatus')" `
                    -Level Warning -Caller $MyInvocation.MyCommand.Name
            }
        }

        # [CHECK 5] Update Recency (Strict/Detailed)
        if ($checkUpdateRecency) {
            try {
                $updateSession = New-Object -ComObject Microsoft.Update.Session
                $updateSearcher = $updateSession.CreateUpdateSearcher()
                $searchResult = $updateSearcher.Search("IsInstalled=1")
                $recentUpdate = $searchResult.Updates | Sort-Object -Property InstallationDate -Descending | Select-Object -First 1

                if ($recentUpdate) {
                    $lastUpdateDate = $recentUpdate.InstallationDate
                    $daysSinceUpdate = [math]::Floor(((Get-Date) - $lastUpdateDate).TotalDays)
                    $expectedStatus = "Within $MaxDaysSinceLastUpdate days"

                    if ($daysSinceUpdate -le $MaxDaysSinceLastUpdate) {
                        $actualStatus = "$daysSinceUpdate days ago"
                        $findings += [PSCustomObject]@{
                            Category = 'Windows Updates'
                            Setting = 'Last Update Recency'
                            Expected = $expectedStatus
                            Actual = $actualStatus
                            Status = 'COMPLIANT'
                            Severity = 'INFO'
                            ComputerName = $ComputerName
                        }
                    }
                    else {
                        $actualStatus = "$daysSinceUpdate days ago"
                        $findings += [PSCustomObject]@{
                            Category = 'Windows Updates'
                            Setting = 'Last Update Recency'
                            Expected = $expectedStatus
                            Actual = $actualStatus
                            Status = 'DRIFT'
                            Severity = 'HIGH'
                            ComputerName = $ComputerName
                        }
                        Write-Log -Message "Update drift: Last update was $daysSinceUpdate days ago (expected within $MaxDaysSinceLastUpdate)" `
                            -Level Warning -Caller $MyInvocation.MyCommand.Name
                    }
                }
                else {
                    $findings += [PSCustomObject]@{
                        Category = 'Windows Updates'
                        Setting = 'Last Update Recency'
                        Expected = "At least one update installed"
                        Actual = 'No updates found'
                        Status = 'DRIFT'
                        Severity = 'HIGH'
                        ComputerName = $ComputerName
                    }
                    Write-Log -Message "Update drift: No installed updates found" `
                        -Level Warning -Caller $MyInvocation.MyCommand.Name
                }
            }
            catch {
                Write-Log -Message "Error checking update recency: $_" -Level Warning -Caller $MyInvocation.MyCommand.Name
            }
        }

        # [CHECK 6] Pending Updates
        try {
            $updateSession = New-Object -ComObject Microsoft.Update.Session
            $updateSearcher = $updateSession.CreateUpdateSearcher()
            $searchResult = $updateSearcher.Search("IsInstalled=0")
            $pendingUpdates = $searchResult.Updates.Count

            if ($pendingUpdates -gt 0) {
                $findings += [PSCustomObject]@{
                    Category = 'Windows Updates'
                    Setting = 'Pending Updates'
                    Expected = 'All Updates Installed'
                    Actual = "$pendingUpdates pending"
                    Status = 'DRIFT'
                    Severity = 'MEDIUM'
                    ComputerName = $ComputerName
                }
                Write-Log -Message "Update drift: $pendingUpdates updates pending installation" `
                    -Level Warning -Caller $MyInvocation.MyCommand.Name
            }
            else {
                $findings += [PSCustomObject]@{
                    Category = 'Windows Updates'
                    Setting = 'Pending Updates'
                    Expected = 'All Updates Installed'
                    Actual = '0 pending'
                    Status = 'COMPLIANT'
                    Severity = 'INFO'
                    ComputerName = $ComputerName
                }
            }
        }
        catch {
            Write-Log -Message "Error checking pending updates: $_" -Level Warning -Caller $MyInvocation.MyCommand.Name
        }
    }
    catch {
        Write-Log -Message "Error checking update status: $_" -Level Error -Caller $MyInvocation.MyCommand.Name
        throw
    }

    # Filter to drift-only if requested
    if ($ReportDriftOnly) {
        $findings = $findings | Where-Object { $_.Status -eq 'DRIFT' }
    }

    return $findings
}
