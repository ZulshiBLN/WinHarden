function _CleanupOldLogs {
    <#
    .SYNOPSIS
    Removes log files older than the specified retention period.

    .DESCRIPTION
    Private helper function that deletes CSV log files older than a configurable number of days.
    Part of ADR-005 logging strategy (7-day retention by default).
    Called automatically by Write-Log to maintain disk space.

    .PARAMETER LogDir
    Path to the logs directory. If not provided, defaults to PSScriptRoot/../logs.

    .PARAMETER DaysToKeep
    Number of days to retain log files. Default: 7 days.
    Logs older than this are deleted.

    .NOTES
    - Part of the logging infrastructure (ADR-005)
    - Does not throw exceptions; silently continues on errors
    - Only processes files matching 'log_*.csv' pattern
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]
        $LogDir,

        [Parameter(Mandatory = $false)]
        [int]
        $DaysToKeep = 7
    )

    if (-not $LogDir) {
        $LogDir = if ($PSScriptRoot) {
            Join-Path -Path $PSScriptRoot -ChildPath '..\logs'
        }
        else {
            Join-Path -Path (Get-Location) -ChildPath 'logs'
        }
    }

    if (-not (Test-Path -Path $LogDir -PathType Container)) {
        return
    }

    $cutoffDate = (Get-Date).AddDays(-$DaysToKeep)

    try {
        Get-ChildItem -Path $LogDir -Filter 'log_*.csv' -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -lt $cutoffDate } |
            Remove-Item -Force -ErrorAction SilentlyContinue
    }
    catch {
        Write-Warning -Message "Log cleanup error: $_"
    }
}
