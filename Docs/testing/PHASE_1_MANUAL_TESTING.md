# Phase 1: Manual Testing Playbook

**Objective:** Validate core WinHarden workflows through hands-on testing  
**Duration:** 2-3 hours per environment  
**Environments:** Dev VM (unrestricted), Prod-like VM (hardened baseline)  
**Date:** 2026-06-27  
**Status:** READY FOR EXECUTION

---

## Setup Requirements

### Pre-Test Checklist

- [ ] PowerShell 5.1+ installed
- [ ] Pester 5.7.1+ installed (`Install-Module Pester -Force`)
- [ ] WinHarden module loaded: `Import-Module ./module/WinHarden.psm1`
- [ ] Administrator PowerShell console
- [ ] Test VMs accessible (local + remote)
- [ ] Logging directory writable: `C:\Logs\WinHarden\`
- [ ] Test reports directory: `C:\Reports\WinHarden\`

### Environment Setup

```powershell
# Load WinHarden module
Import-Module "C:\Repos\WinHarden\module\WinHarden.psm1" -Force -Verbose

# Verify core functions available
$coreFunctions = @(
    'Invoke-SecurityHardening',
    'Test-HardeningCompliance',
    'Get-FirewallDrift',
    'Get-RDPSecurityDrift',
    'Get-NetworkSecurityDrift',
    'Get-AccountPoliciesDrift',
    'New-SecurityDriftReport'
)

foreach ($func in $coreFunctions) {
    if (Get-Command $func -ErrorAction SilentlyContinue) {
        Write-Output "[OK] $func available"
    } else {
        Write-Output "[ERROR] $func NOT available"
    }
}

# Create test directories
@(
    'C:\Logs\WinHarden',
    'C:\Reports\WinHarden'
) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ -Force | Out-Null
        Write-Output "[OK] Created $_"
    }
}
```

---

## Test Scenario 1: Local Hardening (Golden Path)

**Goal:** Execute basic hardening on local machine  
**Expected:** System hardened without errors, logs generated  
**Time:** 10-15 minutes

### 1.1 Pre-Hardening State Check

```powershell
# Baseline: Check current state before hardening
Write-Output "=== PRE-HARDENING STATE ==="
Write-Output "ComputerName: $(hostname)"
Write-Output "OS: $(Get-CimInstance Win32_OperatingSystem | Select-Object Caption)"
Write-Output "PowerShell: $($PSVersionTable.PSVersion)"

# Check key security settings
Get-ItemProperty 'HKLM:\System\CurrentControlSet\Services\RDP' -Name Start -ErrorAction SilentlyContinue | 
    Select-Object @{ L='RDPEnabled'; E={ $_.Start -eq 3 } }

Get-NetFirewallProfile | Select-Object Name, Enabled

Write-Output ""
```

### 1.2 Execute Hardening (WhatIf First)

```powershell
# STEP 1: Preview with WhatIf
Write-Output "=== HARDENING PREVIEW (WhatIf) ==="
Invoke-SecurityHardening -WhatIf -Verbose | 
    Tee-Object -FilePath "C:\Reports\WinHarden\01_hardening_whatif.log"

Write-Output "Review the preview above. Verify changes are acceptable."
Write-Output ""
```

### 1.3 Execute Hardening (Real)

```powershell
# STEP 2: Execute hardening
Write-Output "=== EXECUTING HARDENING ==="
$hardeningResult = Invoke-SecurityHardening -Verbose 4>&1 | 
    Tee-Object -FilePath "C:\Reports\WinHarden\02_hardening_execution.log"

Write-Output "Hardening completed. Checking results..."
Write-Output ""
```

### 1.4 Post-Hardening Validation

```powershell
# STEP 3: Verify hardening applied
Write-Output "=== POST-HARDENING STATE ==="

# Check RDP
$rdpEnabled = (Get-ItemProperty 'HKLM:\System\CurrentControlSet\Services\RDP' -Name Start -ErrorAction SilentlyContinue).Start -eq 3
Write-Output "[$(if ($rdpEnabled) { 'INFO' } else { 'OK' })] RDP enabled: $rdpEnabled (may be intentional)"

# Check Firewall
$fw = Get-NetFirewallProfile -All
Write-Output "[OK] Firewall Status:"
$fw | Select-Object Name, Enabled | Format-Table -AutoSize | Out-String | Write-Output

# Check Windows Defender
$defender = Get-MpComputerStatus -ErrorAction SilentlyContinue
if ($defender) {
    Write-Output "[OK] Defender Real-time: $($defender.RealTimeProtectionEnabled)"
    Write-Output "[OK] Defender Malware: $($defender.IsScanningSupported)"
}

Write-Output ""
```

### 1.5 Verify Logging

```powershell
# STEP 4: Check logs were created
Write-Output "=== LOGGING VERIFICATION ==="

$logDir = "C:\Logs\WinHarden\"
if (Test-Path $logDir) {
    $logs = Get-ChildItem $logDir -Filter "*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 5
    if ($logs) {
        Write-Output "[OK] Found $(($logs | Measure-Object).Count) recent log files:"
        $logs | Select-Object Name, LastWriteTime, @{ L='SizeKB'; E={ [Math]::Round($_.Length/1KB) } } | 
            Format-Table -AutoSize | Out-String | Write-Output
        
        # Show last 20 lines of latest log
        Write-Output "`nLatest log entries:"
        Get-Content $logs[0].FullName -Tail 20 | Write-Output
    } else {
        Write-Output "[ERROR] No logs found in $logDir"
    }
} else {
    Write-Output "[ERROR] Log directory $logDir does not exist"
}

Write-Output ""
```

---

## Test Scenario 2: Compliance Verification

**Goal:** Verify hardening compliance against baseline  
**Expected:** All checks pass, detailed report generated  
**Time:** 5-10 minutes

### 2.1 Run Compliance Check

```powershell
Write-Output "=== COMPLIANCE CHECK ==="

# Run full compliance test
$complianceResult = Test-HardeningCompliance -Verbose 4>&1 | 
    Tee-Object -FilePath "C:\Reports\WinHarden\03_compliance_check.log"

Write-Output ""
```

### 2.2 Analyze Results

```powershell
# Parse compliance results
Write-Output "=== COMPLIANCE SUMMARY ==="

# Check for failures
if ($complianceResult | Select-String "FAILED|Error") {
    Write-Output "[WARN] Some compliance checks failed:"
    $complianceResult | Select-String "FAILED|Error" | Write-Output
} else {
    Write-Output "[OK] All compliance checks passed"
}

# Count pass/fail
$passes = ($complianceResult | Select-String "\[PASS\]|\[OK\]" | Measure-Object).Count
$fails = ($complianceResult | Select-String "\[FAIL\]|\[ERROR\]" | Measure-Object).Count

Write-Output "[OK] Results: $passes passed, $fails failed"
Write-Output ""
```

---

## Test Scenario 3: Drift Detection

**Goal:** Detect configuration drift across multiple categories  
**Expected:** Drift detected, categorized, reported  
**Time:** 15-20 minutes

### 3.1 Firewall Drift Detection

```powershell
Write-Output "=== FIREWALL DRIFT DETECTION ==="

$fwDrift = Get-FirewallDrift -Verbose 4>&1 | 
    Tee-Object -FilePath "C:\Reports\WinHarden\04_firewall_drift.log"

# Show summary
Write-Output "Firewall drift detection completed"
Write-Output ""
```

### 3.2 RDP Security Drift Detection

```powershell
Write-Output "=== RDP SECURITY DRIFT DETECTION ==="

$rdpDrift = Get-RDPSecurityDrift -Verbose 4>&1 | 
    Tee-Object -FilePath "C:\Reports\WinHarden\05_rdp_drift.log"

Write-Output "RDP drift detection completed"
Write-Output ""
```

### 3.3 Network Security Drift Detection

```powershell
Write-Output "=== NETWORK SECURITY DRIFT DETECTION ==="

$netDrift = Get-NetworkSecurityDrift -Verbose 4>&1 | 
    Tee-Object -FilePath "C:\Reports\WinHarden\06_network_drift.log"

Write-Output "Network drift detection completed"
Write-Output ""
```

### 3.4 Account Policies Drift Detection

```powershell
Write-Output "=== ACCOUNT POLICIES DRIFT DETECTION ==="

$acctDrift = Get-AccountPoliciesDrift -Verbose 4>&1 | 
    Tee-Object -FilePath "C:\Reports\WinHarden\07_account_drift.log"

Write-Output "Account policies drift detection completed"
Write-Output ""
```

---

## Test Scenario 4: Report Generation

**Goal:** Generate comprehensive security report  
**Expected:** Report created with masked data, exportable  
**Time:** 5 minutes

### 4.1 Generate Drift Report

```powershell
Write-Output "=== DRIFT REPORT GENERATION ==="

$reportPath = "C:\Reports\WinHarden\SecurityDriftReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"

$report = New-SecurityDriftReport -OutputPath $reportPath -Verbose 4>&1 | 
    Tee-Object -FilePath "C:\Reports\WinHarden\08_report_generation.log"

Write-Output "Report generated: $reportPath"
Write-Output ""
```

### 4.2 Verify Report Contents

```powershell
Write-Output "=== REPORT VERIFICATION ==="

if (Test-Path $reportPath) {
    $reportSize = (Get-Item $reportPath).Length
    Write-Output "[OK] Report exists: $reportPath"
    Write-Output "[OK] Report size: $(([Math]::Round($reportSize/1KB)))KB"
    
    # Check for masked data
    $reportContent = Get-Content $reportPath -Raw
    if ($reportContent -match "\[MASKED\]|\*\*\*") {
        Write-Output "[OK] Sensitive data properly masked in report"
    } else {
        Write-Output "[WARN] No masked data patterns found (may be OK depending on content)"
    }
    
    # Try to open report
    Write-Output "`nOpening report in default browser..."
    try {
        Invoke-Item $reportPath
        Write-Output "[OK] Report opened successfully"
    } catch {
        Write-Output "[INFO] Could not auto-open report: $_"
        Write-Output "Manual open: $reportPath"
    }
} else {
    Write-Output "[ERROR] Report not found: $reportPath"
}

Write-Output ""
```

---

## Test Scenario 5: Edge Cases & Recovery

**Goal:** Test error handling, recovery, and edge cases  
**Expected:** Graceful error handling, informative messages  
**Time:** 10-15 minutes

### 5.1 Test with Invalid Parameters

```powershell
Write-Output "=== EDGE CASE 1: Invalid Parameters ==="

# Try with non-existent computer
Write-Output "Testing with non-existent computer name..."
$result = Invoke-SecurityHardening -ComputerName "NONEXISTENT-SERVER" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue 4>&1
if ($result -match "ERROR|not found|fail" -or $null -eq $result) {
    Write-Output "[OK] Properly handled invalid computer name"
} else {
    Write-Output "[WARN] Unexpected behavior with invalid computer"
}

Write-Output ""
```

### 5.2 Test with WhatIf + Verbose

```powershell
Write-Output "=== EDGE CASE 2: WhatIf Mode Consistency ==="

# Run with WhatIf to ensure no real changes
$whatIfOutput = Invoke-SecurityHardening -WhatIf -Verbose 4>&1

if ($whatIfOutput -match "WhatIf|What if") {
    Write-Output "[OK] WhatIf mode recognized and executed"
} else {
    Write-Output "[WARN] WhatIf output unclear"
}

Write-Output ""
```

### 5.3 Test Error Recovery

```powershell
Write-Output "=== EDGE CASE 3: Error Recovery ==="

# Test graceful handling of registry access issues
Write-Output "Testing graceful degradation for missing resources..."

$testResult = Test-HardeningCompliance -ErrorAction SilentlyContinue -WarningAction SilentlyContinue 4>&1

if ($LASTEXITCODE -eq 0 -or $null -ne $testResult) {
    Write-Output "[OK] Function gracefully handled edge case"
} else {
    Write-Output "[WARN] Check if error handling is appropriate"
}

Write-Output ""
```

### 5.4 Test Logging Edge Cases

```powershell
Write-Output "=== EDGE CASE 4: Logging Robustness ==="

# Verify logging handles special characters
Write-Output "Testing logging with special characters..."
Write-Log -Message "Test message with special chars: !@#$%^&*()_+-=[]{}|;:',.<>?/\" -LogFile "C:\Logs\WinHarden\edge_case_test.log" -ErrorAction SilentlyContinue

if (Test-Path "C:\Logs\WinHarden\edge_case_test.log") {
    $logContent = Get-Content "C:\Logs\WinHarden\edge_case_test.log" -Raw
    if ($logContent -match "Test message") {
        Write-Output "[OK] Logging handles special characters correctly"
    }
}

Write-Output ""
```

---

## Test Scenario 6: Remote Execution (Optional - if remote VM available)

**Goal:** Test remote hardening and compliance verification  
**Expected:** Remote functions work correctly, remote logs generated  
**Time:** 15-20 minutes  
**Prerequisite:** Remote VM accessible with remoting enabled

### 6.1 Setup Remote Session

```powershell
Write-Output "=== REMOTE SESSION SETUP ==="

$remoteComputer = "REMOTE-SERVER-01"  # Replace with actual remote server
$remoteCredential = Get-Credential -Message "Enter credentials for $remoteComputer"

try {
    $session = New-PSSession -ComputerName $remoteComputer -Credential $remoteCredential -ErrorAction Stop
    Write-Output "[OK] Remote session established to $remoteComputer"
} catch {
    Write-Output "[ERROR] Could not establish remote session: $_"
    Write-Output "Skipping remote tests"
    exit
}

Write-Output ""
```

### 6.2 Remote Hardening

```powershell
Write-Output "=== REMOTE HARDENING ==="

# Copy module to remote
Copy-Item -Path ".\module\WinHarden.psm1" -Destination "C:\temp\" -ToSession $session

# Import on remote and execute
Invoke-Command -Session $session -ScriptBlock {
    Import-Module C:\temp\WinHarden.psm1 -Force
    Invoke-SecurityHardening -WhatIf -Verbose 4>&1 | 
        Tee-Object -FilePath "C:\Logs\remote_hardening_whatif.log"
}

Write-Output "Remote hardening preview completed"
Write-Output ""
```

### 6.3 Remote Compliance Check

```powershell
Write-Output "=== REMOTE COMPLIANCE CHECK ==="

Invoke-Command -Session $session -ScriptBlock {
    Test-HardeningCompliance -Verbose 4>&1 | 
        Tee-Object -FilePath "C:\Logs\remote_compliance_check.log"
}

Write-Output "Remote compliance check completed"
Write-Output ""
```

### 6.4 Cleanup Remote Session

```powershell
# Cleanup
Remove-PSSession -Session $session
Write-Output "[OK] Remote session closed"
```

---

## Test Execution Checklist

Complete this checklist as you execute each test scenario:

### Scenario 1: Local Hardening
- [ ] Pre-hardening state captured
- [ ] WhatIf preview reviewed
- [ ] Hardening executed without errors
- [ ] Post-hardening state verified
- [ ] Logs created and accessible
- [ ] No critical errors in logs

### Scenario 2: Compliance
- [ ] Compliance check executed
- [ ] Results parsed successfully
- [ ] Pass/fail count reasonable
- [ ] Summary informative

### Scenario 3: Drift Detection
- [ ] Firewall drift detection completed
- [ ] RDP drift detection completed
- [ ] Network drift detection completed
- [ ] Account policies drift detection completed
- [ ] All drift checks completed without timeouts

### Scenario 4: Report Generation
- [ ] Report file created
- [ ] Report size reasonable (>10KB)
- [ ] Sensitive data masked
- [ ] Report opens in browser
- [ ] Format is readable (HTML/PDF)

### Scenario 5: Edge Cases
- [ ] Invalid parameters handled gracefully
- [ ] WhatIf mode works correctly
- [ ] Error recovery functional
- [ ] Logging robust with special characters

### Scenario 6: Remote Execution (if applicable)
- [ ] Remote session established
- [ ] Remote hardening preview completed
- [ ] Remote compliance check passed
- [ ] Remote session cleanup successful

---

## Test Result Summary Template

Use this template to document your Phase 1 results:

```
===========================================
PHASE 1: MANUAL TESTING SUMMARY
===========================================

Test Date:          2026-06-27
Tester:             [Your Name]
Environment:        [Dev/Prod-like VM]
PowerShell:         [Version]
Pester:             [Version]

SCENARIO 1: Local Hardening
Status:             [PASS/FAIL]
Issues:             [If any]
Notes:              

SCENARIO 2: Compliance
Status:             [PASS/FAIL]
Pass Rate:          [X%]
Issues:             [If any]
Notes:              

SCENARIO 3: Drift Detection
Status:             [PASS/FAIL]
Categories:         [FW/RDP/Network/Account]
Issues:             [If any]
Notes:              

SCENARIO 4: Report Generation
Status:             [PASS/FAIL]
Report Path:        [Location]
Issues:             [If any]
Notes:              

SCENARIO 5: Edge Cases
Status:             [PASS/FAIL]
Cases Tested:       4
Issues:             [If any]
Notes:              

SCENARIO 6: Remote Execution
Status:             [N/A/PASS/FAIL]
Issues:             [If any]
Notes:              

===========================================
OVERALL RESULT:     [PASS/FAIL]
ISSUES FOUND:       [Count]
READY FOR PHASE 2:  [YES/NO]
===========================================

Key Findings:
- 
- 

Recommendations:
- 

Sign-off:
Tester: ___________________  Date: _________
```

---

## Troubleshooting Guide

### Issue: Module not loading

```powershell
# Try explicit path
Import-Module -Name "C:\Repos\WinHarden\module\WinHarden.psm1" -Force -Verbose

# Check for errors
Get-Module WinHarden | Select-Object Name, ExportedFunctions
```

### Issue: Insufficient permissions

```powershell
# Verify admin mode
[Security.Principal.WindowsIdentity]::GetCurrent() | 
    Select-Object Name, @{ L='IsAdmin'; E={ (New-Object Security.Principal.WindowsPrincipal $_).IsInRole('Administrator') } }

# If not admin, re-run PowerShell as Administrator
```

### Issue: Logs directory not writable

```powershell
# Check directory permissions
Get-Acl "C:\Logs\WinHarden\" | Select-Object Owner, Access

# Create if missing
New-Item -ItemType Directory -Path "C:\Logs\WinHarden\" -Force -ErrorAction Stop
```

### Issue: Remote session fails

```powershell
# Verify remoting is enabled
Get-PSSessionConfiguration | Select-Object Name, Enabled

# Test connectivity
Test-NetConnection -ComputerName "REMOTE-SERVER" -CommonTCPPort WINRM
```

---

## Next Steps

After completing Phase 1:

1. **Document Results** - Fill out Test Result Summary
2. **Identify Issues** - List any failures or unexpected behavior
3. **Review Logs** - Check detailed logs for error patterns
4. **Plan Phase 2** - If all tests pass, proceed to Integration Testing
5. **Report Status** - Update project status based on findings

---

**Phase 1 Status:** READY FOR MANUAL EXECUTION  
**Expected Duration:** 2-3 hours per environment  
**Owner:** QA/Testing Team  
**Last Updated:** 2026-06-27
