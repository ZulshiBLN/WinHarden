<#
.SYNOPSIS
WinOpsKit Core Module - Central logging, error handling, and validation.

.DESCRIPTION
Core module provides foundational functions for all other WinOpsKit modules.
Loads functions from functions/Core/ directory:
- Write-Log: Centralized CSV-based logging with masking
- ConvertTo-MaskedString: Sensitive data masking
- Write-ErrorLog: Error logging wrapper
- Test-NotNullOrEmpty: Parameter validation
- Test-ValidPath: Path validation
- Get-ModuleVersion: Version and status info
- Test-WinOpsKitDependencies: Dependency validation

This module is ALWAYS loaded first by WinOpsKit scripts.

.NOTES
This module implements ADR-005 (Logging), ADR-004 (Error Handling), and ADR-008 (Module Import Strategy).
#>

$script:CoreModuleVersion = '1.0.0'

# Determine functions directory relative to this module
$functionsPath = Join-Path -Path $PSScriptRoot -ChildPath '..\functions\Core'

# Public functions to load
$publicFunctions = @(
    'Write-Log'
    'Write-ErrorLog'
    'ConvertTo-MaskedString'
    'Test-NotNullOrEmpty'
    'Test-ValidPath'
    'Get-ModuleVersion'
    'Test-WinOpsKitDependencies'
)

# Private helper functions to load
$privateFunctions = @(
    '_MaskSensitiveData'
    '_TestLogLevel'
    '_CleanupOldLogs'
)

# Load all functions
$allFunctions = $publicFunctions + $privateFunctions

foreach ($funcName in $allFunctions) {
    $funcFile = Join-Path -Path $functionsPath -ChildPath "$funcName.ps1"

    if (Test-Path -Path $funcFile -PathType Leaf) {
        . $funcFile
    }
    else {
        Write-Warning "Core function file not found: $funcFile"
    }
}

# Export only public functions
Export-ModuleMember -Function $publicFunctions

Write-Verbose "WinOpsKit Core Module v$script:CoreModuleVersion loaded with $($publicFunctions.Count) public functions"
