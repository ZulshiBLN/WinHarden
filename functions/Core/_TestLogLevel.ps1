function _TestLogLevel {
    <#
    .SYNOPSIS
    Evaluates if a log level should be logged based on the configured hierarchy.

    .DESCRIPTION
    Private helper function that determines whether a log entry at a specific level
    should be written. Implements hierarchical log level filtering (Error > Warning > Info > Debug > Verbose).

    Returns $true if the log level should be logged, $false otherwise.
    Respects the $env:LOG_LEVEL environment variable for runtime configuration.

    .PARAMETER Level
    The log level to check: Error, Warning, Info, Debug, or Verbose.

    .RETURNS
    Boolean. $true if the level should be logged; $false if it should be filtered.

    .NOTES
    - Called by Write-Log to determine if output is generated
    - Part of ADR-005 logging strategy
    - Hierarchy (highest to lowest): Error > Warning > Info > Debug > Verbose
    - Default log level: Info (if $env:LOG_LEVEL not set)
    - Can be controlled via: $env:LOG_LEVEL = 'Debug'

    .EXAMPLE
    if (_TestLogLevel -Level "Debug") {
        # Output only if DEBUG level is enabled
    }

    .EXAMPLE
    $env:LOG_LEVEL = 'Verbose'
    _TestLogLevel -Level "Debug"  # Returns $true
    _TestLogLevel -Level "Error"  # Returns $true
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Error', 'Warning', 'Info', 'Debug', 'Verbose')]
        [string]
        $Level
    )

    $logLevel = if ([string]::IsNullOrEmpty($env:LOG_LEVEL)) {
        'Info'
    }
    else {
        $env:LOG_LEVEL
    }
    $hierarchy = @('Error', 'Warning', 'Info', 'Debug', 'Verbose')

    $currentIndex = $hierarchy.IndexOf($Level)
    $maxIndex = $hierarchy.IndexOf($logLevel)

    return $currentIndex -le $maxIndex
}
