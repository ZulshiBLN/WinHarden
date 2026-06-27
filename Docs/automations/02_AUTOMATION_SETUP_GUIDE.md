# WinHarden Automations - Setup Guide

**Complete reference for configuring, deploying, and managing WinHarden automation tasks.**

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Environment Setup](#environment-setup)
3. [Task Configuration Details](#task-configuration-details)
4. [Deployment Methods](#deployment-methods)
5. [Post-Deployment Verification](#post-deployment-verification)
6. [Monitoring & Maintenance](#monitoring--maintenance)
7. [Advanced Configuration](#advanced-configuration)
8. [Troubleshooting](#troubleshooting)
9. [Performance Tuning](#performance-tuning)

---

## Architecture Overview

### System Design

The WinHarden automation framework consists of:

1. **Scheduler Component** - Windows Task Scheduler (native)
2. **Execution Layer** - PowerShell 5.1+ scripts
3. **Storage Layer** - CSV/JSON reports in `logs/` directory
4. **Archive Layer** - ZIP compression for historical data

### Data Flow

```
[Scheduled Trigger]
        |
        v
[PowerShell Script Execution]
        |
        v
[Data Collection]
        |
        v
[Report Generation] --> CSV/JSON files
        |
        v
[Log Archive (monthly)] --> ZIP files
```

### Task Dependency Graph

No hard dependencies between tasks (all run independently). However, logical sequence:

```
Daily-Security-Monitor     (monitor every day)
Monitor-Windows-Updates    (check weekly)
Detect-Configuration-Drift (verify weekly)
    |
    v
Monthly-Compliance-Audit   (comprehensive monthly check)
    |
    v
Archive-Old-Reports        (cleanup & archive)
```

### Task Execution Matrix

| Task | Type | Frequency | User | Catchup | Duration | Logs |
|------|------|-----------|------|---------|----------|------|
| Daily-Security-Monitor | Monitoring | Daily | SYSTEM | Yes | 5-10 min | daily_security_*.csv |
| Monitor-Windows-Updates | Monitoring | Weekly | SYSTEM | Yes | 1-2 min | updates_*.csv |
| Detect-Configuration-Drift | Compliance | Weekly | SYSTEM | Yes | 3-5 min | drift_*.csv |
| Monthly-Compliance-Audit | Compliance | Monthly | SYSTEM | Yes | 10-15 min | audit_*.csv |
| Archive-Old-Reports | Maintenance | Monthly | SYSTEM | Yes | 2-3 min | archive/*.zip |

---

## Environment Setup

### Pre-Deployment Checklist

Before running the setup script, verify:

- [ ] Administrator privileges available
- [ ] PowerShell 5.1+ installed
- [ ] WinHarden repository exists at `C:\Repos\WinHarden`
- [ ] Network connectivity for update checks
- [ ] Logs directory writable: `C:\Repos\WinHarden\logs\`
- [ ] Event Viewer access available
- [ ] Task Scheduler service running

### System Requirements

| Component | Minimum | Recommended | Notes |
|-----------|---------|-------------|-------|
| OS | Windows Server 2016 | Windows Server 2019+ | Windows 11 Pro also supported |
| PowerShell | 5.1 | 5.1 or 7.x | 5.1 required (no Core) |
| Memory | 512 MB | 2 GB | Per-task resource usage varies |
| Disk Space | 500 MB | 2 GB | For logs & archives (scalable) |
| Network | Optional | Required | For Windows Update checks |

### Verify Prerequisites

```powershell
# 1. Check PowerShell version
$PSVersionTable.PSVersion
# Expected: Major=5, Minor=1 or higher

# 2. Verify repository structure
$repoPath = "C:\Repos\WinHarden"
Test-Path "$repoPath\scripts\Set-ScheduledTasksHardening.ps1"
Test-Path "$repoPath\logs"
Test-Path "$repoPath\docs"

# 3. Check administrator privileges
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
Write-Host "Administrator mode: $(if($isAdmin) { 'YES' } else { 'NO - RESTART AS ADMIN' })"

# 4. Verify all automation scripts exist
$scripts = @(
    "Set-ScheduledTasksHardening.ps1",
    "Monitor_Audit_Logs.ps1",
    "Monitor_Windows_Updates.ps1",
    "Detect_Security_Drift.ps1",
    "Monthly_Compliance_Audit.ps1",
    "Archive_Old_Reports.ps1"
)

foreach ($script in $scripts) {
    $path = "$repoPath\scripts\$script"
    $status = if (Test-Path $path) { "[OK]" } else { "[MISSING]" }
    Write-Host "$script $status"
}

# 5. Verify logs directory permissions
$logsPath = "$repoPath\logs"
$testFile = "$logsPath\test_write_$(Get-Random).txt"
$canWrite = $true
try {
    "test" | Out-File -FilePath $testFile -ErrorAction Stop
    Remove-Item $testFile
} catch {
    $canWrite = $false
}
Write-Host "Logs directory writable: $(if($canWrite) { '[OK]' } else { '[ERROR]' })"

# 6. Verify Task Scheduler is running
$taskService = Get-Service -Name Schedule -ErrorAction SilentlyContinue
Write-Host "Task Scheduler running: $(if($taskService.Status -eq 'Running') { '[OK]' } else { '[ERROR]' })"
```

---

## Task Configuration Details

### Task 1: Daily-Security-Monitor

**Purpose:** Real-time detection of security threats from Windows Event Log

**Configuration:**
```powershell
Task Name:     Daily-Security-Monitor
Script:        Monitor_Audit_Logs.ps1
Schedule:      DAILY at 09:00 AM
User:          SYSTEM
Enabled:       True
Catchup:       Enabled
Run Duration:  5-10 minutes
Output:        daily_security_YYYYMMDD_HHMMSS.csv
```

**What it detects:**
- Failed login attempts (brute force patterns)
- Suspicious service startups
- Unauthorized file access
- Security policy violations
- Privilege escalation attempts

**Sample Output:**
```
EventID,TimeGenerated,Source,Category,Severity
4625,2026-06-27T09:15:32Z,AuthServer,FailedLogin,High
5140,2026-06-27T09:16:15Z,FileShare,UnauthorizedAccess,High
```

**Configuration options:**
```powershell
# Run manually with verbose output
powershell.exe -File C:\Repos\WinHarden\scripts\Monitor_Audit_Logs.ps1 -Verbose

# Modify schedule (optional)
schtasks /change /tn "Hardening\Daily-Security-Monitor" /st 08:00
```

---

### Task 2: Monitor-Windows-Updates

**Purpose:** Weekly scan for available Windows security patches

**Configuration:**
```powershell
Task Name:     Monitor-Windows-Updates
Script:        Monitor_Windows_Updates.ps1
Schedule:      WEEKLY (Monday) at 08:00 AM
User:          SYSTEM
Enabled:       True
Catchup:       Enabled
Run Duration:  1-2 minutes
Output:        updates_YYYYMMDD_HHMMSS.csv
```

**What it checks:**
- Available critical updates
- Available security updates
- Available regular updates
- Windows Defender definition updates
- Patch Tuesday releases

**Sample Output:**
```
UpdateID,Title,Category,Severity,InstalledDate,Status
KB5032190,Security Update,Security,Critical,,Available
KB5032189,Security Update,Security,High,,Available
```

**Configuration options:**
```powershell
# Check updates manually
powershell.exe -File C:\Repos\WinHarden\scripts\Monitor_Windows_Updates.ps1

# Change schedule to weekly Friday
schtasks /change /tn "Hardening\Monitor-Windows-Updates" /d FR /st 14:00
```

---

### Task 3: Detect-Configuration-Drift

**Purpose:** Weekly scan for unauthorized configuration changes

**Configuration:**
```powershell
Task Name:     Detect-Configuration-Drift
Script:        Detect_Security_Drift.ps1
Schedule:      WEEKLY (Monday) at 10:00 AM
User:          SYSTEM
Enabled:       True
Catchup:       Enabled
Run Duration:  3-5 minutes
Output:        drift_YYYYMMDD_HHMMSS.csv
```

**What it verifies:**
- Windows Defender status (enabled/disabled)
- Firewall rules (enabled/disabled/policy changes)
- User Account Control (UAC) settings
- Windows Update settings
- BitLocker encryption status
- Audit policy settings

**Sample Output:**
```
Setting,Current,Expected,Status,Severity
WinDefender,Enabled,Enabled,[OK],None
Firewall,Enabled,Enabled,[OK],None
UAC,Prompt,Prompt,[OK],None
BitLocker,Encrypted,Encrypted,[OK],None
```

**Configuration options:**
```powershell
# Test drift detection manually
powershell.exe -File C:\Repos\WinHarden\scripts\Detect_Security_Drift.ps1 -Verbose

# Schedule twice weekly (Monday & Thursday)
# Note: Requires manual dual-task setup - see Advanced Configuration
```

---

### Task 4: Monthly-Compliance-Audit

**Purpose:** Comprehensive monthly hardening compliance verification

**Configuration:**
```powershell
Task Name:     Monthly-Compliance-Audit
Script:        Monthly_Compliance_Audit.ps1
Schedule:      MONTHLY (1st day) at 08:00 AM
User:          SYSTEM
Enabled:       True
Catchup:       Enabled
Run Duration:  10-15 minutes
Output:        audit_YYYYMMDD_HHMMSS.csv
```

**What it audits:**
- All hardening baselines
- Account lockout policies
- Password policies
- Privilege escalation rules
- Service hardening
- Network hardening
- Compliance against CIS benchmarks

**Sample Output:**
```
Category,Control,Status,FindingCount,Severity
Accounts,LockoutPolicy,[OK],0,None
Password,Complexity,[OK],0,None
Services,AutoStart,[WARNING],2,Medium
Firewall,Rules,[OK],0,None
```

**Generates:**
- Compliance score (percentage)
- Executive summary
- Detailed findings
- Remediation steps

---

### Task 5: Archive-Old-Reports

**Purpose:** Monthly archival and cleanup of historical reports

**Configuration:**
```powershell
Task Name:     Archive-Old-Reports
Script:        Archive_Old_Reports.ps1
Schedule:      MONTHLY (2nd day) at 09:00 AM
User:          SYSTEM
Enabled:       True
Catchup:       Enabled
Run Duration:  2-3 minutes
Output:        archive/reports_YYYYMM.zip
```

**What it does:**
- Identifies reports older than 6 months
- Compresses into ZIP files
- Moves to `logs/archive/` directory
- Cleans up original log files
- Maintains directory structure

**Archive organization:**
```
C:\Repos\WinHarden\logs\archive\
  reports_202301.zip (January 2023 reports)
  reports_202302.zip (February 2023 reports)
  reports_202303.zip (March 2023 reports)
  ...
```

**Configuration options:**
```powershell
# Change retention period (6 months to 12 months)
# Requires editing script - see Advanced Configuration

# Run archival manually
powershell.exe -File C:\Repos\WinHarden\scripts\Archive_Old_Reports.ps1
```

---

## Deployment Methods

### Method 1: Automated Deployment (Recommended)

```powershell
# Step 1: Open PowerShell as Administrator
# Win + X -> PowerShell (Admin)

# Step 2: Navigate to scripts directory
cd C:\Repos\WinHarden\scripts

# Step 3: Run setup script
.\Set-ScheduledTasksHardening.ps1

# Expected: All 5 tasks created with [OK] status
```

### Method 2: Force Overwrite (Replace existing)

```powershell
# Overwrites tasks if they already exist
.\Set-ScheduledTasksHardening.ps1 -Force

# Useful when:
# - Updating task definitions
# - Fixing corrupted tasks
# - Changing execution parameters
```

### Method 3: Clean Reinstall

```powershell
# Removes ALL existing tasks first, then installs fresh
.\Set-ScheduledTasksHardening.ps1 -Cleanup -Force

# Useful when:
# - Cleaning up broken installations
# - Starting completely fresh
# - Removing orphaned tasks
```

### Method 4: Manual Task Creation

For specific control, create tasks manually:

```powershell
# Example: Create Daily-Security-Monitor task
schtasks /create `
  /tn "Hardening\Daily-Security-Monitor" `
  /tr "powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\Repos\WinHarden\scripts\Monitor_Audit_Logs.ps1" `
  /sc DAILY `
  /st 09:00 `
  /ru SYSTEM `
  /z `
  /f

# Parameters explained:
# /tn = Task name (with path)
# /tr = Task to run (script path)
# /sc = Schedule type (DAILY, WEEKLY, MONTHLY)
# /st = Start time (HH:MM)
# /ru = Run as user (SYSTEM for full privileges)
# /z  = Enable catchup
# /f  = Force creation (overwrite if exists)
```

---

## Post-Deployment Verification

### Immediate Verification

```powershell
# 1. Check all tasks are created
Get-ScheduledTask -TaskPath '\Hardening\*' | 
    Format-Table TaskName, State, Enabled -AutoSize

# Expected output:
# TaskName                     State   Enabled
# --------                     -----   -------
# Daily-Security-Monitor       Ready   True
# Monitor-Windows-Updates      Ready   True
# Detect-Configuration-Drift   Ready   True
# Monthly-Compliance-Audit     Ready   True
# Archive-Old-Reports          Ready   True

# 2. Verify task paths
Get-ScheduledTask -TaskPath '\Hardening\*' | 
    Select-Object TaskName, @{N='ScriptPath'; E={$_.Actions.Arguments}} |
    Format-Table -AutoSize

# 3. Verify execution users
Get-ScheduledTask -TaskPath '\Hardening\*' | 
    ForEach-Object {
        $info = $_ | Get-ScheduledTaskInfo
        [PSCustomObject]@{
            TaskName = $_.TaskName
            RunAs = (Get-ScheduledTaskInfo -TaskName $_.TaskName).RunAsUser
            Enabled = $_.Enabled
        }
    } | Format-Table
```

### Test Task Execution

```powershell
# 1. Run a task manually
schtasks /run /tn "Hardening\Daily-Security-Monitor"

# 2. Wait for completion
Start-Sleep -Seconds 10

# 3. Check output logs
ls C:\Repos\WinHarden\logs\daily_security_*.csv | 
    Select-Object Name, LastWriteTime | 
    Format-Table -AutoSize

# 4. Verify task ran without error
Get-ScheduledTask -TaskName "Daily-Security-Monitor" | 
    Get-ScheduledTaskInfo | 
    Select-Object TaskName, LastRunTime, LastTaskResult

# Expected: LastTaskResult should be 0 (success)
```

### Verify Triggers and Schedule

```powershell
# Check detailed trigger configuration
$task = Get-ScheduledTask -TaskName "Daily-Security-Monitor"
$task | Get-ScheduledTaskInfo | Format-List

# Check trigger details
$task.Triggers | Format-List

# Expected output includes:
# StartBoundary : 2026-06-27T09:00:00
# Enabled       : True
```

---

## Monitoring & Maintenance

### Daily Monitoring Tasks

```powershell
# Check for failed tasks
Get-EventLog -LogName System -Source "TaskScheduler" -Newest 20 | 
    Where-Object { $_.Message -like '*failed*' } | 
    Format-Table TimeGenerated, Message -AutoSize

# Check task status
Get-ScheduledTask -TaskPath '\Hardening\*' | 
    ForEach-Object {
        $info = $_ | Get-ScheduledTaskInfo
        Write-Host "$($_.TaskName): Last=$($info.LastRunTime) Result=$($info.LastTaskResult)"
    }

# Review latest logs
ls C:\Repos\WinHarden\logs\ -Filter *.csv | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object Name, LastWriteTime -First 5
```

### Weekly Maintenance

```powershell
# 1. Verify all tasks ran on schedule
Get-ScheduledTask -TaskPath '\Hardening\*' | 
    Get-ScheduledTaskInfo | 
    Select-Object TaskName, LastRunTime | 
    Format-Table

# 2. Check for missed runs
Get-ScheduledTask -TaskPath '\Hardening\*' | 
    Get-ScheduledTaskInfo | 
    Where-Object { $_.NumberOfMissedRuns -gt 0 } | 
    Select-Object TaskName, NumberOfMissedRuns

# 3. Review error count in logs
Get-EventLog -LogName System -Source "TaskScheduler" -After (Get-Date).AddDays(-7) | 
    Measure-Object | 
    Select-Object Count

# 4. Check disk usage
$logsSize = (Get-ChildItem C:\Repos\WinHarden\logs\ -Recurse | 
    Measure-Object -Property Length -Sum).Sum / 1MB
Write-Host "Logs directory size: $([Math]::Round($logsSize, 2)) MB"
```

### Monthly Review

```powershell
# 1. Generate compliance summary
ls C:\Repos\WinHarden\logs\audit_*.csv | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object Name, LastWriteTime -First 1

# 2. Check drift reports
ls C:\Repos\WinHarden\logs\drift_*.csv | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object Name, LastWriteTime -First 1

# 3. Verify archive completion
ls C:\Repos\WinHarden\logs\archive\*.zip | 
    Select-Object Name, Length -First 5

# 4. Calculate total reports generated
$reportCount = @(
    (ls C:\Repos\WinHarden\logs\daily_security_*.csv | Measure-Object).Count,
    (ls C:\Repos\WinHarden\logs\updates_*.csv | Measure-Object).Count,
    (ls C:\Repos\WinHarden\logs\drift_*.csv | Measure-Object).Count,
    (ls C:\Repos\WinHarden\logs\audit_*.csv | Measure-Object).Count
)
Write-Host "Total reports generated: $($reportCount | Measure-Object -Sum | Select -Expand Sum)"
```

---

## Advanced Configuration

### Disable a Task

```powershell
# Temporarily disable a task (doesn't delete it)
Disable-ScheduledTask -TaskName "Archive-Old-Reports"

# Re-enable a disabled task
Enable-ScheduledTask -TaskName "Archive-Old-Reports"

# Verify status
Get-ScheduledTask -TaskName "Archive-Old-Reports" | Select-Object Enabled
```

### Change Task Schedule

```powershell
# Change execution time
schtasks /change /tn "Hardening\Daily-Security-Monitor" /st 08:00

# Change day of week (for weekly tasks)
schtasks /change /tn "Hardening\Monitor-Windows-Updates" /d MO

# Change day of month (for monthly tasks)
schtasks /change /tn "Hardening\Monthly-Compliance-Audit" /d 15

# Change to multiple days (Monday and Thursday)
schtasks /change /tn "Hardening\Detect-Configuration-Drift" /d MO,TH
```

### Create Duplicate Task with Different Schedule

```powershell
# Create a second instance of Daily-Security-Monitor running at midnight
schtasks /create `
  /tn "Hardening\Daily-Security-Monitor-Midnight" `
  /tr "powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\Repos\WinHarden\scripts\Monitor_Audit_Logs.ps1" `
  /sc DAILY `
  /st 00:00 `
  /ru SYSTEM `
  /z `
  /f

# Now you have 2 instances: 09:00 AM and 00:00 AM
```

### Modify Task Parameters

```powershell
# Get current task action (script + parameters)
$task = Get-ScheduledTask -TaskName "Daily-Security-Monitor"
$task.Actions | Select-Object *

# To modify, export task, edit XML, re-import
# (Advanced - see Task Scheduler documentation)
```

---

## Troubleshooting

### Issue: Tasks not executing

**Symptoms:** Task shows in schedule but never runs

**Diagnosis:**
```powershell
# 1. Check if task is enabled
Get-ScheduledTask -TaskName "Daily-Security-Monitor" | 
    Select-Object Enabled

# 2. Check last run result
Get-ScheduledTask -TaskName "Daily-Security-Monitor" | 
    Get-ScheduledTaskInfo | 
    Select-Object LastRunTime, LastTaskResult

# 3. Check event log for errors
Get-EventLog -LogName System -Source "TaskScheduler" -Newest 20 | 
    Where-Object { $_.Message -like '*Daily-Security-Monitor*' }

# 4. Test script manually
powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\Repos\WinHarden\scripts\Monitor_Audit_Logs.ps1 -Verbose
```

**Solutions:**
```powershell
# Enable task
Enable-ScheduledTask -TaskName "Daily-Security-Monitor"

# Restart Task Scheduler service
Restart-Service -Name Schedule -Force

# Recreate task
Get-ScheduledTask -TaskName "Daily-Security-Monitor" | 
    Unregister-ScheduledTask -Confirm:$false
.\Set-ScheduledTasksHardening.ps1 -Force
```

### Issue: Scripts cannot be found

**Symptoms:** Task fails with "file not found" error

**Diagnosis:**
```powershell
# Verify script path
Test-Path C:\Repos\WinHarden\scripts\Monitor_Audit_Logs.ps1

# Check actual error message
Get-EventLog -LogName System -Source "TaskScheduler" -Newest 5 | 
    Where-Object { $_.Message -like '*cannot find*' } | 
    Select-Object Message
```

**Solutions:**
```powershell
# Verify all scripts exist
ls C:\Repos\WinHarden\scripts\*.ps1 | Select-Object Name

# If repository is in different location, recreate tasks:
# 1. Edit Set-ScheduledTasksHardening.ps1
# 2. Change $scriptsPath variable
# 3. Run .\Set-ScheduledTasksHardening.ps1 -Cleanup -Force
```

### Issue: Tasks run but generate no logs

**Symptoms:** Task shows success but no output files created

**Diagnosis:**
```powershell
# 1. Run script manually to see errors
powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\Repos\WinHarden\scripts\Monitor_Audit_Logs.ps1 -Verbose

# 2. Check logs directory permissions
icacls C:\Repos\WinHarden\logs\

# 3. Check script errors
Get-EventLog -LogName System -Source "TaskScheduler" -Newest 10 | 
    Select-Object Message | 
    Out-Host
```

**Solutions:**
```powershell
# Verify logs directory permissions
icacls C:\Repos\WinHarden\logs\ /grant:r 'SYSTEM:(F)'

# Set logs directory full permissions
$aclPath = 'C:\Repos\WinHarden\logs'
$acl = Get-Acl $aclPath
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    'SYSTEM', 'FullControl', 'ContainerInherit,ObjectInherit', 'None', 'Allow')
$acl.AddAccessRule($rule)
Set-Acl -Path $aclPath -AclObject $acl
```

### Issue: Memory or CPU usage too high

**Symptoms:** Task Scheduler processes consuming resources

**Diagnosis:**
```powershell
# Monitor task resource usage during execution
while ($true) {
    Clear-Host
    Get-Process | Where-Object { $_.Handles -gt 1000 } | 
        Select-Object Name, CPU, Memory | 
        Format-Table
    Start-Sleep -Seconds 2
}

# Check Event Viewer for resource warnings
Get-EventLog -LogName System -After (Get-Date).AddHours(-1) | 
    Where-Object { $_.Message -like '*resource*' }
```

**Solutions:**
```powershell
# Stagger task execution (spread across time)
schtasks /change /tn "Hardening\Monitor-Windows-Updates" /st 08:30
schtasks /change /tn "Hardening\Detect-Configuration-Drift" /st 10:30
schtasks /change /tn "Hardening\Monthly-Compliance-Audit" /st 12:00

# Reduce task frequency
schtasks /change /tn "Hardening\Daily-Security-Monitor" /sc WEEKLY
```

---

## Performance Tuning

### Resource Optimization

| Scenario | Optimization | Implementation |
|----------|---------------|-----------------|
| Low disk space | Reduce archive retention | Edit Archive_Old_Reports.ps1 |
| High CPU usage | Stagger task execution | Change start times |
| Memory pressure | Run off-hours | Move to 22:00-02:00 window |
| Network limited | Disable update checks | Comment out Windows Update checks |

### Schedule Optimization

**Recommended Schedule** (minimal conflicts):
```
08:00 - Monitor-Windows-Updates (weekly Monday)
09:00 - Daily-Security-Monitor (daily)
10:30 - Detect-Configuration-Drift (weekly Monday)
08:00 - Monthly-Compliance-Audit (monthly 1st)
09:00 - Archive-Old-Reports (monthly 2nd)
```

**High-Load Schedule** (better spacing):
```
22:00 - Monitor-Windows-Updates (weekly Monday)
23:00 - Daily-Security-Monitor (daily)
01:00 - Detect-Configuration-Drift (weekly Monday)
08:00 - Monthly-Compliance-Audit (monthly 1st)
09:00 - Archive-Old-Reports (monthly 2nd)
```

---

## Quick Reference

### Essential Commands

```powershell
# List all tasks
Get-ScheduledTask -TaskPath '\Hardening\*'

# Run task now
schtasks /run /tn "Hardening\Daily-Security-Monitor"

# Disable task
Disable-ScheduledTask -TaskName "Daily-Security-Monitor"

# Enable task
Enable-ScheduledTask -TaskName "Daily-Security-Monitor"

# Delete task
Get-ScheduledTask -TaskName "Daily-Security-Monitor" | 
    Unregister-ScheduledTask -Confirm:$false

# View recent logs
ls C:\Repos\WinHarden\logs\ | Sort-Object LastWriteTime -Descending
```

---

**Document Version:** 2.0  
**Last Updated:** 2026-06-27  
**Target Audience:** System Administrators, DevOps Engineers  
**Complexity Level:** Intermediate to Advanced
