function ConvertTo-MaskedString {
    <#
    .SYNOPSIS
    Masks sensitive patterns in text for safe logging and output.

    .DESCRIPTION
    Replaces sensitive information (passwords, tokens, API keys, etc.) with asterisks.
    Automatically detects patterns like "password=secret" and masks the value.

    .PARAMETER Text
    Text to mask.

    .PARAMETER Pattern
    Optional custom regex pattern to match additional sensitive data.

    .EXAMPLE
    ConvertTo-MaskedString -Text "api_key=sk-1234567890"

    .EXAMPLE
    ConvertTo-MaskedString -Text "User entered password: MySecret123"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]
        $InputString,

        [Parameter(Mandatory = $false)]
        [string[]]
        $Pattern
    )

    $result = $InputString

    # Default sensitive patterns (case-insensitive)
    $defaultPatterns = @(
        'password',
        'token',
        'secret',
        'apikey',
        'api_key',
        'credential',
        'credentials',
        'authorization',
        'bearer'
    )

    # Combine default and custom patterns
    $allPatterns = $defaultPatterns + @($Pattern | Where-Object { $_ })

    # Replace each pattern's value with ***
    foreach ($pat in $allPatterns) {
        # Match: pattern (space/colon/equals) value
        $result = $result -ireplace "($pat[s]?[\s:=]+)([^\s]+)", "`$1***"
    }

    return $result
}
