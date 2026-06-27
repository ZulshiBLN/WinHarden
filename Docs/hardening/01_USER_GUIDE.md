# WinHarden - User Guide

**Complete reference for using WinHarden hardening features and cmdlets.**

---

## Table of Contents

1. [Overview](#overview)
2. [Getting Started](#getting-started)
3. [Core Cmdlets](#core-cmdlets)
4. [Common Tasks](#common-tasks)
5. [Monitoring & Reporting](#monitoring--reporting)
6. [Troubleshooting](#troubleshooting)
7. [Advanced Usage](#advanced-usage)

---

## Overview

WinHarden is a comprehensive PowerShell-based security hardening framework for Windows servers and workstations. It provides:

### What WinHarden Does

- **Security Hardening** - Applies CIS benchmark configurations
- **Compliance Verification** - Checks against hardening baselines
- **Drift Detection** - Identifies unauthorized configuration changes
- **Audit Logging** - Records all hardening actions
- **Automated Remediation** - Fixes security issues automatically

### Key Features

| Feature | Purpose | Scope |
|---------|---------|-------|
| Account Hardening | Enforce strong password policies | Local & domain users |
| Firewall Configuration | Deploy security rules | Windows Defender Firewall |
| Service Hardening | Disable unnecessary services | Critical system services |
| Registry Hardening | Secure registry settings | Sensitive registry paths |
| Windows Updates | Enforce security patches | Patch management |
| Audit Policy | Enable comprehensive logging | Windows Event Log |
| BitLocker Integration | Full-disk encryption | Supported volumes |
| UAC Management | User Account Control settings | Windows security |

---

## Getting Started

### Installation

```powershell
# Clone the WinHarden repository
cd C:\Repos
git clone https://github.com/your-org/WinHarden.git

# Navigate to WinHarden directory
cd WinHarden

# Review CLAUDE.md for project guidelines
Get-Content CLAUDE.md -Head 50

# Review available functions
Get-ChildItem functions/ -Recurse -Filter *.ps1 | Select-Object Name
```

### Importing the Module

```powershell
# Method 1: Import entire module
Import-Module C:\Repos\WinHarden -Force

# Method 2: Dot-source specific functions
. C:\Repos\WinHarden\functions\Hardening\New-HardeningBaseline.ps1

# Verify functions are loaded
Get-Command -Module WinHarden | Select-Object Name | Format-Table
```

### Admin Requirements

All WinHarden operations require Administrator privileges:

```powershell
# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

if ($isAdmin) {
    Write-Host "Running as Administrator [OK]"
} else {
    Write-Host "NOT running as Administrator [ERROR]"
    Write-Host "Please re-run PowerShell as Administrator"
    exit 1
}
```

---

## Core Cmdlets

### Baseline Management

#### New-HardeningBaseline

Creates a new security baseline from current system state.

```powershell
# Create baseline with default settings
New-HardeningBaseline -Name "Production-Baseline-2026" -Description "Baseline for production servers"

# Create baseline with custom scope
New-HardeningBaseline `
    -Name "Development-Baseline" `
    -Description "Baseline for dev environment" `
    -IncludeServices $true `
    -IncludeRegistry $true `
    -IncludeAuditPolicy $true

# Verify baseline created
Get-ChildItem C:\Repos\WinHarden\baselines\ | Select-Object Name, LastWriteTime
```

**Output:** Baseline file created in `C:\Repos\WinHarden\baselines\`

#### Get-HardeningBaseline

Retrieves existing baseline configurations.

```powershell
# List all baselines
Get-HardeningBaseline

# Get specific baseline
Get-HardeningBaseline -Name "Production-Baseline-2026"

# Get baseline details
Get-HardeningBaseline -Name "Production-Baseline-2026" | Format-List

# Export baseline
$baseline = Get-HardeningBaseline -Name "Production-Baseline-2026"
$baseline | Export-Clixml -Path "C:\Repos\WinHarden\baselines\backup_prod.xml"
```

### Compliance Operations

#### Test-SystemCompliance

Tests current system against baseline for compliance violations.

```powershell
# Test against default baseline
$result = Test-SystemCompliance -BaselineName "Production-Baseline-2026"

# View compliance summary
$result | Select-Object Category, ComplianceRate, IssueCount

# View detailed compliance report
$result | Format-List

# Export compliance report
$result | Export-Csv -Path "C:\Repos\WinHarden\logs\compliance_report_$(Get-Date -Format 'yyyyMMdd').csv"

# Test specific categories only
Test-SystemCompliance `
    -BaselineName "Production-Baseline-2026" `
    -Categories @("Firewall", "Services", "Registry")
```

**Output:** Compliance report with pass/fail status for each check

#### Invoke-HardeningRemediation

Applies hardening configurations to fix compliance violations.

```powershell
# Apply all remediations
Invoke-HardeningRemediation -BaselineName "Production-Baseline-2026" -Force

# Apply specific category remediations
Invoke-HardeningRemediation `
    -BaselineName "Production-Baseline-2026" `
    -Category "Firewall" `
    -WhatIf  # Preview changes without applying

# Apply with logging
Invoke-HardeningRemediation `
    -BaselineName "Production-Baseline-2026" `
    -Verbose `
    -LogPath "C:\Repos\WinHarden\logs\remediation_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
```

### Drift Detection

#### Get-SecurityDrift

Compares current system state against baseline and reports changes.

```powershell
# Detect all drift
$drift = Get-SecurityDrift -BaselineName "Production-Baseline-2026"

# View drift summary
$drift | Group-Object Category | Select-Object Name, Count

# View drift details
$drift | Where-Object Status -eq "Drift" | Format-Table

# Filter by severity
$drift | Where-Object Severity -in @("High", "Critical") | Format-Table

# Export drift report
$drift | Export-Csv -Path "C:\Repos\WinHarden\logs\drift_report_$(Get-Date -Format 'yyyyMMdd').csv"
```

### Reporting

#### New-SecurityDriftReport

Generates comprehensive security drift report.

```powershell
# Generate full drift report
New-SecurityDriftReport `
    -BaselineName "Production-Baseline-2026" `
    -OutputPath "C:\Repos\WinHarden\logs"

# Generate with summary only
New-SecurityDriftReport `
    -BaselineName "Production-Baseline-2026" `
    -OutputPath "C:\Repos\WinHarden\logs" `
    -SummaryOnly

# Generate for specific category
New-SecurityDriftReport `
    -BaselineName "Production-Baseline-2026" `
    -OutputPath "C:\Repos\WinHarden\logs" `
    -Category "Firewall"
```

**Output:** CSV and JSON reports in logs directory

---

## Common Tasks

### Task 1: Initial Hardening Deployment

```powershell
# Step 1: Create baseline from current state
New-HardeningBaseline -Name "MyServer-Baseline" -Description "Initial baseline"

# Step 2: Manually adjust baseline if needed
# Edit baseline file in C:\Repos\WinHarden\baselines\

# Step 3: Test compliance before applying
$compliance = Test-SystemCompliance -BaselineName "MyServer-Baseline"
$compliance | Where-Object Status -eq "Failed" | Format-Table

# Step 4: Review what will change
Invoke-HardeningRemediation -BaselineName "MyServer-Baseline" -WhatIf

# Step 5: Apply hardening
Invoke-HardeningRemediation -BaselineName "MyServer-Baseline" -Force -Verbose

# Step 6: Verify application
$compliance = Test-SystemCompliance -BaselineName "MyServer-Baseline"
Write-Host "Overall Compliance: $($compliance.ComplianceRate)%"
```

### Task 2: Regular Compliance Monitoring

```powershell
# Daily: Check for drift
$drift = Get-SecurityDrift -BaselineName "MyServer-Baseline"
if ($drift | Where-Object Status -eq "Drift") {
    Write-Host "[WARNING] Drift detected"
    $drift | Where-Object Status -eq "Drift" | Format-Table
}

# Weekly: Generate drift report
New-SecurityDriftReport -BaselineName "MyServer-Baseline" -OutputPath "C:\Repos\WinHarden\logs"

# Monthly: Full compliance audit
$compliance = Test-SystemCompliance -BaselineName "MyServer-Baseline"
$compliance | Export-Csv -Path "C:\Repos\WinHarden\logs\monthly_compliance_$(Get-Date -Format 'yyyyMM').csv"
```

### Task 3: Multi-Server Hardening

```powershell
# Create baseline for all servers
$servers = @("Server1", "Server2", "Server3")

foreach ($server in $servers) {
    Write-Host "Hardening $server..."
    
    # Test compliance
    $compliance = Test-SystemCompliance -ComputerName $server -BaselineName "MyServer-Baseline"
    
    # Apply remediation
    Invoke-HardeningRemediation -ComputerName $server -BaselineName "MyServer-Baseline" -Force
    
    # Verify
    $compliance = Test-SystemCompliance -ComputerName $server -BaselineName "MyServer-Baseline"
    Write-Host "$server: Compliance=$(($compliance.ComplianceRate | Measure-Object -Average).Average)%"
}
```

### Task 4: Emergency Compliance Restoration

```powershell
# If system is compromised, restore from baseline immediately
Invoke-HardeningRemediation -BaselineName "MyServer-Baseline" -Force -Aggressive

# Then verify restoration
$drift = Get-SecurityDrift -BaselineName "MyServer-Baseline"
$drift | Where-Object Status -eq "Drift" | Format-Table

# Generate incident report
New-SecurityDriftReport `
    -BaselineName "MyServer-Baseline" `
    -OutputPath "C:\Repos\WinHarden\logs" `
    -IncidentReport
```

---

## Monitoring & Reporting

### View Hardening Logs

```powershell
# List all logs
Get-ChildItem C:\Repos\WinHarden\logs\ | Select-Object Name, LastWriteTime

# View latest hardening operations
Get-Content C:\Repos\WinHarden\logs\hardening_operations.log -Tail 50

# Filter for errors
Get-Content C:\Repos\WinHarden\logs\hardening_operations.log | 
    Select-String -Pattern "ERROR|WARN" |
    Format-Table
```

### Generate Summary Reports

```powershell
# Compliance summary
$baseline = "MyServer-Baseline"
$compliance = Test-SystemCompliance -BaselineName $baseline

Write-Host "=== Compliance Summary ==="
Write-Host "Baseline: $baseline"
Write-Host "Timestamp: $(Get-Date)"
Write-Host "Overall Compliance: $($compliance.ComplianceRate)%"
Write-Host "Total Checks: $($compliance.TotalChecks)"
Write-Host "Failed Checks: $($compliance.FailedChecks)"
Write-Host "Passed Checks: $($compliance.PassedChecks)"
```

### Export for Analysis

```powershell
# Export compliance data
$compliance = Test-SystemCompliance -BaselineName "MyServer-Baseline"
$compliance | Export-Csv -Path "compliance_export.csv" -NoTypeInformation

# Export drift data
$drift = Get-SecurityDrift -BaselineName "MyServer-Baseline"
$drift | Export-Csv -Path "drift_export.csv" -NoTypeInformation

# Export as JSON for SIEM
$compliance | ConvertTo-Json | Out-File "compliance_report.json"
```

---

## Troubleshooting

### Issue: "Permission Denied" error

**Solution:**
```powershell
# Verify running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
Write-Host "Admin: $isAdmin"

# If not admin, restart PowerShell as Administrator
# Win + X -> PowerShell (Admin)
```

### Issue: "Cannot find baseline" error

**Solution:**
```powershell
# List available baselines
Get-ChildItem C:\Repos\WinHarden\baselines\ -Filter "*.xml"

# Create baseline if missing
New-HardeningBaseline -Name "MyServer-Baseline"
```

### Issue: Remediation fails with "Access Denied"

**Solution:**
```powershell
# Verify SYSTEM account can access paths
icacls C:\Repos\WinHarden\
icacls C:\Repos\WinHarden\baselines\
icacls C:\Repos\WinHarden\logs\

# Grant permissions if needed
icacls C:\Repos\WinHarden /grant:r "SYSTEM:(F)" /T
```

### Issue: Performance degradation during remediation

**Solution:**
```powershell
# Run with reduced scope
Invoke-HardeningRemediation `
    -BaselineName "MyServer-Baseline" `
    -Category "Firewall"  # Single category

# Run during off-peak hours
# Schedule via Task Scheduler for 02:00 AM

# Monitor resource usage
Get-Process | Where-Object CPU -gt 50 | Format-Table
```

---

## Advanced Usage

### Custom Baseline Creation

```powershell
# Create baseline with specific settings
$baseline = @{
    Name = "Custom-Baseline"
    Description = "Custom hardening configuration"
    Firewall = @{
        Enabled = $true
        DefaultInbound = "Block"
        DefaultOutbound = "Allow"
    }
    Services = @{
        DisabledServices = @("RDP", "WinRM")
        MustRunServices = @("WinDefender", "WindowsUpdate")
    }
    Registry = @{
        UAC = "Enabled"
        DEP = "Enabled"
        ASLR = "Enabled"
    }
}

# Apply custom baseline (implementation-specific)
```

### Scheduled Hardening Operations

```powershell
# Create scheduled task for daily compliance check
$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File C:\Repos\WinHarden\scripts\Daily-Compliance-Check.ps1"

$trigger = New-ScheduledTaskTrigger -Daily -At 02:00AM

Register-ScheduledTask `
    -TaskName "WinHarden-Daily-Compliance" `
    -Action $action `
    -Trigger $trigger `
    -RunLevel Highest `
    -Force
```

### Integration with External Tools

```powershell
# Export compliance data for Splunk
$compliance = Test-SystemCompliance -BaselineName "MyServer-Baseline"
$compliance | ConvertTo-Json | 
    Out-File "C:\Splunk\compliance_$(Get-Date -Format 'yyyyMMddHHmmss').json"

# Send to webhook
$body = @{
    baseline = "MyServer-Baseline"
    compliance_rate = $compliance.ComplianceRate
    timestamp = (Get-Date -Format 'o')
} | ConvertTo-Json

Invoke-WebRequest `
    -Uri "https://monitoring.example.com/api/compliance" `
    -Method POST `
    -Body $body `
    -ContentType "application/json"
```

---

## Quick Reference

### Essential Commands

```powershell
# Create baseline
New-HardeningBaseline -Name "MyBaseline"

# Test compliance
Test-SystemCompliance -BaselineName "MyBaseline"

# Detect drift
Get-SecurityDrift -BaselineName "MyBaseline"

# Apply hardening
Invoke-HardeningRemediation -BaselineName "MyBaseline" -Force

# Generate report
New-SecurityDriftReport -BaselineName "MyBaseline" -OutputPath "C:\Repos\WinHarden\logs"

# Get help
Get-Help New-HardeningBaseline -Full
Get-Help Test-SystemCompliance -Full
Get-Help Get-SecurityDrift -Full
```

---

**Document Version:** 2.0  
**Last Updated:** 2026-06-27  
**Target Audience:** System Administrators, Security Engineers, Operations Teams  
**Complexity Level:** Beginner to Intermediate
