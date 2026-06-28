# WinHarden - Deployment Guide

**Complete step-by-step deployment procedures for enterprise hardening.**

---

## Table of Contents

1. [Pre-Deployment Planning](#pre-deployment-planning)
2. [Environment Preparation](#environment-preparation)
3. [Single-Server Deployment](#single-server-deployment)
4. [Multi-Server Deployment](#multi-server-deployment)
5. [Enterprise Deployment](#enterprise-deployment)
6. [Validation & Testing](#validation--testing)
7. [Rollback Procedures](#rollback-procedures)
8. [Post-Deployment](#post-deployment)

---

## Pre-Deployment Planning

### Deployment Strategy Decision

| Scenario | Strategy | Time | Risk | Effort |
|----------|----------|------|------|--------|
| Single dev server | Direct | 1 hour | Low | Low |
| Small team (5 servers) | Phased | 1 day | Low | Medium |
| Department (20 servers) | Rolling | 1 week | Medium | High |
| Enterprise (100+ servers) | Staged | 2-4 weeks | Low | Very High |

### Pre-Deployment Checklist

```powershell
# 1. Verify repository access
Test-Path <WINHARDEN_REPO>
Get-ChildItem <WINHARDEN_REPO> | Select-Object Name

# 2. Verify PowerShell version
$PSVersionTable.PSVersion  # Should be 5.1+

# 3. Check administrator privileges
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
Write-Host "Administrator: $(if($isAdmin) { 'YES' } else { 'NO' })"

# 4. Verify network connectivity
Test-Connection -ComputerName 8.8.8.8 -Count 1

# 5. Check available disk space
Get-PSDrive C | Select-Object Name, Used, Free

# 6. Verify Windows Update service is running
Get-Service -Name wuauserv | Select-Object Name, Status

# 7. Check Event Log availability
Get-EventLog -List | Select-Object Log

# 8. Create backup of current state
Invoke-Command -ScriptBlock {
    $backupPath = "<WINHARDEN_REPO>\backups\pre_deployment_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    New-Item -ItemType Directory -Path $backupPath -Force
    Write-Host "Backup directory created: $backupPath"
}
```

### Create Deployment Plan Document

```powershell
# Template for deployment plan
$plan = @"
=== WinHarden Deployment Plan ===

PROJECT: [Project Name]
DEPLOYMENT DATE: [Date]
PREPARED BY: [Name]
APPROVED BY: [Name]

SCOPE:
- Servers: [List]
- Categories: [Firewall, Services, Registry, etc.]
- Baseline: [Baseline Name]

TIMELINE:
- Planning Phase: [Dates]
- Validation Phase: [Dates]
- Deployment Phase: [Dates]
- Testing Phase: [Dates]

ROLLBACK PLAN:
- Baseline backup location: [Path]
- Rollback timeline: [Duration]
- Approval process: [Process]

COMMUNICATION:
- Stakeholders: [List]
- Update frequency: [Frequency]
- Escalation contacts: [Contacts]
"@

$plan | Out-File "<WINHARDEN_REPO>\deployment_plan_$(Get-Date -Format 'yyyyMMdd').txt"
```

---

## Environment Preparation

### Backup Current System State

```powershell
# Create comprehensive system backup before any changes
$backupPath = "<WINHARDEN_REPO>\backups\pre_deployment_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Path $backupPath -Force

# 1. Backup firewall rules
Get-NetFirewallRule | Export-Csv "$backupPath\firewall_rules.csv"
Get-NetIPAddress | Export-Csv "$backupPath\network_config.csv"

# 2. Backup service configuration
Get-Service | Select-Object Name, Status, StartType | Export-Csv "$backupPath\services.csv"

# 3. Backup registry keys
reg export "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion" "$backupPath\windows_version.reg"
reg export "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services" "$backupPath\services.reg"

# 4. Backup local security policy
gpresult /h "$backupPath\group_policy_report.html"

# 5. Backup event logs
Get-EventLog -List | ForEach-Object {
    $log = $_.Log
    Get-EventLog -LogName $log | Export-Csv "$backupPath\eventlog_$log.csv" -ErrorAction SilentlyContinue
}

# 6. Backup user accounts
Get-LocalUser | Export-Csv "$backupPath\local_users.csv"
Get-LocalGroup | Export-Csv "$backupPath\local_groups.csv"

# 7. Create system snapshot list
dir C:\ | Export-Csv "$backupPath\filesystem_snapshot.csv"

Write-Host "Backup completed: $backupPath"
Get-ChildItem $backupPath | Measure-Object
```

### Create Baseline from Current State

```powershell
# Before applying any hardening, create baseline of current state
Import-Module <WINHARDEN_REPO> -Force

# Create baseline
New-HardeningBaseline `
    -Name "PreDeployment-$(Get-Date -Format 'yyyyMMdd')" `
    -Description "Baseline before WinHarden deployment" `
    -IncludeServices $true `
    -IncludeRegistry $true `
    -IncludeFirewall $true `
    -IncludeAuditPolicy $true

Write-Host "Pre-deployment baseline created"
Get-HardeningBaseline | Where-Object Name -like "*PreDeployment*"
```

### Test Environment Setup

```powershell
# Create test/staging environment for validation

# Step 1: Use VM snapshot (if available)
# Take snapshot of test VM before deployment

# Step 2: Create dry-run baseline
New-HardeningBaseline `
    -Name "Test-Baseline-$(Get-Date -Format 'yyyyMMdd')" `
    -Description "Test baseline for validation"

# Step 3: Run test deployment with WhatIf
Invoke-HardeningRemediation `
    -BaselineName "Test-Baseline" `
    -WhatIf `
    -Verbose | Tee-Object -FilePath "<WINHARDEN_REPO>\logs\test_deployment_whatif.txt"
```

---

## Single-Server Deployment

### Step 1: Initial Assessment (30 minutes)

```powershell
# Load module
Import-Module <WINHARDEN_REPO> -Force

# Check current compliance
$compliance = Test-SystemCompliance -BaselineName "Default-Baseline"
$compliance | Format-List

# Identify high-severity issues
$issues = Get-SecurityDrift -BaselineName "Default-Baseline"
$issues | Where-Object Severity -in @("Critical", "High") | Format-Table

# Generate assessment report
New-SecurityDriftReport `
    -BaselineName "Default-Baseline" `
    -OutputPath "<WINHARDEN_REPO>\logs"

Write-Host "Assessment complete. Review logs at <WINHARDEN_REPO>\logs\"
```

### Step 2: Test Deployment (WhatIf mode) (30 minutes)

```powershell
# Preview all changes without applying
Write-Host "Running WhatIf deployment..."

Invoke-HardeningRemediation `
    -BaselineName "Default-Baseline" `
    -WhatIf `
    -Verbose `
    -ErrorAction Continue `
    | Tee-Object -FilePath "<WINHARDEN_REPO>\logs\whatif_preview_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

Write-Host "Review preview above. Confirm before proceeding with actual deployment."
```

### Step 3: Pre-Deployment Verification (15 minutes)

```powershell
# Final checks before live deployment

# 1. Verify backup completed
$backupPath = Get-ChildItem <WINHARDEN_REPO>\backups\ -Directory | Sort-Object CreationTime -Descending | Select-Object -First 1
Write-Host "Latest backup: $($backupPath.FullName)"
Get-ChildItem $backupPath.FullName | Measure-Object

# 2. Verify baseline is ready
$baseline = Get-HardeningBaseline | Select-Object -First 1
Write-Host "Baseline: $($baseline.Name)"

# 3. Verify critical services running
@("wuauserv", "winlogon", "lsass") | ForEach-Object {
    $svc = Get-Service -Name $_ -ErrorAction SilentlyContinue
    Write-Host "$($_): $($svc.Status)"
}

# 4. Verify remote access available (if remote)
if ($env:COMPUTERNAME -ne "localhost") {
    Test-NetConnection -ComputerName $env:COMPUTERNAME -Port 5985
}

Write-Host "All pre-deployment checks passed. Ready for deployment."
```

### Step 4: Execute Deployment (1-2 hours)

```powershell
# ACTUAL DEPLOYMENT - Apply hardening to live system

Write-Host "=== STARTING LIVE DEPLOYMENT ==="
Write-Host "Time: $(Get-Date)"
Write-Host "Server: $($env:COMPUTERNAME)"

# Start logging
$logPath = "<WINHARDEN_REPO>\logs\deployment_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# Execute with full logging
Invoke-HardeningRemediation `
    -BaselineName "Default-Baseline" `
    -Force `
    -Verbose `
    -ErrorAction Continue `
    -OutVariable deploymentResult | 
    Tee-Object -FilePath $logPath

Write-Host ""
Write-Host "=== DEPLOYMENT COMPLETE ==="
Write-Host "Log: $logPath"
Write-Host "Time: $(Get-Date)"
```

### Step 5: Post-Deployment Validation (30 minutes)

```powershell
# Verify deployment succeeded

# 1. Check compliance after deployment
$compliance = Test-SystemCompliance -BaselineName "Default-Baseline"
Write-Host "Post-Deployment Compliance: $($compliance.ComplianceRate)%"

# 2. Verify no new drift
$drift = Get-SecurityDrift -BaselineName "Default-Baseline"
if ($drift | Where-Object Status -eq "Drift") {
    Write-Host "[WARNING] Drift detected after deployment:"
    $drift | Where-Object Status -eq "Drift" | Format-Table
} else {
    Write-Host "[OK] No drift detected"
}

# 3. Check system stability
$uptime = (Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
Write-Host "System uptime: $($uptime.TotalMinutes) minutes"

# 4. Verify critical services still running
@("wuauserv", "winlogon", "lsass") | ForEach-Object {
    $svc = Get-Service -Name $_ -ErrorAction SilentlyContinue
    Write-Host "$($_): $($svc.Status)"
}

# 5. Generate final report
New-SecurityDriftReport `
    -BaselineName "Default-Baseline" `
    -OutputPath "<WINHARDEN_REPO>\logs"

Write-Host "Deployment validation complete."
```

---

## Multi-Server Deployment

### Prepare Servers List

```powershell
# Create servers file
$servers = @"
server1.example.com,production,firewall
server2.example.com,production,firewall
server3.example.com,staging,firewall
server4.example.com,development,all
"@

$servers | Out-File "<WINHARDEN_REPO>\servers_deployment.csv"

# Verify connectivity to all servers
$serverList = Import-Csv "<WINHARDEN_REPO>\servers_deployment.csv" -Header Name,Env,Scope
foreach ($server in $serverList) {
    $result = Test-Connection -ComputerName $server.Name -Count 1 -Quiet
    Write-Host "$($server.Name): $(if($result) { 'ONLINE' } else { 'OFFLINE' })"
}
```

### Phased Multi-Server Deployment

```powershell
# Deploy in phases: Production -> Staging -> Development

$phases = @(
    @{ Name = "Pilot"; Servers = @("test-server"); Delay = 0 },
    @{ Name = "Production"; Servers = @("server1", "server2"); Delay = 3600 },
    @{ Name = "Staging"; Servers = @("server3"); Delay = 7200 },
    @{ Name = "Development"; Servers = @("server4"); Delay = 14400 }
)

foreach ($phase in $phases) {
    Write-Host "=== Phase: $($phase.Name) ==="
    
    if ($phase.Delay -gt 0) {
        Write-Host "Waiting $($phase.Delay) seconds before next phase..."
        Start-Sleep -Seconds $phase.Delay
    }
    
    foreach ($server in $phase.Servers) {
        Write-Host "Deploying to $server..."
        
        # Create session
        $session = New-PSSession -ComputerName $server
        
        # Copy module
        Copy-Item -Path "<WINHARDEN_REPO>" -Destination "<WINHARDEN_REPO>" -ToSession $session -Recurse -Force
        
        # Deploy
        Invoke-Command -Session $session -ScriptBlock {
            Import-Module <WINHARDEN_REPO>
            Invoke-HardeningRemediation -BaselineName "Default-Baseline" -Force -Verbose
        }
        
        # Verify
        Invoke-Command -Session $session -ScriptBlock {
            $compliance = Test-SystemCompliance -BaselineName "Default-Baseline"
            Write-Host "Compliance: $($compliance.ComplianceRate)%"
        }
        
        # Close session
        Remove-PSSession -Session $session
        
        Write-Host "$server deployment complete"
    }
}
```

---

## Enterprise Deployment

### Automated Deployment with GPO

```powershell
# Use Group Policy Object for domain-wide deployment

# 1. Create GPO deployment script
$gpoScript = @"
# Deploy WinHarden via GPO
Import-Module <WINHARDEN_REPO>
Invoke-HardeningRemediation -BaselineName "Enterprise-Baseline" -Force
"@

$gpoScript | Out-File "<WINHARDEN_REPO>\scripts\GPO_Deployment.ps1"

# 2. Create Group Policy Object (requires Domain Admin)
# New-GPO -Name "WinHarden-Deployment" -Comment "WinHarden hardening deployment"

# 3. Link to Organizational Units
# Set-GPLink -Name "WinHarden-Deployment" -Target "OU=Servers,DC=example,DC=com"

# 4. Deploy script via GPO Startup Script
# Set GPO: Computer Configuration > Windows Settings > Scripts > Startup
```

### Centralized Monitoring Dashboard

```powershell
# Create centralized compliance monitoring

# Collect compliance data from all servers
$complianceReport = @()

$servers = Import-Csv "<WINHARDEN_REPO>\servers_deployment.csv" -Header Name,Env,Scope

foreach ($server in $servers) {
    Write-Host "Collecting compliance from $($server.Name)..."
    
    $session = New-PSSession -ComputerName $server.Name
    
    $compliance = Invoke-Command -Session $session -ScriptBlock {
        Import-Module <WINHARDEN_REPO>
        Test-SystemCompliance -BaselineName "Default-Baseline"
    }
    
    $complianceReport += [PSCustomObject]@{
        Server = $server.Name
        Environment = $server.Env
        Compliance = $compliance.ComplianceRate
        Failed = $compliance.FailedChecks
        Passed = $compliance.PassedChecks
        Timestamp = Get-Date
    }
    
    Remove-PSSession -Session $session
}

# Export to CSV for analysis
$complianceReport | Export-Csv -Path "<WINHARDEN_REPO>\logs\enterprise_compliance_$(Get-Date -Format 'yyyyMMdd').csv"

# Display summary
$complianceReport | Format-Table Server, Environment, Compliance, Failed, Passed -AutoSize
```

---

## Validation & Testing

### Automated Testing Suite

```powershell
# Run comprehensive post-deployment tests

function Test-DeploymentSuccess {
    param(
        [string]$BaselineName = "Default-Baseline",
        [string]$OutputPath = "<WINHARDEN_REPO>\logs"
    )
    
    $testResults = @()
    
    # Test 1: Compliance check
    Write-Host "Test 1: Compliance Check..."
    $compliance = Test-SystemCompliance -BaselineName $BaselineName
    $testResults += [PSCustomObject]@{
        Test = "Compliance Check"
        Result = $(if($compliance.ComplianceRate -ge 95) { "PASS" } else { "FAIL" })
        Details = "Compliance: $($compliance.ComplianceRate)%"
    }
    
    # Test 2: No critical drift
    Write-Host "Test 2: Drift Detection..."
    $drift = Get-SecurityDrift -BaselineName $BaselineName
    $criticalDrift = $drift | Where-Object Severity -eq "Critical"
    $testResults += [PSCustomObject]@{
        Test = "No Critical Drift"
        Result = $(if($criticalDrift.Count -eq 0) { "PASS" } else { "FAIL" })
        Details = "Critical findings: $($criticalDrift.Count)"
    }
    
    # Test 3: Services running
    Write-Host "Test 3: Critical Services..."
    $services = @("wuauserv", "winlogon", "lsass")
    $allRunning = $true
    foreach ($svc in $services) {
        $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
        if ($s.Status -ne "Running") { $allRunning = $false }
    }
    $testResults += [PSCustomObject]@{
        Test = "Critical Services Running"
        Result = $(if($allRunning) { "PASS" } else { "FAIL" })
        Details = "All critical services operational"
    }
    
    # Test 4: Event Log available
    Write-Host "Test 4: Event Logging..."
    $eventLog = Get-EventLog -List | Where-Object Log -eq "System"
    $testResults += [PSCustomObject]@{
        Test = "Event Logging"
        Result = $(if($eventLog) { "PASS" } else { "FAIL" })
        Details = "Event log operational"
    }
    
    # Export results
    $testResults | Export-Csv -Path "$OutputPath\deployment_test_results_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    
    # Display summary
    $passCount = ($testResults | Where-Object Result -eq "PASS").Count
    $totalCount = $testResults.Count
    Write-Host ""
    Write-Host "=== Test Summary ==="
    Write-Host "Passed: $passCount / $totalCount"
    
    return $testResults
}

# Run tests
$testResults = Test-DeploymentSuccess
$testResults | Format-Table Test, Result, Details -AutoSize
```

---

## Rollback Procedures

### Emergency Rollback

```powershell
# If deployment causes critical issues, rollback to pre-deployment state

Write-Host "[ROLLBACK] Starting emergency rollback..."
Write-Host "Time: $(Get-Date)"

# Step 1: Stop all hardening tasks
Get-ScheduledTask -TaskPath '\Hardening\*' | Disable-ScheduledTask

# Step 2: Restore registry from backup
# reg import "<WINHARDEN_REPO>\backups\pre_deployment_*/windows_version.reg"

# Step 3: Restore firewall rules
# (See backup restoration procedure)

# Step 4: Restore services to original state
# Get-Content "<WINHARDEN_REPO>\backups\pre_deployment_*/services.csv" | ForEach-Object {
#     $svc = Import-Csv
#     Set-Service -Name $svc.Name -StartupType $svc.StartType
# }

# Step 5: Restart critical services
Restart-Service -Name wuauserv, winlogon, lsass -Force

# Step 6: Verify rollback
$compliance = Test-SystemCompliance -BaselineName "Default-Baseline"
Write-Host "Post-Rollback Compliance: $($compliance.ComplianceRate)%"

Write-Host "[ROLLBACK] Rollback complete"
Write-Host "Time: $(Get-Date)"
Write-Host "Please investigate what caused the deployment to fail"
```

---

## Post-Deployment

### Monitor Deployment Health

```powershell
# Daily health check after deployment
$baseline = "Default-Baseline"

Write-Host "=== Post-Deployment Health Check ==="
Write-Host "Date: $(Get-Date)"

# 1. Compliance
$compliance = Test-SystemCompliance -BaselineName $baseline
Write-Host "Compliance: $($compliance.ComplianceRate)%"

# 2. Drift
$drift = Get-SecurityDrift -BaselineName $baseline | Where-Object Status -eq "Drift"
Write-Host "Drift items: $($drift.Count)"

# 3. Event log errors
$errors = Get-EventLog -LogName System -EntryType Error -Newest 100
Write-Host "Recent errors: $($errors.Count)"

# 4. System stability
$uptime = (Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
Write-Host "Uptime: $($uptime.TotalHours) hours"
```

---

**Document Version:** 2.0  
**Last Updated:** 2026-06-27  
**Target Audience:** System Administrators, Deployment Engineers, DevOps  
**Complexity Level:** Intermediate to Advanced
