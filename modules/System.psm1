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

# Ensure Core module is loaded first (ADR-009: Dependency Hierarchy)
$coreModulePath = Join-Path -Path $PSScriptRoot -ChildPath 'Core.psm1'
if (Test-Path -Path $coreModulePath) {
    Import-Module -Name $coreModulePath -Force
}

# Determine functions directory relative to this module
$functionsPath = Join-Path -Path $PSScriptRoot -ChildPath '..\functions\System'

# Public functions to load
$publicFunctions = @(
    'New-ExchangeOnlineConnection',
    'New-HardeningSession',
    'Get-HardeningProfile',
    'Invoke-SecurityHardening',
    'Test-HardeningCompliance',
    'Export-HardeningReport',
    'Invoke-RemoteHardening',
    'New-HardeningSchedule'
)

# Private helper functions to load
$privateFunctions = @(
    '_ValidateExchangeModuleAvailable',
    '_VerifyExchangeOnlineConnection'
)

# Load all functions
$allFunctions = $publicFunctions + $privateFunctions

foreach ($funcName in $allFunctions) {
    # Check in root directory and Hardening subdirectory
    $funcFile = Join-Path -Path $functionsPath -ChildPath "$funcName.ps1"

    if (-not (Test-Path -Path $funcFile -PathType Leaf)) {
        $funcFile = Join-Path -Path $functionsPath -ChildPath "Hardening\$funcName.ps1"
    }

    if (Test-Path -Path $funcFile -PathType Leaf) {
        . $funcFile
    }
    else {
        Write-Warning "System function file not found: $funcName.ps1"
    }
}

# Export only public functions
Export-ModuleMember -Function $publicFunctions

Write-Verbose "WinOpsKit System Module v$script:SystemModuleVersion loaded with $($publicFunctions.Count) public function(s)"
