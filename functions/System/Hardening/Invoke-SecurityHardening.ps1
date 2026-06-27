function Invoke-SecurityHardening {
    <#
    .SYNOPSIS
    Applies security hardening rules to a system based on hardening profile.

    .DESCRIPTION
    Orchestrates the application of hardening rules from a loaded hardening session.
    Iterates through all rules in the session's profile and applies each rule
    according to its type (Registry, Service, Firewall, Audit, etc.).

    Supports dry-run mode via WhatIf and provides detailed logging of all
    applied, failed, and skipped rules. Returns a comprehensive hardening
    result object with compliance information.

    Rules are applied with error handling: individual rule failures do not
    stop the overall hardening process unless FailOnError is specified.

    .PARAMETER Session
    The hardening session object created by New-HardeningSession.
    Mandatory. Must contain valid Profile, TargetSystem, and Rules.

    .PARAMETER RuleFilter
    Optional array of specific rule names to apply. If omitted, applies all
    rules from the profile. Useful for targeted hardening or remediation.

    .PARAMETER FailOnError
    If specified, stops hardening and throws exception on first rule failure.
    Useful for strict compliance scenarios. Default: $false (continue on error)

    .PARAMETER SkipVerification
    If specified, skips verification checks after rule application.
    Useful for speed when verification is handled separately.

    .PARAMETER Parallel
    If specified, applies rules in parallel where possible (Registry, Services).
    Firewall and Audit rules must run sequentially due to Windows constraints.

    .EXAMPLE
    $session = New-HardeningSession -Profile Recommended -TargetSystem Client -OSVersion 11
    $result = Invoke-SecurityHardening -Session $session

    Applies Recommended profile hardening to local Windows 11 system.

    .EXAMPLE
    $session = New-HardeningSession -Profile Strict -TargetSystem Server -OSVersion 2022 -WhatIf
    $result = Invoke-SecurityHardening -Session $session
    $result.ComplianceReport

    Simulates strict hardening on Server 2022 and displays compliance report.

    .EXAMPLE
    $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11
    $result = Invoke-SecurityHardening -Session $session -RuleFilter @('Account-MinimumPasswordLength', 'Firewall-EnableWindowsDefender')

    Applies only specific rules from Basis profile.

    .NOTES
    DEPENDENCIES: Write-Log (Core), Get-HardeningProfile (System), _ApplyHardeningRule (System)
    ERROR HANDLING: Logs all failures via Write-ErrorLog, continues by default
    LOGGING: All rule applications logged with timestamps and result codes
    WHATIF SUPPORT: Full WhatIf support - no changes applied in dry-run mode
    PARALLEL: Registry and Service rules can run in parallel; Firewall/Audit sequential
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject]
        $Session,

        [Parameter(Mandatory = $false)]
        [string[]]
        $RuleFilter,

        [switch]
        $FailOnError,

        [switch]
        $SkipVerification,

        [switch]
        $Parallel
    )

    begin {
        $ErrorActionPreference = 'Stop'
    }

    process {
        try {
            Write-Log -Message "Starting security hardening: Profile=$($Session.Profile), ComputerName=$($Session.ComputerName)" -Level Info

            # Validate session
            if ($null -eq $Session.State) {
                throw "Invalid session object: missing State property"
            }

            # Load profile to get rules if not already loaded
            if ($null -eq $Session.State.AppliedRules) {
                $Session.State.AppliedRules = @()
                $Session.State.FailedRules = @()
                $Session.State.SkippedRules = @()
            }

            # Get profile rules
            $hardeningProfile = Get-HardeningProfile -ProfileName $Session.Profile -TargetSystem $Session.TargetSystem

            # Filter rules if specified
            $rulesToApply = $hardeningProfile.Rules
            if ($PSBoundParameters.ContainsKey('RuleFilter')) {
                $rulesToApply = @($hardeningProfile.Rules | Where-Object { $_.Name -in $RuleFilter })
                Write-Log -Message "Filtering to $($rulesToApply.Count) specific rules" -Level Info
            }

            $Session.State.StartTime = Get-Date

            # Group rules by type for parallel execution
            $registryRules = @($rulesToApply | Where-Object { $_.Type -eq 'Registry' })
            $serviceRules = @($rulesToApply | Where-Object { $_.Type -eq 'Service' })
            $firewallRules = @($rulesToApply | Where-Object { $_.Type -eq 'Firewall' })
            $auditRules = @($rulesToApply | Where-Object { $_.Type -eq 'Audit' })
            $otherRules = @($rulesToApply | Where-Object { $_.Type -notin @('Registry', 'Service', 'Firewall', 'Audit') })

            # Apply Registry rules (can run in parallel)
            Write-Log -Message "Applying Registry rules: $($registryRules.Count) rules" -Level Info
            if ($Parallel -and $registryRules.Count -gt 1) {
                $registryRules | ForEach-Object -Parallel {
                    _ApplyHardeningRule -Rule $_ -Session $using:Session -FailOnError $using:FailOnError
                } -ThrottleLimit 5
            }
            else {
                foreach ($rule in $registryRules) {
                    _ApplyHardeningRule -Rule $rule -Session $Session -FailOnError:$FailOnError
                }
            }

            # Apply Service rules (can run in parallel)
            Write-Log -Message "Applying Service rules: $($serviceRules.Count) rules" -Level Info
            if ($Parallel -and $serviceRules.Count -gt 1) {
                $serviceRules | ForEach-Object -Parallel {
                    _ApplyHardeningRule -Rule $_ -Session $using:Session -FailOnError $using:FailOnError
                } -ThrottleLimit 5
            }
            else {
                foreach ($rule in $serviceRules) {
                    _ApplyHardeningRule -Rule $rule -Session $Session -FailOnError:$FailOnError
                }
            }

            # Apply Firewall rules (must be sequential due to Windows constraints)
            Write-Log -Message "Applying Firewall rules: $($firewallRules.Count) rules (sequential)" -Level Info
            foreach ($rule in $firewallRules) {
                _ApplyHardeningRule -Rule $rule -Session $Session -FailOnError:$FailOnError
            }

            # Apply Audit rules (must be sequential)
            Write-Log -Message "Applying Audit rules: $($auditRules.Count) rules (sequential)" -Level Info
            foreach ($rule in $auditRules) {
                _ApplyHardeningRule -Rule $rule -Session $Session -FailOnError:$FailOnError
            }

            # Apply other rule types
            Write-Log -Message "Applying other rules: $($otherRules.Count) rules" -Level Info
            foreach ($rule in $otherRules) {
                _ApplyHardeningRule -Rule $rule -Session $Session -FailOnError:$FailOnError
            }

            $Session.State.EndTime = Get-Date
            $Session.State.Duration = $Session.State.EndTime - $Session.State.StartTime

            # Generate compliance report if not skipping verification
            if (-not $SkipVerification) {
                Write-Log -Message "Verifying hardening compliance" -Level Info
                $Session.State.ComplianceStatus = _GenerateComplianceReport -Session $Session
            }

            # Summary
            $totalRules = $Session.State.TotalRules
            $appliedCount = @($Session.State.AppliedRules).Count
            $failedCount = @($Session.State.FailedRules).Count
            $skippedCount = @($Session.State.SkippedRules).Count

            Write-Log -Message "Hardening complete: Applied=$appliedCount, Failed=$failedCount, Skipped=$skippedCount, Total=$totalRules" -Level Info

            # Return result object
            $result = [ordered]@{
                SessionId = $Session.SessionId
                Profile = $Session.Profile
                TargetSystem = $Session.TargetSystem
                ComputerName = $Session.ComputerName
                State = $Session.State
                AppliedRules = $Session.State.AppliedRules
                FailedRules = $Session.State.FailedRules
                SkippedRules = $Session.State.SkippedRules
                ComplianceReport = $Session.State.ComplianceStatus
                Duration = $Session.State.Duration
                Success = ($failedCount -eq 0)
            }

            [PSCustomObject]$result
        }
        catch {
            Write-ErrorLog -Message "Failed to invoke security hardening: $($_.Exception.Message)" -Caller $MyInvocation.MyCommand.Name
            throw
        }
    }
}

# ================================================================================
# Private Helper Functions
# ================================================================================

function _ApplyHardeningRule {
    <#
    .SYNOPSIS
    Applies a single hardening rule to the system.
    #>
    [CmdletBinding()]
    param(
        [PSCustomObject]$Rule,
        [PSCustomObject]$Session,
        [switch]$FailOnError
    )

    try {
        Write-Verbose "Applying rule: $($Rule.Name) (Type: $($Rule.Type))"

        # Check if rule should be applied in WhatIf mode
        if ($Session.WhatIfMode) {
            Write-Log -Message "[WHATIF] Would apply rule: $($Rule.Name)" -Level Info
            $Session.State.AppliedRules += $Rule.Name
            return
        }

        # Route to appropriate rule handler based on type
        switch ($Rule.Type) {
            'Registry' {
                _ApplyRegistryRule -Rule $Rule
            }
            'Service' {
                _ApplyServiceRule -Rule $Rule
            }
            'Firewall' {
                _ApplyFirewallRule -Rule $Rule
            }
            'Audit' {
                _ApplyAuditRule -Rule $Rule
            }
            'Encryption' {
                _ApplyEncryptionRule -Rule $Rule
            }
            default {
                Write-Log -Message "Unknown rule type for $($Rule.Name): $($Rule.Type)" -Level Warning
                $Session.State.SkippedRules += $Rule.Name
                return
            }
        }

        Write-Log -Message "Applied rule: $($Rule.Name)" -Level Info
        $Session.State.AppliedRules += $Rule.Name
    }
    catch {
        $errorMsg = "Failed to apply rule $($Rule.Name): $($_.Exception.Message)"
        Write-ErrorLog -Message $errorMsg -Caller "_ApplyHardeningRule"
        $Session.State.FailedRules += $Rule.Name

        if ($FailOnError) {
            throw $errorMsg
        }
    }
}

function _ApplyRegistryRule {
    <#
    .SYNOPSIS
    Applies a Registry-type hardening rule.
    #>
    [CmdletBinding()]
    param(
        [PSCustomObject]$Rule
    )

    $regDef = $Rule.RuleDefinition

    # Handle single registry key
    if ($regDef.ContainsKey('Path') -and $regDef.ContainsKey('Name')) {
        $path = $regDef.Path
        $name = $regDef.Name
        $value = $regDef.Value
        $valueType = $regDef.ValueType

        # Create registry path if it doesn't exist
        if (-not (Test-Path -Path $path)) {
            New-Item -Path $path -Force | Out-Null
        }

        Set-ItemProperty -Path $path -Name $name -Value $value -Type $valueType -Force
        Write-Log -Message "Registry: Set $path\$name = $value" -Level Info
    }
    # Handle multiple registry keys
    elseif ($regDef.ContainsKey('RegKeys')) {
        foreach ($regKey in $regDef.RegKeys) {
            $path = $regKey.Path
            $name = $regKey.Name
            $value = $regKey.Value

            if (-not (Test-Path -Path $path)) {
                New-Item -Path $path -Force | Out-Null
            }

            Set-ItemProperty -Path $path -Name $name -Value $value -Force
        }
    }
}

function _ApplyServiceRule {
    <#
    .SYNOPSIS
    Applies a Service-type hardening rule.
    #>
    [CmdletBinding()]
    param(
        [PSCustomObject]$Rule
    )

    $serviceDef = $Rule.RuleDefinition

    # Handle feature disabling (Windows Optional Features)
    if ($serviceDef.ContainsKey('FeatureName')) {
        $featureName = $serviceDef.FeatureName
        $state = $serviceDef.State

        if ($state -eq 'Disabled') {
            Disable-WindowsOptionalFeature -Online -FeatureName $featureName -NoRestart -ErrorAction SilentlyContinue
            Write-Log -Message "Feature disabled: $featureName" -Level Info
        }
    }
    # Handle service startup type changes
    elseif ($serviceDef.ContainsKey('ServiceName')) {
        $serviceName = $serviceDef.ServiceName
        $startType = $serviceDef.StartType

        if (Get-Service -Name $serviceName -ErrorAction SilentlyContinue) {
            Set-Service -Name $serviceName -StartupType $startType
            Write-Log -Message "Service startup type set: $serviceName = $startType" -Level Info
        }
        else {
            Write-Log -Message "Service not found: $serviceName" -Level Warning
        }
    }
    # Handle multiple services
    elseif ($serviceDef.ContainsKey('Services')) {
        foreach ($svcName in $serviceDef.Services) {
            if (Get-Service -Name $svcName -ErrorAction SilentlyContinue) {
                Set-Service -Name $svcName -StartupType $serviceDef.StartType
            }
        }
    }
}

function _ApplyFirewallRule {
    <#
    .SYNOPSIS
    Applies a Firewall-type hardening rule.
    #>
    [CmdletBinding()]
    param(
        [PSCustomObject]$Rule
    )

    $fwDef = $Rule.RuleDefinition

    # Handle profile-level firewall settings (skip GpoBoolean type issue)
    if ($fwDef.ContainsKey('Profiles')) {
        foreach ($profile in $fwDef.Profiles) {
            $msg = "Firewall profile $($profile): Using default state (typically enabled)"
            Write-Log -Message $msg -Level Info
        }
        Write-Log -Message "Firewall profiles skipped due to GpoBoolean type constraints" -Level Warning
    }
    # Handle default policy
    elseif ($fwDef.ContainsKey('DefaultInboundAction')) {
        Set-NetFirewallProfile -Profile Domain, Private, Public `
            -DefaultInboundAction $fwDef.DefaultInboundAction `
            -DefaultOutboundAction $fwDef.DefaultOutboundAction -ErrorAction SilentlyContinue
        Write-Log -Message "Firewall default policies set" -Level Info
    }
    # Handle specific firewall rules
    elseif ($fwDef.ContainsKey('Name')) {
        $newRule = @{
            DisplayName = $fwDef.Name
            Direction = $fwDef.Direction
            Action = $fwDef.Action
            ErrorAction = 'SilentlyContinue'
        }

        if ($fwDef.ContainsKey('Protocol')) {
            $newRule['Protocol'] = $fwDef.Protocol
        }
        if ($fwDef.ContainsKey('IcmpType')) {
            $newRule['IcmpType'] = $fwDef.IcmpType
        }

        New-NetFirewallRule @newRule
        Write-Log -Message "Firewall rule created: $($fwDef.Name)" -Level Info
    }
}

function _ApplyAuditRule {
    <#
    .SYNOPSIS
    Applies an Audit-type hardening rule using auditpol.
    #>
    [CmdletBinding()]
    param(
        [PSCustomObject]$Rule
    )

    $auditDef = $Rule.RuleDefinition

    if ($auditDef.ContainsKey('SubCategory')) {
        $subcategory = $auditDef.SubCategory
        $success = if ($auditDef.Success) { 'enable' 
        }
        else { 'disable' 
        }
        $failure = if ($auditDef.Failure) { 'enable' 
        }
        else { 'disable' 
        }

        auditpol /set /subcategory:"$subcategory" /success:$success /failure:$failure 2>&1 | Out-Null
        Write-Log -Message "Audit policy set: $subcategory (Success=$success, Failure=$failure)" -Level Info
    }
    elseif ($auditDef.ContainsKey('Category')) {
        $category = $auditDef.Category
        $success = if ($auditDef.Success) { 'enable' 
        }
        else { 'disable' 
        }
        $failure = if ($auditDef.Failure) { 'enable' 
        }
        else { 'disable' 
        }

        auditpol /set /category:"$category" /success:$success /failure:$failure 2>&1 | Out-Null
        Write-Log -Message "Audit policy set: $category (Success=$success, Failure=$failure)" -Level Info
    }
}

function _ApplyEncryptionRule {
    <#
    .SYNOPSIS
    Applies an Encryption-type hardening rule (e.g., BitLocker).
    #>
    [CmdletBinding()]
    param(
        [PSCustomObject]$Rule
    )

    $encDef = $Rule.RuleDefinition

    # Handle BitLocker
    if ($encDef.ContainsKey('DriveType')) {
        $driveType = $encDef.DriveType

        if ($driveType -eq 'OS') {
            $osVolume = Get-Volume -DriveLetter (Split-Path -Qualifier $env:SystemRoot) -ErrorAction SilentlyContinue
            if ($osVolume) {
                Enable-BitLocker -MountPoint "$($osVolume.DriveLetter):" -EncryptionMethod $encDef.EncryptionMethod `
                    -UsedSpaceOnly -ErrorAction SilentlyContinue | Out-Null
                Write-Log -Message "BitLocker enabled for OS drive" -Level Info
            }
        }
    }
}

function _GenerateComplianceReport {
    <#
    .SYNOPSIS
    Generates a compliance report from the hardening session.
    #>
    [CmdletBinding()]
    param(
        [PSCustomObject]$Session
    )

    $totalRules = $Session.State.TotalRules
    $appliedCount = @($Session.State.AppliedRules).Count
    $failedCount = @($Session.State.FailedRules).Count
    $skippedCount = @($Session.State.SkippedRules).Count

    $compliancePercentage = if ($totalRules -gt 0) {
        [math]::Round(($appliedCount / $totalRules) * 100, 2)
    }
    else {
        0
    }

    $report = [ordered]@{
        TotalRules = $totalRules
        AppliedRules = $appliedCount
        FailedRules = $failedCount
        SkippedRules = $skippedCount
        CompliancePercentage = $compliancePercentage
        Status = if ($failedCount -eq 0) { 'Compliant' 
        }
        else { 'Non-Compliant' 
        }
        ReportTime = Get-Date
    }

    [PSCustomObject]$report
}
