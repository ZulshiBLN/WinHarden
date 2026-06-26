function New-HardeningSession {
    <#
    .SYNOPSIS
    Creates a new Windows hardening session with profile and target configuration.

    .DESCRIPTION
    Initializes a hardening session for applying security hardening rules to Windows clients
    or servers. Validates OS version, system prerequisites, and profile compatibility.

    Supports three hardening levels:
    - Basis: Minimum security requirements
    - Recommended: Standard security practices
    - Strict: Maximum security restrictions

    Operating systems supported:
    - Windows 11 (Client)
    - Windows Server 2019, 2022, 2025 (Server)

    Returns a session object that tracks applied rules, failures, and compliance state.

    .PARAMETER Profile
    The hardening profile to apply: Basis, Recommended, or Strict.
    Mandatory. Validates against supported profiles.

    .PARAMETER TargetSystem
    The system type being hardened: Client (Windows 11) or Server (2019/2022/2025).
    Mandatory. Determines OS-specific rule applicability.

    .PARAMETER OSVersion
    The operating system version number: 11 (Client) or 2019/2022/2025 (Server).
    Mandatory. Validated against TargetSystem parameter.

    .PARAMETER WhatIf
    When specified, simulates hardening without applying changes. All rules are evaluated
    but not executed. Useful for compliance testing and auditing.
    Optional. Default: $false

    .PARAMETER ComputerName
    Target computer for remote hardening. If omitted, applies to local system.
    Optional. Default: $env:COMPUTERNAME

    .EXAMPLE
    New-HardeningSession -Profile Recommended -TargetSystem Client -OSVersion 11

    Creates a hardening session for Windows 11 with Recommended profile locally.

    .EXAMPLE
    New-HardeningSession -Profile Strict -TargetSystem Server -OSVersion 2022 -WhatIf

    Simulates strict hardening for Windows Server 2022 without applying changes.

    .EXAMPLE
    $session = New-HardeningSession -Profile Basis -TargetSystem Server -OSVersion 2025
    $session | Invoke-SecurityHardening

    Creates a session object and pipes it to the hardening invocation function.

    .NOTES
    DEPENDENCIES: Write-Log (Core), Test-NotNullOrEmpty (Core)
    ERROR HANDLING: Throws on invalid profile or unsupported OS version
    LOGGING: All session creation events logged via Write-Log
    WHATIF SUPPORT: Full support via $WhatIfPreference
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $false)]
        [ValidateSet('Basis', 'Recommended', 'Strict')]
        [string]
        $Profile,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Client', 'Server')]
        [string]
        $TargetSystem,

        [Parameter(Mandatory = $true)]
        [ValidateScript({
            if ($TargetSystem -eq 'Client' -and $_ -notin @(11)) {
                throw "Client systems only support Windows 11. Provided: $_"
            }
            if ($TargetSystem -eq 'Server' -and $_ -notin @(2019, 2022, 2025)) {
                throw "Server systems only support 2019, 2022, or 2025. Provided: $_"
            }
            $true
        })]
        [int]
        $OSVersion,

        [Parameter(Mandatory = $false)]
        [string]
        $ComputerName = $env:COMPUTERNAME,

        [switch]
        $SkipPrerequisiteCheck
    )

    $ErrorActionPreference = 'Stop'

    try {
        Write-Log -Message "Initializing hardening session: Profile=$Profile, Target=$TargetSystem, OSVersion=$OSVersion" -Level Info

        # Validate prerequisites
        if (-not $SkipPrerequisiteCheck) {
            _ValidateHardeningPrerequisites -ComputerName $ComputerName
        }

        # Create session object
        $session = [ordered]@{
                SessionId            = [guid]::NewGuid().ToString()
                CreatedTime          = Get-Date
                Profile              = $Profile
                TargetSystem         = $TargetSystem
                OSVersion            = $OSVersion
                ComputerName         = $ComputerName
                WhatIfMode           = $WhatIfPreference
                State                = @{
                    TotalRules       = 0
                    AppliedRules     = @()
                    FailedRules      = @()
                    SkippedRules     = @()
                    ComplianceStatus = 'Pending'
                    StartTime        = $null
                    EndTime          = $null
                    Duration         = $null
                }
                Logs                 = @()
                ComplianceReport     = $null
            }

            # Validate profile compatibility with OS
            _ValidateProfileCompatibility -Session $session

            # Load profile rules count
        $profileRules = Get-HardeningProfile -ProfileName $Profile -TargetSystem $TargetSystem
        $session.State.TotalRules = @($profileRules.Rules).Count

        Write-Log -Message "Hardening session created successfully. SessionId=$($session.SessionId), Rules=$($session.State.TotalRules)" -Level Info

        # Return session as PSCustomObject for compatibility
        [PSCustomObject]$session
    }
    catch {
        Write-ErrorLog -Message "Failed to create hardening session: $($_.Exception.Message)" -Caller $MyInvocation.MyCommand.Name
        throw
    }
}

# ================================================================================
# Private Helper Functions
# ================================================================================

function _ValidateHardeningPrerequisites {
    <#
    .SYNOPSIS
    Validates that system prerequisites for hardening are met.
    #>
    [CmdletBinding()]
    param(
        [string]$ComputerName
    )

    # Check admin rights
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')
    if (-not $isAdmin) {
        throw "Administrator privileges required for hardening operations"
    }

    # Check if target computer is reachable
    if ($ComputerName -ne $env:COMPUTERNAME) {
        if (-not (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet)) {
            throw "Target computer '$ComputerName' is not reachable"
        }
    }

    Write-Log -Message "Hardening prerequisites validated successfully" -Level Info
}

function _ValidateProfileCompatibility {
    <#
    .SYNOPSIS
    Validates profile compatibility with target OS.
    #>
    [CmdletBinding()]
    param(
        [PSCustomObject]$Session
    )

    $compatibilityMatrix = @{
        'Client' = @{
            '11' = @('Basis', 'Recommended', 'Strict')
        }
        'Server' = @{
            '2019' = @('Basis', 'Recommended', 'Strict')
            '2022' = @('Basis', 'Recommended', 'Strict')
            '2025' = @('Basis', 'Recommended', 'Strict')
        }
    }

    $supportedProfiles = $compatibilityMatrix[$Session.TargetSystem][$Session.OSVersion.ToString()]

    if ($null -eq $supportedProfiles) {
        throw "Unsupported OS version for $($Session.TargetSystem): $($Session.OSVersion)"
    }

    if ($Session.Profile -notin $supportedProfiles) {
        throw "Profile '$($Session.Profile)' not supported for $($Session.TargetSystem) $($Session.OSVersion)"
    }
}
