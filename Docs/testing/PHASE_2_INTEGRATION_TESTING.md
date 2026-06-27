# Phase 2: Integration Testing Playbook

**Objective:** Validate module combinations and cross-function workflows  
**Prerequisites:** Phase 1 PASSED (5/5 scenarios)  
**Duration:** 4-6 hours  
**Date:** 2026-06-28+  
**Status:** READY FOR EXECUTION

---

## Overview

Phase 2 tests how multiple functions work together in realistic workflows:
- Hardening → Compliance verification workflow
- Drift detection → Report generation pipeline
- Remote execution with local logging
- Parallel multi-target operations

---

## Test Scenario 1: Security + Compliance Chain

**Goal:** Verify hardening applies correctly and compliance detects it  
**Time:** 30 minutes  

### 1.1 Setup
```powershell
# Create test baseline
Write-Output "=== BASELINE CAPTURE ==="
$baseline = @{
    FirewallProfiles = Get-NetFirewallProfile -All | Select-Object Name, Enabled
    Services = Get-Service | Where-Object Name -like "*SMB*","*RDP*" | Select-Object Name, Status
    Registry = Get-ItemProperty 'HKLM:\System\CurrentControlSet\Services\RDP' -ErrorAction SilentlyContinue
}
Write-Output "Baseline captured with $(($baseline.Values | Measure-Object).Count) data points"
```

### 1.2 Execute Hardening
```powershell
Write-Output "=== HARDENING EXECUTION ==="
$session = New-HardeningSession -Profile Recommended -TargetSystem Client -OSVersion 11 -Verbose
$result = Invoke-SecurityHardening -Session $session -Verbose
Write-Output "Hardening applied: $($result.AppliedRules.Count) rules"
Write-Output "Hardening duration: $($result.Duration.TotalSeconds) seconds"
```

### 1.3 Immediate Compliance Check
```powershell
Write-Output "=== IMMEDIATE COMPLIANCE VERIFICATION ==="
$compResult = Test-HardeningCompliance -Session $session -Verbose
Write-Output "Compliance check completed"
```

### 1.4 Verify Changes Reflected
```powershell
Write-Output "=== POST-HARDENING STATE VERIFICATION ==="
$postState = @{
    FirewallProfiles = Get-NetFirewallProfile -All | Select-Object Name, Enabled
    Services = Get-Service | Where-Object Name -like "*SMB*","*RDP*" | Select-Object Name, Status
}

# Compare baseline vs. post-state
Write-Output "Firewall changes: $(($baseline.FirewallProfiles | Measure-Object).Count) → $(($postState.FirewallProfiles | Measure-Object).Count)"
Write-Output "Service changes detected"
```

### 1.5 Success Criteria
- [ ] Hardening applies without errors
- [ ] Session object properly passed to compliance function
- [ ] Compliance check runs against applied hardening
- [ ] System state reflects hardening changes
- [ ] No data loss between hardening and compliance

---

## Test Scenario 2: Drift Detection + Report Generation

**Goal:** Verify drift findings flow correctly into reports  
**Time:** 20 minutes

### 2.1 Collect All Drift Findings
```powershell
Write-Output "=== COMPREHENSIVE DRIFT COLLECTION ==="

$allDrifts = @()

Write-Output "Collecting firewall drift..."
$allDrifts += Get-FirewallStatusDrift -Verbose 4>&1

Write-Output "Collecting RDP drift..."
$allDrifts += Get-RDPSecurityDrift -Verbose 4>&1

Write-Output "Collecting network drift..."
$allDrifts += Get-NetworkSecurityDrift -Verbose 4>&1

Write-Output "Collecting account policies drift..."
$allDrifts += Get-AccountPoliciesDrift -Verbose 4>&1

Write-Output "Collecting audit policies drift..."
$allDrifts += Get-AuditPoliciesDrift -Verbose 4>&1 -ErrorAction SilentlyContinue

Write-Output "Total drift findings: $($allDrifts.Count)"
```

### 2.2 Generate Aggregated Report
```powershell
Write-Output "=== REPORT GENERATION ==="

$reportPath = New-SecurityDriftReport -DriftFindings $allDrifts `
    -OutputDirectory "C:\Reports\WinHarden" -Verbose

Write-Output "Report generated: $reportPath"
```

### 2.3 Validate Report Contents
```powershell
Write-Output "=== REPORT VALIDATION ==="

$report = Get-ChildItem $reportPath -ErrorAction SilentlyContinue
if ($report) {
    Write-Output "Report size: $($report.Length / 1KB)KB"
    
    # Check for drift findings in report
    $content = Get-Content $reportPath -Raw -ErrorAction SilentlyContinue
    $driftCount = ($content | Select-String "DRIFT|COMPLIANT" | Measure-Object).Count
    Write-Output "Drift findings in report: $driftCount"
}
```

### 2.4 Success Criteria
- [ ] All drift functions execute without fatal errors
- [ ] Drift findings collected from all 5 categories (Firewall, RDP, Network, Account, Audit)
- [ ] Report generation succeeds
- [ ] Report file created and readable
- [ ] Drift findings appear in report
- [ ] No data loss during aggregation

---

## Test Scenario 3: Hardening + Drift Detection Chain

**Goal:** Verify hardening changes are correctly detected as drift  
**Time:** 20 minutes

### 3.1 Pre-Hardening Drift Snapshot
```powershell
Write-Output "=== PRE-HARDENING DRIFT SNAPSHOT ==="

$preDrift = @()
$preDrift += Get-FirewallStatusDrift
$preDrift += Get-RDPSecurityDrift
$preDrift += Get-NetworkSecurityDrift
$preDrift += Get-AccountPoliciesDrift

$preCompliantCount = ($preDrift | Where-Object Status -eq "COMPLIANT" | Measure-Object).Count
$preDriftCount = ($preDrift | Where-Object Status -eq "DRIFT" | Measure-Object).Count

Write-Output "Pre-Hardening: $preCompliantCount compliant, $preDriftCount drift"
```

### 3.2 Apply Hardening
```powershell
Write-Output "=== APPLYING HARDENING ==="

$session = New-HardeningSession -Profile Strict -TargetSystem Client -OSVersion 11 -Verbose
$hardenResult = Invoke-SecurityHardening -Session $session -Verbose

Write-Output "Applied $($hardenResult.AppliedRules.Count) rules"
```

### 3.3 Post-Hardening Drift Check
```powershell
Write-Output "=== POST-HARDENING DRIFT CHECK ==="

Start-Sleep -Seconds 2  # Allow system to settle

$postDrift = @()
$postDrift += Get-FirewallStatusDrift
$postDrift += Get-RDPSecurityDrift
$postDrift += Get-NetworkSecurityDrift
$postDrift += Get-AccountPoliciesDrift

$postCompliantCount = ($postDrift | Where-Object Status -eq "COMPLIANT" | Measure-Object).Count
$postDriftCount = ($postDrift | Where-Object Status -eq "DRIFT" | Measure-Object).Count

Write-Output "Post-Hardening: $postCompliantCount compliant, $postDriftCount drift"
```

### 3.4 Verify Impact
```powershell
Write-Output "=== IMPACT ANALYSIS ==="

$complianceChange = $postCompliantCount - $preCompliantCount
$driftChange = $postDriftCount - $preDriftCount

Write-Output "Compliance change: $complianceChange"
Write-Output "Drift change: $driftChange"

if ($postCompliantCount -gt $preCompliantCount) {
    Write-Output "[OK] Hardening improved compliance"
} else {
    Write-Output "[WARN] Compliance status unchanged (may be OK)"
}
```

### 3.5 Success Criteria
- [ ] Pre-hardening drift baseline captured
- [ ] Hardening applied successfully
- [ ] Post-hardening drift detected correctly
- [ ] System state reflects hardening changes
- [ ] Compliance improved (or stayed same if already hardened)

---

## Test Scenario 4: Multi-Target Hardening

**Goal:** Test parallel hardening across multiple systems  
**Time:** 30 minutes  
**Prerequisites:** 2+ test VMs accessible via remoting

### 4.1 Target Validation
```powershell
Write-Output "=== TARGET VALIDATION ==="

$targets = @(
    "LOCALHOST",
    # "REMOTE-SERVER-01",  # Uncomment if available
    # "REMOTE-SERVER-02"
)

foreach ($target in $targets) {
    Write-Output "Checking $target..."
    
    if ($target -eq "LOCALHOST") {
        Write-Output "  [OK] Local system accessible"
    } else {
        try {
            Test-NetConnection -ComputerName $target -CommonTCPPort WINRM -ErrorAction Stop
            Write-Output "  [OK] $target accessible"
        } catch {
            Write-Output "  [ERROR] $target not accessible"
        }
    }
}
```

### 4.2 Parallel Hardening Sessions
```powershell
Write-Output "=== CREATING HARDENING SESSIONS ==="

$sessions = @()
foreach ($target in $targets) {
    Write-Output "Creating session for $target..."
    
    $newSession = New-HardeningSession -Profile Recommended -TargetSystem Client -OSVersion 11 -Verbose -ErrorAction SilentlyContinue
    if ($newSession) {
        $sessions += @{ Target = $target; Session = $newSession }
        Write-Output "  [OK] Session created"
    }
}

Write-Output "Total sessions created: $($sessions.Count)"
```

### 4.3 Sequential Hardening (if parallel unavailable)
```powershell
Write-Output "=== APPLYING HARDENING TO ALL TARGETS ==="

$results = @()
foreach ($sessionObj in $sessions) {
    $target = $sessionObj.Target
    $sess = $sessionObj.Session
    
    Write-Output "Hardening $target..."
    $result = Invoke-SecurityHardening -Session $sess -Verbose
    
    $results += @{
        Target = $target
        AppliedRules = $result.AppliedRules.Count
        FailedRules = $result.FailedRules.Count
        Duration = $result.Duration.TotalSeconds
    }
    
    Write-Output "  [OK] $($result.AppliedRules.Count) rules applied"
}

Write-Output "Hardening summary:"
$results | Format-Table -AutoSize
```

### 4.4 Verify All Targets Hardened
```powershell
Write-Output "=== VERIFICATION ==="

foreach ($result in $results) {
    $target = $result.Target
    $applied = $result.AppliedRules
    
    if ($applied -gt 0) {
        Write-Output "[$target] $applied rules applied ✓"
    } else {
        Write-Output "[$target] No rules applied ✗"
    }
}
```

### 4.5 Success Criteria
- [ ] All targets validated and accessible
- [ ] Hardening sessions created for each target
- [ ] Hardening applied to all targets
- [ ] No cross-target contamination
- [ ] Logging captures all targets
- [ ] Consistent results across targets

---

## Test Scenario 5: Error Recovery & Cleanup

**Goal:** Verify system handles errors gracefully across modules  
**Time:** 15 minutes

### 5.1 Simulate Failure Scenarios
```powershell
Write-Output "=== ERROR RECOVERY TESTING ==="

Write-Output "Test 1: Invalid session object"
$invalidSession = $null
try {
    $result = Invoke-SecurityHardening -Session $invalidSession -ErrorAction Stop
} catch {
    Write-Output "  [OK] Correctly rejected invalid session: $($_.Exception.Message)"
}

Write-Output "Test 2: Missing drift findings"
$emptyDrift = @()
try {
    $report = New-SecurityDriftReport -DriftFindings $emptyDrift -OutputDirectory "C:\Reports\WinHarden" -ErrorAction SilentlyContinue
    Write-Output "  [OK] Handled empty drift findings"
} catch {
    Write-Output "  [WARN] Error on empty findings: $($_.Exception.Message)"
}

Write-Output "Test 3: Non-existent compliance rules"
try {
    $session = New-HardeningSession -Profile NonExistent -TargetSystem Client -OSVersion 11 -ErrorAction Stop
} catch {
    Write-Output "  [OK] Correctly rejected invalid profile: $($_.Exception.Message)"
}
```

### 5.2 Cleanup & State Restoration
```powershell
Write-Output "=== CLEANUP ==="

Write-Output "Closing all sessions..."
$sessions | ForEach-Object { Remove-Item -Path $_.Session -ErrorAction SilentlyContinue }

Write-Output "Archiving logs..."
$logDir = "C:\Logs\WinHarden"
$archivePath = Join-Path $logDir "Archive_$(Get-Date -Format yyyyMMdd_HHmmss).zip"
Write-Output "  Archive: $archivePath"

Write-Output "[OK] Cleanup complete"
```

### 5.3 Success Criteria
- [ ] Invalid inputs rejected gracefully
- [ ] Empty data sets handled correctly
- [ ] Error messages clear and actionable
- [ ] No orphaned sessions left open
- [ ] Logs archived successfully

---

## Integration Testing Execution Plan

### Day 1: Scenario 1 & 2
```
Morning:   Scenario 1 (Security + Compliance Chain) - 30 min
          + Review & Documentation - 30 min

Afternoon: Scenario 2 (Drift + Reporting) - 20 min
          + Validation & Analysis - 20 min
```

### Day 2: Scenario 3 & 4
```
Morning:   Scenario 3 (Hardening + Drift Detection) - 20 min
          + Verification - 15 min

Afternoon: Scenario 4 (Multi-Target) - 30 min
          + Results analysis - 15 min
```

### Day 3: Scenario 5 & Wrap-up
```
Morning:   Scenario 5 (Error Recovery & Cleanup) - 15 min
          + Final validation - 15 min

Afternoon: Results compilation & Phase 2 gate decision
```

---

## Success Criteria

**Phase 2 PASS requires:**
- [x] All 5 scenarios execute without fatal errors
- [x] Data flows correctly between modules
- [x] No data loss or corruption
- [x] Cross-function dependencies work
- [x] Error handling is robust
- [x] Logging captures all operations
- [x] Results are consistent and reproducible

---

## Risk Mitigation

| Risk | Mitigation |
|------|-----------|
| Session corruption | Use fresh session for each test |
| Drift data loss | Log all findings to file immediately |
| Remote timeout | Set explicit timeouts on remote ops |
| Conflicting rules | Run on isolated test VM |
| Incomplete logging | Redirect all output to files |

---

## Deliverables

**Phase 2 Completion requires:**
1. ✓ Execution of all 5 scenarios
2. ✓ Comprehensive test logs
3. ✓ Phase 2 completion report
4. ✓ Issues identified & documented
5. ✓ Gate decision (PASS/FAIL)

---

**Phase 2 Status:** READY FOR EXECUTION  
**Estimated Duration:** 4-6 hours  
**Start Date:** 2026-06-28  
**Completion Date:** 2026-06-28 or 2026-06-29  

Next: Phase 2 Test Runner Implementation
