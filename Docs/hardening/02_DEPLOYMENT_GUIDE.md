# WinHarden Hardening – Deployment Guide

**Version:** 1.0  
**Last Updated:** 2026-06-26  
**Target Audience:** IT Operations, Infrastructure Teams, Security Teams

---

## Table of Contents

1. [Pre-Deployment Planning](#pre-deployment-planning)
2. [Installation](#installation)
3. [Pilot Deployment](#pilot-deployment)
4. [Production Rollout](#production-rollout)
5. [Multi-System Deployment](#multi-system-deployment)
6. [Monitoring & Verification](#monitoring--verification)
7. [Rollback Procedures](#rollback-procedures)
8. [Deployment Checklist](#deployment-checklist)

---

## Pre-Deployment Planning

### 1. Assess Current Environment

**Gather information about your systems:**

```powershell
# Run discovery scan on target systems
$discovery = @()
Get-ADComputer -Filter * | ForEach-Object {
    $comp = $_
    Invoke-Command -ComputerName $comp.Name -ScriptBlock {
        [PSCustomObject]@{
            ComputerName = $env:COMPUTERNAME
            OSVersion = [Environment]::OSVersion.VersionString
            PowerShellVersion = $PSVersionTable.PSVersion.Major
            IsAdmin = ([Security.Principal.WindowsIdentity]::GetCurrent()).Owner
            RAM_GB = (Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1GB
            CPU_Cores = (Get-WmiObject Win32_ComputerSystem).NumberOfLogicalProcessors
        }
    } | ForEach-Object { $discovery += $_ }
}

# Export for analysis
$discovery | Export-Csv -Path "environment_inventory.csv" -NoTypeInformation
```

**Key metrics to assess:**
- OS versions (Windows Server 2016+ or Windows 10/11)
- PowerShell versions (5.1+ required)
- Network connectivity for remote deployment
- Backup/recovery procedures in place
- Change management requirements

### 2. Select Hardening Profile

Choose profile based on risk tolerance and requirements:

| Factor | Basis | Recommended | Strict |
|--------|-------|-------------|--------|
| **Compliance Level** | Basic | Medium | High |
| **User Impact** | Minimal | Moderate | High |
| **Deployment Time** | 30 sec | 45 sec | 2 min |
| **Rollback Complexity** | Low | Medium | High |
| **Best For** | Legacy systems | Standard prod | High-security |

**Decision Matrix:**

```
If compliance required?
  -> Yes, Strict HIPAA/PCI-DSS? Use Strict
  -> Yes, SOC2/ISO27001? Use Recommended
  -> No, legacy system? Use Basis
```

### 3. Define Rollout Strategy

**Phased Approach (Recommended):**

```
Week 1:  Pilot (5 systems, Basis profile)
Week 2:  Pilot validation + monitoring
Week 3:  Expand to 10% of production (Basis -> Recommended)
Week 4:  Expand to 50% of production
Week 5:  Full production rollout
Week 6+: Monitoring, optimization, Strict profile (if needed)
```

### 4. Communication Plan

**Notify stakeholders:**
- Security team
- Operations team
- Compliance/audit team
- Application owners (for Strict profile)

**Message:**
> We are implementing WinHarden security hardening to improve our security posture. Pilot deployment begins [DATE]. No user-facing changes expected for Basis profile.

---

## Installation

### Step 1: Obtain WinHarden

**Option A: From GitHub**
```powershell
git clone https://github.com/your-org/WinHarden.git C:\Program Files\WinHarden
cd C:\Program Files\WinHarden
```

**Option B: From Package**
```powershell
Expand-Archive -Path WinHarden-v1.0.zip -DestinationPath "C:\Program Files\WinHarden" -Force
cd C:\Program Files\WinHarden
```

### Step 2: Verify Installation

```powershell
# Check directory structure
Test-Path ".\functions\"    # Should be True
Test-Path ".\modules\"      # Should be True
Test-Path ".\scripts\"      # Should be True
Test-Path ".\build.ps1"     # Should be True

# Run build validation
.\build.ps1 -Validate

# Expected: "Build validation passed"
```

### Step 3: Configure Logging

```powershell
# Create logs directory
New-Item -ItemType Directory -Path ".\logs" -Force

# Set log level environment variable
[Environment]::SetEnvironmentVariable("LOG_LEVEL", "Info", "User")
$env:LOG_LEVEL = "Info"
```

### Step 4: Test Module Import

```powershell
# Test Core module
Import-Module .\modules\Core.psm1
Get-Command Write-Log                  # Should work
Get-Command Get-HardeningProfile       # Should fail (System module not loaded)

# Test System module
Import-Module .\modules\System.psm1
Get-Command Get-HardeningProfile       # Now works
```

---

## Pilot Deployment

### Phase 1: Single System Test (1-2 hours)

**Choose 1 test system (non-critical, desktop preferred):**

```powershell
# Step 1: Create baseline backup
Checkpoint-Computer -Description "Pre-WinHarden-Pilot" -RestorePointType "MODIFY_SETTINGS"

# Step 2: Run WhatIf to preview changes
Import-Module .\modules\Core.psm1
Import-Module .\modules\System.psm1

$session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11

Invoke-SecurityHardening -Session $session -WhatIf
# Review output carefully – note any unexpected changes

# Step 3: Apply hardening
$result = Invoke-SecurityHardening -Session $session

# Review results
$result | Select-Object Profile, RulesApplied, RulesFailed, CompliancePercentage

# Step 4: Verify system stability
# - Reboot system
# - Test network connectivity
# - Test key applications
# - Check Event Viewer for errors

Restart-Computer

# After reboot:
# Test connectivity, open key apps, verify no unexpected behavior
```

### Phase 2: Expanded Pilot (3-5 systems, 1 week)

**Expand to small group of similar systems:**

```powershell
# Create deployment script
$servers = @('PILOT-01', 'PILOT-02', 'PILOT-03', 'PILOT-04', 'PILOT-05')

foreach ($server in $servers) {
    Write-Host "Deploying to $server..."
    
    Invoke-Command -ComputerName $server -ScriptBlock {
        # Import modules
        Import-Module C:\Program Files\WinHarden\modules\Core.psm1
        Import-Module C:\Program Files\WinHarden\modules\System.psm1
        
        # Create session
        $session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11
        
        # Apply hardening
        $result = Invoke-SecurityHardening -Session $session
        
        # Verify
        $compliance = Test-HardeningCompliance -Session $session
        
        # Return results
        [PSCustomObject]@{
            ComputerName = $env:COMPUTERNAME
            RulesApplied = $result.RulesApplied
            Compliance = $compliance.CompliancePercentage
            Status = if ($compliance.CompliancePercentage -eq 100) { 'SUCCESS' } else { 'FAILED' }
        }
    }
}
```

### Phase 3: Pilot Validation

**Monitoring for 1 week:**

```powershell
# Create daily monitoring script
$session = New-HardeningSession -Profile Basis -TargetSystem Client

Invoke-Command -ComputerName PILOT-01 -ScriptBlock {
    $compliance = Test-HardeningCompliance -Session $using:session
    
    [PSCustomObject]@{
        ComputerName = $env:COMPUTERNAME
        CompliancePercentage = $compliance.CompliancePercentage
        CheckDate = Get-Date
        Status = if ($compliance.CompliancePercentage -eq 100) { 'COMPLIANT' } else { 'DRIFT' }
    }
}
```

**Acceptance Criteria:**
- All pilot systems reach 100% compliance
- No unexpected application failures reported
- No security alerts related to hardening
- System performance acceptable
- Users report no impact

**Decision Point:**
- If ALL criteria met → Proceed to production rollout
- If issues found → Debug, fix, re-test before continuing

---

## Production Rollout

### Week 1-2: Staging (10% of systems)

```powershell
# Calculate 10% of environment
$allServers = Get-ADComputer -Filter "OperatingSystem -like '*Server*'" | Select-Object -ExpandProperty Name
$stagingServers = $allServers | Get-Random -Count ([Math]::Ceiling($allServers.Count * 0.1))

# Deploy to staging
foreach ($server in $stagingServers) {
    $session = New-HardeningSession -Profile Recommended -TargetSystem Server
    Invoke-RemoteHardening -Session $session -ComputerName $server
}

# Verify
foreach ($server in $stagingServers) {
    $compliance = Invoke-Command -ComputerName $server -ScriptBlock {
        $session = New-HardeningSession -Profile Recommended -TargetSystem Server
        Test-HardeningCompliance -Session $session
    }
    
    Write-Host "$server : $($compliance.CompliancePercentage)% compliant"
}
```

### Week 3: Expand (50% of systems)

```powershell
# Deploy to additional 40% of systems
$deployServers = $allServers | Where-Object { $stagingServers -notcontains $_ } | Get-Random -Count ([Math]::Ceiling($allServers.Count * 0.4))

# Batch deployment (5 systems in parallel)
$deployServers | ForEach-Object -Parallel {
    $server = $_
    $session = New-HardeningSession -Profile Recommended -TargetSystem Server
    Invoke-RemoteHardening -Session $session -ComputerName $server
} -ThrottleLimit 5
```

### Week 4+: Full Production Rollout (remaining systems)

```powershell
# Final rollout to all remaining systems
$remainingServers = $allServers | Where-Object { $stagingServers -notcontains $_ -and $deployServers -notcontains $_ }

# Large-scale parallel deployment
$remainingServers | ForEach-Object -Parallel {
    $server = $_
    
    try {
        $session = New-HardeningSession -Profile Recommended -TargetSystem Server
        $result = Invoke-RemoteHardening -Session $session -ComputerName $server
        
        @{
            ComputerName = $server
            Status = 'SUCCESS'
            RulesApplied = $result.RulesApplied
        }
    } catch {
        @{
            ComputerName = $server
            Status = 'FAILED'
            Error = $_.Exception.Message
        }
    }
} -ThrottleLimit 10 | Export-Csv -Path "deployment_results.csv"
```

---

## Multi-System Deployment

### Remote Deployment via WinRM

**Prerequisites:**
- WinRM enabled on target systems
- Network connectivity to target systems
- Administrator credentials/permissions

```powershell
# Enable WinRM on target systems (if not already enabled)
Enable-PSRemoting -Force

# Create sessions to multiple systems
$sessions = New-PSSession -ComputerName SERVER01, SERVER02, SERVER03

# Deploy WinHarden
Invoke-Command -Session $sessions -ScriptBlock {
    # Copy WinHarden to target
    Copy-Item -Path "C:\Program Files\WinHarden" -Destination "C:\Program Files\" -Recurse -Force
    
    # Import modules
    Import-Module C:\Program Files\WinHarden\modules\Core.psm1
    Import-Module C:\Program Files\WinHarden\modules\System.psm1
    
    # Create and apply hardening
    $session = New-HardeningSession -Profile Recommended -TargetSystem Server
    Invoke-SecurityHardening -Session $session
}

# Cleanup
Remove-PSSession -Session $sessions
```

### Group Policy Deployment

**Deploy via GPO for enterprise-wide coverage:**

1. Create GPO with WinHarden deployment
2. Link to OUs containing target systems
3. Monitor compliance via Group Policy Results

```powershell
# Create GPO startup script
New-GPO -Name "WinHarden-Deployment"

# Configure startup script
Set-GPRegistryValue -Name "WinHarden-Deployment" `
    -Key "HKLM\Software\Microsoft\Windows\CurrentVersion\Group Policy\State\Machine\Scripts\Startup" `
    -ValueName "0" `
    -Value "C:\Windows\System32\WinHarden\Deploy.ps1" `
    -Type String
```

### Configuration Management (DSC/Ansible)

**Integrate with existing CM tools:**

**PowerShell DSC:**
```powershell
Configuration WinHardenDeploy {
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    
    Node "localhost" {
        Script ApplyHardening {
            SetScript = {
                Import-Module C:\Program Files\WinHarden\modules\Core.psm1
                Import-Module C:\Program Files\WinHarden\modules\System.psm1
                
                $session = New-HardeningSession -Profile Recommended -TargetSystem Client
                Invoke-SecurityHardening -Session $session
            }
            TestScript = {
                $session = New-HardeningSession -Profile Recommended -TargetSystem Client
                $compliance = Test-HardeningCompliance -Session $session
                return ($compliance.CompliancePercentage -eq 100)
            }
            GetScript = {
                $session = New-HardeningSession -Profile Recommended -TargetSystem Client
                $compliance = Test-HardeningCompliance -Session $session
                return @{
                    Result = $compliance.CompliancePercentage
                }
            }
        }
    }
}
```

---

## Monitoring & Verification

### Daily Compliance Monitoring

```powershell
# Create scheduled task for daily verification
$scriptPath = "C:\Scripts\DailyHardeningCheck.ps1"

# Script content:
# Import-Module C:\Program Files\WinHarden\modules\Core.psm1
# Import-Module C:\Program Files\WinHarden\modules\System.psm1
# $session = New-HardeningSession -Profile Recommended -TargetSystem Server
# $compliance = Test-HardeningCompliance -Session $session
# $compliance | Export-Csv -Path "C:\Logs\compliance_$(Get-Date -Format yyyyMMdd).csv" -NoTypeInformation

$trigger = New-ScheduledTaskTrigger -Daily -At 2:00am
$action = New-ScheduledTaskAction -Execute PowerShell.exe -Argument "-NoProfile -File $scriptPath"
Register-ScheduledTask -TaskName "DailyHardeningCompliance" -Trigger $trigger -Action $action -Force
```

### Compliance Dashboard

**Create visibility into hardening status:**

```powershell
# Aggregate compliance across all systems
$allSystems = Get-ADComputer -Filter * | Select-Object -ExpandProperty Name

$results = @()
foreach ($computer in $allSystems) {
    $compliance = Invoke-Command -ComputerName $computer -ScriptBlock {
        $session = New-HardeningSession -Profile Recommended -TargetSystem Server
        Test-HardeningCompliance -Session $session
    }
    
    $results += [PSCustomObject]@{
        ComputerName = $computer
        CompliancePercentage = $compliance.CompliancePercentage
        CompliantRules = $compliance.CompliantRuleCount
        NonCompliantRules = $compliance.NonCompliantRuleCount
        CheckDate = Get-Date
    }
}

# Export for dashboard/BI tool
$results | Export-Csv -Path "compliance_dashboard.csv" -NoTypeInformation

# Summary
Write-Host "Average Compliance: $($results | Measure-Object -Property CompliancePercentage -Average).Average%"
Write-Host "Systems at 100%: $($results | Where-Object CompliancePercentage -eq 100 | Measure-Object | Select-Object -ExpandProperty Count)"
Write-Host "Systems with drift: $($results | Where-Object CompliancePercentage -lt 100 | Measure-Object | Select-Object -ExpandProperty Count)"
```

### Alert on Drift

```powershell
# Monitor for compliance drift and alert
$alertThreshold = 95  # Alert if compliance drops below 95%

$nonCompliant = $results | Where-Object { $_.CompliancePercentage -lt $alertThreshold }

if ($nonCompliant) {
    # Send alert
    $emailBody = "Compliance drift detected on the following systems:`n`n"
    $nonCompliant | ForEach-Object {
        $emailBody += "$($_.ComputerName): $($_.CompliancePercentage)%`n"
    }
    
    Send-MailMessage -To "security-team@company.com" `
        -Subject "WinHarden: Compliance Drift Alert" `
        -Body $emailBody `
        -SmtpServer "smtp.company.com"
}
```

---

## Rollback Procedures

### Immediate Rollback (within hours)

**Restore from system checkpoint:**

```powershell
# Restore to pre-hardening checkpoint
Get-ComputerRestorePoint | Where-Object Description -eq "Pre-WinHarden-Pilot" | Restore-ComputerRestorePoint -Confirm:$false

# Reboot to apply
Restart-Computer
```

### Partial Rollback (specific rules)

**Revert only problematic rules:**

```powershell
# Identify non-compliant rules
$session = New-HardeningSession -Profile Recommended -TargetSystem Client
$compliance = Test-HardeningCompliance -Session $session -Detailed

# List rules causing issues
$problematicRules = $compliance.RuleResults | Where-Object { $_.Compliant -eq $false -and $_.Severity -eq 'HIGH' }

# Remove only those rules
# (WinHarden provides rule-specific revert functions)
$problematicRules | ForEach-Object {
    Invoke-RemoteCommand -FunctionName "Revert-HardeningRule-$($_.RuleName)"
}
```

### Full System Rollback (if needed)

**Complete removal of hardening:**

```powershell
# 1. Stop scheduled hardening tasks
Unregister-ScheduledTask -TaskName "DailyHardeningCompliance" -Confirm:$false
Unregister-ScheduledTask -TaskName "WinHarden-*" -Confirm:$false

# 2. Remove WinHarden
Remove-Item -Path "C:\Program Files\WinHarden" -Recurse -Force

# 3. Reset system to baseline (or restore from backup)
# Use Windows Server backup or VM snapshot

# 4. Document rollback for compliance
Write-Log -Message "WinHarden completely removed from system" -Level Warning
```

---

## Deployment Checklist

### Pre-Deployment

- [ ] Security team approval obtained
- [ ] Change management ticket created
- [ ] Backup/restore procedures tested
- [ ] Communication sent to stakeholders
- [ ] Pilot systems identified and approved
- [ ] Hardening profile selected (Basis/Recommended/Strict)
- [ ] WinHarden version obtained and verified
- [ ] Network connectivity confirmed for remote deployment
- [ ] Administrator credentials secured and tested

### Pilot Phase

- [ ] Baseline backup created on pilot systems
- [ ] WinHarden installed and validated
- [ ] WhatIf mode run and reviewed
- [ ] Hardening applied to 1 system
- [ ] System stability verified (connectivity, apps, performance)
- [ ] Compliance verification passed (100%)
- [ ] 1-week monitoring completed without issues
- [ ] Expanded pilot to 5 systems completed
- [ ] Approval received to proceed with production

### Staging Deployment

- [ ] 10% of systems deployed and monitored
- [ ] Compliance maintained at 100%
- [ ] No application compatibility issues reported
- [ ] Performance baseline established
- [ ] Approval received to proceed to 50% rollout

### Full Production

- [ ] Maintenance window scheduled
- [ ] Parallel deployment of remaining systems
- [ ] Real-time monitoring enabled
- [ ] Alert thresholds configured
- [ ] Daily compliance checks running
- [ ] Compliance dashboard operational
- [ ] Post-deployment review completed
- [ ] Documentation updated

### Post-Deployment

- [ ] Compliance maintained at 95%+ across all systems
- [ ] Security incidents resolved (if any)
- [ ] Performance impact assessment completed
- [ ] Final compliance report generated
- [ ] Deployment lessons learned documented
- [ ] Ongoing monitoring procedures established
- [ ] Optional: Transition to Strict profile (if required)

---

**End of Deployment Guide**

For support during deployment, consult the Troubleshooting section in the User Guide or contact your system administrator.
