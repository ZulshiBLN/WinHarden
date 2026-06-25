#Requires -Version 5.1
<#
.SYNOPSIS
User and Group Management Module for WinOpsKit

.DESCRIPTION
Provides functions for user account, group, and permission management.
Part of the WinOpsKit infrastructure (ADR-008: Module Import Strategy).

Depends on: Core module (for logging and error handling)
#>

# Ensure Core module is loaded (ADR-009: Dependency Hierarchy)
Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'Core.psm1') -Force

# Import all User module functions from functions/User directory
$functionsPath = Join-Path -Path $PSScriptRoot -ChildPath '..\functions\User'

if (Test-Path -Path $functionsPath -PathType Container) {
    $publicFunctions = @()
    $privateFunctions = @()

    # Load private functions (prefixed with _)
    $privateFiles = Get-ChildItem -Path $functionsPath -Filter '_*.ps1' -ErrorAction SilentlyContinue
    foreach ($file in $privateFiles) {
        . $file.FullName
        $privateFunctions += $file.BaseName
    }

    # Load public functions
    $publicFiles = Get-ChildItem -Path $functionsPath -Filter '*.ps1' -Exclude '_*' -ErrorAction SilentlyContinue
    foreach ($file in $publicFiles) {
        . $file.FullName
        $publicFunctions += $file.BaseName
    }

    # Export public functions only
    if ($publicFunctions) {
        Export-ModuleMember -Function $publicFunctions
    }
}
