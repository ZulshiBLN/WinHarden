# WinHarden Hardening System - Deployment Guide

**Version:** 1.0  
**Last Updated:** 2026-06-26  
**Audience:** IT Administrators, Infrastructure Teams

---

## Table of Contents

1. [Deployment Overview](#deployment-overview)
2. [Local Deployment](#local-deployment)
3. [Remote Deployment](#remote-deployment)
4. [Group Policy Deployment](#group-policy-deployment)
5. [Scheduled Deployment](#scheduled-deployment)
6. [Multi-System Deployment](#multi-system-deployment)
7. [Verification & Monitoring](#verification--monitoring)
8. [Troubleshooting](#troubleshooting)

---

## Deployment Overview

### Deployment Methods

The WinHarden Hardening System supports three primary deployment methods:

| Method | Scope | Audience | Complexity |
|--------|-------|----------|-----------|
| **Local** | Single system | Local admin | Low |
| **Remote** | Multiple systems | Domain admin | Medium |
| **GPO** | Domain-wide | Domain admin | Medium |
| **Scheduled** | Recurring | Domain admin | Medium |

### Deployment Decision Tree

```
Start: Need to harden systems?
  |
  +-- Single system? --> Local Deployment
  |
  +-- Multiple systems?
       |
       +-- Same network, WinRM enabled? --> Remote Deployment
       |
       +-- Domain-joined? --> Group Policy Deployment
       |
       +-- Recurring checks needed? --> Scheduled Deployment
```

---

## Local Deployment

### Prerequisites

- Administrator rights on target system
- PowerShell 5.1 or higher
- WinHarden modules imported

### Step-by-Step

#### Step 1: Prepare System

```powershell
# Run PowerShell as Administrator
# Verify prerequisites
[bool]([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Should return: True
```

#### Step 2: Import Modules

```powershell
# Set path to WinHarden
$winOpsKitPath = "C:\Path\To\WinHarden"

# Import Core module
Import-Module "$winOpsKitPath\modules\Core.psm1" -Force

# Import System module
Import-Module "$winOpsKitPath\modules\System.psm1" -Force
```

#### Step 3: Create Hardening Session

```powershell
# For Windows 11 Client
$session = New-HardeningSession -Profile Recommended `
    -TargetSystem Client `
    -OSVersion 11

# For Windows Server 2022
$session = New-HardeningSession -Profile Recommended `
    -TargetSystem Server `
    -OSVersion 2022
```

#### Step 4: Preview Changes (Optional but Recommended)

```powershell
# Preview what will be applied
Invoke-SecurityHardening -Session $session -WhatIf
```

#### Step 5: Apply Hardening

```powershell
# Apply hardening rules
Write-Host "Applying hardening rules..."
$result = Invoke-SecurityHardening -Session $session

Write-Host "Successfully applied $($result.SuccessfulRules.Count) rules"
Write-Host "Failed rules: $($result.FailedRules.Count)"
```

#### Step 6: Verify Compliance

```powershell
# Check compliance after hardening
$compliance = Test-HardeningCompliance -Session $session

Write-Host "Compliance: $($compliance.CompliancePercentage)%"
Write-Host "Status: $($compliance.Status)"
Write-Host "Compliant Rules: $($compliance.CompliantRules)/$($compliance.TotalRules)"
```

#### Step 7: Generate Report

```powershell
# Export compliance report
Export-HardeningReport -ComplianceReport $compliance `
    -Format HTML `
    -OutputPath "C:\Reports\Hardening-Report.html"

Write-Host "Report saved: C:\Reports\Hardening-Report.html"
```

### Local Deployment Script

```powershell
# Complete local deployment script
param(
    [ValidateSet('Basis', 'Recommended', 'Strict')]
    [string]$Profile = 'Recommended',
    
    [string]$WinHardenPath = 'C:\WinHarden'
)

# Import modules
Import-Module "$WinHardenPath\modules\Core.psm1" -Force
Import-Module "$WinHardenPath\modules\System.psm1" -Force

# Detect OS
if ($PSVersionTable.OS -match 'Windows Server') {
    $targetSystem = 'Server'
    $osVersion = [int]$((Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentVersion.Split('.')[0] + (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ReleaseId)
} else {
    $targetSystem = 'Client'
    $osVersion = [int](Get-WmiObject Win32_OperatingSystem).Caption.Split(' ')[-1]
}

# Create session
Write-Host "Creating hardening session for $targetSystem (OS: $osVersion)..."
$session = New-HardeningSession -Profile $Profile `
    -TargetSystem $targetSystem -OSVersion $osVersion

# Apply hardening
Write-Host "Applying $Profile hardening profile..."
$result = Invoke-SecurityHardening -Session $session
Write-Host "Applied $($result.SuccessfulRules.Count) rules"

# Verify
Write-Host "Verifying compliance..."
$compliance = Test-HardeningCompliance -Session $session
Write-Host "Compliance: $($compliance.CompliancePercentage)%"

# Report
Export-HardeningReport -ComplianceReport $compliance `
    -Format HTML -OutputPath "C:\Reports\Hardening-Report.html"

Write-Host "Deployment complete!"
```

---

## Remote Deployment

### Prerequisites

- Source: Domain admin or appropriate credentials
- Target: PowerShell Remoting enabled (WinRM)
- Network: Access to target systems on port 5985 (HTTP) or 5986 (HTTPS)

### Enable PowerShell Remoting on Targets

```powershell
# On target systems (requires admin):
Enable-PSRemoting -Force

# Verify it's enabled
Get-Service WinRM | Select-Object Status
```

### Remote Deployment: Single System

```powershell
$credential = Get-Credential  # Provide domain credentials

Invoke-RemoteHardening `
    -ComputerName "Server1" `
    -Profile Recommended `
    -Credential $credential
```

### Remote Deployment: Multiple Systems

```powershell
$servers = @("Server1", "Server2", "Server3", "Server4", "Server5")
$credential = Get-Credential

Invoke-RemoteHardening `
    -ComputerName $servers `
    -Profile Recommended `
    -Credential $credential `
    -Parallel
```

### Remote Deployment: From CSV

```powershell
# servers.csv format:
# ComputerName,Profile
# Server1,Recommended
# Server2,Strict
# Server3,Basis

$servers = Import-Csv "servers.csv"
$credential = Get-Credential

foreach ($server in $servers) {
    Write-Host "Hardening $($server.ComputerName) with $($server.Profile) profile..."
    Invoke-RemoteHardening `
        -ComputerName $server.ComputerName `
        -Profile $server.Profile `
        -Credential $credential
}
```

### Remote Deployment Script

```powershell
param(
    [string[]]$ComputerNames = @(),
    [ValidateSet('Basis', 'Recommended', 'Strict')]
    [string]$Profile = 'Recommended',
    [switch]$Parallel
)

$credential = Get-Credential -Message "Enter domain credentials"

Write-Host "Starting remote deployment to $($ComputerNames.Count) system(s)..."

Invoke-RemoteHardening `
    -ComputerName $ComputerNames `
    -Profile $Profile `
    -Credential $credential `
    -Parallel:$Parallel

Write-Host "Remote deployment complete!"
```

---

## Group Policy Deployment

### Prerequisites

- Domain admin credentials
- GPMC (Group Policy Management Console) installed
- Domain-joined system

### Step 1: Create GPO from Hardening Profile

```powershell
# Create GPO for Recommended profile
Import-HardeningGPO -Profile Recommended `
    -GPOName "WinHarden-Hardening-Recommended" `
    -Domain "contoso.com"
```

### Step 2: Link GPO to Organizational Unit

```powershell
# Link to Servers OU
Import-HardeningGPO -Profile Recommended `
    -TargetOU "OU=Servers,DC=contoso,DC=com" `
    -Domain "contoso.com"

# Link to Workstations OU
Import-HardeningGPO -Profile Basis `
    -TargetOU "OU=Workstations,DC=contoso,DC=com" `
    -Domain "contoso.com"
```

### Step 3: Enable Audit Logging

```powershell
# Create GPO with audit enabled
Import-HardeningGPO -Profile Strict `
    -TargetOU "OU=HighSecurity,DC=contoso,DC=com" `
    -EnableAudit
```

### Step 4: Verify GPO Creation

```powershell
# List all hardening GPOs
Get-HardeningGPO -Domain "contoso.com"

# Filter by profile
Get-HardeningGPO -Domain "contoso.com" -Profile Recommended
```

### GPO Deployment Script

```powershell
param(
    [string]$Domain = "contoso.com"
)

# OU mapping for deployment
$ouMapping = @{
    "OU=Servers,DC=contoso,DC=com" = "Recommended"
    "OU=Workstations,DC=contoso,DC=com" = "Basis"
    "OU=HighSecurity,DC=contoso,DC=com" = "Strict"
}

foreach ($ou in $ouMapping.Keys) {
    $profile = $ouMapping[$ou]
    Write-Host "Deploying $profile profile to $ou..."
    
    Import-HardeningGPO -Profile $profile `
        -TargetOU $ou `
        -Domain $Domain `
        -EnableAudit
}

Write-Host "GPO deployment complete!"

# Force GPO refresh on domain
gpupdate /force
```

---

## Scheduled Deployment

### Create Daily Compliance Check

```powershell
# Schedule daily compliance check at 2 AM
New-HardeningSchedule -Profile Recommended `
    -Schedule Daily `
    -Time "02:00" `
    -GenerateReport `
    -ReportFormat HTML
```

### Create Weekly Compliance Check with Auto-Remediation

```powershell
# Every Monday at 3 AM, auto-remediate non-compliant rules
New-HardeningSchedule -Profile Strict `
    -Schedule Weekly `
    -DayOfWeek Monday `
    -Time "03:00" `
    -AutoRemediate `
    -GenerateReport
```

### Create Monthly Full Audit

```powershell
# Full compliance audit on 1st of month
New-HardeningSchedule -Profile Recommended `
    -Schedule Monthly `
    -DayOfMonth 1 `
    -Time "04:00" `
    -GenerateReport `
    -ReportFormat HTML
```

---

## Multi-System Deployment

### Deployment to 100+ Systems

```powershell
# Load systems from AD
$servers = Get-ADComputer -Filter "OperatingSystem -like '*Server*'" | Select-Object -ExpandProperty Name

$credential = Get-Credential
$batchSize = 20

# Deploy in batches
for ($i = 0; $i -lt $servers.Count; $i += $batchSize) {
    $batch = $servers[$i..($i + $batchSize - 1)]
    
    Write-Host "Deploying batch $([math]::Floor($i/$batchSize)+1) ($($batch.Count) systems)..."
    
    Invoke-RemoteHardening `
        -ComputerName $batch `
        -Profile Recommended `
        -Credential $credential `
        -Parallel
    
    Start-Sleep -Seconds 30  # Wait between batches
}
```

---

## Verification & Monitoring

### Verify Deployment

```powershell
# Check compliance after deployment
$session = New-HardeningSession -Profile Recommended `
    -TargetSystem Server -OSVersion 2022

$compliance = Test-HardeningCompliance -Session $session

if ($compliance.CompliancePercentage -ge 90) {
    Write-Host "Deployment successful!" -ForegroundColor Green
} else {
    Write-Host "Deployment issues detected!" -ForegroundColor Red
    $compliance.NonCompliantRules | ForEach-Object {
        Write-Host "  - $($_.Name)"
    }
}
```

### Monitor with Email Alerts

```powershell
# Send compliance alerts
Send-HardeningAlert `
    -SmtpServer "smtp.company.com" `
    -FromAddress "hardening@company.com" `
    -ToAddress @("security-team@company.com") `
    -AlertType Compliance `
    -Severity $(if($compliance.CompliancePercentage -lt 80) { "Warning" } else { "Info" }) `
    -ComplianceReport $compliance
```

### Track Compliance Trends

```powershell
# View compliance over time
Get-HardeningTrendData -ComputerName "Server1" -Days 30 |
    Select-Object Date, CompliancePercentage, Trend |
    Format-Table
```

---

## Troubleshooting

### Deployment Failed

```powershell
# Check errors from last deployment
$Error | Select-Object -First 10 | Format-List

# Verify system is reachable
Test-Connection "Server1" -Count 2

# Check WinRM is running
Invoke-Command -ComputerName "Server1" -ScriptBlock { "OK" }
```

### Partial Rule Application

```powershell
# Identify which rules failed
$session = New-HardeningSession -Profile Recommended `
    -TargetSystem Server -OSVersion 2022

$result = Invoke-SecurityHardening -Session $session
$result.FailedRules | Format-Table Name, Error
```

### Compliance Verification Failed

```powershell
# Debug compliance checks
$compliance = Test-HardeningCompliance -Session $session
$compliance.NonCompliantRules | ForEach-Object {
    Write-Host "$($_.Name): Expected=$($_.ExpectedValue), Actual=$($_.ActualValue)"
}
```

---

## Deployment Checklist

- [ ] Prerequisites met (admin rights, PowerShell version)
- [ ] WinHarden modules imported
- [ ] Backup system state or create restore point
- [ ] Run with -WhatIf to preview changes
- [ ] Apply hardening to pilot group first
- [ ] Verify compliance on pilot group
- [ ] Generate baseline reports
- [ ] Monitor for issues
- [ ] Deploy to production
- [ ] Set up scheduled compliance checks
- [ ] Configure email alerts

---

**Version:** 1.0  
**Last Updated:** 2026-06-26  
**Status:** Production Ready
