function Get-ModuleVersion {
    <#
    .SYNOPSIS
    Returns WinOpsKit module version and status information.

    .DESCRIPTION
    Provides current WinOpsKit version, PowerShell version compatibility,
    build date, and implementation status.

    .EXAMPLE
    Get-ModuleVersion

    .EXAMPLE
    Get-ModuleVersion | Select-Object Version, Phase
    #>

    [CmdletBinding()]
    param()

    return @{
        Module = 'WinOpsKit'
        Version = '0.1.0'
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        BuildDate = (Get-Date).ToString('yyyy-MM-dd')
        Infrastructure = 'Complete (9 ADRs)'
        Phase = 'Implementation'
    }
}
