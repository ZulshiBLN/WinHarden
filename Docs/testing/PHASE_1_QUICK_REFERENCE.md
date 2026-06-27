# Phase 1: Quick Reference Card

**One-page guide for Phase 1 Manual Testing**

---

## Launch Test Runner

```powershell
# Navigate to testing directory
cd C:\Repos\WinHarden

# Run Phase 1 master script (all scenarios)
.\testing\Phase_1_Manual_Test_Runner.ps1 -Environment Dev

# Run for production-like environment
.\testing\Phase_1_Manual_Test_Runner.ps1 -Environment Prod
```

---

## Manual Test Scenarios (5 minutes each)

### 1. Local Hardening (Golden Path)
**What:** Execute hardening on local machine  
**Command:** `Invoke-SecurityHardening -WhatIf` then `Invoke-SecurityHardening`  
**Expected:** System hardened, logs created  
**Time:** 10 min

### 2. Compliance Check
**What:** Verify hardening compliance  
**Command:** `Test-HardeningCompliance`  
**Expected:** All checks pass or meaningful failures documented  
**Time:** 5 min

### 3. Drift Detection (4 categories)
**What:** Detect configuration drift  
**Commands:**
- `Get-FirewallDrift`
- `Get-RDPSecurityDrift`
- `Get-NetworkSecurityDrift`
- `Get-AccountPoliciesDrift`

**Expected:** Drift detected, categorized  
**Time:** 15 min

### 4. Report Generation
**What:** Create comprehensive security report  
**Command:** `New-SecurityDriftReport`  
**Expected:** HTML/PDF report with masked data  
**Time:** 5 min

### 5. Edge Cases
**What:** Test error handling  
**Tests:** Invalid parameters, WhatIf, error recovery  
**Expected:** Graceful error handling  
**Time:** 10 min

---

## Key Directories

| Path | Purpose |
|------|---------|
| `C:\Logs\WinHarden\` | Test execution logs |
| `C:\Reports\WinHarden\` | Test reports & artifacts |
| `.\testing\` | Test scripts & runners |
| `./module/WinHarden.psm1` | Core module |

---

## Verify Prerequisites

```powershell
# Load module
Import-Module ./module/WinHarden.psm1 -Force

# Check core functions
Get-Command Invoke-SecurityHardening, Test-HardeningCompliance, Get-FirewallDrift

# Create directories
mkdir C:\Logs\WinHarden\, C:\Reports\WinHarden\ -ErrorAction SilentlyContinue
```

---

## Test Results Checklist

**After each scenario, verify:**

- [ ] Scenario executed without fatal errors
- [ ] Log files created in `C:\Logs\WinHarden\`
- [ ] Reports generated in `C:\Reports\WinHarden\`
- [ ] No critical errors in log output
- [ ] Functions handled edge cases gracefully

---

## Troubleshooting Quick Fixes

| Issue | Fix |
|-------|-----|
| Module not found | `Import-Module C:\Repos\WinHarden\module\WinHarden.psm1 -Force -Verbose` |
| Access denied | Run PowerShell as Administrator |
| Logs not writable | `mkdir C:\Logs\WinHarden\ -Force` |
| Remote fails | `Test-NetConnection -ComputerName SERVER -CommonTCPPort WINRM` |

---

## Success Criteria

**Phase 1 PASS if:**
- ✓ All 5 scenarios execute without fatal errors
- ✓ All logs generated successfully
- ✓ Reports created and readable
- ✓ No critical issues in execution
- ✓ Error handling graceful

**Phase 1 FAIL if:**
- ✗ Module fails to load
- ✗ Core functions missing
- ✗ Script execution hangs
- ✗ Fatal unhandled errors

---

## Next Phase

When Phase 1 PASS:
1. Document results in test summary
2. Archive logs & reports
3. Review PHASE_2_INTEGRATION_TESTING.md
4. Begin Phase 2 (Integration Testing)

---

**Quick Ref Version:** 1.0  
**Last Updated:** 2026-06-27  
**Total Estimated Time:** 2-3 hours per environment
