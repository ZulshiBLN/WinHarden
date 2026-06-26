function Test-ValidPath {
    <#
    .SYNOPSIS
    Validates that a path exists.

    .DESCRIPTION
    Checks if a file or directory path exists.
    Logs error and throws exception if path doesn't exist.

    .PARAMETER Path
    Path to validate.

    .PARAMETER Name
    Path name for error message.

    .EXAMPLE
    Test-ValidPath -Path "C:\Config" -Name "ConfigPath"

    .EXAMPLE
    if (Test-ValidPath -Path $logFile) { Write-Log "Log file exists" -Level Info }

    .NOTES
    DEPENDENCIES: Write-Log (Core)
    Throws terminating error if path does not exist.
    Returns $true if validation succeeds.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Path,

        [Parameter(Mandatory = $false)]
        [string]
        $Name = 'Path'
    )

    if (-not (Test-Path -Path $Path)) {
        $errorMessage = "$Name does not exist: $Path"
        Write-Log -Message $errorMessage -Level Error
        throw $errorMessage
    }

    return $true
}
