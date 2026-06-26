# WinHarden - Quickstart Guide: Set-ScheduledTasks

## Overview

This guide provides the fastest way to deploy WinHarden automation tasks to your Windows Server using the `Set-ScheduledTasksHardening.ps1` script.

---

## Prerequisites

- Windows Server 2016 or later (Windows 11 tested)
- PowerShell 5.1 or higher
- **ADMINISTRATOR privileges** (required)
- WinHarden repository cloned to `C:\Repos\WinHarden`

---

## Quick Start (5 Minutes)

### Step 1: Open PowerShell as Administrator

```powershell
# Win + X -> PowerShell (Admin)
# OR: Win + R -> powershell.exe -> Ctrl+Shift+Enter
```

### Step 2: Navigate to Scripts Directory

```powershell
cd C:\Repos\WinHarden\scripts
```

### Step 3: Run the Setup Script

```powershell
.\Set-ScheduledTasksHardening.ps1
```

**Expected Output:**
- [STEP 1] Admin rights verification - PASSED
- [STEP 2] Script existence check - 5/5 found
- [STEP 3] Task definitions - 5 tasks loaded
- [STEP 5] Task creation - [OK] for each task
- [STEP 7] Summary - All tasks created successfully

---

## What Gets Installed

| Task | Schedule | Time | Purpose |
|------|----------|------|---------|
| Monitor-Windows-Updates | Weekly (Monday) | 08:00 | Security update detection |
| Daily-Security-Monitor | Daily | 09:00 | Real-time threat monitoring |
| Detect-Configuration-Drift | Weekly (Monday) | 10:00 | Unauthorized change detection |
| Monthly-Compliance-Audit | Monthly (1st) | 08:00 | Compliance verification |
| Archive-Old-Reports | Monthly (2nd) | 09:00 | Report cleanup & archival |

---

## Verify Installation

### Method 1: Task Scheduler GUI

```powershell
taskschd.msc
# Navigate to: Task Scheduler Library -> Hardening
# You should see 5 tasks listed
```

### Method 2: PowerShell Command

```powershell
Get-ScheduledTask -TaskPath '\Hardening\*' | Format-Table TaskName, State
```

**Example Output:**
```
TaskName                    State
--------                    -----
Monthly-Compliance-Audit    Ready
Daily-Security-Monitor      Ready
Archive-Old-Reports         Ready
Detect-Configuration-Drift  Ready
Monitor-Windows-Updates     Ready
```

---

## Manual Task Execution (Testing)

Test a task manually without waiting for its scheduled time:

```powershell
# Example: Run Daily-Security-Monitor now
schtasks /run /tn "Hardening\Daily-Security-Monitor"
```

---

## View Task Logs

### Option 1: Event Viewer (GUI)

```powershell
eventvwr.msc
# Navigate to: Windows Logs -> System
# Filter by Task Scheduler (source)
```

### Option 2: PowerShell

```powershell
# View last 10 events for a specific task
Get-EventLog -LogName System -Source "TaskScheduler" -Newest 10
```

---

## Troubleshooting

### Issue: "This script must run as ADMINISTRATOR"

**Solution:** Right-click PowerShell, select "Run as Administrator"

### Issue: "Some scripts are missing"

**Solution:** Verify all automation scripts exist:
```powershell
ls C:\Repos\WinHarden\scripts\*.ps1 | Where-Object { $_.Name -like '*Compliance*', '*Monitor*', '*Archive*', '*Drift*', '*Update*' }
```

### Issue: Tasks not appearing in Task Scheduler

**Solution:** Run verification command:
```powershell
Get-ScheduledTask -TaskPath '\Hardening\*' | Measure-Object
# Should show Count: 5
```

---

## Advanced Options

### Option: Force Overwrite Existing Tasks

```powershell
.\Set-ScheduledTasksHardening.ps1 -Force
```

### Option: Cleanup & Reinstall

```powershell
.\Set-ScheduledTasksHardening.ps1 -Cleanup -Force
```

### Option: Remove All Tasks

```powershell
Get-ScheduledTask -TaskPath '\Hardening\*' | Unregister-ScheduledTask -Confirm:$false
```

---

## Next Steps

1. **Review Reports:** Check `C:\Repos\WinHarden\logs\` for audit reports
2. **Monitor Execution:** Review task history in Event Viewer
3. **Adjust Schedules (optional):** Right-click task in Task Scheduler -> Properties -> Triggers
4. **Enable Notifications (optional):** Configure alerts for failed tasks

---

## Support

For detailed configuration options, see [02_AUTOMATION_SETUP_GUIDE.md](./02_AUTOMATION_SETUP_GUIDE.md)
For catchup & recovery settings, see [03_CATCHUP_CONFIGURATION_GUIDE.md](./03_CATCHUP_CONFIGURATION_GUIDE.md)

---

**Last Updated:** 2026-06-26  
**Script Version:** 1.0  
**Tested On:** Windows 11 Pro, Windows Server 2019
