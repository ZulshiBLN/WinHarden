function Get-AutoUpdateConfiguration {
    <#
    .SYNOPSIS
    Retrieves the current Windows automatic update configuration.

    .DESCRIPTION
    Reads the automatic update settings from the Windows Registry (Group Policy).
    Returns a PSCustomObject with the AU policy setting and human-readable description.

    .PARAMETER None

    .EXAMPLE
    $config = Get-AutoUpdateConfiguration
    Write-Output "Auto-Update Policy: $($config.Description)"

    .NOTES
    DEPENDENCIES: Write-Log (Core)
    APPLIES TO: Windows Server 2016+, Windows 10+
    #>

    [CmdletBinding()]
    param()

    $ErrorActionPreference = 'Stop'

    try {
        $auPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
        $autoUpdatePolicy = (Get-ItemProperty -Path $auPath -Name AUOptions `
                -ErrorAction SilentlyContinue).AUOptions

        $autoUpdateSettings = @{
            1 = "Keep my computer current is disabled"
            2 = "Notify for download and auto install"
            3 = "Auto download and notify for install"
            4 = "Auto download and schedule install"
            5 = "Automatic Updates required, auto install at 3:00 AM"
        }

        if ($autoUpdatePolicy) {
            $description = $autoUpdateSettings[[int]$autoUpdatePolicy]
            Write-Log -Message "Auto-Update Configuration retrieved: Policy=$autoUpdatePolicy" `
                -Level Info -Caller $MyInvocation.MyCommand.Name

            return [PSCustomObject]@{
                PolicyValue = $autoUpdatePolicy
                Description = $description
                IsEnabled = $autoUpdatePolicy -ne 1
            }
        }
        else {
            Write-Log -Message "Auto-Update uses default Windows settings (no Group Policy override)" `
                -Level Info -Caller $MyInvocation.MyCommand.Name

            return [PSCustomObject]@{
                PolicyValue = $null
                Description = "Default Windows settings (no Group Policy override)"
                IsEnabled = $true
            }
        }
    }
    catch {
        Write-Log -Message "Error retrieving Auto-Update configuration: $($_.Exception.Message)" `
            -Level Error -Caller $MyInvocation.MyCommand.Name
        throw
    }
}
