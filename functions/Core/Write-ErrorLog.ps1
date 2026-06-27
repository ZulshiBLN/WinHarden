function Write-ErrorLog {
    <#
    .SYNOPSIS
    Wrapper for Write-Log with Error level.

    .DESCRIPTION
    Convenience function that automatically sets log level to Error and logs the message.

    .PARAMETER Message
    Error message to log.

    .PARAMETER Caller
    Optional caller identifier.

    .EXAMPLE
    Write-ErrorLog -Message "Critical operation failed"

    .NOTES
    DEPENDENCIES: Requires Write-Log function (Core module)
    CREATED: 2026-06-25
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Message,

        [Parameter(Mandatory = $false)]
        [string]
        $Caller
    )

    Write-Log -Message $Message -Level Error -Caller $Caller
}
