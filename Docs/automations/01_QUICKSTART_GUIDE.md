# WinHarden Automations - Quickstart Guide

**Get WinHarden automation tasks running in under 5 minutes.**

---

## Table of Contents

1. [System Requirements](#system-requirements)
2. [5-Minute Installation](#5-minute-installation)
3. [What Gets Installed](#what-gets-installed)
4. [Verify Installation](#verify-installation)
5. [Next Steps](#next-steps)

---

## System Requirements

Before you start, verify you have:

- **Windows Server 2016+** or **Windows 10/11**
- **PowerShell 5.1+** (built into Windows 7+)
- **Administrator privileges** (required for Task Scheduler access)
- **WinHarden repository** cloned to `<WINHARDEN_REPO>`
- **Network access** (for Windows Update checks, compliance verification)

**Quick Check:**
```powershell
# Run these commands to verify readiness
$PSVersionTable.PSVersion
Write-Host "PowerShell version OK"

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
Write-Host "Administrator: $(if($isAdmin) { 'YES' } else { 'NO - RESTART AS ADMIN' })"

Test-Path "<WINHARDEN_REPO>"
Write-Host "Repository path OK"
```

---

## 5-Minute Installation

### Step 1: Open PowerShell as Administrator (30 seconds)

```powershell
# Method 1: Win + X, then select "PowerShell (Admin)"
# Method 2: Win + R, type "powershell", press Ctrl+Shift+Enter
# Method 3: Search "PowerShell", right-click, "Run as administrator"
```

**Verify admin mode:** The title bar should show "Administrator: Windows PowerShell"

### Step 2: Navigate to Scripts Directory (30 seconds)

```powershell
cd <WINHARDEN_REPO>\scripts
```

Verify you're in the correct directory:
```powershell
ls *.ps1 | Select-Object Name

# Expected output includes:
# Set-ScheduledTasksHardening.ps1
# Monitor_Audit_Logs.ps1
# Monitor_Windows_Updates.ps1
# Detect_Security_Drift.ps1
# Monthly_Compliance_Audit.ps1
# Archive_Old_Reports.ps1
```

### Step 3: Run Installation Script (3 minutes)

```powershell
.\Set-ScheduledTasksHardening.ps1
```

**Expected Output:**
```
[STEP 1] Admin Rights Verification
  [OK] Running with administrator privileges

[STEP 2] Automation Scripts Check
  [OK] Monitor_Audit_Logs.ps1 found
  [OK] Monitor_Windows_Updates.ps1 found
  [OK] Detect_Security_Drift.ps1 found
  [OK] Monthly_Compliance_Audit.ps1 found
  [OK] Archive_Old_Reports.ps1 found

[STEP 3] Task Definitions
  [OK] 5 task definitions loaded

[STEP 5] Task Creation
  [OK] Daily-Security-Monitor created
  [OK] Monitor-Windows-Updates created
  [OK] Detect-Configuration-Drift created
  [OK] Monthly-Compliance-Audit created
  [OK] Archive-Old-Reports created

[STEP 7] SUMMARY - All tasks created successfully
```

### Step 4: Verify Installation (1 minute)

```powershell
Get-ScheduledTask -TaskPath '\Hardening\*' | Format-Table TaskName, State, Enabled

# All tasks should show State=Ready, Enabled=True
```

---

## What Gets Installed

Five automated security and compliance tasks are created:

| Task Name | Schedule | Runs | Purpose |
|-----------|----------|------|---------|
| Daily-Security-Monitor | Daily | 09:00 AM | Real-time threat detection from audit logs |
| Monitor-Windows-Updates | Weekly | Mon 08:00 AM | Check for available security patches |
| Detect-Configuration-Drift | Weekly | Mon 10:00 AM | Detect unauthorized configuration changes |
| Monthly-Compliance-Audit | Monthly | 1st day, 08:00 AM | Full compliance verification |
| Archive-Old-Reports | Monthly | 2nd day, 09:00 AM | Archive reports older than 6 months |

**Output Directory:** All results saved to `<WINHARDEN_REPO>\logs\`

---

## Verify Installation

### Method 1: Task Scheduler GUI (Easiest)

```powershell
# Open Task Scheduler
taskschd.msc
```

1. In left panel, navigate to: **Task Scheduler Library** -> **Hardening**
2. You should see all 5 tasks listed
3. Each task should show **Status: Ready**

### Method 2: PowerShell Command

```powershell
# List all Hardening tasks with status
Get-ScheduledTask -TaskPath '\Hardening\*' | Format-Table TaskName, State, Enabled -AutoSize

# Check detailed info for one task
Get-ScheduledTask -TaskName "Daily-Security-Monitor" | Get-ScheduledTaskInfo
```

### Method 3: Test Task Execution

```powershell
# Manually run a task to verify it works
schtasks /run /tn "Hardening\Daily-Security-Monitor"

# Wait a moment and check for logs
Start-Sleep -Seconds 5
ls <WINHARDEN_REPO>\logs\daily_security_*.csv
```

---

## Troubleshooting Quick Fixes

### Issue: "This script must run as ADMINISTRATOR"

**Fix:** Close PowerShell and re-open as Administrator
```powershell
# Verify admin mode
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
if ($isAdmin) { Write-Host "Admin mode OK" } else { Write-Host "NOT admin - restart PowerShell as Admin" }
```

### Issue: "Some scripts are missing"

**Fix:** Verify all automation scripts exist
```powershell
$required = @(
    "Monitor_Audit_Logs.ps1",
    "Monitor_Windows_Updates.ps1", 
    "Detect_Security_Drift.ps1",
    "Monthly_Compliance_Audit.ps1",
    "Archive_Old_Reports.ps1"
)

foreach ($script in $required) {
    $path = "<WINHARDEN_REPO>\scripts\$script"
    $status = if (Test-Path $path) { "[OK]" } else { "[MISSING]" }
    Write-Host "$script $status"
}
```

### Issue: Installation fails with permission error

**Fix:** Verify logs directory is writable
```powershell
# Test write permission
$testFile = "<WINHARDEN_REPO>\logs\test_write.txt"
"test" | Out-File -FilePath $testFile -ErrorAction SilentlyContinue

if (Test-Path $testFile) {
    Remove-Item $testFile
    Write-Host "Logs directory is writable [OK]"
} else {
    Write-Host "Cannot write to logs directory [ERROR]"
    Write-Host "Run: icacls <WINHARDEN_REPO>\logs /grant:r '%USERNAME%:(F)'"
}
```

### Issue: Tasks created but not running

**Fix:** Check Task Scheduler allowed actions
```powershell
# Enable task execution if disabled
Enable-ScheduledTask -TaskName "Daily-Security-Monitor"

# Verify enabled
Get-ScheduledTask -TaskName "Daily-Security-Monitor" | Select-Object TaskName, Enabled
```

---

## Next Steps

### Immediate (Now)
1. [x] Installation complete
2. [ ] Run `/verify` command to test execution
3. [ ] Check Event Viewer for task execution logs

### Short-term (This week)
1. [ ] Review output logs in `<WINHARDEN_REPO>\logs\`
2. [ ] Verify daily/weekly tasks are creating reports
3. [ ] Check Event Viewer for any task errors

### Ongoing (Weekly/Monthly)
1. [ ] Monitor task execution in Event Viewer
2. [ ] Review compliance reports
3. [ ] Adjust task schedules if needed (see Setup Guide)
4. [ ] Verify logs are being archived properly

### Learn More
- **Detailed Configuration:** See [02_AUTOMATION_SETUP_GUIDE.md](02_AUTOMATION_SETUP_GUIDE.md)
- **Catchup & Recovery:** See [03_CATCHUP_CONFIGURATION_GUIDE.md](03_CATCHUP_CONFIGURATION_GUIDE.md)

---

## Common Commands Reference

```powershell
# List all Hardening tasks
Get-ScheduledTask -TaskPath '\Hardening\*'

# Run a task immediately
schtasks /run /tn "Hardening\Daily-Security-Monitor"

# Disable a task
Disable-ScheduledTask -TaskName "Monthly-Compliance-Audit"

# Enable a task
Enable-ScheduledTask -TaskName "Monthly-Compliance-Audit"

# Check logs directory
ls <WINHARDEN_REPO>\logs\ | Sort-Object LastWriteTime -Descending | Select-Object Name, LastWriteTime -First 10

# View recent task execution events
Get-EventLog -LogName System -Source "TaskScheduler" -Newest 20 | Format-Table TimeGenerated, Message
```

---

**Installation completed:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  
**Document Version:** 2.0  
**Last Updated:** 2026-06-27  
**Target Audience:** System Administrators, First-time Users
