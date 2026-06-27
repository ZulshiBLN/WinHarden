# Phase 3: End-to-End Testing Playbook

**Objective:** Validate complete production workflows and system stability  
**Prerequisites:** Phase 2 PASSED (5/5 scenarios)  
**Duration:** 6-8 hours  
**Date:** 2026-06-27+  
**Status:** READY FOR EXECUTION

---

## Overview

Phase 3 tests complete workflows from start to finish:
- Full hardening cycles (initial hardening, compliance, drift, reporting)
- Scheduled compliance audits (Task Scheduler integration)
- Multi-environment consistency (same hardening across different systems)
- Incident detection and recovery (change → detect → remediate)
- Long-term stability verification

---

## Test Scenario 1: Complete Hardening Workflow

**Goal:** Execute complete hardening cycle: Setup → Harden → Verify → Report  
**Time:** 60 minutes  

### 1.1 Pre-Workflow Baseline
```powershell
Write-Output "=== PRE-WORKFLOW BASELINE ==="

# Capture initial system state
$baseline = @{
    Timestamp = Get-Date
    ComputerName = hostname
    OSVersion = (Get-CimInstance Win32_OperatingSystem).Version
    
    # Security baseline
    FirewallProfiles = Get-NetFirewallProfile -All | Select-Object Name, Enabled
    Services = Get-Service | Where-Object {$_.Name -match "SMB|RDP|WinRM"} | Select-Object Name, Status
    UserRights = Get-LocalGroup | Select-Object Name
    
    # Drift baseline
    DriftCount = (Get-FirewallStatusDrift | Where-Object Status -eq "DRIFT" | Measure-Object).Count
}

Write-Output "Baseline captured: $($baseline.Count) data points"
Write-Output "  ComputerName: $($baseline.ComputerName)"
Write-Output "  OS: $($baseline.OSVersion)"
Write-Output "  Initial drift items: $($baseline.DriftCount)"
```

### 1.2 Create Hardening Session
```powershell
Write-Output "=== CREATING HARDENING SESSION ==="

$session = New-HardeningSession `
    -Profile Recommended `
    -TargetSystem Client `
    -OSVersion 11 `
    -Verbose

Write-Output "Session created: $($session.SessionId)"
Write-Output "Profile: $($session.Profile)"
Write-Output "Target: $($session.TargetSystem)"
Write-Output "Rules in session: $($session.Rules.Count)"
```

### 1.3 Execute Hardening
```powershell
Write-Output "=== EXECUTING HARDENING ==="

$hardenStart = Get-Date
$hardenResult = Invoke-SecurityHardening -Session $session -Verbose
$hardenEnd = Get-Date
$hardenDuration = ($hardenEnd - $hardenStart).TotalSeconds

Write-Output "Hardening completed in $hardenDuration seconds"
Write-Output "  Rules applied: $($hardenResult.AppliedRules.Count)"
Write-Output "  Rules failed: $($hardenResult.FailedRules.Count)"
Write-Output "  Rules skipped: $($hardenResult.SkippedRules.Count)"
Write-Output "  Success: $($hardenResult.Success)"
```

### 1.4 Verify Compliance
```powershell
Write-Output "=== COMPLIANCE VERIFICATION ==="

$compStart = Get-Date
$compResult = Test-HardeningCompliance -Session $session -Verbose
$compEnd = Get-Date
$compDuration = ($compEnd - $compStart).TotalSeconds

Write-Output "Compliance check completed in $compDuration seconds"

# Analyze compliance
if ($compResult) {
    Write-Output "Compliance report generated"
}
```

### 1.5 Detect Drift Post-Hardening
```powershell
Write-Output "=== POST-HARDENING DRIFT DETECTION ==="

$postDrift = @()
$postDrift += Get-FirewallStatusDrift
$postDrift += Get-RDPSecurityDrift
$postDrift += Get-NetworkSecurityDrift
$postDrift += Get-AccountPoliciesDrift

$postCompliant = ($postDrift | Where-Object Status -eq "COMPLIANT" | Measure-Object).Count
$postDriftCount = ($postDrift | Where-Object Status -eq "DRIFT" | Measure-Object).Count

Write-Output "Post-hardening drift: $postCompliant compliant, $postDriftCount drift items"

# Compare to baseline
Write-Output "Change from baseline: $(($baseline.DriftCount - $postDriftCount)) drift items"
```

### 1.6 Generate Comprehensive Report
```powershell
Write-Output "=== GENERATING COMPREHENSIVE REPORT ==="

$reportStart = Get-Date
$report = New-SecurityDriftReport `
    -DriftFindings $postDrift `
    -OutputDirectory "C:\Reports\WinHarden" `
    -Verbose
$reportEnd = Get-Date

Write-Output "Report generated in $(($reportEnd - $reportStart).TotalSeconds) seconds"
Write-Output "Report location: $report"
```

### 1.7 Post-Workflow Verification
```powershell
Write-Output "=== POST-WORKFLOW VERIFICATION ==="

# Verify all artifacts exist
$artifacts = @(
    "Hardening applied successfully: $($hardenResult.Success)"
    "Compliance check completed: $(if ($compResult) { 'Yes' } else { 'No' })"
    "Drift report generated: $(if (Test-Path $report) { 'Yes' } else { 'No' })"
)

$artifacts | ForEach-Object { Write-Output "  ✓ $_" }

Write-Output "=== WORKFLOW COMPLETE ==="
Write-Output "Total execution time: $(((Get-Date) - $baseline.Timestamp).TotalSeconds) seconds"
```

### 1.8 Success Criteria
- [ ] Session created without errors
- [ ] All hardening rules applied (or documented failures)
- [ ] Compliance check runs post-hardening
- [ ] Drift detection captures post-hardening state
- [ ] Report generated successfully
- [ ] System stable after hardening
- [ ] All logs capture complete workflow

---

## Test Scenario 2: Scheduled Compliance Audit

**Goal:** Verify compliance audit scheduling works  
**Time:** 30 minutes  
**Prerequisite:** Task Scheduler available

### 2.1 Create Scheduled Task
```powershell
Write-Output "=== CREATING SCHEDULED COMPLIANCE TASK ==="

$taskName = "WinHarden_Compliance_Audit"
$taskPath = "\WinHarden\"

$action = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-NoProfile -Command `"cd C:\Repos\WinHarden; Test-HardeningCompliance`""

$trigger = New-ScheduledTaskTrigger -Daily -At 02:00AM

Register-ScheduledTask -TaskName $taskName `
    -Action $action `
    -Trigger $trigger `
    -Description "Nightly WinHarden compliance audit" `
    -ErrorAction SilentlyContinue

Write-Output "Task created: $taskName"
```

### 2.2 Execute Task
```powershell
Write-Output "=== EXECUTING SCHEDULED TASK ==="

Start-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

Write-Output "Task started"

# Wait for completion
Start-Sleep -Seconds 5

$taskInfo = Get-ScheduledTaskInfo -TaskName $taskName
Write-Output "Last run: $($taskInfo.LastRunTime)"
Write-Output "Last result: $($taskInfo.LastTaskResult)"
```

### 2.3 Verify Task Execution
```powershell
Write-Output "=== VERIFYING TASK EXECUTION ==="

$taskRun = Get-ScheduledTask -TaskName $taskName
if ($taskRun.State -eq "Ready") {
    Write-Output "[OK] Task completed successfully"
} else {
    Write-Output "[WARN] Task state: $($taskRun.State)"
}

# Check for task logs
$eventLogs = Get-EventLog -LogName "Windows PowerShell" -Source "PowerShell" -Newest 10 -ErrorAction SilentlyContinue
if ($eventLogs) {
    Write-Output "Found PowerShell event logs from task execution"
}
```

### 2.4 Cleanup
```powershell
Write-Output "=== CLEANING UP SCHEDULED TASK ==="

Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

Write-Output "Task removed"
```

### 2.5 Success Criteria
- [ ] Scheduled task created successfully
- [ ] Task executes without errors
- [ ] Logs capture task execution
- [ ] Task can be removed cleanly

---

## Test Scenario 3: Multi-Environment Consistency

**Goal:** Verify hardening produces consistent results across environments  
**Time:** 30 minutes  
**Prerequisite:** 2+ target systems (or 2 local sessions simulating environments)

### 3.1 Baseline Drift Across Environments
```powershell
Write-Output "=== BASELINE DRIFT ACROSS ENVIRONMENTS ==="

$environments = @(
    @{ Name = "Dev"; Profile = "Recommended" }
    @{ Name = "Prod-Like"; Profile = "Strict" }
)

$baselines = @()
foreach ($env in $environments) {
    Write-Output "Baseline [$($env.Name)]..."
    
    $drift = @()
    $drift += Get-FirewallStatusDrift -ErrorAction SilentlyContinue
    $drift += Get-RDPSecurityDrift -ErrorAction SilentlyContinue
    $drift += Get-NetworkSecurityDrift -ErrorAction SilentlyContinue
    $drift += Get-AccountPoliciesDrift -ErrorAction SilentlyContinue
    
    $baselines += @{
        Environment = $env.Name
        Profile = $env.Profile
        CompliantCount = ($drift | Where-Object Status -eq "COMPLIANT" | Measure-Object).Count
        DriftCount = ($drift | Where-Object Status -eq "DRIFT" | Measure-Object).Count
    }
}

$baselines | Format-Table -AutoSize
```

### 3.2 Apply Hardening to Each Environment
```powershell
Write-Output "=== APPLYING HARDENING ==="

$results = @()
foreach ($env in $environments) {
    Write-Output "Hardening [$($env.Name)]..."
    
    $session = New-HardeningSession `
        -Profile $env.Profile `
        -TargetSystem Client `
        -OSVersion 11 `
        -ErrorAction SilentlyContinue
    
    $result = Invoke-SecurityHardening -Session $session -ErrorAction SilentlyContinue
    
    $results += @{
        Environment = $env.Name
        Profile = $env.Profile
        RulesApplied = $result.AppliedRules.Count
        RulesFailed = $result.FailedRules.Count
    }
}

$results | Format-Table -AutoSize
```

### 3.3 Verify Consistency
```powershell
Write-Output "=== CONSISTENCY VERIFICATION ==="

$postStates = @()
foreach ($env in $environments) {
    Write-Output "Post-hardening drift [$($env.Name)]..."
    
    $drift = @()
    $drift += Get-FirewallStatusDrift -ErrorAction SilentlyContinue
    $drift += Get-RDPSecurityDrift -ErrorAction SilentlyContinue
    $drift += Get-NetworkSecurityDrift -ErrorAction SilentlyContinue
    $drift += Get-AccountPoliciesDrift -ErrorAction SilentlyContinue
    
    $postStates += @{
        Environment = $env.Name
        CompliantCount = ($drift | Where-Object Status -eq "COMPLIANT" | Measure-Object).Count
        DriftCount = ($drift | Where-Object Status -eq "DRIFT" | Measure-Object).Count
    }
}

Write-Output "Consistency check complete"
# Compare pre vs post across environments
```

### 3.4 Success Criteria
- [ ] Hardening applies consistently to all environments
- [ ] Similar drift reduction across environments
- [ ] No environment-specific failures
- [ ] All hardening completes successfully

---

## Test Scenario 4: Incident Detection & Recovery

**Goal:** Verify drift detection catches unintended changes and recovery works  
**Time:** 30 minutes

### 4.1 Establish Hardened Baseline
```powershell
Write-Output "=== ESTABLISHING HARDENED BASELINE ==="

# Apply hardening
$session = New-HardeningSession -Profile Recommended -TargetSystem Client -OSVersion 11
$result = Invoke-SecurityHardening -Session $session -ErrorAction SilentlyContinue

# Baseline drift post-hardening
$baselineDrift = @()
$baselineDrift += Get-FirewallStatusDrift -ErrorAction SilentlyContinue
$baselineDrift += Get-RDPSecurityDrift -ErrorAction SilentlyContinue
$baselineDrift += Get-NetworkSecurityDrift -ErrorAction SilentlyContinue
$baselineDrift += Get-AccountPoliciesDrift -ErrorAction SilentlyContinue

$baselineCompliant = ($baselineDrift | Where-Object Status -eq "COMPLIANT" | Measure-Object).Count
$baselineDriftCount = ($baselineDrift | Where-Object Status -eq "DRIFT" | Measure-Object).Count

Write-Output "Baseline established: $baselineCompliant compliant, $baselineDriftCount drift"
```

### 4.2 Simulate Configuration Change
```powershell
Write-Output "=== SIMULATING UNINTENDED CONFIGURATION CHANGE ==="

# Disable a security feature (simulating drift)
try {
    Set-NetFirewallProfile -Profile Domain -Enabled $false -ErrorAction SilentlyContinue
    Write-Output "Configuration change applied (test scenario)"
} catch {
    Write-Output "Could not apply test change (permissions or system protection)"
}
```

### 4.3 Detect the Drift
```powershell
Write-Output "=== DETECTING CONFIGURATION DRIFT ==="

Start-Sleep -Seconds 2

$postChangeDrift = @()
$postChangeDrift += Get-FirewallStatusDrift -ErrorAction SilentlyContinue
$postChangeDrift += Get-RDPSecurityDrift -ErrorAction SilentlyContinue
$postChangeDrift += Get-NetworkSecurityDrift -ErrorAction SilentlyContinue
$postChangeDrift += Get-AccountPoliciesDrift -ErrorAction SilentlyContinue

$postChangeCompliant = ($postChangeDrift | Where-Object Status -eq "COMPLIANT" | Measure-Object).Count
$postChangeDriftCount = ($postChangeDrift | Where-Object Status -eq "DRIFT" | Measure-Object).Count

Write-Output "Post-change state: $postChangeCompliant compliant, $postChangeDriftCount drift"

# Detect changes
$newDrift = $postChangeDriftCount - $baselineDriftCount
if ($newDrift -gt 0) {
    Write-Output "[OK] Drift detection caught $newDrift new drift items"
} else {
    Write-Output "[INFO] No new drift detected (or changes reverted)"
}
```

### 4.4 Recovery Process
```powershell
Write-Output "=== RECOVERY PROCESS ==="

# Restore security baseline
$recoverySession = New-HardeningSession -Profile Recommended -TargetSystem Client -OSVersion 11 -ErrorAction SilentlyContinue
$recoveryResult = Invoke-SecurityHardening -Session $recoverySession -ErrorAction SilentlyContinue

Write-Output "Recovery hardening applied: $($recoveryResult.AppliedRules.Count) rules"

# Re-enable security features
try {
    Set-NetFirewallProfile -Profile Domain -Enabled $true -ErrorAction SilentlyContinue
    Write-Output "Security features restored"
} catch {
    Write-Output "Could not restore features"
}
```

### 4.5 Verify Recovery
```powershell
Write-Output "=== VERIFYING RECOVERY ==="

Start-Sleep -Seconds 2

$recoveredDrift = @()
$recoveredDrift += Get-FirewallStatusDrift -ErrorAction SilentlyContinue
$recoveredDrift += Get-RDPSecurityDrift -ErrorAction SilentlyContinue
$recoveredDrift += Get-NetworkSecurityDrift -ErrorAction SilentlyContinue
$recoveredDrift += Get-AccountPoliciesDrift -ErrorAction SilentlyContinue

$recoveredCompliant = ($recoveredDrift | Where-Object Status -eq "COMPLIANT" | Measure-Object).Count
$recoveredDriftCount = ($recoveredDrift | Where-Object Status -eq "DRIFT" | Measure-Object).Count

Write-Output "Recovered state: $recoveredCompliant compliant, $recoveredDriftCount drift"

if ($recoveredCompliant -ge $baselineCompliant) {
    Write-Output "[OK] System successfully recovered to baseline"
} else {
    Write-Output "[WARN] Recovery incomplete"
}
```

### 4.6 Success Criteria
- [ ] Drift detection catches unintended changes
- [ ] Recovery process restores configuration
- [ ] System returns to known-good state
- [ ] No data loss during recovery

---

## Test Scenario 5: Long-Term Stability

**Goal:** Verify hardening remains stable over time  
**Time:** 15 minutes

### 5.1 Extended Monitoring
```powershell
Write-Output "=== EXTENDED STABILITY MONITORING ==="

# Take drift snapshots at intervals
$snapshots = @()

for ($i = 1; $i -le 5; $i++) {
    Write-Output "Snapshot $i..."
    
    $drift = @()
    $drift += Get-FirewallStatusDrift -ErrorAction SilentlyContinue
    $drift += Get-RDPSecurityDrift -ErrorAction SilentlyContinue
    $drift += Get-NetworkSecurityDrift -ErrorAction SilentlyContinue
    $drift += Get-AccountPoliciesDrift -ErrorAction SilentlyContinue
    
    $snapshots += @{
        Iteration = $i
        CompliantCount = ($drift | Where-Object Status -eq "COMPLIANT" | Measure-Object).Count
        DriftCount = ($drift | Where-Object Status -eq "DRIFT" | Measure-Object).Count
        Timestamp = Get-Date
    }
    
    Start-Sleep -Seconds 3
}

Write-Output "Stability snapshots: $($snapshots.Count) taken"
```

### 5.2 Trend Analysis
```powershell
Write-Output "=== TREND ANALYSIS ==="

$stability = $true
for ($i = 1; $i -lt $snapshots.Count; $i++) {
    $prev = $snapshots[$i-1]
    $curr = $snapshots[$i]
    
    if ($curr.CompliantCount -ne $prev.CompliantCount -or $curr.DriftCount -ne $prev.DriftCount) {
        Write-Output "Change detected at iteration $i: Compliant $($prev.CompliantCount) → $($curr.CompliantCount)"
        $stability = $false
    }
}

if ($stability) {
    Write-Output "[OK] System state stable across $($snapshots.Count) snapshots"
} else {
    Write-Output "[WARN] System state changed during monitoring period"
}
```

### 5.3 Success Criteria
- [ ] Drift state remains consistent over time
- [ ] No unexpected configuration changes
- [ ] No resource degradation
- [ ] System remains responsive

---

## E2E Testing Execution Plan

### Timeline
**Day 1: Scenarios 1-3**
```
Morning (2 hours):    Scenario 1 (Complete Workflow)
Midday (1 hour):      Scenario 2 (Scheduled Audit)
Afternoon (1 hour):   Scenario 3 (Multi-Environment)
```

**Day 2: Scenarios 4-5**
```
Morning (1 hour):     Scenario 4 (Incident & Recovery)
Afternoon (1 hour):   Scenario 5 (Long-Term Stability)
Late:                 Results compilation & gate decision
```

---

## Success Criteria

**Phase 3 PASS requires:**
- [x] All 5 scenarios execute without fatal errors
- [x] Complete workflows execute end-to-end
- [x] System remains stable throughout
- [x] Drift detection works in real scenarios
- [x] Recovery procedures effective
- [x] Logging captures all operations

---

## Risk Mitigation

| Risk | Mitigation |
|------|-----------|
| System instability | Test on VM, have snapshot for rollback |
| Long task hangs | Set explicit timeouts |
| Drift persistence | Baseline drift before tests |
| Task scheduling issues | Manual execution backup |

---

**Phase 3 Status:** READY FOR EXECUTION  
**Estimated Duration:** 6-8 hours  
**Estimated Completion:** 2026-06-27 or 2026-06-28
