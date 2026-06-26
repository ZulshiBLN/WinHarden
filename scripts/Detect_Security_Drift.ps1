# WinHarden Configuration Drift Detection Script
# Verifies hardening settings remain active and detects unauthorized changes
# Detects unauthorized changes or system degradation
# Schedule: Weekly (e.g., Monday @ 10:00 AM)
# Run As: SYSTEM (Highest Privileges)

param(
    [string]$OutputDir = "c:\Repos\WinHarden\logs"
)

$ErrorActionPreference = "Continue"

Write-Output ""
Write-Output "=============================================================="
Write-Output "     WINHARDEN CONFIGURATION DRIFT DETECTION"
Write-Output "=============================================================="
Write-Output ""
Write-Output "Start Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$driftFindings = @()

Write-Output ""
Write-Output "[1] CHECKING ACCOUNT POLICIES"
Write-Output "=============================================================="
# Check minimum password length
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters"
$minPassword = (Get-ItemProperty -Path $regPath -Name MinimumPasswordLength `
    -ErrorAction SilentlyContinue).MinimumPasswordLength
if ($minPassword -lt 12) {
    Write-Output "[ERROR] DRIFT DETECTED: Minimum password length is $minPassword (should be 12)"
    $driftFindings += [PSCustomObject]@{
        Category = "Account Policy"
        Setting = "Minimum Password Length"
        Expected = "12 characters"
        Actual = "$minPassword characters"
        Status = "DRIFT"
        Severity = "HIGH"
    }
}
else {
    Write-Output "[OK] Minimum password length: OK ($minPassword)"
}

# Check password complexity
$complexity = (Get-ItemProperty -Path $regPath -Name PasswordComplexity `
    -ErrorAction SilentlyContinue).PasswordComplexity
if ($complexity -ne 1) {
    Write-Output "[ERROR] DRIFT DETECTED: Password complexity is disabled"
    $driftFindings += [PSCustomObject]@{
        Category = "Account Policy"
        Setting = "Password Complexity"
        Expected = "Enabled (1)"
        Actual = "Disabled ($complexity)"
        Status = "DRIFT"
        Severity = "HIGH"
    }
}
else {
    Write-Output "[OK] Password complexity: OK (Enabled)"
}

Write-Output ""
Write-Output "[2] CHECKING NETWORK SECURITY"
Write-Output "=============================================================="
# Check SMB1 status
try {
    $smb1 = (Get-WindowsOptionalFeature -FeatureName SMBDirect -Online -ErrorAction SilentlyContinue).State
    $smb1Protocol = (Get-WindowsOptionalFeature -FeatureName SMB1Protocol -Online -ErrorAction SilentlyContinue).State

    if ($smb1Protocol -eq "Enabled") {
        Write-Output "[ERROR] DRIFT DETECTED: SMB1 is ENABLED (should be Disabled)"
        $driftFindings += [PSCustomObject]@{
            Category = "Network Security"
            Setting = "SMB1 Protocol"
            Expected = "Disabled"
            Actual = "Enabled"
            Status = "DRIFT"
            Severity = "CRITICAL"
        }
    }
    else {
        Write-Output "[OK] SMB1 Protocol: OK (Disabled)"
    }
}
catch {
    Write-Output "[WARN] Could not verify SMB1 status"
}

# Check NTLMv2
$ntlmPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
$ntlmLevel = (Get-ItemProperty -Path $ntlmPath -Name LmCompatibilityLevel `
    -ErrorAction SilentlyContinue).LmCompatibilityLevel
if ($ntlmLevel -lt 5) {
    Write-Output "[ERROR] DRIFT DETECTED: NTLMv2 not enforced (level: $ntlmLevel, should be 5)"
    $driftFindings += [PSCustomObject]@{
        Category = "Network Security"
        Setting = "NTLM Compatibility Level"
        Expected = "5 (NTLMv2 Only)"
        Actual = "$ntlmLevel"
        Status = "DRIFT"
        Severity = "HIGH"
    }
}
else {
    Write-Output "[OK] NTLM Compatibility: OK (Level 5 - NTLMv2)"
}

Write-Output ""
Write-Output "[3] CHECKING RDP SECURITY"
Write-Output "=============================================================="
# Check RDP Encryption Level
$rdpPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
$rdpEncryption = (Get-ItemProperty -Path $rdpPath -Name MinEncryptionLevel `
    -ErrorAction SilentlyContinue).MinEncryptionLevel
if ($rdpEncryption -lt 3) {
    Write-Output "[ERROR] DRIFT DETECTED: RDP encryption level is $rdpEncryption (should be 3 = High)"
    $driftFindings += [PSCustomObject]@{
        Category = "RDP Security"
        Setting = "Encryption Level"
        Expected = "3 (High - 128-bit)"
        Actual = "$rdpEncryption"
        Status = "DRIFT"
        Severity = "HIGH"
    }
}
else {
    Write-Output "[OK] RDP Encryption: OK (Level $rdpEncryption)"
}

# Check RDP NLA
$rdpNLA = (Get-ItemProperty -Path $rdpPath -Name SecurityLayer `
    -ErrorAction SilentlyContinue).SecurityLayer
if ($rdpNLA -ne 2) {
    Write-Output "[ERROR] DRIFT DETECTED: RDP NLA disabled (SecurityLayer: $rdpNLA, should be 2)"
    $driftFindings += [PSCustomObject]@{
        Category = "RDP Security"
        Setting = "Network Level Authentication"
        Expected = "2 (Enabled)"
        Actual = "$rdpNLA"
        Status = "DRIFT"
        Severity = "HIGH"
    }
}
else {
    Write-Output "[OK] RDP NLA: OK (Enabled)"
}

Write-Output ""
Write-Output "[4] CHECKING FIREWALL STATUS"
Write-Output "=============================================================="
# Check Firewall profiles
$domainFW = (Get-NetFirewallProfile -Name Domain -ErrorAction SilentlyContinue).Enabled
$privateFW = (Get-NetFirewallProfile -Name Private -ErrorAction SilentlyContinue).Enabled
$publicFW = (Get-NetFirewallProfile -Name Public -ErrorAction SilentlyContinue).Enabled

$fwStatus = "All profiles enabled"
if (-not $domainFW -or -not $privateFW -or -not $publicFW) {
    Write-Output "[ERROR] DRIFT DETECTED: Firewall not fully enabled"
    $driftFindings += [PSCustomObject]@{
        Category = "Firewall"
        Setting = "Firewall Profiles"
        Expected = "All Enabled"
        Actual = "Domain:$domainFW, Private:$privateFW, Public:$publicFW"
        Status = "DRIFT"
        Severity = "HIGH"
    }
}
else {
    Write-Output "[OK] Firewall: OK (All profiles enabled)"
}

Write-Output ""
Write-Output "[5] CHECKING AUDIT POLICIES"
Write-Output "=============================================================="
# Check audit policies
$auditPolicies = auditpol /get /subcategory:"Logon","Sensitive Privilege Use" /r 2>&1
if ($auditPolicies -match "Success and Failure") {
    Write-Output "[OK] Audit Policies: OK (Logon & Privilege Use enabled)"
}
else {
    Write-Output "[WARN] Audit policies might be misconfigured (verify manually)"
}

Write-Output ""
Write-Output "[6] CHECKING WINDOWS UPDATE"
Write-Output "=============================================================="
# Check automatic updates
$autoUpdate = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name NoAutoUpdate -ErrorAction SilentlyContinue).NoAutoUpdate
if ($autoUpdate -eq 1) {
    Write-Output "[ERROR] DRIFT DETECTED: Automatic updates disabled"
    $driftFindings += [PSCustomObject]@{
        Category = "Updates"
        Setting = "Automatic Updates"
        Expected = "Enabled"
        Actual = "Disabled"
        Status = "DRIFT"
        Severity = "MEDIUM"
    }
}
else {
    Write-Output "[OK] Automatic Updates: OK (Enabled)"
}

Write-Output ""
Write-Output "[7] CHECKING SERVICE SECURITY"
Write-Output "=============================================================="
# Check Print Spooler
$spooler = Get-Service -Name Spooler -ErrorAction SilentlyContinue
if ($spooler.StartType -ne "Disabled") {
    Write-Output "[ERROR] DRIFT DETECTED: Print Spooler is running/enabled (should be Disabled)"
    $driftFindings += [PSCustomObject]@{
        Category = "Services"
        Setting = "Print Spooler"
        Expected = "Disabled"
        Actual = "$($spooler.StartType)"
        Status = "DRIFT"
        Severity = "MEDIUM"
    }
}
else {
    Write-Output "[OK] Print Spooler: OK (Disabled)"
}

Write-Output ""
Write-Output "=============================================================="
Write-Output ""
Write-Output "[DRIFT ANALYSIS SUMMARY]"
Write-Output "=============================================================="
if ($driftFindings.Count -eq 0) {
    Write-Output ""
    Write-Output "[OK] NO CONFIGURATION DRIFT DETECTED"
    Write-Output "All hardening settings are intact and active."
    $status = "COMPLIANT"
}
else {
    Write-Output ""
    Write-Output "[WARN] CONFIGURATION DRIFT DETECTED!"
    Write-Output "Found $($driftFindings.Count) settings that differ from hardening baseline."
    $status = "NON-COMPLIANT"

    Write-Output ""
    Write-Output "Detailed Findings:"
    $driftFindings | Format-Table -AutoSize
}

Write-Output ""
Write-Output "[REPORT OUTPUT]"
Write-Output "=============================================================="
# Save report
$reportDate = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$reportFile = Join-Path $OutputDir "Drift_Detection_$reportDate.csv"

$reportData = @{
    'Scan_Date' = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    'Status' = $status
    'Drifts_Found' = $driftFindings.Count
    'Severity' = if ($driftFindings | Where-Object Severity -eq "CRITICAL") { "CRITICAL" } elseif ($driftFindings | Where-Object Severity -eq "HIGH") { "HIGH" } else { "NONE" }
}

$reportData | Export-Csv -Path $reportFile -NoTypeInformation
Write-Output ""
Write-Output "[OK] Report saved: $reportFile"
if ($driftFindings.Count -gt 0) {
    Write-Output ""
    Write-Output "[ACTION REQUIRED]"
    Write-Output "  1. Review detected drift findings above"
    Write-Output "  2. Investigate cause of changes (unauthorized or accidental)"
    Write-Output "  3. Re-apply hardening rules if necessary"
    Write-Output "  4. Document changes and approvals"
}

Write-Output ""
Write-Output "End Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Output "=============================================================="
exit 0
