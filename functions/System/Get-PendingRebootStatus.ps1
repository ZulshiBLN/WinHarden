function Get-PendingRebootStatus {
    <#
    .SYNOPSIS
    Checks if the system has a pending reboot due to Windows Updates.

    .DESCRIPTION
    Examines the Registry for pending file rename operations that indicate
    a reboot is required for updates to take effect. Supports WhatIf mode
    to preview what would be checked without making changes.

    .PARAMETER None

    .EXAMPLE
    $rebootPending = Get-PendingRebootStatus
    if ($rebootPending.IsPending) {
        Write-Output "Reboot required"
    }

    .EXAMPLE
    Get-PendingRebootStatus -WhatIf

    .NOTES
    DEPENDENCIES: Write-Log (Core)
    APPLIES TO: Windows Server 2016+, Windows 10+
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param()

    $ErrorActionPreference = 'Stop'

    try {
        if ($PSCmdlet.ShouldProcess('System', 'Check pending reboot status')) {
            $sessionPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager"
            $pendingReboot = $false

            if (Test-Path $sessionPath -ErrorAction SilentlyContinue) {
                $sessionManager = Get-Item -Path $sessionPath -ErrorAction SilentlyContinue
                if ($sessionManager.GetValueNames() -contains "PendingFileRenameOperations") {
                    $pendingReboot = $true
                    if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
                        Write-Log -Message "Pending reboot detected: system requires restart for updates" `
                            -Level Warning -Caller $MyInvocation.MyCommand.Name
                    }
                    else {
                        Write-Warning "Pending reboot detected: system requires restart for updates"
                    }
                }
            }

            if (-not $pendingReboot) {
                if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
                    Write-Log -Message "No pending reboot detected" -Level Info -Caller $MyInvocation.MyCommand.Name
                }
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
    }
    catch {
        if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
            Write-Log -Message "Error checking pending reboot status: $($_.Exception.Message)" `
                -Level Error -Caller $MyInvocation.MyCommand.Name
        }
        else {
            Write-Error "Error checking pending reboot status: $($_.Exception.Message)"
        }
        throw
    }
}
