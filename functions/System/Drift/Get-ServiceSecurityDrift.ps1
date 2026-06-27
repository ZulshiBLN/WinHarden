function Get-ServiceSecurityDrift {
    <#
    .SYNOPSIS
    Detects configuration drift in Windows service security settings.

    .DESCRIPTION
    Comprehensive service security drift detection covering dangerous services,
    service startup types, and service account configurations. Supports profile-based
    configurations (Basis, Recommended, Strict) and multi-system deployment.
    Returns PSCustomObject array with detailed drift findings.

    .PARAMETER Profile
    Hardening profile to check against: Basis, Recommended, or Strict (default: Recommended).
    Profile determines which services should be disabled or running.

    .PARAMETER ComputerName
    Target computer for remote drift detection (default: localhost).
    For remote computers, WinRM must be enabled and user must have admin rights.

    .PARAMETER Credential
    PSCredential object for remote connection (optional, required for remote computers).

    .PARAMETER Detailed
    Switch to include detailed service information (startup type, status, account, etc.).

    .PARAMETER ReportDriftOnly
    Switch to return only services with detected drift (excludes compliant services).

    .EXAMPLE
    Get-ServiceSecurityDrift -Profile Recommended -Detailed

    Detects service drift against Recommended profile with detailed information.

    .EXAMPLE
    Get-ServiceSecurityDrift -ComputerName SERVER01 -Credential $cred -ReportDriftOnly

    Checks remote computer and returns only drifted services.

    .NOTES
    DEPENDENCIES: Write-Log (Core), Get-HardeningProfile (System)
    APPLIES TO: Windows Server 2016+ and Windows 11+
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [ValidateSet('Basis', 'Recommended', 'Strict')]
        [string]$Profile = 'Recommended',

        [ValidateNotNullOrEmpty()]
        [string]$ComputerName = 'localhost',

        [System.Management.Automation.PSCredential]$Credential,

        [switch]$Detailed,

        [switch]$ReportDriftOnly
    )

    $ErrorActionPreference = 'Stop'
    $findings = @()

    try {
        Write-Log -Message "Starting service security drift detection (Profile: $Profile, ComputerName: $ComputerName)" `
            -Level Info -Caller $MyInvocation.MyCommand.Name

        # Determine target system type
        $targetSystem = 'Server'
        if ($ComputerName -eq 'localhost') {
            $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
            if ($osInfo.ProductType -eq 1) {
                $targetSystem = 'Client'
            }
        }

        # Load hardening profile for service rules
        $hardeningProfile = Get-HardeningProfile -ProfileName $Profile -TargetSystem $targetSystem `
            -ErrorAction SilentlyContinue

        if ($null -eq $hardeningProfile) {
            throw "Failed to load hardening profile: $Profile"
        }

        # Extract service rules from profile
        $serviceRules = $hardeningProfile.Rules | Where-Object { $_.Type -eq 'Service' }

        # Build target services list from profile rules
        $targetServices = @()
        foreach ($rule in $serviceRules) {
            if ($rule.RuleDefinition.ContainsKey('ServiceName')) {
                $targetServices += @{
                    Name = $rule.RuleDefinition.ServiceName
                    Expected = $rule.RuleDefinition.StartType
                    Severity = $rule.Severity
                    Rule = $rule.Name
                }
            }
            elseif ($rule.RuleDefinition.ContainsKey('Services')) {
                foreach ($svc in $rule.RuleDefinition.Services) {
                    $targetServices += @{
                        Name = $svc
                        Expected = $rule.RuleDefinition.StartType
                        Severity = $rule.Severity
                        Rule = $rule.Name
                    }
                }
            }
        }

        # Add critical services that should always be monitored
        $criticalServices = @(
            @{ Name = 'wuauserv'; Expected = 'Automatic'; Severity = 'CRITICAL'; Rule = 'Service-WindowsUpdate' },
            @{ Name = 'WinDefend'; Expected = 'Automatic'; Severity = 'CRITICAL'; Rule = 'Service-WindowsDefender' },
            @{ Name = 'mpssvc'; Expected = 'Automatic'; Severity = 'CRITICAL'; Rule = 'Service-Firewall' },
            @{ Name = 'Audiosrv'; Expected = 'Manual'; Severity = 'MEDIUM'; Rule = 'Service-AudioMonitoring' },
            @{ Name = 'DiagTrack'; Expected = 'Disabled'; Severity = 'HIGH'; Rule = 'Service-DiagnosticTracking' },
            @{ Name = 'dmwappushservice'; Expected = 'Disabled'; Severity = 'MEDIUM'; Rule = 'Service-MobileDevice' },
            @{ Name = 'TermService'; Expected = 'Manual'; Severity = 'MEDIUM'; Rule = 'Service-RemoteDesktop' }
        )

        # Merge critical services with profile-based services (avoid duplicates)
        $existingNames = $targetServices.Name -as [System.Collections.Generic.HashSet[string]]
        foreach ($criticalService in $criticalServices) {
            if ($criticalService.Name -notin $existingNames) {
                $targetServices += $criticalService
            }
        }

        # Query services (local or remote)
        if ($PSCmdlet.ShouldProcess("Service security drift detection on $ComputerName", "Check")) {
            $scriptBlock = {
                param([string[]]$serviceNames)
                Get-Service -Name $serviceNames -ErrorAction SilentlyContinue |
                    Select-Object Name, DisplayName, StartType, Status
            }

            if ($ComputerName -eq 'localhost') {
                $services = & $scriptBlock -serviceNames @($targetServices.Name)
            }
            else {
                if ($null -eq $Credential) {
                    $services = Invoke-Command -ComputerName $ComputerName `
                        -ScriptBlock $scriptBlock -ArgumentList @($targetServices.Name) -ErrorAction SilentlyContinue
                }
                else {
                    $services = Invoke-Command -ComputerName $ComputerName -Credential $Credential `
                        -ScriptBlock $scriptBlock -ArgumentList @($targetServices.Name) -ErrorAction SilentlyContinue
                }
            }

            # Analyze drift for each service
            foreach ($serviceConfig in $targetServices) {
                $service = $services | Where-Object { $_.Name -eq $serviceConfig.Name }

                if ($null -eq $service) {
                    # Service not found on system
                    $findings += [PSCustomObject]@{
                        Category = 'Service.Hardening'
                        ServiceName = $serviceConfig.Name
                        Rule = $serviceConfig.Rule
                        Expected = $serviceConfig.Expected
                        Actual = 'NOT_FOUND'
                        Status = 'DRIFT'
                        Severity = $serviceConfig.Severity
                        Remediation = "Install or enable service: $($serviceConfig.Name)"
                    }

                    Write-Log -Message "Service drift: $($serviceConfig.Name) not found (expected $($serviceConfig.Expected))" `
                        -Level Warning -Caller $MyInvocation.MyCommand.Name
                }
                elseif ($service.StartType -ne $serviceConfig.Expected) {
                    # Service startup type mismatch
                    $findings += [PSCustomObject]@{
                        Category = 'Service.Hardening'
                        ServiceName = $serviceConfig.Name
                        DisplayName = $service.DisplayName
                        Rule = $serviceConfig.Rule
                        Expected = $serviceConfig.Expected
                        Actual = $service.StartType
                        Status = 'DRIFT'
                        Severity = $serviceConfig.Severity
                        ComputerName = $ComputerName
                        CurrentStatus = $service.Status
                        Remediation = "Set-Service -Name $($serviceConfig.Name) -StartupType $($serviceConfig.Expected)"
                    }

                    Write-Log -Message "Service drift: $($serviceConfig.Name) startup type is $($service.StartType) (expected $($serviceConfig.Expected))" `
                        -Level Warning -Caller $MyInvocation.MyCommand.Name
                }
                elseif (-not $ReportDriftOnly -and $Detailed) {
                    # Service is compliant - include in detailed output
                    $findings += [PSCustomObject]@{
                        Category = 'Service.Hardening'
                        ServiceName = $serviceConfig.Name
                        DisplayName = $service.DisplayName
                        Rule = $serviceConfig.Rule
                        Expected = $serviceConfig.Expected
                        Actual = $service.StartType
                        Status = 'COMPLIANT'
                        Severity = $serviceConfig.Severity
                        ComputerName = $ComputerName
                        CurrentStatus = $service.Status
                        Remediation = 'None'
                    }
                }
            }
        }

        # Filter if ReportDriftOnly is specified
        if ($ReportDriftOnly) {
            $findings = $findings | Where-Object { $_.Status -eq 'DRIFT' }
        }

        Write-Log -Message "Service security drift detection complete: $($findings.Count) findings" `
            -Level Info -Caller $MyInvocation.MyCommand.Name

        return $findings
    }
    catch {
        Write-ErrorLog -Message "Error during service security drift detection: $($_.Exception.Message)" `
            -Caller $MyInvocation.MyCommand.Name
        throw
    }
}
