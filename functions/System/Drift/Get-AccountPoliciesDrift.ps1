<#
.SYNOPSIS
Detects configuration drift in account policies (password length, complexity).

.DESCRIPTION
Checks if minimum password length and password complexity settings match security baselines.
Returns PSCustomObject with drift findings (empty array if compliant).

.PARAMETER MinimumPasswordLength
Expected minimum password length (default: 12 characters).

.PARAMETER RequirePasswordComplexity
Whether password complexity should be enabled (default: $true).

.EXAMPLE
$drifts = Get-AccountPoliciesDrift
if ($drifts.Count -gt 0) { $drifts | Write-Output }

.NOTES
DEPENDENCIES: Write-Log (Core)
APPLIES TO: Windows Server 2016+ (HKLM registry paths)
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [int]$MinimumPasswordLength = 12,
    [bool]$RequirePasswordComplexity = $true
)

$regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters"
$findings = @()

try {
    # Check minimum password length
    $minPasswordProperty = Get-ItemProperty -Path $regPath -Name MinimumPasswordLength -ErrorAction SilentlyContinue
    $minPassword = $minPasswordProperty.MinimumPasswordLength
    if ($minPassword -lt $MinimumPasswordLength) {
        $findings += [PSCustomObject]@{
            Category = "Account Policy"
            Setting = "Minimum Password Length"
            Expected = "$MinimumPasswordLength characters"
            Actual = "$minPassword characters"
            Status = "DRIFT"
            Severity = "HIGH"
        }
        Write-Log -Message "Account Policy drift: Min password length is $minPassword (expected $MinimumPasswordLength)" `
            -Level Warning -Caller $MyInvocation.MyCommand.Name
    }

    # Check password complexity
    $complexityProperty = Get-ItemProperty -Path $regPath -Name PasswordComplexity -ErrorAction SilentlyContinue
    $complexity = $complexityProperty.PasswordComplexity
    $complexityEnabled = $complexity -eq 1
    if ($complexityEnabled -ne $RequirePasswordComplexity) {
        if ($RequirePasswordComplexity) {
            $expectedText = "Enabled (1)"
        }
        else {
            $expectedText = "Disabled (0)"
        }
        if ($complexityEnabled) {
            $actualText = "Enabled ($complexity)"
        }
        else {
            $actualText = "Disabled ($complexity)"
        }
        $findings += [PSCustomObject]@{
            Category = "Account Policy"
            Setting = "Password Complexity"
            Expected = $expectedText
            Actual = $actualText
            Status = "DRIFT"
            Severity = "HIGH"
        }
        if ($complexityEnabled) {
            $current = 'enabled'
        }
        else {
            $current = 'disabled'
        }
        if ($RequirePasswordComplexity) {
            $expected = 'enabled'
        }
        else {
            $expected = 'disabled'
        }
        Write-Log -Message "Account Policy drift: Password complexity is $current (expected $expected)" `
            -Level Warning -Caller $MyInvocation.MyCommand.Name
    }
}
catch {
    Write-Log -Message "Error checking account policies: $_" -Level Error -Caller $MyInvocation.MyCommand.Name
    throw
}

return $findings
