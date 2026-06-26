function Get-ModuleVersion {
    <#
    .SYNOPSIS
    Returns WinHarden module version and status information.

    .DESCRIPTION
    Provides current WinHarden version, PowerShell version compatibility,
    build date, and implementation status.

    .EXAMPLE
    Get-ModuleVersion

    .EXAMPLE
    Get-ModuleVersion | Select-Object Version, Phase
    #>

    [CmdletBinding()]
    param()

    return @{
        Module = 'WinHarden'
        Version = '0.1.0'
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        BuildDate = (Get-Date).ToString('yyyy-MM-dd')
        Infrastructure = 'Complete (9 ADRs)'
        Phase = 'Implementation'
    }
}
