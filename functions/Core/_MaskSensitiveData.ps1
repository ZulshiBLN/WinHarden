function _MaskSensitiveData {
    <#
    .SYNOPSIS
    Masks sensitive information patterns in text for safe logging.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $InputString
    )

    $sensitivePrefixes = @(
        'password',
        'token',
        'secret',
        'apikey',
        'api_key',
        'private_key',
        'auth',
        'credential'
    )

    $maskedString = $InputString
    foreach ($prefix in $sensitivePrefixes) {
        $maskedString = $maskedString -replace "(?i)$prefix\s*[:=]\s*[^\s,;`"']*", "$prefix=***"
    }

    return $maskedString
}
