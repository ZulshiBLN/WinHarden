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

    .NOTES
    Returns WinHarden module metadata including version, PowerShell compatibility,
    and current implementation phase. Used by scripts and build automation for
    version tracking and compatibility validation.
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
