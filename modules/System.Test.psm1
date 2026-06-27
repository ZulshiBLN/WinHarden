<#
.SYNOPSIS
WinHarden System Module - Test Version (only Get-AccountPoliciesDrift)

This is a test-specific module that loads only Get-AccountPoliciesDrift
to avoid elevation issues from other drift detection functions.

.NOTES
DEPENDS ON: Core.psm1 (Write-Log, error handling helpers)
DEPENDS ON: functions\System\Drift\Get-AccountPoliciesDrift.ps1
#>

# DEPENDS ON: Core.psm1, Get-AccountPoliciesDrift function (ADR-009 / Rule 12.3)
$ErrorActionPreference = 'Stop'

# Ensure Core module is loaded first (only load if not already imported to avoid namespace hiding)
$coreModulePath = Join-Path -Path $PSScriptRoot -ChildPath 'Core.psm1'
if (-not (Get-Module -Name Core -ErrorAction SilentlyContinue)) {
    if (Test-Path -Path $coreModulePath) {
        try {
            Import-Module -Name $coreModulePath -Force -ErrorAction Stop
        }
        catch {
            Write-Error "Failed to load Core module from '$coreModulePath': $_" -ErrorAction Stop
        }
    }
    else {
        Write-Error "Core module not found at: $coreModulePath" -ErrorAction Stop
    }
}

# Validate Core module loaded correctly (helps debug issues like Get-NetworkSecurityDrift Write-Log failure)
if (-not (Get-Command Write-Log -ErrorAction SilentlyContinue)) {
    Write-Error "Core module failed to load properly: Write-Log command not found" -ErrorAction Stop
}

# Load only Get-AccountPoliciesDrift
$functionsPath = Join-Path -Path $PSScriptRoot -ChildPath '..\functions\System'
$funcFile = Join-Path -Path $functionsPath -ChildPath 'Drift\Get-AccountPoliciesDrift.ps1'

if (Test-Path -Path $funcFile -PathType Leaf) {
    try {
        . $funcFile -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to load Get-AccountPoliciesDrift from '$funcFile': $_" -ErrorAction Stop
    }
}
else {
    Write-Error "Function file not found: $funcFile" -ErrorAction Stop
}

# Validate function loaded correctly
if (-not (Get-Command Get-AccountPoliciesDrift -ErrorAction SilentlyContinue)) {
    Write-Error "Function Get-AccountPoliciesDrift was not properly loaded" -ErrorAction Stop
}

# Export only this function
Export-ModuleMember -Function 'Get-AccountPoliciesDrift'

Write-Verbose "WinHarden System.Test Module loaded successfully (Get-AccountPoliciesDrift only)"
