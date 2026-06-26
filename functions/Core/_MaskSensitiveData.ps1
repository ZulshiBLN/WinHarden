function _MaskSensitiveData {
    <#
    .SYNOPSIS
    Masks sensitive information patterns in text for safe logging.

    .DESCRIPTION
    Private helper function that replaces sensitive data (passwords, tokens, API keys, etc.)
    with asterisks (***) to prevent exposure in logs.
    Part of ADR-005 logging strategy for compliance and security.

    Detects patterns like:
    - password=secret123 -> password=***
    - token=abc123 -> token=***
    - apikey=xyz789 -> apikey=***

    .PARAMETER InputString
    The text to mask. Sensitive patterns will be replaced with ***.

    .NOTES
    - Called by Write-Log automatically
    - Case-insensitive matching for sensitive keywords
    - Replaces values between keyword and whitespace/delimiter
    - Sensitive keywords: password, token, secret, apikey, api_key, private_key, auth, credential
    - Part of compliance requirements (Regel 10.5)

    .EXAMPLE
    $masked = _MaskSensitiveData -InputString "password=MySecret123"
    # Returns: "password=***"
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
