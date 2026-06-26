# WinHarden Windows Hardening System - User Guide

**Version:** 1.0  
**Last Updated:** 2026-06-26  
**Status:** Production Ready (Grade A)

---

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Installation](#installation)
4. [Quick Start](#quick-start)
5. [Hardening Profiles](#hardening-profiles)
6. [Common Use Cases](#common-use-cases)
7. [Advanced Features](#advanced-features)
8. [Troubleshooting](#troubleshooting)
9. [FAQs](#faqs)

---

## Overview

The WinHarden Windows Hardening System provides automated, profile-based security hardening for Windows Client and Server systems. It supports three hardening levels (Basis, Recommended, Strict) and includes compliance verification, remediation, reporting, and automation capabilities.

### Key Features

- **Three Security Profiles:** Basis (minimum), Recommended (standard), Strict (maximum)
- **Automated Hardening:** Apply security rules to registry, services, firewall, and audit policies
- **Compliance Verification:** Check current system compliance with hardening rules
- **Auto-Remediation:** Automatically fix non-compliant settings
- **Multi-Format Reports:** JSON, CSV, HTML, and Text export
- **Remote Deployment:** Harden multiple systems via PowerShell Remoting
- **Email Alerts:** Receive notifications for compliance events
- **Scheduled Automation:** Run compliance checks on recurring schedules
- **Group Policy Integration:** Deploy hardening policies domain-wide
- **Compliance Trending:** Track hardening progress over time

### Supported Platforms

- **Clients:** Windows 11
- **Servers:** Windows Server 2019, 2022, 2025
- **PowerShell:** 5.1 (Windows PowerShell), 7.x (Core)

---

## Prerequisites

### System Requirements

- **Administrator Rights:** Required to modify system settings
- **PowerShell 5.1+:** Windows PowerShell (built-in) or PowerShell 7.x
- **Core Module:** WinHarden Core module imported
- **System Module:** WinHarden System module with Hardening functions

### Optional Requirements

- **Group Policy Management Console (GPMC):** For GPO integration
- **Active Directory:** For domain-wide deployment (GPO mode)
- **SMTP Server:** For email alert notifications
- **PowerShell Remoting:** For remote hardening deployment

### Permissions

- **Local Hardening:** Administrator rights required
- **Remote Hardening:** Domain Admin or appropriate RDP/WinRM permissions
- **GPO Integration:** Domain Admin rights required
- **Scheduling:** SYSTEM privilege (Task Scheduler)

---

## Installation

### Step 1: Locate WinHarden

```powershell
# Find WinHarden installation
$winOpsKitPath = "C:\Path\To\WinHarden"
```

### Step 2: Import Modules

```powershell
# Import Core module (required first)
Import-Module "$winOpsKitPath\modules\Core.psm1" -Force

# Import System module (includes hardening functions)
Import-Module "$winOpsKitPath\modules\System.psm1" -Force
```

### Step 3: Verify Installation

```powershell
# List available hardening functions
Get-Command -Module System | Where-Object Name -like "*Hardening*"

# Expected output:
# CommandType Name
# ----------- ----
# Function    New-HardeningSession
# Function    Get-HardeningProfile
# Function    Invoke-SecurityHardening
# Function    Test-HardeningCompliance
# Function    Export-HardeningReport
# Function    Invoke-RemoteHardening
# Function    New-HardeningSchedule
# Function    Import-HardeningGPO
# Function    Send-HardeningAlert
# Function    Get-HardeningTrendData
```

### Step 4: Run as Administrator

**Important:** Always run PowerShell as Administrator for hardening operations.

```powershell
# Check current user
[Security.Principal.WindowsIdentity]::GetCurrent().Owner
# Should return: S-1-5-21-...-500 (Administrator SID)
```

---

## Quick Start

### 5-Minute Hardening: Basis Profile

```powershell
# Step 1: Create hardening session
$session = New-HardeningSession -Profile Basis `
    -TargetSystem Client `
    -OSVersion 11

# Step 2: Apply hardening rules
Invoke-SecurityHardening -Session $session

# Step 3: Verify compliance
$compliance = Test-HardeningCompliance -Session $session

# Step 4: View results
Write-Host "Compliance: $($compliance.CompliancePercentage)%"
Write-Host "Status: $($compliance.Status)"
```

### 10-Minute Hardening + Report: Recommended Profile

```powershell
# Create session for recommended profile
$session = New-HardeningSession -Profile Recommended `
    -TargetSystem Server `
    -OSVersion 2022

# Apply hardening
Write-Host "Applying hardening rules..."
Invoke-SecurityHardening -Session $session

# Verify compliance
Write-Host "Verifying compliance..."
$compliance = Test-HardeningCompliance -Session $session

# Generate HTML report
Export-HardeningReport -ComplianceReport $compliance `
    -Format HTML `
    -OutputPath "C:\Reports\Hardening-Report.html"

Write-Host "Report saved to: C:\Reports\Hardening-Report.html"
```

### Dry-Run Mode (No Changes)

```powershell
# Use WhatIf to preview changes without applying
$session = New-HardeningSession -Profile Recommended `
    -TargetSystem Client -OSVersion 11

# Preview what would be changed
Invoke-SecurityHardening -Session $session -WhatIf
```

---

## Hardening Profiles

### Basis Profile

**Target:** Minimum security baseline  
**Rules:** 12 foundational security rules  
**Use Case:** Development systems, non-production

```powershell
# Example: Apply Basis profile
$session = New-HardeningSession -Profile Basis `
    -TargetSystem Client -OSVersion 11

Invoke-SecurityHardening -Session $session
```

**Includes:**
- Minimum password length (12 characters)
- Password complexity requirements
- Windows Defender firewall
- SMB1 disabled
- UAC elevation prompt
- RDP NLA enabled
- Obsolete ciphers disabled
- IPv6 disabled
- Security updates automatic
- Audit logon events
- LLMNR disabled
- Print spooler disabled

### Recommended Profile

**Target:** Standard production security  
**Rules:** 18 enhanced security rules  
**Use Case:** Production systems, standard deployments

```powershell
# Example: Apply Recommended profile
$session = New-HardeningSession -Profile Recommended `
    -TargetSystem Server -OSVersion 2022

Invoke-SecurityHardening -Session $session
```

**Includes:** All Basis rules PLUS:
- Account lockout duration (30 minutes)
- ICMP echo disabled
- Unnecessary services disabled
- DEP enabled
- SMB signing enforced
- RDP encryption level set
- IP source routing disabled
- Privilege use auditing
- NTLMv2 enforcement

### Strict Profile

**Target:** Maximum security hardening  
**Rules:** 14+ strict security rules  
**Use Case:** High-security environments, compliance

```powershell
# Example: Apply Strict profile
$session = New-HardeningSession -Profile Strict `
    -TargetSystem Server -OSVersion 2025

Invoke-SecurityHardening -Session $session
```

**Includes:** All Recommended rules PLUS:
- Minimum password length (14 characters)
- Strict account lockout (5 attempts, 30 min)
- Inbound firewall policy strict
- BitLocker enabled
- TLS 1.2+ enforced
- Clipboard redirection disabled
- Drive redirection disabled
- RDP port randomized
- SMB signing required
- Minimal services only
- All UAC checks enabled
- Extended audit logging
- Autorun disabled
- ICMP redirects disabled
- Credential Guard enabled (Server)

---

## Common Use Cases

### Use Case 1: Harden Single Workstation

```powershell
# Scenario: Secure a single Windows 11 client

$session = New-HardeningSession -Profile Recommended `
    -TargetSystem Client -OSVersion 11

# Preview changes
Invoke-SecurityHardening -Session $session -WhatIf

# Apply hardening
Invoke-SecurityHardening -Session $session

# Verify
$result = Test-HardeningCompliance -Session $session
Write-Host "Compliance: $($result.CompliancePercentage)%"
```

### Use Case 2: Harden Server with Specific Rules

```powershell
# Scenario: Apply only firewall and account policies

$session = New-HardeningSession -Profile Recommended `
    -TargetSystem Server -OSVersion 2022

# Filter to specific rules
Invoke-SecurityHardening -Session $session `
    -RuleFilter @("Firewall*", "Account*")
```

### Use Case 3: Auto-Remediate Non-Compliant Systems

```powershell
# Scenario: Automatically fix non-compliant settings

$session = New-HardeningSession -Profile Recommended `
    -TargetSystem Server -OSVersion 2022

# Check and remediate
$result = Test-HardeningCompliance -Session $session `
    -Remediate

Write-Host "Remediated $($result.RemediatedRules.Count) rules"
```

### Use Case 4: Generate Compliance Report

```powershell
# Scenario: Create compliance report in multiple formats

$session = New-HardeningSession -Profile Strict `
    -TargetSystem Server -OSVersion 2025

$compliance = Test-HardeningCompliance -Session $session

# JSON for programmatic processing
Export-HardeningReport -ComplianceReport $compliance `
    -Format JSON -OutputPath "report.json"

# HTML for dashboards
Export-HardeningReport -ComplianceReport $compliance `
    -Format HTML -OutputPath "report.html"

# CSV for Excel
Export-HardeningReport -ComplianceReport $compliance `
    -Format CSV -OutputPath "report.csv"
```

### Use Case 5: Schedule Recurring Compliance Checks

```powershell
# Scenario: Run compliance check every Monday at 2 AM

New-HardeningSchedule -Profile Recommended `
    -Schedule Weekly `
    -DayOfWeek Monday `
    -Time "02:00" `
    -GenerateReport `
    -ReportFormat HTML

# Enable auto-remediation
New-HardeningSchedule -Profile Strict `
    -Schedule Daily `
    -Time "03:00" `
    -AutoRemediate `
    -GenerateReport
```

---

## Advanced Features

### Remote Hardening

```powershell
# Harden multiple servers remotely
Invoke-RemoteHardening `
    -ComputerName @("Server1", "Server2", "Server3") `
    -Profile Recommended `
    -Parallel
```

### Email Alerts

```powershell
# Send compliance alert
Send-HardeningAlert `
    -SmtpServer "smtp.company.com" `
    -FromAddress "hardening@company.com" `
    -ToAddress @("security-team@company.com") `
    -AlertType Compliance `
    -Severity Warning `
    -ComplianceReport $compliance
```

### Compliance Trending

```powershell
# View compliance trends
Get-HardeningTrendData -ComputerName "Server1" `
    -Days 30 | Select-Object Date, CompliancePercentage, Trend
```

### Group Policy Deployment

```powershell
# Deploy hardening via GPO to domain
Import-HardeningGPO -Profile Recommended `
    -TargetOU "OU=Servers,DC=contoso,DC=com" `
    -EnableAudit
```

---

## Troubleshooting

### Issue: "Access Denied" or Permission Errors

**Cause:** Not running as Administrator

**Solution:**
```powershell
# Check if running as admin
[bool]([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Should return: True
# If False, restart PowerShell as Administrator
```

### Issue: "Profile not found"

**Cause:** Incorrect profile name or wrong path

**Solution:**
```powershell
# Verify available profiles
Get-Item -Path "functions/System/Hardening.Profiles/*.psd1"

# Use correct names: Basis, Recommended, Strict
```

### Issue: "Invalid session object"

**Cause:** Session object is malformed or missing State property

**Solution:**
```powershell
# Always create session using New-HardeningSession
$session = New-HardeningSession -Profile Basis `
    -TargetSystem Client -OSVersion 11

# Do not manually create or edit session objects
```

### Issue: Rules not applying

**Cause:** Insufficient privileges or system constraints

**Solution:**
```powershell
# Ensure running as Administrator
# Some rules may require specific Windows versions
# Use -WhatIf to preview what will happen
Invoke-SecurityHardening -Session $session -WhatIf
```

### Issue: SMTP/Email alerts failing

**Cause:** SMTP server unreachable or invalid credentials

**Solution:**
```powershell
# Verify SMTP connectivity
Test-NetConnection -ComputerName "smtp.company.com" -Port 587

# Use correct SMTP server and port
# Provide credentials if required
$cred = Get-Credential
Send-HardeningAlert -SmtpServer "smtp.company.com" `
    -FromAddress "alerts@company.com" `
    -ToAddress "admin@company.com" `
    -AlertType Compliance `
    -Credential $cred `
    -UseSSL `
    -SmtpPort 587
```

---

## FAQs

### Q: How often should I run hardening?
**A:** Run initial hardening once, then verify compliance quarterly or after system updates. Use scheduled compliance checks for continuous monitoring.

### Q: Can I undo hardening changes?
**A:** No automated undo. Changes are applied to system settings. To revert, you would need to manually restore settings or use system restore points if available.

### Q: Is it safe to use Strict profile in production?
**A:** Strict profile is very restrictive. Test thoroughly in non-production first. Recommended profile is typically best for production.

### Q: How do I know which profile to use?
**A:** Start with Recommended for production systems. Use Basis for development/test. Use Strict only in high-security environments.

### Q: Can I apply hardening to multiple computers?
**A:** Yes, use Invoke-RemoteHardening for multiple systems via PowerShell Remoting, or Import-HardeningGPO for domain-wide deployment via Group Policy.

### Q: What if hardening breaks an application?
**A:** Use -WhatIf to preview changes first. If issues occur, you can manually revert specific settings. Consider using Basis profile which is less restrictive.

### Q: How does compliance verification work?
**A:** Test-HardeningCompliance checks each rule against actual system settings and reports compliance percentage and status.

### Q: Can I customize hardening rules?
**A:** Profiles are predefined. For custom rules, you can use RuleFilter to apply only specific rules you need.

---

## Additional Resources

- [Deployment Guide](HARDENING_DEPLOYMENT_GUIDE.md) - Installation and deployment
- [Architecture Guide](HARDENING_ARCHITECTURE.md) - System design and components
- [SIEM Integration](HARDENING_SIEM_INTEGRATION.md) - Dashboard and SIEM setup
- [Function Help](Get-Help Get-HardeningProfile -Full) - Detailed function documentation

---

**Version:** 1.0  
**Last Updated:** 2026-06-26  
**Status:** Production Ready
