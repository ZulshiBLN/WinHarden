# WinHarden Automations - Catchup Configuration Guide

**Master the task recovery and missed-run mechanisms for continuous compliance monitoring.**

---

## Table of Contents

1. [Catchup Overview](#catchup-overview)
2. [How Catchup Works](#how-catchup-works)
3. [Current Configuration](#current-configuration)
4. [Managing Missed Runs](#managing-missed-runs)
5. [Recovery Strategies](#recovery-strategies)
6. [Monitoring Missed Tasks](#monitoring-missed-tasks)
7. [Advanced Catchup Configuration](#advanced-catchup-configuration)
8. [Troubleshooting Catchup Issues](#troubleshooting-catchup-issues)
9. [Best Practices](#best-practices)

---

## Catchup Overview

### Why Catchup Matters

**Scenario:**
- System scheduled to perform Monthly-Compliance-Audit on the 1st at 08:00 AM
- System powered off: 6:00 PM day before through 10:00 AM on the 1st
- Without catchup: Task is skipped, no compliance report generated that month
- With catchup: Task runs at 10:15 AM when system comes online, report generated

### What Catchup Does

Windows Task Scheduler's catchup mechanism ensures:
1. **No missed executions** - Tasks run even if system was offline
2. **Audit trail continuity** - Reports generated for all scheduled periods
3. **Compliance verification** - Monthly audits never skipped
4. **Data consistency** - All monitoring intervals covered

### When Catchup Is Triggered

Catchup runs when:
- System boots after scheduled task execution time
- System has been offline longer than task interval
- Task is enabled and catchup flag is set

Example:
```
Scheduled: Every Monday 08:00
System: Offline for 2 weeks (missed 2 Mondays)
Result: Task runs at boot-up time, executes for both missed Mondays
```

---

## How Catchup Works

### Catchup Mechanism in Windows Task Scheduler

| Setting | Default Value | Effect |
|---------|---------------|--------|
| Catchup Flag | /z enabled | Enables "run if missed" |
| Missed Task Threshold | 1 | Minimum missed occurrences to trigger |
| Catchup Trigger | System boot | When missed task gets executed |
| Retry Interval | None | No retry if catchup fails |
| Max Concurrent | Unlimited | Multiple catchup tasks can run together |

### Catchup Technical Flow

```
[Scheduled Trigger Time Passes]
        |
        v
[System Offline?]
        |
    YES |
        v
[Catchup Flag Set?]
        |
    YES |
        v
[System Boots or Available]
        |
        v
[Execute Task Immediately]
        |
        v
[Clear Missed Run Count]
```

### WinHarden Catchup Implementation

In `Set-ScheduledTasksHardening.ps1`, catchup is enabled for ALL tasks:

```powershell
# Line 177 - Enable catchup for all tasks
$command += "/z "  # Enable missed task catchup flag

# Result in schtasks command:
schtasks /create /tn "Hardening\Daily-Security-Monitor" /z ...
```

This flag is set when tasks are created:
- `/z` = "Run the task as soon as possible after a scheduled start is missed"

---

## Current Configuration

### Default Catchup Settings

All 5 WinHarden tasks have catchup ENABLED by default:

```powershell
# Verify catchup is enabled for all tasks
Get-ScheduledTask -TaskPath '\Hardening\*' | 
    ForEach-Object {
        $taskXml = [xml]$_.XML
        $catchupEnabled = $taskXml.Task.Settings.StartWhenAvailable
        Write-Host "$($_.TaskName): Catchup=$(if($catchupEnabled) { 'ENABLED' } else { 'DISABLED' })"
    }

# Expected output:
# Daily-Security-Monitor: Catchup=ENABLED
# Monitor-Windows-Updates: Catchup=ENABLED
# Detect-Configuration-Drift: Catchup=ENABLED
# Monthly-Compliance-Audit: Catchup=ENABLED
# Archive-Old-Reports: Catchup=ENABLED
```

### Configuration Summary

| Task | Frequency | Catchup | Duration | Missed Runs Impact |
|------|-----------|---------|----------|-------------------|
| Daily-Security-Monitor | Daily | Enabled | 5-10 min | 1 missed day = 1 catchup run |
| Monitor-Windows-Updates | Weekly | Enabled | 1-2 min | 1 missed week = 1 catchup run |
| Detect-Configuration-Drift | Weekly | Enabled | 3-5 min | 1 missed week = 1 catchup run |
| Monthly-Compliance-Audit | Monthly | Enabled | 10-15 min | 1 missed month = 1 catchup run |
| Archive-Old-Reports | Monthly | Enabled | 2-3 min | 1 missed month = 1 catchup run |

### Enable/Disable Catchup in GUI

For each task in Task Scheduler:
1. Right-click task -> **Properties**
2. Click **Conditions** tab
3. Check/uncheck: **"If the task is missed, then run it as soon as possible"**
4. Click **OK**

---

## Managing Missed Runs

### View Missed Run Count

```powershell
# Method 1: PowerShell - Current missed runs
Get-ScheduledTask -TaskPath '\Hardening\*' | 
    ForEach-Object {
        $info = $_ | Get-ScheduledTaskInfo
        Write-Host "$($_.TaskName): Missed=$($info.NumberOfMissedRuns) LastRun=$($info.LastRunTime)"
    }

# Example output:
# Daily-Security-Monitor: Missed=3 LastRun=2026-06-24 09:00:00
# Monthly-Compliance-Audit: Missed=0 LastRun=2026-06-01 08:00:00

# Method 2: Task Scheduler GUI
# 1. Open taskschd.msc
# 2. Navigate to: Task Scheduler Library -> Hardening
# 3. Select task, view "Last Run Time" and "Next Run Time" columns

# Method 3: Event Viewer
# 1. Open eventvwr.msc
# 2. Navigate to: Windows Logs -> System
# 3. Filter by Source: "TaskScheduler"
# 4. Look for Event ID 142 (missed task)
```

### View Missed Run History

```powershell
# Get detailed missed run information from Event Log
Get-EventLog -LogName System -Source "TaskScheduler" -Newest 50 | 
    Where-Object { $_.Message -like '*missed*' } | 
    Format-Table TimeGenerated, Message -AutoSize

# Filter for specific task
Get-EventLog -LogName System -Source "TaskScheduler" -Newest 50 | 
    Where-Object { $_.Message -like '*Daily-Security-Monitor*' } | 
    Format-Table TimeGenerated, EventID, Message -AutoSize
```

### Clear Missed Run Count

```powershell
# Option 1: Allow tasks to naturally clear after running
# Missed count resets automatically when task executes

# Option 2: Re-register task (clears all history)
Get-ScheduledTask -TaskName "Daily-Security-Monitor" | 
    Unregister-ScheduledTask -Confirm:$false

# Then recreate:
.\Set-ScheduledTasksHardening.ps1 -Force

# Option 3: Manual trigger (runs catchup immediately)
schtasks /run /tn "Hardening\Daily-Security-Monitor"
```

---

## Recovery Strategies

### Strategy 1: Automatic Catchup (Default - Recommended)

**Configuration:**
- Catchup enabled for all tasks
- Tasks run as soon as system becomes available
- No user intervention required

**Behavior:**
```
Friday 09:00 - Daily-Security-Monitor scheduled
System offline: Friday 14:00 - Monday 08:00
Monday 08:15 - System boots
Monday 08:20 - Daily-Security-Monitor runs immediately (catchup)
Monday 09:00 - Regular scheduled run happens
```

**Advantages:**
- Automatic, no manual intervention
- No missed audits or compliance reports
- Simple to understand and manage
- Auditable (all catchup runs logged)

**Disadvantages:**
- Resource spike when system comes online
- Multiple tasks may run simultaneously
- Not ideal for high-load servers
- May not be suitable for very slow systems

**Best for:**
- Standard deployments
- Office/business environments
- Systems with predictable availability
- Compliance-driven organizations

### Strategy 2: Staggered Recovery

**Configuration:**
Modify task start times to spread execution if system was down.

**Implementation:**
```powershell
# Original schedule
# 08:00 - Monitor-Windows-Updates
# 09:00 - Daily-Security-Monitor
# 10:00 - Detect-Configuration-Drift

# Staggered schedule (30-min offsets)
schtasks /change /tn "Hardening\Monitor-Windows-Updates" /st 08:00
schtasks /change /tn "Hardening\Daily-Security-Monitor" /st 09:00
schtasks /change /tn "Hardening\Detect-Configuration-Drift" /st 10:00

# If system boots at 08:30, tasks execute:
# 08:30 - Monitor-Windows-Updates (catchup)
# 09:00 - Daily-Security-Monitor (scheduled)
# 10:00 - Detect-Configuration-Drift (scheduled)
```

**Advantages:**
- Reduces simultaneous execution
- Lower resource spike
- Better predictability
- Easier load balancing

**Disadvantages:**
- Manual setup required
- Requires monitoring and adjustment
- Some tasks may start later than expected
- More complex to maintain

**Best for:**
- Resource-constrained systems
- High-load environments
- Systems with predictable offline windows
- Custom scheduling requirements

### Strategy 3: Selective Catchup (Per-Task)

**Configuration:**
Enable catchup for critical tasks only, disable for others.

**Implementation:**
```powershell
# Disable catchup for Archive-Old-Reports (non-critical)
# 1. Get task XML
$task = Get-ScheduledTask -TaskName "Archive-Old-Reports"

# 2. Modify to disable catchup
# (Advanced - requires XML manipulation)

# Easier method: Recreate without /z flag
Get-ScheduledTask -TaskName "Archive-Old-Reports" | 
    Unregister-ScheduledTask -Confirm:$false

# Recreate manually:
schtasks /create /tn "Hardening\Archive-Old-Reports" `
    /tr "powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\Repos\WinHarden\scripts\Archive_Old_Reports.ps1" `
    /sc MONTHLY /d 2 /st 09:00 /ru SYSTEM /f
    # NOTE: No /z flag (catchup disabled)
```

**Catchup Status per Task:**
```powershell
# Critical (catchup enabled)
schtasks /create ... /z ... # Daily-Security-Monitor
schtasks /create ... /z ... # Monthly-Compliance-Audit

# Non-critical (catchup disabled)
schtasks /create ... /f ... # Archive-Old-Reports (no /z)
```

**Advantages:**
- Fine-grained control
- Only critical tasks catch up
- Reduces unnecessary executions
- Optimizes for specific environment

**Disadvantages:**
- Complex setup and maintenance
- Requires understanding of each task
- May lead to missed non-critical reports
- Harder to debug

**Best for:**
- Sophisticated environments
- Mixed-priority workloads
- Systems with specific compliance requirements

---

## Monitoring Missed Tasks

### Daily Monitoring

```powershell
# Create a daily check script
$hardeningTasks = Get-ScheduledTask -TaskPath '\Hardening\*'

Write-Host "=== Daily Task Status Report ==="
Write-Host "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host ""

foreach ($task in $hardeningTasks) {
    $info = $task | Get-ScheduledTaskInfo
    $status = if ($info.NumberOfMissedRuns -gt 0) { "[WARNING]" } else { "[OK]" }
    
    Write-Host "$($task.TaskName)"
    Write-Host "  Status: $status"
    Write-Host "  Missed Runs: $($info.NumberOfMissedRuns)"
    Write-Host "  Last Run: $(if ($info.LastRunTime) { $info.LastRunTime } else { 'Never' })"
    Write-Host "  Next Run: $(if ($info.NextRunTime) { $info.NextRunTime } else { 'Not scheduled' })"
    Write-Host "  Result Code: $($info.LastTaskResult)"
    Write-Host ""
}
```

### Real-Time Monitoring Script

```powershell
# Monitor missed tasks every hour
# Save as: C:\Repos\WinHarden\scripts\Monitor_Missed_Tasks.ps1

$runInterval = 3600  # 1 hour
$maxMissedThreshold = 5  # Alert if >5 missed runs

while ($true) {
    Clear-Host
    Write-Host "[MISSED TASK MONITOR]"
    Write-Host "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Host "========================================"
    Write-Host ""
    
    $alertsFound = 0
    
    Get-ScheduledTask -TaskPath '\Hardening\*' | ForEach-Object {
        $info = $_ | Get-ScheduledTaskInfo
        $missed = $info.NumberOfMissedRuns
        
        if ($missed -gt 0) {
            $alertsFound++
            $severity = if ($missed -gt $maxMissedThreshold) { "[CRITICAL]" } else { "[WARNING]" }
            Write-Host "$($_.TaskName) $severity"
            Write-Host "  Missed Runs: $missed"
        }
    }
    
    if ($alertsFound -eq 0) {
        Write-Host "All tasks OK - no missed runs"
    }
    
    Write-Host ""
    Write-Host "Next check in $($runInterval / 60) minutes..."
    Start-Sleep -Seconds $runInterval
}
```

### Automated Alert for Excessive Missed Runs

```powershell
# Save as: C:\Repos\WinHarden\scripts\Alert_Missed_Tasks.ps1

$missedThreshold = 10
$alertFile = "C:\Repos\WinHarden\logs\missed_tasks_alert.txt"
$alertedTasks = @()

Get-ScheduledTask -TaskPath '\Hardening\*' | ForEach-Object {
    $info = $_ | Get-ScheduledTaskInfo
    
    if ($info.NumberOfMissedRuns -gt $missedThreshold) {
        $alertedTasks += "$($_.TaskName): $($info.NumberOfMissedRuns) missed runs"
    }
}

if ($alertedTasks.Count -gt 0) {
    $alert = @"
[ALERT] Excessive Missed Task Runs
Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Threshold: $missedThreshold missed runs

Tasks:
$($alertedTasks -join "`n")

Recommended Actions:
1. Check system availability/uptime
2. Verify Task Scheduler service is running
3. Review Event Viewer for task failures
4. Consider disabling catchup for low-priority tasks
"@
    
    Add-Content -Path $alertFile -Value $alert
    Write-Host $alert
}
```

### Monthly Missed Task Report

```powershell
# Generate comprehensive missed task report
$reportDate = Get-Date -Format 'yyyy-MM-dd'
$reportPath = "C:\Repos\WinHarden\logs\missed_tasks_report_$reportDate.csv"

$report = Get-ScheduledTask -TaskPath '\Hardening\*' | 
    ForEach-Object {
        $info = $_ | Get-ScheduledTaskInfo
        [PSCustomObject]@{
            TaskName = $_.TaskName
            LastRunTime = $info.LastRunTime
            NextRunTime = $info.NextRunTime
            LastTaskResult = $info.LastTaskResult
            MissedRuns = $info.NumberOfMissedRuns
            Enabled = $_.Enabled
            ReportDate = $reportDate
        }
    }

$report | Export-Csv -Path $reportPath -NoTypeInformation
Write-Host "Report saved to: $reportPath"

# Display summary
$totalMissed = ($report | Measure-Object -Property MissedRuns -Sum).Sum
Write-Host "Total missed runs across all tasks: $totalMissed"
```

---

## Advanced Catchup Configuration

### Enable Catchup Only on Business Days

```powershell
# Create two instances of Daily-Security-Monitor:
# 1. Weekday version (Mon-Fri, catchup enabled)
# 2. Weekend version (Sat-Sun, catchup disabled)

# Weekday instance
schtasks /create /tn "Hardening\Daily-Security-Monitor-Weekday" `
    /tr "powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\Repos\WinHarden\scripts\Monitor_Audit_Logs.ps1" `
    /sc WEEKLY /d MO,TU,WE,TH,FR /st 09:00 /ru SYSTEM /z /f

# Weekend instance (no catchup)
schtasks /create /tn "Hardening\Daily-Security-Monitor-Weekend" `
    /tr "powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\Repos\WinHarden\scripts\Monitor_Audit_Logs.ps1" `
    /sc WEEKLY /d SA,SU /st 09:00 /ru SYSTEM /f
    # NOTE: No /z flag
```

### Delayed Catchup Execution

Windows doesn't natively support "delay before catchup", but you can add a delay wrapper:

```powershell
# Create wrapper: C:\Repos\WinHarden\scripts\Delayed_Monitor_Audit_Logs.ps1

# Add delay before executing actual script
# This prevents immediate catchup, allowing normal schedule to run first
Start-Sleep -Seconds 300  # 5-minute delay

# Then call actual script
& C:\Repos\WinHarden\scripts\Monitor_Audit_Logs.ps1

# Schedule wrapper instead of original script
schtasks /create /tn "Hardening\Daily-Security-Monitor-Delayed" `
    /tr "powershell.exe -File C:\Repos\WinHarden\scripts\Delayed_Monitor_Audit_Logs.ps1" `
    /sc DAILY /st 09:00 /ru SYSTEM /z /f
```

### Conditional Catchup (Power State Check)

```powershell
# Create intelligent wrapper that only catches up if system was actually offline

# Save as: C:\Repos\WinHarden\scripts\Smart_Catchup_Monitor_Audit_Logs.ps1

$lastRunFile = "C:\Repos\WinHarden\logs\.last_run_timestamp"

# Check if this is first run or catchup run
$currentTime = Get-Date
$isFirstRun = -not (Test-Path $lastRunFile)

if ($isFirstRun) {
    # First run - execute normally
    Write-Host "First run at $currentTime"
} else {
    # Check if sufficient time has passed (indicates catchup)
    $lastRun = [DateTime]::Parse((Get-Content $lastRunFile))
    $timeDiff = ($currentTime - $lastRun).TotalHours
    
    if ($timeDiff -gt 24) {
        Write-Host "Catchup detected (offline for $([Math]::Round($timeDiff, 1)) hours)"
    }
}

# Save current run time
$currentTime.ToString('o') | Set-Content -Path $lastRunFile

# Execute actual monitoring script
& C:\Repos\WinHarden\scripts\Monitor_Audit_Logs.ps1
```

---

## Troubleshooting Catchup Issues

### Issue: Task Caught Up Too Frequently

**Symptoms:**
- Task shows multiple missed runs
- Task executes multiple times in succession
- Event Viewer shows many catchup events

**Causes:**
- System powered off during multiple scheduled intervals
- Catchup flag enabled for all missed occurrences
- System uptime shorter than task intervals

**Diagnosis:**
```powershell
# Check system uptime
$uptime = (Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
Write-Host "System uptime: $($uptime.Days) days, $($uptime.Hours) hours"

# Check missed run count
Get-ScheduledTask -TaskPath '\Hardening\*' | 
    Get-ScheduledTaskInfo | 
    Select-Object TaskName, NumberOfMissedRuns | 
    Where-Object { $_.NumberOfMissedRuns -gt 0 }

# Check Event Viewer for pattern
Get-EventLog -LogName System -Source "TaskScheduler" -Newest 100 | 
    Where-Object { $_.EventID -eq 142 } | 
    Measure-Object
```

**Solutions:**
```powershell
# Option 1: Disable catchup for low-priority tasks
Get-ScheduledTask -TaskName "Archive-Old-Reports" | 
    Unregister-ScheduledTask -Confirm:$false

schtasks /create /tn "Hardening\Archive-Old-Reports" `
    /tr "powershell.exe -File C:\Repos\WinHarden\scripts\Archive_Old_Reports.ps1" `
    /sc MONTHLY /d 2 /st 09:00 /ru SYSTEM /f
    # No /z flag

# Option 2: Reduce frequency of high-frequency tasks
schtasks /change /tn "Hardening\Daily-Security-Monitor" /sc WEEKLY /d MO,WE,FR

# Option 3: Schedule during longer availability window
# Move system to always-on or longer online periods

# Option 4: Manually clear missed runs
schtasks /run /tn "Hardening\Daily-Security-Monitor"
Start-Sleep -Seconds 5
schtasks /run /tn "Hardening\Monitor-Windows-Updates"
Start-Sleep -Seconds 5
# Run all tasks manually to clear missed count
```

### Issue: "Too Many Missed Runs" Alert

**Symptoms:**
- Event ID 142 appears frequently in Event Viewer
- NumberOfMissedRuns >10 for multiple tasks
- System sluggish after boot

**Causes:**
- System offline for extended period (days/weeks)
- Multiple tasks accumulating missed runs
- Catchup processing consuming resources

**Diagnosis:**
```powershell
# Identify which tasks have excessive missed runs
Get-ScheduledTask -TaskPath '\Hardening\*' | 
    ForEach-Object {
        $info = $_ | Get-ScheduledTaskInfo
        if ($info.NumberOfMissedRuns -gt 5) {
            Write-Host "$($_.TaskName): $($info.NumberOfMissedRuns) missed runs [ALERT]"
        }
    }

# Check Event Viewer for failure patterns
Get-EventLog -LogName System -Source "TaskScheduler" -After (Get-Date).AddHours(-24) | 
    Where-Object { $_.EventID -eq 201 } | 
    Measure-Object
```

**Solutions:**
```powershell
# Option 1: Manually trigger all tasks to clear missed count
Write-Host "Clearing missed task runs..."
@(
    "Daily-Security-Monitor",
    "Monitor-Windows-Updates",
    "Detect-Configuration-Drift",
    "Monthly-Compliance-Audit",
    "Archive-Old-Reports"
) | ForEach-Object {
    schtasks /run /tn "Hardening\$_"
    Start-Sleep -Seconds 3
}

# Option 2: Re-register all tasks (clears history completely)
Write-Host "Re-registering all tasks..."
Get-ScheduledTask -TaskPath '\Hardening\*' | 
    Unregister-ScheduledTask -Confirm:$false

# Reinstall fresh
& C:\Repos\WinHarden\scripts\Set-ScheduledTasksHardening.ps1 -Force

# Option 3: Monitor resource usage during catchup
# Stagger task execution to spread load
```

### Issue: Catchup Tasks Blocking Other Operations

**Symptoms:**
- System sluggish during catchup execution
- Other processes delayed
- High CPU/memory usage

**Causes:**
- Multiple catchup tasks running simultaneously
- Task resource requirements too high
- System underpowered for concurrent execution

**Solutions:**
```powershell
# Option 1: Increase schedule spacing
schtasks /change /tn "Hardening\Monitor-Windows-Updates" /st 08:00
Start-Sleep -Seconds 1
schtasks /change /tn "Hardening\Daily-Security-Monitor" /st 09:00
Start-Sleep -Seconds 1
schtasks /change /tn "Hardening\Detect-Configuration-Drift" /st 10:00

# Option 2: Move to off-peak hours
schtasks /change /tn "Hardening\Monthly-Compliance-Audit" /st 22:00
schtasks /change /tn "Hardening\Detect-Configuration-Drift" /st 23:00
schtasks /change /tn "Hardening\Daily-Security-Monitor" /st 00:00

# Option 3: Disable catchup for low-priority tasks
# (See "Selective Catchup" strategy above)

# Option 4: Limit system power state changes
# Prevent unexpected power-downs during production hours
```

---

## Best Practices

### For System Availability

1. **Enable catchup for all critical tasks** - Monthly-Compliance-Audit, Daily-Security-Monitor
2. **Stagger execution times** - Prevent simultaneous starts
3. **Schedule off-peak audits** - Run heavy tasks at night
4. **Monitor missed runs daily** - Detect patterns early
5. **Set system to always-on** - Avoid scheduled power-downs

### For Data Consistency

1. **Audit scripts must be idempotent** - Safe to run multiple times
2. **Report timestamps reflect actual execution time** - Not scheduled time
3. **Catchup runs are sequential** - No parallel execution of same task
4. **Document task dependencies** - If one task depends on another
5. **Verify data integrity** - Check reports for duplicate entries

### For Compliance

1. **Keep detailed audit logs** - For compliance verification
2. **Never disable catchup for compliance tasks** - Risk missed audits
3. **Review missed runs monthly** - Document reasons for unavailability
4. **Archive reports systematically** - Maintain historical compliance data
5. **Alert on excessive missed runs** - >5 misses = investigation needed

---

## Common Issues FAQ

**Q: If system is offline for 7 days, will Daily-Security-Monitor run 7 times?**  
A: Yes. The task will execute for each missed day in sequence upon system boot.

**Q: Does catchup affect report accuracy?**  
A: No. Reports still represent intended time periods. Timestamps show actual execution time.

**Q: Can I manually clear missed runs without re-registering?**  
A: Practically, no. Either re-register task or manually trigger all missed occurrences.

**Q: What if a task takes longer than its interval to run?**  
A: Task will still complete. Next scheduled/catchup run occurs after completion.

**Q: Are catchup runs logged in Event Viewer?**  
A: Yes. Event ID 142 specifically logs "task missed and caught up" events.

**Q: Can I set different catchup strategies per task?**  
A: Yes. Recreate individual tasks with or without /z flag as needed.

---

## Quick Reference Commands

```powershell
# Check catchup status for all tasks
Get-ScheduledTask -TaskPath '\Hardening\*' | 
    ForEach-Object {
        $info = $_ | Get-ScheduledTaskInfo
        [PSCustomObject]@{
            Task = $_.TaskName
            Missed = $info.NumberOfMissedRuns
            LastRun = $info.LastRunTime
            NextRun = $info.NextRunTime
        }
    } | Format-Table

# Manually execute missed task
schtasks /run /tn "Hardening\Daily-Security-Monitor"

# Check catchup in Event Viewer
Get-EventLog -LogName System -Source "TaskScheduler" -Newest 20 | 
    Where-Object { $_.EventID -eq 142 } | 
    Format-Table TimeGenerated, Message

# Clear missed runs by re-registering
Get-ScheduledTask -TaskName "Daily-Security-Monitor" | 
    Unregister-ScheduledTask -Confirm:$false
.\Set-ScheduledTasksHardening.ps1 -Force
```

---

**Document Version:** 2.0  
**Last Updated:** 2026-06-27  
**Target Audience:** System Administrators, DevOps Engineers, Compliance Officers  
**Complexity Level:** Intermediate to Advanced
