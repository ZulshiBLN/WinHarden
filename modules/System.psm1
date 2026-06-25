<#
.SYNOPSIS
WinOpsKit System Module - Exchange Online and system administration functions.

.DESCRIPTION
System module provides Exchange Online connectivity and system administration functions.
Loads functions from functions/System/ directory:
- New-ExchangeOnlineConnection: Establishes Exchange Online connections

This module requires Core module to be loaded first.

.NOTES
This module implements ADR-008 (Module Import Strategy).
Depends on: Core module (for Write-Log, error handling)
#>

$script:SystemModuleVersion = '1.0.0'

# Determine functions directory relative to this module
$functionsPath = Join-Path -Path $PSScriptRoot -ChildPath '..\functions\System'

# Public functions to load
$publicFunctions = @(
    'New-ExchangeOnlineConnection'
)

# Private helper functions to load
$privateFunctions = @(
    '_ValidateExchangeModuleAvailable'
    '_VerifyExchangeOnlineConnection'
)

# Load all functions
$allFunctions = $publicFunctions + $privateFunctions

foreach ($funcName in $allFunctions) {
    $funcFile = Join-Path -Path $functionsPath -ChildPath "$funcName.ps1"

    if (Test-Path -Path $funcFile -PathType Leaf) {
        . $funcFile
    }
    else {
        Write-Warning "System function file not found: $funcFile"
    }
}

# Export only public functions
Export-ModuleMember -Function $publicFunctions

Write-Verbose "WinOpsKit System Module v$script:SystemModuleVersion loaded with $($publicFunctions.Count) public function(s)"
