# WinHarden Hardening – User Guide

**Version:** 1.0  
**Last Updated:** 2026-06-26  
**Audience:** System Administrators, Security Operations Teams

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Core Concepts](#core-concepts)
3. [Installation](#installation)
4. [Basic Hardening Workflow](#basic-hardening-workflow)
5. [Hardening Profiles](#hardening-profiles)
6. [Advanced Usage](#advanced-usage)
7. [Compliance Verification](#compliance-verification)
8. [Troubleshooting](#troubleshooting)
9. [Best Practices](#best-practices)

---

## Quick Start

### Prerequisites

- Windows Server 2016+ or Windows 10/11
- PowerShell 5.1+ (with 7.x supported)
- Administrator privileges
- Network connectivity for SIEM/monitoring integration

### 30-Second Setup

```powershell
# Import WinHarden
Import-Module .\modules\Core.psm1
Import-Module .\modules\System.psm1

# Create a hardening session
$session = New-HardeningSession -Profile Recommended -TargetSystem Client -OSVersion 11

# Apply hardening (with preview)
Invoke-SecurityHardening -Session $session -WhatIf

# Apply for real
Invoke-SecurityHardening -Session $session

# Verify compliance
$compliance = Test-HardeningCompliance -Session $session
$compliance.CompliancePercentage
```

---

## Core Concepts

### Hardening Session

A hardening session is an isolated execution context that contains:
- Target profile (Basis, Recommended, Strict)
- System configuration (Client/Server, OS version)
- Rules to apply
- Execution state and results

Each session is **independent** – you can run multiple sessions without interference.

```powershell
# Create a session (doesn't apply anything yet)
$session = New-HardeningSession -Profile Recommended -TargetSystem Client -OSVersion 11

# The session object contains:
# - Profile: Name of the hardening profile
# - TargetSystem: Client | Server
# - ComputerName: Target system
# - OSVersion: Windows version
# - State: Session state tracking
```

### Hardening Profiles

Three profiles available, each with increasing security strictness:

| Profile | Rules | Use Case | Risk Level |
|---------|-------|----------|-----------|
| **Basis** | 20 rules | Minimal hardening, maximum compatibility | Low |
| **Recommended** | 35 rules | Balanced security and usability | Medium |
| **Strict** | 55+ rules | Maximum security, restricted functionality | High |

Choose based on your security requirements and user impact tolerance.

### Rule Categories

Hardening rules are organized by type:

- **Registry** – Registry key modifications
- **Service** – Disable/configure Windows services
- **Firewall** – Windows Defender Firewall rules
- **Audit** – Audit policy configuration
- **Account** – Password policy, account lockout
- **Group Policy** – GPO-based hardening

---

## Installation

### Step 1: Extract WinHarden

```powershell
# Extract to a secure location
Expand-Archive -Path WinHarden.zip -DestinationPath C:\Program Files\WinHarden -Force
cd C:\Program Files\WinHarden
```

### Step 2: Verify Installation

```powershell
# Check directory structure
ls -R functions/, modules/, scripts/

# Verify Core module loads
Import-Module .\modules\Core.psm1
Get-Command Write-Log  # Should return the function
```

### Step 3: Test Run

```powershell
# Run in WhatIf mode to verify everything works
$session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11
Invoke-SecurityHardening -Session $session -WhatIf

# Expected output: Lists rules to be applied without applying them
```

---

## Basic Hardening Workflow

### Step 1: Create a Session

```powershell
$session = New-HardeningSession `
    -Profile Recommended `
    -TargetSystem Client `
    -OSVersion 11
```

**Parameters:**
- `-Profile`: Basis | Recommended | Strict
- `-TargetSystem`: Client | Server (determines applicable rules)
- `-OSVersion`: 10 | 11 | 2016 | 2019 | 2022
- `-SkipPrerequisiteCheck`: (optional) Skip environment validation

### Step 2: Preview Changes (WhatIf)

```powershell
# Dry-run mode – shows what will change WITHOUT applying
Invoke-SecurityHardening -Session $session -WhatIf

# Output:
# What if: Performing the operation "Apply Rule: Account-MinimumPasswordLength" on target "LOCAL SYSTEM".
# What if: Performing the operation "Apply Rule: Firewall-EnableWindowsDefender" on target "LOCAL SYSTEM".
# ...
```

### Step 3: Apply Hardening

```powershell
# Apply the hardening rules
$result = Invoke-SecurityHardening -Session $session

# View results
$result | Select-Object Profile, RulesApplied, RulesFailed, CompliancePercentage

# Output:
# Profile              : Recommended
# RulesApplied         : 33
# RulesFailed          : 0
# CompliancePercentage : 100
```

### Step 4: Verify Compliance

```powershell
# Check compliance after applying hardening
$compliance = Test-HardeningCompliance -Session $session

# Summary
$compliance.CompliancePercentage        # 100%
$compliance.CompliantRuleCount          # 33
$compliance.NonCompliantRuleCount       # 0

# Details
$compliance.RuleResults | Where-Object { $_.Compliant -eq $false }
```

---

## Hardening Profiles

### Basis Profile

**Security Level:** Low-to-Medium  
**Rules:** 20  
**Impact:** Minimal  
**Best For:** Legacy systems, maximum compatibility

Key rules:
- Disable obsolete protocols (SMBv1, LLMNR)
- Set minimum password length (8 chars)
- Enable basic Windows Defender
- Configure basic audit logging

**Deployment Time:** 30 seconds  
**User Impact:** None to minimal

```powershell
$session = New-HardeningSession -Profile Basis -TargetSystem Client
Invoke-SecurityHardening -Session $session
```

### Recommended Profile

**Security Level:** Medium  
**Rules:** 35  
**Impact:** Moderate  
**Best For:** Standard production systems

Key rules:
- All Basis rules
- Credential Guard enabled
- SmartScreen enabled
- Advanced audit policies
- Windows Update mandatory
- Firewall rules configured

**Deployment Time:** 45 seconds  
**User Impact:** Slight (some deprecated features disabled)

```powershell
$session = New-HardeningSession -Profile Recommended -TargetSystem Client
Invoke-SecurityHardening -Session $session
```

### Strict Profile

**Security Level:** High  
**Rules:** 55+  
**Impact:** Significant  
**Best For:** High-security environments, sensitive systems

Key rules:
- All Recommended rules
- Exploit protection hardening
- Device Guard enabled
- Advanced Threat Protection
- Restrictive UAC
- Disabled USB ports
- Enhanced logging

**Deployment Time:** 2 minutes  
**User Impact:** High (functionality restrictions)

```powershell
$session = New-HardeningSession -Profile Strict -TargetSystem Server
Invoke-SecurityHardening -Session $session
```

---

## Advanced Usage

### Selective Rule Application

Apply only specific rules:

```powershell
$session = New-HardeningSession -Profile Recommended -TargetSystem Client -OSVersion 11

# Apply only firewall and account rules
$result = Invoke-SecurityHardening -Session $session -RuleFilter @(
    'Firewall-EnableWindowsDefender',
    'Account-MinimumPasswordLength',
    'Account-AccountLockoutThreshold'
)

$result.RulesApplied  # 3 rules applied
```

### Fail-Safe Mode

Stop on first error:

```powershell
# Strict mode: any rule failure stops execution
$result = Invoke-SecurityHardening -Session $session -FailOnError

# Handles errors more strictly; useful for CI/CD pipelines
```

### Parallel Execution

Apply compatible rules in parallel:

```powershell
# Faster execution for large rule sets
$result = Invoke-SecurityHardening -Session $session -Parallel

# Execution time reduced by ~30-40% on multi-core systems
```

### Scheduled Hardening

Run hardening on a schedule:

```powershell
# Create a scheduled task
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 2am
$action = New-ScheduledTaskAction -Execute PowerShell.exe -Argument `
    "-NoProfile -File C:\Scripts\ApplyHardening.ps1"
Register-ScheduledTask -TaskName "WinHarden-Weekly" -Trigger $trigger -Action $action
```

### Remote Hardening

Apply hardening to remote systems:

```powershell
# Harden remote servers
$session = New-HardeningSession -Profile Recommended -TargetSystem Server -OSVersion 2022 `
    -ComputerName SERVER01, SERVER02, SERVER03

$result = Invoke-RemoteHardening -Session $session

# Results
$result | Group-Object ComputerName | ForEach-Object {
    "$($_.Name): $($_.Group.Count) rules applied"
}
```

---

## Compliance Verification

### Quick Compliance Check

```powershell
$compliance = Test-HardeningCompliance -Session $session

# Results
$compliance.CompliancePercentage        # Percentage (0-100)
$compliance.CompliantRuleCount          # Number compliant
$compliance.NonCompliantRuleCount       # Number non-compliant
$compliance.AppliedRuleCount            # Total rules applied
```

### Detailed Compliance Report

```powershell
# Full details on every rule
$compliance = Test-HardeningCompliance -Session $session -Detailed

# Show non-compliant rules
$compliance.RuleResults | Where-Object { $_.Compliant -eq $false } | Select-Object `
    RuleName, Category, Expected, Actual, Severity

# Output:
# RuleName                Expected        Actual          Severity
# --------                --------        ------          --------
# Firewall-EnableWD       Enabled         Disabled        HIGH
# Account-MinPassword     8               6               MEDIUM
```

### Automatic Remediation

```powershell
# Automatically fix non-compliant rules
$remediation = Test-HardeningCompliance -Session $session -Remediate

$remediation.RemediatedRules | ForEach-Object {
    Write-Host "$($_.RuleName): $($_.Status)"
}

# Output:
# Firewall-EnableWD: FIXED
# Account-MinPassword: FIXED
```

### Export Compliance Report

```powershell
# Save compliance report for auditing
$compliance = Test-HardeningCompliance -Session $session -Detailed

$compliance | ConvertTo-Json | Out-File -FilePath "compliance_$(Get-Date -Format yyyyMMdd).json"

# CSV format for spreadsheets
$compliance.RuleResults | Export-Csv -Path "compliance_rules.csv" -NoTypeInformation
```

---

## Troubleshooting

### Issue: "Invalid session object"

**Symptom:** `throw "Invalid session object: missing State property"`

**Solution:**
```powershell
# Ensure session was created with New-HardeningSession
$session = New-HardeningSession -Profile Recommended -TargetSystem Client

# Do NOT manually construct session objects
```

### Issue: Rules Not Applying

**Symptom:** Rules applied but not taking effect

**Solution:**
```powershell
# 1. Check if running as administrator
[Security.Principal.WindowsIdentity]::GetCurrent().Owner

# 2. Verify WhatIf is not enabled
# (WhatIf mode previews but doesn't apply changes)

# 3. Check logs for errors
Get-Content logs/log_*.csv | Where-Object { $_ -match "ERROR" }
```

### Issue: Performance Issues

**Symptom:** Hardening takes too long to apply

**Solution:**
```powershell
# Use Parallel mode
$result = Invoke-SecurityHardening -Session $session -Parallel

# Or apply only specific rules
$result = Invoke-SecurityHardening -Session $session -RuleFilter @('Account-*', 'Firewall-*')

# Skip verification
$result = Invoke-SecurityHardening -Session $session -SkipVerification
```

### Issue: Compliance Verification Failing

**Symptom:** `Test-HardeningCompliance` shows non-compliant rules after applying

**Solution:**
```powershell
# 1. Wait for system updates to apply
Start-Sleep -Seconds 30

# 2. Re-test compliance
$compliance = Test-HardeningCompliance -Session $session

# 3. Use -Remediate to auto-fix
$remediation = Test-HardeningCompliance -Session $session -Remediate

# 4. Check logs for errors
Write-Log -Level Error  # Shows recent errors
```

### Issue: Cannot Run Scripts

**Symptom:** "File cannot be loaded because running scripts is disabled"

**Solution:**
```powershell
# Set execution policy for current user
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# Or for all users (admin required)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force

# Then run WinHarden again
```

---

## Best Practices

### 1. Always Test First

```powershell
# ALWAYS use WhatIf before applying
Invoke-SecurityHardening -Session $session -WhatIf

# Review output carefully before pressing Enter to apply
```

### 2. Start with Basis, Work Up

```powershell
# First: Deploy Basis (safe, minimal impact)
$basis = New-HardeningSession -Profile Basis -TargetSystem Client
Invoke-SecurityHardening -Session $basis

# After 1-2 weeks: Move to Recommended if no issues
$recommended = New-HardeningSession -Profile Recommended -TargetSystem Client
Invoke-SecurityHardening -Session $recommended

# Only use Strict if required by compliance
$strict = New-HardeningSession -Profile Strict -TargetSystem Server
Invoke-SecurityHardening -Session $strict
```

### 3. Verify After Each Change

```powershell
# Always verify compliance after applying hardening
$session = New-HardeningSession -Profile Recommended -TargetSystem Client
Invoke-SecurityHardening -Session $session
$compliance = Test-HardeningCompliance -Session $session

if ($compliance.CompliancePercentage -lt 100) {
    Write-Host "Compliance issues detected!"
    $compliance.RuleResults | Where-Object { $_.Compliant -eq $false }
}
```

### 4. Monitor Logs

```powershell
# Check logs for errors
$logs = Import-Csv logs/log_$(Get-Date -Format yyyyMMdd).csv
$logs | Where-Object { $_.Level -eq 'ERROR' }

# Keep logs for audit trail (7 days retention by default)
```

### 5. Document Your Changes

```powershell
# Keep a record of what was applied
$session = New-HardeningSession -Profile Recommended -TargetSystem Client
$result = Invoke-SecurityHardening -Session $session

# Export session info
$session | ConvertTo-Json | Out-File -FilePath "hardening_session_$(Get-Date -Format yyyyMMdd).json"
```

### 6. Plan for Rollback

```powershell
# Before applying Strict hardening, create a system restore point
Checkpoint-Computer -Description "Pre-WinHarden-Strict" -RestorePointType "MODIFY_SETTINGS"

# Or export baseline for comparison
Get-HardeningProfile -ProfileName Recommended | Export-Csv -Path "baseline.csv"
```

### 7. Use Scheduled Compliance Checks

```powershell
# Set up daily compliance verification
$scriptPath = "C:\Scripts\DailyComplianceCheck.ps1"

# Content of DailyComplianceCheck.ps1:
# $session = New-HardeningSession -Profile Recommended -TargetSystem Client
# $compliance = Test-HardeningCompliance -Session $session
# if ($compliance.CompliancePercentage -lt 100) {
#     Send-HardeningAlert -ComplianceStatus $compliance -AlertLevel WARNING
# }

# Schedule it
$trigger = New-ScheduledTaskTrigger -Daily -At 8am
$action = New-ScheduledTaskAction -Execute PowerShell.exe -Argument "-NoProfile -File $scriptPath"
Register-ScheduledTask -TaskName "DailyComplianceCheck" -Trigger $trigger -Action $action
```

---

## Support & Resources

### Getting Help

1. **Check the FAQ** – See [FAQ.md](06_FAQ.md)
2. **Review logs** – `logs/log_*.csv`
3. **Run Test-HardeningCompliance** – Shows detailed results
4. **Check CLAUDE.md** – Developer collaboration rules
5. **Review DECISIONS.md** – Architecture decisions

### Additional Documentation

- [Deployment Guide](02_DEPLOYMENT_GUIDE.md) – Enterprise deployment procedures
- [Architecture Guide](03_ARCHITECTURE.md) – Technical architecture details
- [SIEM Integration](04_SIEM_INTEGRATION.md) – Integrate with monitoring systems
- [Performance Guide](05_PERFORMANCE.md) – Performance tuning and optimization
- [Full Report](07_FULL_REPORT.md) – Comprehensive technical documentation

---

**End of User Guide**

For questions or issues, consult the Troubleshooting section or contact your system administrator.
