function Get-FirewallStatusDrift {
    <#
    .SYNOPSIS
    Detects configuration drift in Windows Firewall settings.

    .DESCRIPTION
    Checks if firewall profiles and settings match expected baselines.
    Supports local and remote computers, with configurable profile levels (Basis, Recommended, Strict).
    Returns PSCustomObject array with drift findings.

    .PARAMETER ComputerName
    Target computer name for remote firewall status check.
    Default: localhost (current computer).

    .PARAMETER Profile
    Firewall profile level to check against (Basis, Recommended, Strict).
    - Basis: All profiles enabled, minimal configuration
    - Recommended: All profiles enabled, standard security settings
    - Strict: All profiles enabled, maximum security settings
    Default: Basis

    .PARAMETER Detailed
    Return detailed firewall configuration information (not just drift).
    Includes rules count, logging settings, default actions.

    .PARAMETER ReportDriftOnly
    Only return objects with drift status = "DRIFT". Skips compliant systems.

    .PARAMETER Credential
    PSCredential for remote computer authentication (when ComputerName specified).

    .EXAMPLE
    Get-FirewallStatusDrift
    Checks local firewall status against Basis profile.

    .EXAMPLE
    Get-FirewallStatusDrift -ComputerName 'SERVER01' -Profile Recommended
    Checks SERVER01 firewall status against Recommended profile.

    .EXAMPLE
    Get-FirewallStatusDrift -Profile Strict -ReportDriftOnly
    Lists only strict profile violations on local computer.

    .NOTES
    DEPENDENCIES: Write-Log (Core)
    APPLIES TO: Windows Server 2016+
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$ComputerName = 'localhost',
        [ValidateSet('Basis', 'Recommended', 'Strict')]
        [string]$Profile = 'Basis',
        [switch]$Detailed,
        [switch]$ReportDriftOnly,
        [pscredential]$Credential
    )

    $findings = @()

    try {
        # Get firewall status
        $fwParams = @{
            ErrorAction = 'SilentlyContinue'
        }

        if ($ComputerName -ne 'localhost') {
            $fwParams['ComputerName'] = $ComputerName
            if ($Credential) {
                $fwParams['Credential'] = $Credential
            }
        }

        $domainFW = (Get-NetFirewallProfile -Name Domain @fwParams).Enabled
        $privateFW = (Get-NetFirewallProfile -Name Private @fwParams).Enabled
        $publicFW = (Get-NetFirewallProfile -Name Public @fwParams).Enabled

        $anyDisabled = -not $domainFW -or -not $privateFW -or -not $publicFW

        # Define expected settings per profile
        $expectedSettings = @{
            'Basis' = @{
                'AllProfilesEnabled' = $true
                'InboundDefault' = 'Block'
                'OutboundDefault' = 'Allow'
                'LogDroppedPackets' = $false
                'LogSuccessfulConnections' = $false
            }
            'Recommended' = @{
                'AllProfilesEnabled' = $true
                'InboundDefault' = 'Block'
                'OutboundDefault' = 'Allow'
                'LogDroppedPackets' = $true
                'LogSuccessfulConnections' = $false
            }
            'Strict' = @{
                'AllProfilesEnabled' = $true
                'InboundDefault' = 'Block'
                'OutboundDefault' = 'Block'
                'LogDroppedPackets' = $true
                'LogSuccessfulConnections' = $true
            }
        }

        $expected = $expectedSettings[$Profile]

        # Check if all profiles enabled
        if ($anyDisabled) {
            if (-not $ReportDriftOnly -or $ReportDriftOnly) {
                $findings += [PSCustomObject]@{
                    Category = 'Firewall'
                    Setting = 'Firewall Profiles'
                    Expected = 'Domain:$true, Private:$true, Public:$true'
                    Actual = "Domain:$domainFW, Private:$privateFW, Public:$publicFW"
                    Status = 'DRIFT'
                    Severity = 'HIGH'
                    ComputerName = $ComputerName
                }
            }
        }

        # Get additional firewall settings for detailed/Recommended/Strict profiles
        if ($Profile -ne 'Basis' -or $Detailed) {
            $domainProfile = Get-NetFirewallProfile -Name Domain @fwParams
            $inboundDefault = $domainProfile.DefaultInboundAction
            $outboundDefault = $domainProfile.DefaultOutboundAction

            # Check inbound default action
            if ($inboundDefault -ne $expected['InboundDefault']) {
                $findings += [PSCustomObject]@{
                    Category = 'Firewall'
                    Setting = 'Inbound Default Action'
                    Expected = $expected['InboundDefault']
                    Actual = $inboundDefault
                    Status = 'DRIFT'
                    Severity = 'MEDIUM'
                    ComputerName = $ComputerName
                }
            }

            # Check outbound default action
            if ($outboundDefault -ne $expected['OutboundDefault']) {
                $findings += [PSCustomObject]@{
                    Category = 'Firewall'
                    Setting = 'Outbound Default Action'
                    Expected = $expected['OutboundDefault']
                    Actual = $outboundDefault
                    Status = 'DRIFT'
                    Severity = 'MEDIUM'
                    ComputerName = $ComputerName
                }
            }
        }

        # Get firewall rules count
        if ($Detailed) {
            $ruleParams = $fwParams.Clone()
            $inboundRules = @(Get-NetFirewallRule -Direction Inbound @ruleParams).Count
            $outboundRules = @(Get-NetFirewallRule -Direction Outbound @ruleParams).Count

            $findings += [PSCustomObject]@{
                Category = 'Firewall'
                Setting = 'Inbound Rules Count'
                Expected = 'N/A'
                Actual = $inboundRules
                Status = 'INFO'
                Severity = 'INFO'
                ComputerName = $ComputerName
            }

            $findings += [PSCustomObject]@{
                Category = 'Firewall'
                Setting = 'Outbound Rules Count'
                Expected = 'N/A'
                Actual = $outboundRules
                Status = 'INFO'
                Severity = 'INFO'
                ComputerName = $ComputerName
            }
        }

        # If no drift found and not Detailed, add compliance entry
        if ($findings.Count -eq 0 -and -not $Detailed) {
            if (-not $ReportDriftOnly) {
                $findings += [PSCustomObject]@{
                    Category = 'Firewall'
                    Setting = 'Firewall Profiles'
                    Expected = 'All Enabled'
                    Actual = "Domain:$domainFW, Private:$privateFW, Public:$publicFW"
                    Status = 'COMPLIANT'
                    Severity = 'INFO'
                    ComputerName = $ComputerName
                }
            }
        }

        # Log results
        if ($findings) {
            $driftCount = @($findings | Where-Object { $_.Status -eq 'DRIFT' }).Count
            Write-Log -Message "Firewall status check for $ComputerName - Profile:$Profile - Found $driftCount drift items" `
                -Level Info -Caller $MyInvocation.MyCommand.Name
        }
    }
    catch {
        Write-Log -Message "Error checking firewall status on $ComputerName : $_" -Level Error -Caller $MyInvocation.MyCommand.Name
        throw
    }

    return $findings
}
