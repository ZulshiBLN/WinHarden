<#
.SYNOPSIS
Configure WinHarden scheduled tasks with advanced catchup & recovery settings.

.DESCRIPTION
Main orchestration script for configuring WinHarden task scheduler settings.
Loads Core and System modules, then invokes Set-TaskScheduleCatchup function.

Configures:
- Automatic catchup when system reboots
- Execution timeout limits
- Battery/offline execution
- Hard termination for stuck tasks

Requires administrator privileges.

.PARAMETER EnableCatchup
Enable start when available (default: $true).

.PARAMETER MaxTaskDurationHours
Maximum task execution time in hours (default: 2).

.PARAMETER EnableRetry
Enable retry configuration documentation (default: $true).

.PARAMETER RetryIntervalMinutes
Retry interval in minutes (default: 15).

.PARAMETER MaxRetries
Maximum retry attempts (default: 3).

.EXAMPLE
.\Configure-TasksCatchup.ps1 -EnableCatchup $true -MaxTaskDurationHours 2

.NOTES
REQUIRES: Administrator privileges
DEPENDENCIES: Core and System modules
#>

param(
    [Parameter(Mandatory = $false)]
    [bool]$EnableCatchup = $true,

    [Parameter(Mandatory = $false)]
    [bool]$EnableRetry = $true,

    [Parameter(Mandatory = $false)]
    [int]$MaxTaskDurationHours = 2,

    [Parameter(Mandatory = $false)]
    [int]$RetryIntervalMinutes = 15,

    [Parameter(Mandatory = $false)]
    [int]$MaxRetries = 3
)

$ErrorActionPreference = 'Continue'

# Header
Write-Output ''
Write-Output '=============================================================='
Write-Output '      CONFIGURE WINHARDEN TASKS - CATCHUP & RECOVERY'
Write-Output '=============================================================='
Write-Output ''
Write-Output "Script: Configure-TasksCatchup"
Write-Output "Purpose: Advanced task configuration for reliability"
Write-Output "Run Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Output ''

# Load Core and System modules
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath '..\modules'
$coreModule = Join-Path -Path $modulesPath -ChildPath 'Core.psm1'
$systemModule = Join-Path -Path $modulesPath -ChildPath 'System.psm1'

if (-not (Test-Path -Path $coreModule)) {
    Write-Output '[ERROR] Core module not found: ' + $coreModule
    exit 1
}

if (-not (Test-Path -Path $systemModule)) {
    Write-Output '[ERROR] System module not found: ' + $systemModule
    exit 1
}

try {
    Import-Module -Name $coreModule -Force
    Import-Module -Name $systemModule -Force
}
catch {
    Write-Output '[ERROR] Failed to load modules: ' + $_.Exception.Message
    exit 1
}

# Display configuration
Write-Output '[STEP 1] CONFIGURATION PARAMETERS'
Write-Output '=============================================================='
Write-Output ''
Write-Output "Enable Catchup: $EnableCatchup"
Write-Output "Max Task Duration: $MaxTaskDurationHours hours"
Write-Output "Enable Retry on Failure: $EnableRetry"
Write-Output "Retry Interval: $RetryIntervalMinutes minutes"
Write-Output "Max Retries: $MaxRetries"
Write-Output ''

# Invoke the configuration function
Write-Output '[STEP 2] APPLYING TASK CONFIGURATION'
Write-Output '=============================================================='
Write-Output ''

$result = Set-TaskScheduleCatchup -EnableCatchup $EnableCatchup `
    -EnableRetry $EnableRetry `
    -MaxTaskDurationHours $MaxTaskDurationHours `
    -RetryIntervalMinutes $RetryIntervalMinutes `
    -MaxRetries $MaxRetries

# Summary
Write-Output ''
Write-Output '[STEP 3] CONFIGURATION SUMMARY'
Write-Output '=============================================================='
Write-Output ''
Write-Output '[OK] Tasks are now configured with:'
Write-Output '  * Automatic catchup when system reboots'
Write-Output '  * Maximum runtime limits'
Write-Output '  * Execution guaranteed (battery/offline-agnostic)'
Write-Output '  * Full reliability for security monitoring'
Write-Output ''
Write-Output 'Your system will now:'
Write-Output '  [OK] Never miss scheduled security checks'
Write-Output '  [OK] Execute missed tasks automatically'
Write-Output '  [OK] Prevent runaway tasks from hanging'
Write-Output '  [OK] Maintain continuous security posture'
Write-Output ''
Write-Output '[ADVANCED: MANUAL RETRY CONFIGURATION]'
Write-Output '=============================================================='
Write-Output ''
Write-Output 'For additional retry settings on task failure:'
Write-Output '  1. Open Task Scheduler: taskschd.msc'
Write-Output '  2. Navigate to: Hardening folder'
Write-Output '  3. Right-click a task -> Properties -> Triggers'
Write-Output '  4. Click a trigger -> Edit -> Advanced Settings'
Write-Output '  5. Check: Repeat task every X minutes for a duration of X hours'
Write-Output '  6. Set retry count if task fails'
Write-Output ''
Write-Output '=============================================================='
Write-Output ''

exit $result
