<#
.SYNOPSIS
WinHarden System Module - Windows Hardening System functions.

.DESCRIPTION
System module provides Windows security hardening capabilities.
Loads hardening functions from functions/System/Hardening/ directory:
- Session management
- Hardening rule application
- Compliance verification
- Reporting and analytics
- Remote deployment
- Automation and scheduling

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

# Public functions to load (Hardening)
$hardeningFunctions = @(
    'New-HardeningSession',
    'Get-HardeningProfile',
    'Invoke-SecurityHardening',
    'Test-HardeningCompliance',
    'Export-HardeningReport',
    'Invoke-RemoteHardening',
    'New-HardeningSchedule',
    'Import-HardeningGPO',
    'Send-HardeningAlert',
    'Get-HardeningTrendData'
)

# Public functions to load (Drift Detection)
$driftFunctions = @(
    'Get-AccountPoliciesDrift',
    'Get-NetworkSecurityDrift',
    'Get-RDPSecurityDrift',
    'Get-FirewallStatusDrift',
    'Get-AuditPoliciesDrift',
    'Get-UpdateStatusDrift',
    'Get-ServiceSecurityDrift',
    'Get-AutoUpdateConfiguration',
    'New-SecurityDriftReport'
)

$publicFunctions = $hardeningFunctions + $driftFunctions
$privateFunctions = @()

# Load all functions
$allFunctions = $publicFunctions + $privateFunctions

foreach ($funcName in $allFunctions) {
    # Check in root directory, Hardening subdirectory, and Drift subdirectory
    $funcFile = Join-Path -Path $functionsPath -ChildPath "$funcName.ps1"

    if (-not (Test-Path -Path $funcFile -PathType Leaf)) {
        $funcFile = Join-Path -Path $functionsPath -ChildPath "Hardening\$funcName.ps1"
    }

    if (-not (Test-Path -Path $funcFile -PathType Leaf)) {
        $funcFile = Join-Path -Path $functionsPath -ChildPath "Drift\$funcName.ps1"
    }

    if (Test-Path -Path $funcFile -PathType Leaf) {
        try {
            . $funcFile
        }
        catch {
            Write-Warning "Failed to load System function $($funcName): $($_.Exception.Message)"
        }
    }
    else {
        Write-Warning "System function file not found: $funcName.ps1"
    }
}

# Export only public functions
Export-ModuleMember -Function $publicFunctions

Write-Verbose "WinHarden System Module v$script:SystemModuleVersion loaded with $($publicFunctions.Count) public function(s)"
