# WinHarden - Automation Setup Guide

## Table of Contents

1. [Overview](#overview)
2. [Environment Setup](#environment-setup)
3. [Task Configuration](#task-configuration)
4. [Deployment Process](#deployment-process)
5. [Post-Deployment Verification](#post-deployment-verification)
6. [Monitoring & Maintenance](#monitoring--maintenance)
7. [Troubleshooting](#troubleshooting)

---

## Overview

The WinHarden automation framework deploys 5 scheduled tasks to Windows Task Scheduler that continuously monitor, audit, and maintain hardening compliance across your system.

### Task Breakdown

**Security & Monitoring Tasks:**
- **Daily-Security-Monitor** - Real-time monitoring of audit logs for threat detection
- **Monitor-Windows-Updates** - Weekly check for available security updates
- **Detect-Configuration-Drift** - Weekly scan for unauthorized configuration changes

**Compliance & Maintenance Tasks:**
- **Monthly-Compliance-Audit** - Monthly verification of hardening standards
- **Archive-Old-Reports** - Monthly cleanup and archival of old audit reports

---

## Environment Setup

### System Requirements

| Component | Requirement | Notes |
|-----------|-------------|-------|
| OS | Windows Server 2016+ or Windows 10/11 | Must support Task Scheduler |
| PowerShell | 5.1+ | Windows 7+ includes 5.1 |
| Execution Policy | RemoteSigned (minimum) | Can be set per-session |
| Permissions | Administrator | Required for Task Scheduler access |
| Disk Space | 500 MB minimum | For logs and reports |

### Pre-Deployment Checklist

- [ ] Administrator account available
- [ ] PowerShell 5.1+ installed
- [ ] WinHarden repository accessible at `C:\Repos\WinHarden`
- [ ] All automation scripts present:
  - [ ] Monthly_Compliance_Audit.ps1
  - [ ] Monitor_Audit_Logs.ps1
  - [ ] Archive_Old_Reports.ps1
  - [ ] Detect_Security_Drift.ps1
  - [ ] Monitor_Windows_Updates.ps1
- [ ] Logs directory writable: `C:\Repos\WinHarden\logs\`

### Verify Prerequisites

```powershell
# Check PowerShell version
$PSVersionTable.PSVersion

# Verify all scripts exist
$scripts = @(
    "Monthly_Compliance_Audit.ps1",
    "Monitor_Audit_Logs.ps1",
    "Archive_Old_Reports.ps1",
    "Detect_Security_Drift.ps1",
    "Monitor_Windows_Updates.ps1"
)

$scriptsPath = "C:\Repos\WinHarden\scripts"
foreach ($script in $scripts) {
    $exists = Test-Path "$scriptsPath\$script"
    Write-Host "$script - $(if($exists) { '[OK]' } else { '[MISSING]' })"
}

# Verify admin rights
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
Write-Host "Admin Rights - $(if($isAdmin) { '[OK]' } else { '[DENIED]' })"
```

---

## Task Configuration

### Configuration Details

#### 1. Daily-Security-Monitor

```powershell
Name:        Daily-Security-Monitor
Script:      Monitor_Audit_Logs.ps1
Schedule:    DAILY at 09:00 AM
User:        SYSTEM
Description: Real-time security event monitoring and threat detection
Catchup:     Enabled (/z flag)
```

**What it does:**
- Monitors Windows Security Event Log in real-time
- Detects suspicious authentication attempts
- Flags failed service startups
- Generates daily threat intelligence report

**Output:** `C:\Repos\WinHarden\logs\daily_security_*.csv`

---

#### 2. Monitor-Windows-Updates

```powershell
Name:        Monitor-Windows-Updates
Script:      Monitor_Windows_Updates.ps1
Schedule:    WEEKLY (Monday) at 08:00 AM
User:        SYSTEM
Description: Weekly check for available Windows security updates
Catchup:     Enabled (/z flag)
```

**What it does:**
- Scans for available Windows security patches
- Prioritizes critical updates
- Generates update availability report
- Recommends scheduling for monthly maintenance windows

**Output:** `C:\Repos\WinHarden\logs\updates_*.csv`

---

#### 3. Detect-Configuration-Drift

```powershell
Name:        Detect-Configuration-Drift
Script:      Detect_Security_Drift.ps1
Schedule:    WEEKLY (Monday) at 10:00 AM
User:        SYSTEM
Description: Weekly scan for unauthorized changes to hardening settings
Catchup:     Enabled (/z flag)
```

**What it does:**
- Compares current settings against hardening baseline
- Detects unauthorized registry changes
- Identifies disabled security features
- Flags policy deviations
- Generates drift report with remediation steps

**Output:** `C:\Repos\WinHarden\logs\drift_*.csv`

---

#### 4. Monthly-Compliance-Audit

```powershell
Name:        Monthly-Compliance-Audit
Script:      Monthly_Compliance_Audit.ps1
Schedule:    MONTHLY (1st day) at 08:00 AM
User:        SYSTEM
Description: Monthly hardening compliance verification and audit
Catchup:     Enabled (/z flag)
```

**What it does:**
- Full compliance check against baseline
- Tests all hardening controls
- Generates executive summary
- Documents any gaps or issues
- Creates audit trail for compliance purposes

**Output:** `C:\Repos\WinHarden\logs\audit_*.csv`

---

#### 5. Archive-Old-Reports

```powershell
Name:        Archive-Old-Reports
Script:      Archive_Old_Reports.ps1
Schedule:    MONTHLY (2nd day) at 09:00 AM
User:        SYSTEM
Description: Archive monthly audit reports older than 6 months to ZIP files
Catchup:     Enabled (/z flag)
```

**What it does:**
- Compresses reports older than 6 months
- Moves archives to `logs/archive/` directory
- Reduces active log directory size
- Preserves historical audit trail

**Output:** `C:\Repos\WinHarden\logs\archive\reports_*.zip`

---

## Deployment Process

### Step 1: Preparation

```powershell
# Open PowerShell as Administrator
# Win + X -> PowerShell (Admin)

# Navigate to scripts directory
cd C:\Repos\WinHarden\scripts

# Verify execution policy allows script execution
Get-ExecutionPolicy
# Should show: RemoteSigned or AllSigned

# If needed, set for current session only:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force
```

### Step 2: Run Setup Script

```powershell
# Standard deployment (recommended)
.\Set-ScheduledTasksHardening.ps1

# With force flag (overwrites existing tasks)
.\Set-ScheduledTasksHardening.ps1 -Force

# With cleanup (removes old tasks first)
.\Set-ScheduledTasksHardening.ps1 -Cleanup -Force
```

### Step 3: Monitor Output

The script will display:
- [STEP 1] Admin Rights Verification
- [STEP 2] Automation Scripts Check
- [STEP 3] Task Definitions
- [STEP 4] Cleanup (if enabled)
- [STEP 5] Task Creation
- [STEP 6] Verification
- [STEP 7] Summary Report

**Expected Result:** All 5 tasks created successfully with status [OK]

---

## Post-Deployment Verification

### Immediate Verification (After Deployment)

```powershell
# List all tasks in Hardening folder
Get-ScheduledTask -TaskPath '\Hardening\*' | Format-Table TaskName, State, Enabled

# Verify each task is registered
$requiredTasks = @(
    "Monthly-Compliance-Audit",
    "Daily-Security-Monitor",
    "Archive-Old-Reports",
    "Detect-Configuration-Drift",
    "Monitor-Windows-Updates"
)

foreach ($taskName in $requiredTasks) {
    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($task) {
        Write-Host "$taskName - [OK]"
    } else {
        Write-Host "$taskName - [MISSING]" -ForegroundColor Red
    }
}
```

### Test Task Execution

```powershell
# Test run a task (does not affect schedule)
schtasks /run /tn "Hardening\Daily-Security-Monitor"

# Verify task started
Start-Sleep -Seconds 2
Get-ScheduledTask -TaskName "Daily-Security-Monitor" | Select-Object TaskName, LastTaskResult, LastRunTime

# Check for output logs
ls C:\Repos\WinHarden\logs\ | Where-Object { $_.LastWriteTime -gt (Get-Date).AddMinutes(-5) }
```

### Check Task Triggers

```powershell
# View detailed schedule for each task
Get-ScheduledTask -TaskPath '\Hardening\*' | ForEach-Object {
    Write-Host "Task: $($_.TaskName)"
    $_ | Get-ScheduledTaskInfo | Select-Object LastRunTime, LastTaskResult, NumberOfMissedRuns
}
```

---

## Monitoring & Maintenance

### Daily Monitoring

**Check for failed tasks:**
```powershell
Get-EventLog -LogName System -Source "TaskScheduler" -Newest 20 | 
  Where-Object { $_.Message -like '*failed*' -or $_.Message -like '*error*' } | 
  Format-Table TimeGenerated, Message -AutoSize
```

**Review task results:**
```powershell
Get-ScheduledTask -TaskPath '\Hardening\*' | ForEach-Object {
    $info = $_ | Get-ScheduledTaskInfo
    Write-Host "$($_.TaskName): Last Run=$(if($info.LastRunTime) { $info.LastRunTime } else { 'Never' }), Result=$($info.LastTaskResult)"
}
```

### Weekly Review

1. Check `C:\Repos\WinHarden\logs\` for expected reports
2. Review daily and weekly task completion
3. Verify no missed task runs (catchup mechanism working)
4. Check for any errors in Event Viewer

### Monthly Review

1. Run `Monthly-Compliance-Audit` manually to verify baseline
2. Review drift reports for unauthorized changes
3. Confirm archive task completed (old reports compressed)
4. Verify storage usage within acceptable limits

### Log Rotation

The Archive task automatically manages logs:
- Reports older than 6 months are compressed
- Archives stored in `logs/archive/`
- Active log directory kept under 100 MB

---

## Troubleshooting

### Issue: "Script cannot be found" errors

**Symptom:** Task fails with "The system cannot find the file specified"

**Solution:**
```powershell
# Verify scripts path in Set-ScheduledTasksHardening.ps1
$scriptsPath = "c:\Repos\WinHarden\scripts"
Get-ChildItem "$scriptsPath\*.ps1" | Select-Object Name, LastWriteTime

# If scripts are in different location, update path in Set-ScheduledTasksHardening.ps1
# Line 40: $scriptsPath = "c:\Repos\WinHarden\scripts"
```

### Issue: Task runs but produces no logs

**Symptom:** Task runs successfully but no output files generated

**Solution:**
```powershell
# Run script manually to see errors
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Repos\WinHarden\scripts\Monitor_Audit_Logs.ps1"

# Check logs directory permissions
icacls C:\Repos\WinHarden\logs\

# Verify SYSTEM user has write permissions
# Should see: (CI)(ID)(RX),(R) for SYSTEM user
```

### Issue: "Access Denied" when creating tasks

**Symptom:** Task creation fails with access denied error

**Solution:**
```powershell
# Verify running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
Write-Host "Running as Admin: $isAdmin"

# If not admin, exit and re-run PowerShell as Administrator
# Win + X -> PowerShell (Admin)
```

### Issue: Missed runs not being caught up

**Symptom:** Task scheduled for 08:00 AM, but missed run at 08:00 (system was off) and not caught up later

**Solution:**
The catchup mechanism is enabled by default (schtasks `/z` flag). However:
```powershell
# Verify task has catchup enabled
$taskInfo = Get-ScheduledTask -TaskName "Daily-Security-Monitor"
$taskInfo | Get-ScheduledTaskInfo

# Check "Enable missed task to run as soon as possible" in Task Scheduler GUI
# Or manually enable it:
# Right-click task -> Properties -> Conditions -> Check "If the task is missed, then run it as soon as possible"
```

### Issue: Task running with wrong user context

**Symptom:** Task runs but with insufficient privileges

**Solution:**
```powershell
# Verify SYSTEM user is set as task user
Get-ScheduledTask -TaskName "Monthly-Compliance-Audit" | Get-ScheduledTaskInfo

# If wrong user is shown, re-run setup script:
.\Set-ScheduledTasksHardening.ps1 -Force

# Tasks should always run as SYSTEM user for full hardening access
```

---

## Performance Considerations

### Resource Usage

| Task | CPU (Peak) | Memory | Disk I/O | Duration |
|------|-----------|--------|----------|----------|
| Daily-Security-Monitor | 15-25% | 50-100 MB | Medium | 5-10 min |
| Monitor-Windows-Updates | 5-10% | 30-50 MB | Low | 1-2 min |
| Detect-Configuration-Drift | 20-30% | 100-150 MB | Medium | 3-5 min |
| Monthly-Compliance-Audit | 30-50% | 200-300 MB | High | 10-15 min |
| Archive-Old-Reports | 5-15% | 50-100 MB | Medium | 2-3 min |

### Optimization Tips

1. **Stagger task execution** - Adjust times to avoid simultaneous runs
2. **Off-peak scheduling** - Consider moving compliance audits to after-hours
3. **Monitor disk space** - Archive mechanism keeps logs under control
4. **Disable unnecessary tasks** - Only deploy tasks relevant to your environment

---

## Next Steps

1. Review deployment status in summary report
2. Configure email alerts (optional) - see Task Scheduler properties
3. Set up monitoring dashboard (optional) - parse logs into monitoring system
4. Schedule quarterly compliance reviews
5. Plan update windows based on Monitor-Windows-Updates reports

---

**Last Updated:** 2026-06-26  
**Document Version:** 1.0  
**Target Audience:** System Administrators, Security Operations
