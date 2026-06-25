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

    # Handle -WhatIf parameter
    if ($WhatIfPreference) {
        Write-Verbose "WhatIf: Would log error '$Message'"
        return
    }

    Write-Log -Message $Message -Level Error -Caller $Caller
}
