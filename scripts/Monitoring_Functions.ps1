# WinHarden Monitoring Functions
# Add these to your PowerShell profile for quick access

function Get-SecurityEvents {
    <#
    .SYNOPSIS
    Retrieves critical security events from the Windows Event Log.

    .DESCRIPTION
    Queries the Security event log for all events recorded within the specified number of hours,
    sorted by most recent first. Useful for post-incident investigations and threat hunting.

    .PARAMETER Hours
    Number of hours to look back in the event log. Default is 24 hours.

    .PARAMETER WhatIf
    Shows what would happen if the cmdlet runs without actually running it.

    .PARAMETER Confirm
    Prompts for confirmation before executing the cmdlet.

    .EXAMPLE
    Get-SecurityEvents
    Returns all security events from the last 24 hours.

    .EXAMPLE
    Get-SecurityEvents -Hours 1
    Returns all security events from the last hour.

    .NOTES
    REQUIRES: Windows Event Log access (Administrator privileges recommended)
    RELATED: Get-FailedLogins, Get-PrivilegeEscalations
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $false)]
        [int]
        $Hours = 24
    )

    if ($PSCmdlet.ShouldProcess("Security event log", "Query")) {
        $startTime = (Get-Date).AddHours(-$Hours)
        Get-WinEvent -FilterHashtable @{
            LogName = "Security"
            StartTime = $startTime
        } -MaxEvents 100 | Sort-Object TimeCreated -Descending
    }
}

function Get-FailedLogins {
    <#
    .SYNOPSIS
    Retrieves failed login attempts from the Windows Event Log.

    .DESCRIPTION
    Queries the Security event log for failed login events (ID 4625) recorded within the specified
    number of hours, sorted by most recent first. Helps identify unauthorized access attempts and
    potential brute-force attacks.

    .PARAMETER Hours
    Number of hours to look back in the event log. Default is 1 hour.

    .PARAMETER WhatIf
    Shows what would happen if the cmdlet runs without actually running it.

    .PARAMETER Confirm
    Prompts for confirmation before executing the cmdlet.

    .EXAMPLE
    Get-FailedLogins
    Returns all failed login attempts from the last hour.

    .EXAMPLE
    Get-FailedLogins -Hours 24
    Returns all failed login attempts from the last 24 hours.

    .NOTES
    REQUIRES: Windows Event Log access (Administrator privileges recommended)
    EVENT_ID: 4625 (An account failed to log on)
    RELATED: Get-SecurityEvents, Get-PrivilegeEscalations
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $false)]
        [int]
        $Hours = 1
    )

    if ($PSCmdlet.ShouldProcess("Security event log", "Query failed login events (ID 4625)")) {
        $startTime = (Get-Date).AddHours(-$Hours)
        Get-WinEvent -FilterHashtable @{
            LogName = "Security"
            ID = 4625
            StartTime = $startTime
        } | Sort-Object TimeCreated -Descending
    }
}

function Get-PrivilegeEscalations {
    <#
    .SYNOPSIS
    Retrieves privilege escalation events from the Windows Event Log.

    .DESCRIPTION
    Queries the Security event log for privilege escalation events (IDs 4672 and 4673) recorded
    within the specified number of hours, sorted by most recent first. Event 4672 indicates special
    logon with administrative privileges, and 4673 indicates explicit access to sensitive objects.

    .PARAMETER Hours
    Number of hours to look back in the event log. Default is 24 hours.

    .PARAMETER WhatIf
    Shows what would happen if the cmdlet runs without actually running it.

    .PARAMETER Confirm
    Prompts for confirmation before executing the cmdlet.

    .EXAMPLE
    Get-PrivilegeEscalations
    Returns all privilege escalation events from the last 24 hours.

    .EXAMPLE
    Get-PrivilegeEscalations -Hours 168
    Returns all privilege escalation events from the last week (7 days).

    .NOTES
    REQUIRES: Windows Event Log access (Administrator privileges recommended)
    EVENT_IDS: 4672 (Special Logon), 4673 (Sensitive Privilege Use)
    RELATED: Get-SecurityEvents, Get-FailedLogins
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $false)]
        [int]
        $Hours = 24
    )

    if ($PSCmdlet.ShouldProcess("Security event log", "Query privilege escalation events (IDs 4672, 4673)")) {
        $startTime = (Get-Date).AddHours(-$Hours)
        Get-WinEvent -FilterHashtable @{
            LogName = "Security"
            ID = 4672, 4673
            StartTime = $startTime
        } | Sort-Object TimeCreated -Descending
    }
}

# Add to PowerShell profile:
# . "c:\Repos\WinHarden\scripts\Monitoring_Functions.ps1"
