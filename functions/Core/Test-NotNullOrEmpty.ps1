function Test-NotNullOrEmpty {
    <#
    .SYNOPSIS
    Validates that a parameter value is not null or empty.

    .DESCRIPTION
    Checks if a string value is null, empty, or contains only whitespace.
    Logs error and throws exception if validation fails.

    .PARAMETER Value
    Value to validate.

    .PARAMETER Name
    Parameter name for error message.

    .EXAMPLE
    Test-NotNullOrEmpty -Value $computerName -Name "ComputerName"

    .EXAMPLE
    $result = Test-NotNullOrEmpty -Value "server01" -Name "ServerName"
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]
        $Value,

        [Parameter(Mandatory = $false)]
        [string]
        $Name = 'Value'
    )

    # Validate that value is not null, empty, or whitespace
    if ([string]::IsNullOrWhiteSpace($Value)) {
        $errorMessage = "$Name cannot be null or empty"
        Write-Log -Message $errorMessage -Level Error
        throw $errorMessage
    }

    return $true
}
