<#
.SYNOPSIS
Retrieves the recent Windows Update installation history.

.DESCRIPTION
Queries the system for recently installed updates using Get-HotFix.
Returns the N most recent updates with their installation dates.

.PARAMETER Count
Number of recent updates to retrieve (default: 5).

.EXAMPLE
$history = Get-UpdateHistory -Count 10
$history | Write-Output

.NOTES
DEPENDENCIES: Write-Log (Core)
APPLIES TO: Windows Server 2016+, Windows 10+
#>

[CmdletBinding()]
param(
    [int]$Count = 5
)

$ErrorActionPreference = 'Stop'

try {
    Write-Log -Message "Retrieving recent update history (last $Count updates)" `
        -Level Info -Caller $MyInvocation.MyCommand.Name

    $updateHistory = Get-HotFix -ErrorAction SilentlyContinue |
        Sort-Object InstalledOn -Descending |
        Select-Object -First $Count

    if ($updateHistory) {
        Write-Log -Message "Successfully retrieved $($updateHistory.Count) recent updates" `
            -Level Info -Caller $MyInvocation.MyCommand.Name

        return $updateHistory
    }
    else {
        Write-Log -Message "No update history found on system" -Level Warning -Caller $MyInvocation.MyCommand.Name
        return $null
    }
}
catch {
    Write-Log -Message "Error retrieving update history: $($_.Exception.Message)" `
        -Level Error -Caller $MyInvocation.MyCommand.Name
    throw
}
