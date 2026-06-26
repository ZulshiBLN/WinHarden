<#
.SYNOPSIS
Retrieves the current Windows Update status and available updates.

.DESCRIPTION
Queries the Windows Update COM object to check for available updates.
Returns a PSCustomObject with count of available, security, and critical updates.
Logs all errors through the central Write-Log function.

.PARAMETER None

.EXAMPLE
$status = Get-WindowsUpdateStatus
if ($status.AvailableUpdates -gt 0) {
    Write-Output "Updates available: $($status.AvailableUpdates)"
}

.NOTES
DEPENDENCIES: Write-Log (Core)
APPLIES TO: Windows Server 2016+, Windows 10+
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

try {
    $updateSession = New-Object -ComObject Microsoft.Update.Session
    $updateSearcher = $updateSession.CreateUpdateSearcher()

    Write-Log -Message "Searching for available Windows updates..." -Level Info -Caller $MyInvocation.MyCommand.Name

    $searchResult = $updateSearcher.Search("IsInstalled=0")
    $availableUpdates = $searchResult.Updates

    $securityUpdates = $availableUpdates | Where-Object { $_.Categories.Name -contains "Security Updates" }
    $criticalUpdates = $availableUpdates | Where-Object { $_.Categories.Name -contains "Critical Updates" }
    $otherUpdates = $availableUpdates | Where-Object {
        $_.Categories.Name -notcontains "Security Updates" `
            -and $_.Categories.Name -notcontains "Critical Updates"
    }

    $updateCount = ($availableUpdates | Measure-Object).Count
    $securityCount = ($securityUpdates | Measure-Object).Count
    $criticalCount = ($criticalUpdates | Measure-Object).Count
    $otherCount = ($otherUpdates | Measure-Object).Count

    Write-Log -Message "Update search completed: $updateCount total ($securityCount security, $criticalCount critical, $otherCount other)" `
        -Level Info -Caller $MyInvocation.MyCommand.Name

    return [PSCustomObject]@{
        AvailableUpdates = $updateCount
        SecurityUpdates = $securityCount
        CriticalUpdates = $criticalCount
        OtherUpdates = $otherCount
        AllUpdates = $availableUpdates
        SecurityUpdatesList = $securityUpdates
        CriticalUpdatesList = $criticalUpdates
    }
}
catch {
    Write-Log -Message "Error checking Windows Update status: $($_.Exception.Message)" `
        -Level Error -Caller $MyInvocation.MyCommand.Name
    throw
}
