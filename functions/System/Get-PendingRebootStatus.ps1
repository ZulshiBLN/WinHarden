<#
.SYNOPSIS
Checks if the system has a pending reboot due to Windows Updates.

.DESCRIPTION
Examines the Registry for pending file rename operations that indicate
a reboot is required for updates to take effect.

.PARAMETER None

.EXAMPLE
$rebootPending = Get-PendingRebootStatus
if ($rebootPending.IsPending) {
    Write-Output "Reboot required"
}

.NOTES
DEPENDENCIES: Write-Log (Core)
APPLIES TO: Windows Server 2016+, Windows 10+
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

try {
    $sessionPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager"
    $pendingReboot = $false

    if (Test-Path $sessionPath -ErrorAction SilentlyContinue) {
        $sessionManager = Get-Item -Path $sessionPath -ErrorAction SilentlyContinue
        if ($sessionManager.GetValueNames() -contains "PendingFileRenameOperations") {
            $pendingReboot = $true
            Write-Log -Message "Pending reboot detected: system requires restart for updates" `
                -Level Warning -Caller $MyInvocation.MyCommand.Name
        }
    }

    if (-not $pendingReboot) {
        Write-Log -Message "No pending reboot detected" -Level Info -Caller $MyInvocation.MyCommand.Name
    }

    $message = if ($pendingReboot) {
        "System requires restart for updates to take effect"
    }
    else {
        "No reboot required"
    }

    return [PSCustomObject]@{
        IsPending = $pendingReboot
        Message = $message
    }
}
catch {
    Write-Log -Message "Error checking pending reboot status: $($_.Exception.Message)" `
        -Level Error -Caller $MyInvocation.MyCommand.Name
    throw
}
