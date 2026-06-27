# Phase 3: E2E Testing - Launch Instructions

**Status:** Ready for manual execution in Admin PowerShell  
**Date:** 2026-06-27  

---

## Prerequisites

✅ Phase 1: PASSED (5/5 scenarios)  
✅ Phase 2: PASSED (5/5 scenarios)  
✅ Phase 3 Infrastructure: Created and committed  

---

## Launch Phase 3

### Step 1: Open PowerShell as Administrator

1. Press `Win + X` → Select "Windows Terminal (Admin)" or "PowerShell (Admin)"
2. Verify admin status:
   ```powershell
   [Security.Principal.WindowsIdentity]::GetCurrent() | 
       ForEach-Object { (New-Object Security.Principal.WindowsPrincipal $_).IsInRole('Administrator') }
   # Should return: True
   ```

### Step 2: Navigate to WinHarden Directory

```powershell
cd C:\Repos\WinHarden
```

### Step 3: Launch Phase 3 E2E Test Runner

```powershell
.\testing\Phase_3_E2E_Test_Runner.ps1 -Environment Dev
```

---

## What Phase 3 Tests

**Execution Time:** ~30-40 seconds

| Scenario | Tests | Expected Result |
|----------|-------|-----------------|
| **S1: Complete Workflow** | Hardening → Compliance → Drift → Report | ✅ PASS |
| **S2: Scheduled Audit** | Task Scheduler integration | ✅ PASS |
| **S3: Multi-Environment** | Consistency across profiles | ✅ PASS |
| **S4: Incident & Recovery** | Drift detection + remediation | ✅ PASS |
| **S5: Long-Term Stability** | State persistence (5 snapshots) | ✅ PASS |

---

## Monitor Execution

During execution, you'll see:

```
[HH:MM:SS] [OK] Scenario 1: Complete workflow successful
[HH:MM:SS] [OK] Scenario 2: Scheduled audit workflow successful
[HH:MM:SS] [OK] Scenario 3: Multi-environment consistency verified
[HH:MM:SS] [OK] Scenario 4: Incident and recovery successful
[HH:MM:SS] [OK] Scenario 5: Long-term stability verified
```

**Final Result:**
```
[HH:MM:SS] [OK] Overall: 5/5 passed
[HH:MM:SS] [INFO] Status: READY FOR PHASE 4
```

---

## Output Locations

After execution, check:

```
C:\Logs\WinHarden\
  └─ Phase_3_TestRun_YYYYMMDD_HHMMSS.log     [Main test log]

C:\Reports\WinHarden\
  └─ Drift_Detection_YYYY-MM-DD_HH-MM-SS.csv [E2E report]
```

---

## Success Criteria

**Phase 3 PASS requires:**
- [x] All 5 scenarios execute without fatal errors
- [x] Complete workflows end-to-end
- [x] System remains stable throughout
- [x] Recovery procedures work
- [x] Long-term state consistency

---

## If Something Fails

1. **Check the log:**
   ```powershell
   Get-Content C:\Logs\WinHarden\Phase_3_TestRun_*.log -Tail 50
   ```

2. **Review errors:**
   - Look for `[ERROR]` lines
   - Check the specific scenario number
   - See PHASE_3_E2E_TESTING.md for expected behavior

3. **Rerun specific scenario:**
   - Edit Phase_3_E2E_Test_Runner.ps1
   - Comment out working scenarios
   - Run again

---

## Next Steps After Phase 3

**If all 5 scenarios PASS:**
1. ✅ Document Phase 3 results
2. ✅ Move to Phase 4 (Performance Testing) or Phase 5 (Security Review)
3. ✅ Prepare for production deployment

**If issues found:**
1. Document failures
2. Create fixes
3. Rerun failing scenarios
4. Proceed when all tests pass

---

## Quick Commands

```powershell
# Run Phase 3
cd C:\Repos\WinHarden
.\testing\Phase_3_E2E_Test_Runner.ps1 -Environment Dev

# View latest log
Get-Content (Get-ChildItem C:\Logs\WinHarden\Phase_3_*.log | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName -Tail 100

# Check test artifacts
Get-ChildItem C:\Reports\WinHarden\ | Sort-Object LastWriteTime -Descending | Select-Object -First 5
```

---

**Ready to execute?** Run the command above in Admin PowerShell! 🚀
