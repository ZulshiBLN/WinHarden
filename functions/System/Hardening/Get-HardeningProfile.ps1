function Get-HardeningProfile {
    <#
    .SYNOPSIS
    Loads hardening profile configuration from definition files.

    .DESCRIPTION
    Retrieves a hardening profile (Basis, Recommended, or Strict) that contains
    all security rules applicable to the specified target system and OS version.

    Profile files are stored as PowerShell data files (.psd1) in the
    Hardening.Profiles directory. Each profile contains:
    - Rule names and definitions
    - Severity levels (Critical, High, Medium, Low)
    - OS-specific configurations
    - Profile-specific settings

    .PARAMETER ProfileName
    The name of the profile to load: Basis, Recommended, or Strict.
    Mandatory. Must match existing profile file names.

    .PARAMETER TargetSystem
    The system type: Client or Server. Determines which OS-specific rules are included.
    Mandatory.

    .PARAMETER OSVersion
    The specific OS version: 11 (Client) or 2019/2022/2025 (Server).
    Optional. If provided, validates profile compatibility.

    .EXAMPLE
    Get-HardeningProfile -ProfileName Recommended -TargetSystem Client

    Loads the Recommended profile for Windows 11 clients.

    .EXAMPLE
    $basis = Get-HardeningProfile -ProfileName Basis -TargetSystem Server -OSVersion 2022
    $basis.Rules | Select-Object -First 5

    Loads Basis profile for Server 2022 and displays first 5 rules.

    .NOTES
    DEPENDENCIES: Test-ValidPath (Core)
    ERROR HANDLING: Throws if profile file not found or invalid
    LOGGING: Profile loading events logged via Write-Log
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Basis', 'Recommended', 'Strict')]
        [string]
        $ProfileName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Client', 'Server')]
        [string]
        $TargetSystem,

        [Parameter(Mandatory = $false)]
        [int]
        $OSVersion
    )

    $ErrorActionPreference = 'Stop'

    if ($PSCmdlet.ShouldProcess("hardening profile '$ProfileName'", "Load")) {
        try {
            $profilePath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath "Hardening.Profiles\$ProfileName.psd1"

            Write-Log -Message "Loading hardening profile: $ProfileName for $TargetSystem" -Level Info

            # Validate profile file exists
            if (-not (Test-Path -Path $profilePath -PathType Leaf)) {
                throw "Profile file not found: $profilePath"
            }

            # Load profile data
            $profileData = Import-PowerShellDataFile -Path $profilePath

            if ($null -eq $profileData) {
                throw "Failed to load profile data from: $profilePath"
            }

            # Validate profile structure
            if (-not $profileData.ContainsKey('Profile') -or -not $profileData.ContainsKey('Rules')) {
                throw "Invalid profile structure in: $profilePath. Missing 'Profile' or 'Rules' keys."
            }

            # Filter rules by target system if rules are OS-specific
            $filteredRules = @()
            foreach ($rule in $profileData.Rules) {
                $include = $false

                # Check if rule supports target system
                if ($rule.ContainsKey('OSSupport')) {
                    $osSupport = $rule.OSSupport
                    if ($osSupport.ContainsKey($TargetSystem)) {
                        $versions = $osSupport[$TargetSystem]
                        if ($PSBoundParameters.ContainsKey('OSVersion')) {
                            # Filter by specific OS version
                            if ($OSVersion -in $versions) {
                                $include = $true
                            }
                        }
                        else {
                            # Include if any version is supported
                            $include = $true
                        }
                    }
                }
                else {
                    # Rule applies to all systems
                    $include = $true
                }

                if ($include) {
                    $filteredRules += $rule
                }
            }

            # Create result object
            $result = [ordered]@{
                ProfileName = $ProfileName
                TargetSystem = $TargetSystem
                OSVersion = $OSVersion
                ProfileMetadata = $profileData.Profile
                Rules = $filteredRules
                RuleCount = @($filteredRules).Count
                LoadedTime = Get-Date
            }

            Write-Log -Message "Profile loaded successfully: $($result.RuleCount) rules for $TargetSystem" -Level Info

            [PSCustomObject]$result
        }
        catch {
            Write-ErrorLog -Message "Failed to load hardening profile: $($_.Exception.Message)" -Caller $MyInvocation.MyCommand.Name
            throw
        }
    }
}
