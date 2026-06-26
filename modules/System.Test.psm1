<#
.SYNOPSIS
WinHarden System Module - Test Version (only Get-AccountPoliciesDrift)

This is a test-specific module that loads only Get-AccountPoliciesDrift
to avoid elevation issues from other drift detection functions.
#>

# Ensure Core module is loaded first
$coreModulePath = Join-Path -Path $PSScriptRoot -ChildPath 'Core.psm1'
if (Test-Path -Path $coreModulePath) {
    Import-Module -Name $coreModulePath -Force
}

# Load only Get-AccountPoliciesDrift
$functionsPath = Join-Path -Path $PSScriptRoot -ChildPath '..\functions\System'
$funcFile = Join-Path -Path $functionsPath -ChildPath 'Drift\Get-AccountPoliciesDrift.ps1'

if (Test-Path -Path $funcFile -PathType Leaf) {
    . $funcFile
}

# Export only this function
Export-ModuleMember -Function 'Get-AccountPoliciesDrift'

Write-Verbose "WinHarden System.Test Module loaded (Get-AccountPoliciesDrift only)"
