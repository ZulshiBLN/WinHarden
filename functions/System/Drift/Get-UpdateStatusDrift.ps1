function Get-UpdateStatusDrift {
    <#
    .SYNOPSIS
    Detects configuration drift in Windows Update settings.
    
    .DESCRIPTION
    Checks if automatic Windows updates are enabled.
    Returns PSCustomObject array with drift findings.
    
    .PARAMETER RequireAutoUpdates
    Whether automatic updates should be enabled (default: $true).
    
    .EXAMPLE
    $drifts = Get-UpdateStatusDrift
    if ($drifts.Count -gt 0) { $drifts | Write-Output }
    
    .NOTES
    DEPENDENCIES: Write-Log (Core)
    APPLIES TO: Windows Server 2016+
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [bool]$RequireAutoUpdates = $true
    )
    
    $findings = @()
    
    try {
        $updatePath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
        $updateProperty = Get-ItemProperty -Path $updatePath -Name NoAutoUpdate -ErrorAction SilentlyContinue
        $autoUpdate = $updateProperty.NoAutoUpdate
        $autoUpdateDisabled = $autoUpdate -eq 1
        if ($autoUpdateDisabled -eq $RequireAutoUpdates) {
            $findings += [PSCustomObject]@{
                Category = "Updates"
                Setting = "Automatic Updates"
                Expected = "Enabled"
                Actual = "Disabled"
                Status = "DRIFT"
                Severity = "MEDIUM"
            }
            Write-Log -Message "Update Status drift: Automatic updates disabled" `
                -Level Warning -Caller $MyInvocation.MyCommand.Name
        }
    }
    catch {
        Write-Log -Message "Error checking update status: $_" -Level Warning -Caller $MyInvocation.MyCommand.Name
    }
    
    return $findings
}
