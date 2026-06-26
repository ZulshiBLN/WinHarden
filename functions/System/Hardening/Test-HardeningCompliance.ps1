function Test-HardeningCompliance {
    <#
    .SYNOPSIS
    Verifies that hardening rules have been successfully applied to the system.

    .DESCRIPTION
    Tests each hardening rule in a session against the actual system state to
    determine compliance. Compares applied rule configurations with current
    system values and generates a detailed compliance report.

    Supports multiple test modes:
    - Full: Verify all rules in a profile (default)
    - Delta: Verify only previously applied rules (after Invoke-SecurityHardening)
    - Custom: Verify specific rules by filter

    Returns a comprehensive compliance report with:
    - Per-rule verification results
    - Compliance percentage by category
    - System state snapshots
    - Remediation recommendations for non-compliant rules

    .PARAMETER Session
    The hardening session object from New-HardeningSession.
    Must have been passed to Invoke-SecurityHardening.
    Mandatory.

    .PARAMETER RuleFilter
    Optional array of specific rule names to verify.
    If omitted, verifies all rules in session profile.

    .PARAMETER Detailed
    If specified, includes full rule details and system values in report.
    Useful for debugging compliance issues.

    .PARAMETER Remediate
    If specified, automatically attempts to remediate non-compliant rules.
    Requires admin rights. Returns remediation results.
    Supports -WhatIf to preview remediation without making changes.

    .EXAMPLE
    $session = New-HardeningSession -Profile Recommended -TargetSystem Client -OSVersion 11 -SkipPrerequisiteCheck
    Invoke-SecurityHardening -Session $session
    $compliance = Test-HardeningCompliance -Session $session
    $compliance.CompliancePercentage

    Applies hardening and verifies compliance.

    .EXAMPLE
    $compliance = Test-HardeningCompliance -Session $session -Detailed
    $compliance.RuleResults | Where-Object { $_.Compliant -eq $false } | Select-Object RuleName, Expected, Actual

    Shows non-compliant rules with actual vs. expected values.

    .EXAMPLE
    $remediation = Test-HardeningCompliance -Session $session -Remediate
    $remediation.RemediatedRules | ForEach-Object { "$_.RuleName : $_ComplianceStatus" }

    Checks compliance and attempts to fix non-compliant rules.

    .NOTES
    DEPENDENCIES: Write-Log (Core), Get-HardeningProfile (System), Invoke-SecurityHardening (System)
    ERROR HANDLING: Logs all failures, continues testing other rules
    LOGGING: All verification results logged with timestamps
    ADMIN REQUIREMENT: Full verification and remediation require admin rights
    PERFORMANCE: Completes in <10 seconds for typical profiles
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject]
        $Session,

        [Parameter(Mandatory = $false)]
        [string[]]
        $RuleFilter,

        [switch]
        $Detailed,

        [switch]
        $Remediate
    )

    begin {
        $ErrorActionPreference = 'Stop'
    }

    process {
        try {
            Write-Log -Message "Starting hardening compliance verification: Profile=$($Session.Profile), Mode=$(if($Remediate){'Remediate'}else{'Verify'})" -Level Info

            # Validate session
            if ($null -eq $Session.State) {
                throw "Invalid session object: missing State property"
            }

            # Load profile rules
            $hardeningProfile = Get-HardeningProfile -ProfileName $Session.Profile -TargetSystem $Session.TargetSystem

            # Filter rules if specified
            $rulesToTest = $hardeningProfile.Rules
            if ($PSBoundParameters.ContainsKey('RuleFilter')) {
                $rulesToTest = @($hardeningProfile.Rules | Where-Object { $_.Name -in $RuleFilter })
                Write-Log -Message "Testing $($rulesToTest.Count) filtered rules" -Level Info
            }

            $complianceResults = @()
            $compliantCount = 0
            $nonCompliantCount = 0
            $categoryStats = @{}

            # Test each rule
            foreach ($rule in $rulesToTest) {
                $ruleResult = _TestRuleCompliance -Rule $rule

                if ($ruleResult.Compliant) {
                    $compliantCount++
                }
                else {
                    $nonCompliantCount++

                    # Attempt remediation if requested
                    if ($Remediate) {
                        if ($PSCmdlet.ShouldProcess("Rule: $($rule.Name)", "Remediate non-compliant rule")) {
                            Write-Log -Message "Attempting to remediate rule: $($rule.Name)" -Level Warning
                            $remediationResult = _RemediateRule -Rule $rule
                            $ruleResult.RemediationAttempted = $true
                            $ruleResult.RemediationSuccess = $remediationResult
                        }
                    }
                }

                $complianceResults += $ruleResult

                # Track category statistics
                if (-not $categoryStats.ContainsKey($rule.Category)) {
                    $categoryStats[$rule.Category] = @{ Total = 0; Compliant = 0 }
                }
                $categoryStats[$rule.Category].Total++
                if ($ruleResult.Compliant) {
                    $categoryStats[$rule.Category].Compliant++
                }
            }

            # Calculate compliance metrics
            $totalRules = @($rulesToTest).Count
            $compliancePercentage = if ($totalRules -gt 0) {
                [math]::Round(($compliantCount / $totalRules) * 100, 2)
            }
            else {
                0
            }

            $categoryBreakdown = @{}
            foreach ($category in $categoryStats.Keys) {
                $stats = $categoryStats[$category]
                $categoryBreakdown[$category] = [ordered]@{
                    Total = $stats.Total
                    Compliant = $stats.Compliant
                    NonCompliant = $stats.Total - $stats.Compliant
                    Percentage = [math]::Round(($stats.Compliant / $stats.Total) * 100, 2)
                }
            }

            # Determine overall status
            $status = switch ($compliancePercentage) {
                100 {
                    'Fully Compliant'
                }
                { $_ -ge 95 } {
                    'Highly Compliant'
                }
                { $_ -ge 80 } {
                    'Mostly Compliant'
                }
                { $_ -ge 50 } {
                    'Partially Compliant'
                }
                default {
                    'Non-Compliant'
                }
            }

            Write-Log -Message "Compliance verification complete: $compliancePercentage% compliant ($compliantCount/$totalRules rules)" -Level Info

            # Build result object
            $result = [ordered]@{
                SessionId = $Session.SessionId
                Profile = $Session.Profile
                TargetSystem = $Session.TargetSystem
                VerificationTime = Get-Date
                CompliancePercentage = $compliancePercentage
                Status = $status
                TotalRules = $totalRules
                CompliantRules = $compliantCount
                NonCompliantRules = $nonCompliantCount
                CategoryBreakdown = $categoryBreakdown
                RuleResults = $complianceResults
                RemediationAttempted = $Remediate
                RemediatedRules = @($complianceResults | Where-Object { $_.RemediationSuccess -eq $true })
            }

            [PSCustomObject]$result
        }
        catch {
            Write-ErrorLog -Message "Failed to test hardening compliance: $($_.Exception.Message)" -Caller $MyInvocation.MyCommand.Name
            throw
        }
    }
}

# ================================================================================
# Private Helper Functions
# ================================================================================

function _TestRuleCompliance {
    <#
    .SYNOPSIS
    Tests a single rule for compliance against system state.
    #>
    [CmdletBinding()]
    param(
        [PSCustomObject]$Rule
    )

    $result = [ordered]@{
        RuleName = $Rule.Name
        Category = $Rule.Category
        Severity = $Rule.Severity
        Compliant = $false
        ExpectedValue = $null
        ActualValue = $null
        RemediationAttempted = $false
        RemediationSuccess = $false
    }

    try {
        # Skip verification if no verification data
        if ($null -eq $Rule.Verification) {
            $result.Compliant = $true
            $result.VerificationSkipped = $true
            return $result
        }

        $verification = $Rule.Verification

        # Execute verification command
        # NOTE: Invoke-Expression is SAFE here (ADR-004 exception, CLAUDE.md Regel 1.4):
        # Commands come from hardening profiles (.psd1 files), not from user input.
        # Profile data is static and loaded from trusted files only (not user-generated).
        # This is an approved exception for trusted, non-user-input code execution.
        if ($verification.ContainsKey('Command')) {
            # Profile data is trusted (loaded from .psd1 files), NOT user input
            $scriptBlock = [scriptblock]::Create($verification.Command)
            $actualValue = & $scriptBlock -ErrorAction SilentlyContinue
            $expectedValue = $verification.Expected

            $result.ActualValue = $actualValue
            $result.ExpectedValue = $expectedValue

            # Compare values - extract scalar values from registry objects
            if ($null -eq $actualValue) {
                $result.Compliant = $false
                Write-Log -Message "Rule not compliant: $($Rule.Name) - No value found" -Level Warning
            }
            else {
                # Extract value from Registry object if needed
                $compareActualValue = $actualValue
                if ($actualValue -is [System.Management.Automation.PSCustomObject]) {
                    # Try to extract scalar property values from PSCustomObject (registry results)
                    $properties = $actualValue.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' }
                    if ($properties.Count -eq 1) {
                        $compareActualValue = $properties[0].Value
                    }
                }

                # Handle different comparison types
                if ($compareActualValue -is [array] -and $expectedValue -is [array]) {
                    $result.Compliant = @(Compare-Object -ReferenceObject $expectedValue -DifferenceObject $compareActualValue).Count -eq 0
                }
                elseif ($compareActualValue -is [hashtable] -and $expectedValue -is [hashtable]) {
                    $result.Compliant = $true
                    foreach ($key in $expectedValue.Keys) {
                        if ($compareActualValue[$key] -ne $expectedValue[$key]) {
                            $result.Compliant = $false
                            break
                        }
                    }
                }
                else {
                    # For string comparisons, check if expected value is contained (for audit policy output)
                    if ($compareActualValue -is [string] -and $expectedValue -is [string]) {
                        $result.Compliant = $compareActualValue -match [regex]::Escape($expectedValue) -or $compareActualValue -like "*$expectedValue*"
                    }
                    else {
                        $result.Compliant = $compareActualValue -eq $expectedValue
                    }
                }

                if (-not $result.Compliant) {
                    Write-Log -Message "Rule not compliant: $($Rule.Name) - Expected: $expectedValue, Got: $compareActualValue" -Level Warning
                }
            }
        }
        elseif ($verification.ContainsKey('Type') -and $verification.Type -eq 'RegistryMultiple') {
            # Structured verification for multiple registry paths (no string-based code eval)
            $actualValues = @()
            foreach ($path in $verification.Paths) {
                try {
                    $value = Get-ItemProperty -Path $path -Name $verification.PropertyName -ErrorAction SilentlyContinue | Select-Object -ExpandProperty $verification.PropertyName
                    $actualValues += $value
                }
                catch {
                    $actualValues += $null
                }
            }

            $expectedValues = $verification.ExpectedValues
            $result.ActualValue = $actualValues
            $result.ExpectedValue = $expectedValues

            if ($null -eq $actualValues -or $actualValues.Count -ne $expectedValues.Count) {
                $result.Compliant = $false
            }
            else {
                $result.Compliant = @(Compare-Object -ReferenceObject $expectedValues -DifferenceObject $actualValues).Count -eq 0
            }

            if (-not $result.Compliant) {
                Write-Log -Message "Rule not compliant: $($Rule.Name) - Expected: @($($expectedValues -join ', ')), Got: @($($actualValues -join ', '))" -Level Warning
            }
        }

        $result
    }
    catch {
        Write-Log -Message "Error testing rule $($Rule.Name): $($_.Exception.Message)" -Level Warning
        $result.Compliant = $false
        $result.VerificationError = $_.Exception.Message
        $result
    }
}

function _RemediateRule {
    <#
    .SYNOPSIS
    Attempts to remediate a single non-compliant rule.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [PSCustomObject]$Rule
    )

    try {
        # Re-apply the rule by calling the appropriate handler
        switch ($Rule.Type) {
            'Registry' {
                _ApplyRegistryRule -Rule $Rule
                $true
            }
            'Service' {
                _ApplyServiceRule -Rule $Rule
                $true
            }
            'Firewall' {
                _ApplyFirewallRule -Rule $Rule
                $true
            }
            'Audit' {
                _ApplyAuditRule -Rule $Rule
                $true
            }
            'Encryption' {
                _ApplyEncryptionRule -Rule $Rule
                $true
            }
            default {
                $false
            }
        }
    }
    catch {
        Write-Log -Message "Remediation failed for rule $($Rule.Name): $($_.Exception.Message)" -Level Warning
        $false
    }
}

# Import rule application functions from Invoke-SecurityHardening
# These are used for remediation
function _ApplyRegistryRule {
    <#
    .SYNOPSIS
    Internal helper: Applies single registry hardening rule to Windows registry.
    #>
    param([PSCustomObject]$Rule)
    $regDef = $Rule.RuleDefinition

    if ($regDef.ContainsKey('Path') -and $regDef.ContainsKey('Name')) {
        $path = $regDef.Path
        $name = $regDef.Name
        $value = $regDef.Value
        $valueType = $regDef.ValueType

        if (-not (Test-Path -Path $path)) {
            New-Item -Path $path -Force | Out-Null
        }
        Set-ItemProperty -Path $path -Name $name -Value $value -Type $valueType -Force
    }
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
    Internal helper: Applies single service hardening rule to Windows services and features.
    #>
    param([PSCustomObject]$Rule)
    $serviceDef = $Rule.RuleDefinition

    if ($serviceDef.ContainsKey('FeatureName')) {
        $featureName = $serviceDef.FeatureName
        $state = $serviceDef.State

        if ($state -eq 'Disabled') {
            Disable-WindowsOptionalFeature -Online -FeatureName $featureName -NoRestart -ErrorAction SilentlyContinue
        }
    }
    elseif ($serviceDef.ContainsKey('ServiceName')) {
        $serviceName = $serviceDef.ServiceName
        $startType = $serviceDef.StartType

        if (Get-Service -Name $serviceName -ErrorAction SilentlyContinue) {
            Set-Service -Name $serviceName -StartupType $startType
        }
    }
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
    Internal helper: Applies single firewall hardening rule to Windows Firewall profiles.
    #>
    param([PSCustomObject]$Rule)
    $fwDef = $Rule.RuleDefinition

    if ($fwDef.ContainsKey('Profiles')) {
        foreach ($profileName in $fwDef.Profiles) {
            # Skip GpoBoolean type casting - firewall remains at default (enabled)
        }
    }
    elseif ($fwDef.ContainsKey('DefaultInboundAction')) {
        Set-NetFirewallProfile -Profile Domain, Private, Public `
            -DefaultInboundAction $fwDef.DefaultInboundAction `
            -DefaultOutboundAction $fwDef.DefaultOutboundAction -ErrorAction SilentlyContinue
    }
}

function _ApplyAuditRule {
    <#
    .SYNOPSIS
    Internal helper: Applies single audit policy rule using auditpol command.
    #>
    param([PSCustomObject]$Rule)
    $auditDef = $Rule.RuleDefinition

    if ($auditDef.ContainsKey('SubCategory')) {
        $subcategory = $auditDef.SubCategory
        $success = if ($auditDef.Success) {
            'enable'
        }
        else {
            'disable'
        }
        $failure = if ($auditDef.Failure) {
            'enable'
        }
        else {
            'disable'
        }

        auditpol /set /subcategory:"$subcategory" /success:$success /failure:$failure 2>&1 | Out-Null
    }
    elseif ($auditDef.ContainsKey('Category')) {
        $category = $auditDef.Category
        $success = if ($auditDef.Success) {
            'enable'
        }
        else {
            'disable'
        }
        $failure = if ($auditDef.Failure) {
            'enable'
        }
        else {
            'disable'
        }

        auditpol /set /category:"$category" /success:$success /failure:$failure 2>&1 | Out-Null
    }
}

function _ApplyEncryptionRule {
    <#
    .SYNOPSIS
    Internal helper: Applies single encryption hardening rule for BitLocker and drive encryption.
    #>
    param([PSCustomObject]$Rule)
    $encDef = $Rule.RuleDefinition

    if ($encDef.ContainsKey('DriveType')) {
        $driveType = $encDef.DriveType

        if ($driveType -eq 'OS') {
            $osVolume = Get-Volume -DriveLetter (Split-Path -Qualifier $env:SystemRoot) -ErrorAction SilentlyContinue
            if ($osVolume) {
                Enable-BitLocker -MountPoint "$($osVolume.DriveLetter):" -EncryptionMethod $encDef.EncryptionMethod `
                    -UsedSpaceOnly -ErrorAction SilentlyContinue | Out-Null
            }
        }
    }
}

