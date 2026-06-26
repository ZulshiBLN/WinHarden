# WinHarden Monitoring Functions
# Add these to your PowerShell profile for quick access

function Get-SecurityEvents {
    <#
    .SYNOPSIS
    Get all critical security events from the last N hours
    .EXAMPLE
    Get-SecurityEvents -Hours 24
    #>
    param([int]$Hours = 24)
    
    $startTime = (Get-Date).AddHours(-$Hours)
    Get-WinEvent -FilterHashtable @{
        LogName = "Security"
        StartTime = $startTime
    } -MaxEvents 100 | Sort-Object TimeCreated -Descending
}

function Get-FailedLogins {
    <#
    .SYNOPSIS
    Get failed login attempts from the last N hours
    #>
    param([int]$Hours = 1)
    
    $startTime = (Get-Date).AddHours(-$Hours)
    Get-WinEvent -FilterHashtable @{
        LogName = "Security"
        ID = 4625
        StartTime = $startTime
    } | Sort-Object TimeCreated -Descending
}

function Get-PrivilegeEscalations {
    <#
    .SYNOPSIS
    Get privilege escalation events from the last N hours
    #>
    param([int]$Hours = 24)
    
    $startTime = (Get-Date).AddHours(-$Hours)
    Get-WinEvent -FilterHashtable @{
        LogName = "Security"
        ID = 4672, 4673
        StartTime = $startTime
    } | Sort-Object TimeCreated -Descending
}

# Add to PowerShell profile:
# . "c:\Repos\WinHarden\scripts\Monitoring_Functions.ps1"
