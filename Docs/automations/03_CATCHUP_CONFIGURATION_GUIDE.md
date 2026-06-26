# WinHarden - Catchup Configuration Guide

## Table of Contents

1. [Overview](#overview)
2. [Catchup Mechanism Explained](#catchup-mechanism-explained)
3. [Current Configuration](#current-configuration)
4. [Managing Missed Runs](#managing-missed-runs)
5. [Recovery Strategies](#recovery-strategies)
6. [Monitoring Missed Tasks](#monitoring-missed-tasks)
7. [Advanced Configuration](#advanced-configuration)
8. [Troubleshooting](#troubleshooting)

---

## Overview

The "catchup" mechanism ensures that scheduled tasks run even if the system was powered off or unavailable during their scheduled time. This guide explains how WinHarden implements task recovery and how to customize it for your environment.

### Why Catchup Matters

**Scenario:**
- Monthly-Compliance-Audit scheduled for 1st of month at 08:00 AM
- System is powered off from 6:00 PM - 10:00 AM next morning
- Without catchup: Audit is missed, no compliance report generated
- With catchup: Audit runs at 10:15 AM when system comes online

---

## Catchup Mechanism Explained

### How Task Scheduler Catchup Works

Windows Task Scheduler has built-in catchup functionality:

| Setting | Default | Effect |
|---------|---------|--------|
| Catchup Flag (`/z`) | Enabled | Task runs ASAP if missed |
| Missed Task Threshold | 1 | Runs after 1 missed occurrence |
| Recovery Action | None | Task doesn't retry on failure |
| Run with highest privileges | Varies | Determines task access level |

### WinHarden Catchup Configuration

The setup script (`Set-ScheduledTasksHardening.ps1`) enables catchup for all tasks:

```powershell
# Line 177 in Set-ScheduledTasksHardening.ps1
$command += "/z "  # Enable missed task catchup
$command += "/f"   # Force flag
```

This translates to schtasks command:
```powershell
schtasks /create /tn "Hardening\[TaskName]" /z /f [other params]
```

---

## Current Configuration

### Default Catchup Settings

All 5 WinHarden tasks are configured with:

| Task | Catchup Enabled | Start If Missed | User Context | Run Duration |
|------|-----------------|-----------------|---------------|--------------|
| Daily-Security-Monitor | Yes (/z) | As soon as possible | SYSTEM | 5-10 min |
| Monitor-Windows-Updates | Yes (/z) | As soon as possible | SYSTEM | 1-2 min |
| Detect-Configuration-Drift | Yes (/z) | As soon as possible | SYSTEM | 3-5 min |
| Monthly-Compliance-Audit | Yes (/z) | As soon as possible | SYSTEM | 10-15 min |
| Archive-Old-Reports | Yes (/z) | As soon as possible | SYSTEM | 2-3 min |

### Verify Current Settings

```powershell
# Check catchup status in Task Scheduler GUI
# For each task:
# 1. Right-click task
# 2. Properties tab
# 3. Look for "If the task is missed, then run it as soon as possible"

# Or via PowerShell:
$task = Get-ScheduledTask -TaskName "Daily-Security-Monitor"
$task | Get-ScheduledTaskInfo

# Check task XML for catchup flag
$task.XML | Select-String "StopIfGoingOnBatteries|RunOnlyIfNetworkAvailable|AllowDemandStart"
```

---

## Managing Missed Runs

### Viewing Missed Runs

**Method 1: Task Scheduler GUI**
```
1. Open taskschd.msc
2. Navigate to: Hardening folder
3. Select a task
4. Properties -> History tab
5. Look for events with status "The task was run due to a trigger condition"
```

**Method 2: PowerShell**
```powershell
# Check missed run count for each task
Get-ScheduledTask -TaskPath '\Hardening\*' | ForEach-Object {
    $info = $_ | Get-ScheduledTaskInfo
    Write-Host "Task: $($_.TaskName)"
    Write-Host "  Missed Runs: $($info.NumberOfMissedRuns)"
    Write-Host "  Last Run: $($info.LastRunTime)"
    Write-Host "  Last Result: $($info.LastTaskResult)"
    Write-Host ""
}
```

**Method 3: Event Viewer**
```powershell
# View all Task Scheduler events
eventvwr.msc
# Path: Windows Logs -> System -> Task Scheduler
# Filter by Event ID:
# 141 = Task triggered
# 142 = Task missed and caught up
# 200 = Task executed
# 201 = Task execution failed
```

### Clearing Missed Run History

```powershell
# Option 1: Clear all missed runs for a task
$task = Get-ScheduledTask -TaskName "Daily-Security-Monitor"
# No direct PowerShell cmdlet to clear missed runs
# Use Event Viewer to view only (clearing requires manual action)

# Option 2: Re-register task (clears history)
Get-ScheduledTask -TaskName "Daily-Security-Monitor" | Unregister-ScheduledTask -Confirm:$false
# Then re-run setup script:
# .\Set-ScheduledTasksHardening.ps1 -Force
```

---

## Recovery Strategies

### Strategy 1: Automatic Catchup (Current)

**Configuration:**
- Catchup enabled for all tasks
- Tasks run as soon as system becomes available
- No loss of scheduled execution

**Pros:**
- Simple, automatic
- No missed audits
- Minimal user intervention

**Cons:**
- May cause resource spike when system comes online
- Multiple tasks may run simultaneously if system was down

**Best For:** Standard deployments, normal office environments

### Strategy 2: Staggered Recovery

Modify task schedules to spread out execution if system was down.

**Example:**
```powershell
# Original schedule
# Daily-Security-Monitor: 09:00 AM (every day)
# Detect-Configuration-Drift: 10:00 AM (Monday)
# Monitor-Windows-Updates: 08:00 AM (Monday)

# Staggered schedule (reduce simultaneous execution)
# Daily-Security-Monitor: 09:00 AM (every day)
# Detect-Configuration-Drift: 10:30 AM (Monday)  <- 30 min offset
# Monitor-Windows-Updates: 08:30 AM (Monday)     <- 30 min offset
```

**Implementation:**
```powershell
# Edit task via GUI:
# 1. Open taskschd.msc
# 2. Right-click task -> Properties
# 3. Triggers tab -> Edit trigger
# 4. Change "Start time" to new value

# Or via schtasks:
schtasks /change /tn "Hardening\Daily-Security-Monitor" /st 09:00
```

### Strategy 3: No Catchup (Not Recommended)

Disable catchup for non-critical tasks.

```powershell
# WARNING: Only for non-critical tasks
# Run schtasks without /z flag

# To disable catchup for existing task:
# 1. Delete task: Get-ScheduledTask -TaskName "Archive-Old-Reports" | Unregister-ScheduledTask
# 2. Manually re-create without /z flag

# This is NOT recommended - use Strategy 1 or 2 instead
```

---

## Monitoring Missed Tasks

### Real-Time Monitoring

```powershell
# Create a monitoring script to check missed runs every hour
$while ($true) {
    Clear-Host
    Write-Host "Missed Task Monitor - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Host "=" * 60
    
    Get-ScheduledTask -TaskPath '\Hardening\*' | ForEach-Object {
        $info = $_ | Get-ScheduledTaskInfo
        $missed = $info.NumberOfMissedRuns
        $color = if ($missed -gt 0) { "Yellow" } else { "Green" }
        
        Write-Host "$($_.TaskName) - Missed: $missed - $(if($missed -gt 0) { '[ATTENTION]' } else { '[OK]' })" -ForegroundColor $color
    }
    
    Write-Host "`nNext check in 60 minutes..."
    Start-Sleep -Seconds 3600
}
```

### Automated Alert for Missed Tasks

```powershell
# Add to a scheduled task that checks every 6 hours
$missedCount = 0
Get-ScheduledTask -TaskPath '\Hardening\*' | ForEach-Object {
    $info = $_ | Get-ScheduledTaskInfo
    $missedCount += $info.NumberOfMissedRuns
}

if ($missedCount -gt 0) {
    # Log alert
    "ALERT: $missedCount missed task runs detected at $(Get-Date)" | 
        Add-Content C:\Repos\WinHarden\logs\missed_tasks_alert.log
    
    # Optional: Send email notification (requires SMTP setup)
    # Send-MailMessage ...
}
```

### Dashboard Reporting

Parse task history for reporting:

```powershell
# Generate missed tasks report
$report = Get-ScheduledTask -TaskPath '\Hardening\*' | ForEach-Object {
    $info = $_ | Get-ScheduledTaskInfo
    [PSCustomObject]@{
        TaskName = $_.TaskName
        LastRun = $info.LastRunTime
        LastResult = $info.LastTaskResult
        MissedRuns = $info.NumberOfMissedRuns
        NextRunTime = $info.NextRunTime
    }
}

$report | Export-Csv -Path "C:\Repos\WinHarden\logs\task_status_report.csv" -NoTypeInformation
```

---

## Advanced Configuration

### Custom Catchup Behavior

**Enable Catchup Only on Weekdays**

```powershell
# For tasks that should only catch up on business days:
# 1. Create two task instances:
#    - "Daily-Security-Monitor-Weekday" (catch up enabled)
#    - "Daily-Security-Monitor-Weekend" (catch up disabled)

# 2. Or manually adjust via schtasks:
schtasks /change /tn "Hardening\Daily-Security-Monitor" /d MO,TU,WE,TH,FR
```

**Delayed Catchup Start**

Windows doesn't natively support "delay before catchup", but you can:

```powershell
# Create wrapper script that delays execution:
# filename: Delayed_Monitor_Audit_Logs.ps1

# Add delay before calling actual script
Start-Sleep -Seconds 300  # 5-minute delay before running

# Then call actual script
& C:\Repos\WinHarden\scripts\Monitor_Audit_Logs.ps1
```

### Per-Task Catchup Configuration

Disable catchup for low-priority tasks:

```powershell
# Remove catchup from Archive task (low priority)
# Get current task definition
$task = Get-ScheduledTask -TaskName "Archive-Old-Reports"

# Edit XML to remove /Z flag equivalent
# (advanced - requires manual XML manipulation)

# Easier: Recreate task without /z flag
Get-ScheduledTask -TaskName "Archive-Old-Reports" | Unregister-ScheduledTask -Confirm:$false

# Manually recreate:
schtasks /create /tn "Hardening\Archive-Old-Reports" `
  /tr "powershell.exe -File C:\Repos\WinHarden\scripts\Archive_Old_Reports.ps1" `
  /sc MONTHLY /d 2 /st 09:00 /ru SYSTEM `
  /f
  # Note: NO /z flag this time
```

---

## Troubleshooting

### Issue: Task Caught Up Too Frequently

**Symptom:** Task runs multiple times in succession after system startup

**Cause:** System was off multiple scheduled intervals, and catchup ran for each missed occurrence

**Solution:**
```powershell
# Option 1: Disable catchup for this task
# (See "Per-Task Catchup Configuration" above)

# Option 2: Reduce task frequency
# Change from DAILY to WEEKLY for less-critical tasks

# Option 3: Check system power settings
# Ensure system doesn't power off during scheduled maintenance windows
Get-PowerCfg -L | Where-Object { $_.Name -like "*Sleep*" }
```

### Issue: "Too Many Missed Runs" in Event Viewer

**Symptom:** Event ID 142 shows task caught up 10+ times

**Cause:** System was off for extended period (days/weeks)

**Solution:**
```powershell
# 1. Identify which task is reporting excessive missed runs
Get-ScheduledTask -TaskPath '\Hardening\*' | ForEach-Object {
    Write-Host "$($_.TaskName): $($_ | Get-ScheduledTaskInfo | Select -Expand NumberOfMissedRuns) missed"
}

# 2. Manually clear by re-registering task
Get-ScheduledTask -TaskName "[TaskName]" | Unregister-ScheduledTask -Confirm:$false

# 3. Re-run setup script to restore
.\Set-ScheduledTasksHardening.ps1 -Force

# 4. Or update in GUI: Clear task history and recreate
```

### Issue: Catchup Task Failures Masking Real Errors

**Symptom:** Task caught up but failed, making it hard to debug

**Solution:**
```powershell
# Review detailed error logs in Event Viewer
# Each catchup attempt is logged separately

# Filter for failed catchup events:
Get-EventLog -LogName System -Source "TaskScheduler" -ErrorAction SilentlyContinue | 
  Where-Object { $_.Message -like "*missed*" -and $_.Message -like "*failed*" } | 
  Format-Table TimeGenerated, Message

# Test task manually to reproduce error:
schtasks /run /tn "Hardening\Daily-Security-Monitor"
```

### Issue: Catchup Tasks Blocking Other System Operations

**Symptom:** System sluggish after multiple catchup tasks run

**Solution:**
```powershell
# 1. Increase schedule spacing
# Move tasks to different times (see Strategy 2)

# 2. Reduce task intensity
# Remove non-critical checks from scripts
# Optimize scripts for performance

# 3. Limit concurrent tasks
# Use task scheduler's built-in concurrency limits
# (Advanced: modify task XML)

# 4. Schedule during off-peak hours
# Move compliance audits to evening/night
schtasks /change /tn "Hardening\Monthly-Compliance-Audit" /st 22:00
```

---

## Best Practices

### For System Availability

- **Enable catchup** for all critical compliance and security tasks
- **Stagger execution times** to prevent resource spikes
- **Schedule audits** during off-peak hours when possible
- **Monitor missed runs** weekly to detect patterns

### For Data Consistency

- **Catchup runs are not guaranteed** to run in exact order if multiple missed
- **Audit scripts should be idempotent** (safe to run multiple times)
- **Report timestamps** will reflect actual run time, not scheduled time
- **Document dependencies** if one task depends on another

### For Performance

- **Disable catchup** only for truly optional/redundant tasks
- **Use task priorities** to ensure critical tasks run first after catchup
- **Monitor resource usage** during high-activity periods
- **Clean up logs regularly** to prevent disk space issues

---

## FAQ

**Q: If system is off for 3 days, will missed Daily-Security-Monitor tasks all run?**
A: Yes, the task will catch up for 3 missed runs. They'll execute sequentially on system startup.

**Q: Does catchup affect the integrity of audit reports?**
A: No. Reports still represent the time range they were designed to cover. Timestamps will show actual run time.

**Q: Can I manually trigger a missed task?**
A: Yes - use `schtasks /run /tn "Hardening\[TaskName]"` to run any task on-demand.

**Q: What if a task is too large and catches up multiple times?**
A: Consider disabling catchup for that task, or breaking it into smaller subtasks.

**Q: How long are missed run records kept?**
A: Until task history is cleared manually or system event log is rolled over.

---

## Next Steps

1. Monitor missed run trends in your environment
2. Adjust catchup strategy based on system availability patterns
3. Document any custom catchup rules you implement
4. Review monthly to optimize schedule timing

---

**Last Updated:** 2026-06-26  
**Document Version:** 1.0  
**Target Audience:** System Administrators, DevOps Engineers  
**Complexity Level:** Intermediate to Advanced
