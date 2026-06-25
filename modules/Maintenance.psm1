#Requires -Version 5.1
<#
.SYNOPSIS
System Maintenance and Monitoring Module for WinOpsKit

.DESCRIPTION
Provides functions for system maintenance, updates, cleanup, and monitoring.
Part of the WinOpsKit infrastructure (ADR-008: Module Import Strategy).

Depends on: Core, System, and User modules
#>

# Ensure Core module is loaded first (ADR-009: Dependency Hierarchy)
Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'Core.psm1') -Force

# Optionally load System and User modules if they exist
$systemModulePath = Join-Path -Path $PSScriptRoot -ChildPath 'System.psm1'
if (Test-Path -Path $systemModulePath) {
    Import-Module -Name $systemModulePath -Force
}

$userModulePath = Join-Path -Path $PSScriptRoot -ChildPath 'User.psm1'
if (Test-Path -Path $userModulePath) {
    Import-Module -Name $userModulePath -Force
}

# Import all Maintenance module functions from functions/Maintenance directory
$functionsPath = Join-Path -Path $PSScriptRoot -ChildPath '..\functions\Maintenance'

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
