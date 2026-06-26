# WinHarden Hardening – Frequently Asked Questions (FAQ)

**Version:** 1.0  
**Last Updated:** 2026-06-26  
**Topic:** Common Questions & Troubleshooting

---

## Getting Started

### Q: What is WinHarden?

**A:** WinHarden is a PowerShell security hardening automation toolkit for Windows Server and desktop systems. It applies security best practices through rules organized in profiles (Basis, Recommended, Strict), providing a scalable way to harden systems at enterprise scale.

**Key capabilities:**
- 55+ security hardening rules across multiple categories
- Automated compliance verification
- Dry-run (WhatIf) support for safe testing
- Enterprise-scale deployment
- SIEM integration for monitoring
- Full audit logging with sensitive data masking

### Q: What systems does WinHarden support?

**A:** WinHarden supports:
- Windows Server 2016, 2019, 2022
- Windows 10 (all versions)
- Windows 11 (all versions)
- PowerShell 5.1+ (with 7.x supported)

**Not supported:**
- Windows Server 2012 R2 or older
- Windows 7 or 8.1
- Cross-platform scenarios

### Q: What are the three hardening profiles?

**A:**

| Profile | Rules | Best For | Impact |
|---------|-------|----------|--------|
| **Basis** | 20 | Legacy systems, baseline hardening | Minimal |
| **Recommended** | 35 | Standard production systems | Moderate |
| **Strict** | 55+ | High-security environments | High |

Start with Basis, move to Recommended once validated.

### Q: How long does hardening take?

**A:**
- **Basis profile:** ~30 seconds
- **Recommended profile:** ~45 seconds
- **Strict profile:** ~2 minutes
- **Compliance verification:** ~12 seconds

Total time including verification: 1-3 minutes depending on profile.

---

## Installation & Deployment

### Q: How do I install WinHarden?

**A:** Three steps:

1. **Extract files:**
```powershell
Expand-Archive -Path WinHarden.zip -DestinationPath C:\Program Files\WinHarden -Force
```

2. **Verify installation:**
```powershell
cd C:\Program Files\WinHarden
.\build.ps1 -Validate
```

3. **Test run:**
```powershell
Import-Module .\modules\Core.psm1
Import-Module .\modules\System.psm1
$session = New-HardeningSession -Profile Basis -TargetSystem Client -OSVersion 11
Invoke-SecurityHardening -Session $session -WhatIf
```

### Q: Do I need administrator privileges?

**A:** **Yes, administrator privileges are required** to:
- Apply hardening rules (registry, services, firewall, etc.)
- Verify compliance
- Create scheduled tasks

User-level accounts can only view logs and profiles.

### Q: Can I deploy WinHarden remotely?

**A:** **Yes, three methods:**

1. **WinRM (Recommended):**
```powershell
Invoke-Command -ComputerName SERVER01 -ScriptBlock {
    $session = New-HardeningSession -Profile Recommended -TargetSystem Server
    Invoke-SecurityHardening -Session $session
}
```

2. **Group Policy:**
Create GPO startup script that runs WinHarden on each system boot.

3. **Configuration Management:**
Integrate with Ansible, DSC, or other CM tools.

### Q: How do I uninstall WinHarden?

**A:** WinHarden is not persistent – it's a script toolkit. To remove:

```powershell
# Remove directory
Remove-Item -Path "C:\Program Files\WinHarden" -Recurse -Force

# Remove scheduled tasks (if any)
Unregister-ScheduledTask -TaskName "WinHarden-*" -Confirm:$false

# Rollback hardening changes (optional)
# Use Windows System Restore or Group Policy to revert to baseline
```

---

## Usage & Operation

### Q: What does WhatIf mode do?

**A:** WhatIf mode shows what would happen WITHOUT making changes:

```powershell
Invoke-SecurityHardening -Session $session -WhatIf

# Output (example):
# What if: Performing the operation "Apply Rule: Account-MinimumPasswordLength" on target "LOCAL SYSTEM".
# What if: Performing the operation "Apply Rule: Firewall-EnableWindowsDefender" on target "LOCAL SYSTEM".
```

**Key point:** In WhatIf mode, **no actual changes are made** to the system. Use this to preview changes before applying.

### Q: Can I apply only specific rules?

**A:** **Yes, use the `-RuleFilter` parameter:**

```powershell
# Apply only firewall rules
Invoke-SecurityHardening -Session $session -RuleFilter @('Firewall-*')

# Apply specific rules
Invoke-SecurityHardening -Session $session -RuleFilter @(
    'Account-MinimumPasswordLength',
    'Firewall-EnableWindowsDefender'
)
```

### Q: What happens if a rule fails?

**A:** By default, **one rule failure doesn't stop the process**:

```powershell
# Graceful (default): Continue if rule fails
Invoke-SecurityHardening -Session $session
# Result: All other rules applied, failed rule logged

# Strict: Stop on first failure
Invoke-SecurityHardening -Session $session -FailOnError
# Result: Stops at first failure
```

Check logs for details:
```powershell
Get-Content logs/log_*.csv | Where-Object { $_ -match "ERROR" }
```

### Q: How do I check compliance?

**A:**

```powershell
# Quick check (percentage)
$compliance = Test-HardeningCompliance -Session $session
$compliance.CompliancePercentage  # e.g., 98%

# Detailed check (rule-by-rule)
$compliance = Test-HardeningCompliance -Session $session -Detailed
$compliance.RuleResults | Where-Object { $_.Compliant -eq $false }

# Auto-remediate non-compliant rules
$remediation = Test-HardeningCompliance -Session $session -Remediate
$remediation.RemediatedRules
```

### Q: What if compliance drops below 100%?

**A:** Check the detailed report:

```powershell
$compliance = Test-HardeningCompliance -Session $session -Detailed
$nonCompliant = $compliance.RuleResults | Where-Object { $_.Compliant -eq $false }

# Show non-compliant rules
$nonCompliant | Select-Object RuleName, Expected, Actual, Severity

# Causes of drift:
# 1. Manual changes to system (outside WinHarden)
# 2. Windows Update resets settings
# 3. Third-party software modified settings
# 4. Service restart cleared settings
```

**Solutions:**
- Use `-Remediate` to auto-fix: `Test-HardeningCompliance -Session $session -Remediate`
- Manually reapply hardening: `Invoke-SecurityHardening -Session $session`
- Implement scheduled compliance checks to detect drift early

### Q: Can I undo hardening changes?

**A:** **Partial rollback:**

```powershell
# Revert specific rules
# (WinHarden provides revert functions for each rule type)
Revert-RegistryHardeningRule -RuleName "Account-MinimumPasswordLength"
```

**Full rollback:**

```powershell
# Option 1: System Restore
Restore-ComputerRestorePoint -Description "Pre-WinHarden" -Confirm:$false
Restart-Computer

# Option 2: Group Policy reset
# Use Group Policy to revert settings to baseline

# Option 3: Restore from backup
# Restore from VM snapshot or system backup
```

---

## Compliance & Verification

### Q: How often should I verify compliance?

**A:** Recommended schedule:

- **Daily:** Automated compliance checks (via scheduled task)
- **Weekly:** Manual review of compliance dashboard
- **Monthly:** Full audit and reporting
- **Quarterly:** Re-baseline compliance targets

```powershell
# Set up daily verification
$trigger = New-ScheduledTaskTrigger -Daily -At 2am
$action = New-ScheduledTaskAction -Execute PowerShell.exe -Argument `
    "-NoProfile -File C:\Scripts\DailyComplianceCheck.ps1"
Register-ScheduledTask -TaskName "DailyComplianceCheck" -Trigger $trigger -Action $action
```

### Q: What should I do if compliance is below 95%?

**A:** Investigate and remediate:

```powershell
# 1. Identify non-compliant rules
$compliance = Test-HardeningCompliance -Session $session -Detailed
$drift = $compliance.RuleResults | Where-Object CompliancePercentage -lt 95

# 2. Check for drift cause
foreach ($rule in $drift) {
    Write-Host "Rule: $($rule.RuleName)"
    Write-Host "  Expected: $($rule.Expected)"
    Write-Host "  Actual: $($rule.Actual)"
    Write-Host "  Last Modified: $($rule.LastModifiedDate)"
}

# 3. Remediate
Test-HardeningCompliance -Session $session -Remediate

# 4. Verify fix
Test-HardeningCompliance -Session $session
```

### Q: How do I interpret compliance percentages?

**A:**

| Compliance | Status | Action |
|-----------|--------|--------|
| 100% | Fully Compliant | Continue normal monitoring |
| 95-99% | Acceptable | Investigate drift, schedule remediation |
| 90-95% | Concerning | Investigate immediately, remediate within 24 hours |
| <90% | Critical | Investigate immediately, remediate now |

### Q: Can I customize compliance thresholds?

**A:** Not built-in, but you can create custom alerts:

```powershell
# Custom alert on 95% threshold
$compliance = Test-HardeningCompliance -Session $session
if ($compliance.CompliancePercentage -lt 95) {
    Send-MailMessage -To "security@company.com" `
        -Subject "WinHarden Alert: Compliance below 95%" `
        -Body "Compliance: $($compliance.CompliancePercentage)%"
}
```

---

## Performance & Optimization

### Q: How can I speed up hardening?

**A:** Several optimizations:

```powershell
# 1. Use parallel execution (5.5x faster)
Invoke-SecurityHardening -Session $session -Parallel

# 2. Skip verification if verifying separately
Invoke-SecurityHardening -Session $session -SkipVerification

# 3. Apply only needed rules
Invoke-SecurityHardening -Session $session -RuleFilter @('Account-*')

# 4. Use Basis profile instead of Recommended or Strict
$session = New-HardeningSession -Profile Basis -TargetSystem Client
```

**Performance comparison:**
- Sequential (default): 8.3s
- Parallel: 1.5s (5.5x faster)
- Skip verification: 8.3s instead of 20.7s
- Basis profile only: 4.6s

### Q: Will hardening impact system performance?

**A:** **Minimal impact:**

- **CPU:** <2% during execution
- **Memory:** ~40-50MB temporary
- **Disk:** ~100MB logs per week
- **Network:** Only during remote deployment
- **User experience:** No noticeable impact after completion

**One-time impact:** 30 seconds to 2 minutes depending on profile.

### Q: How much disk space does WinHarden use?

**A:**

| Component | Size |
|-----------|------|
| Installation | 50MB |
| Logs (per day) | 2-5MB |
| Logs (7-day rotation) | ~21-35MB |
| Temporary (peak) | ~30MB |
| **Total** | **~150MB** |

---

## Security & Compliance

### Q: Is WinHarden secure?

**A:** **Yes, with multiple security features:**

- Zero hardcoded credentials (uses Windows Credential Manager)
- Automatic sensitive data masking in logs (passwords, tokens, keys → `***`)
- Full audit logging for compliance
- Input validation on all parameters
- Error handling that doesn't expose sensitive data
- Admin-only operations

### Q: What compliance frameworks does WinHarden support?

**A:** WinHarden rules align with multiple frameworks:

- **HIPAA** – Account policies, audit logging, encryption
- **PCI-DSS** – Firewall rules, service hardening, audit policies
- **SOC2** – Logging, compliance verification, monitoring
- **ISO 27001** – Security controls, access control, audit trails
- **CIS Benchmarks** – Windows hardening rules
- **DISA STIG** – Windows Server hardening rules

See [SIEM Integration](04_SIEM_INTEGRATION.md) for compliance reporting.

### Q: How is sensitive data protected?

**A:** Multi-layer protection:

1. **At rest:** Credentials stored in Windows Credential Manager, not config files
2. **In transit:** HTTPS for remote operations, WinRM encryption
3. **In logs:** Automatic masking of passwords, tokens, keys (`password: ***`)
4. **In memory:** Cleared after use, no persistence to disk

### Q: Can I audit who ran hardening?

**A:** **Yes, full audit trail:**

```powershell
# Check logs for user/account information
Get-Content logs/log_*.csv | Select-Object Caller, Function, Message | 
    Where-Object Caller -match "Admin|System"

# Event log integration
Get-WinEvent -LogName Security | Where-Object ID -eq 4625 | Select-Object TimeCreated, Message

# SIEM integration provides centralized audit dashboard
```

---

## Troubleshooting

### Q: "Administrator privileges required" – How do I fix this?

**A:** Run PowerShell as Administrator:

```powershell
# Option 1: Right-click PowerShell → "Run as administrator"

# Option 2: From command line
PowerShell -NoProfile -WindowStyle Hidden -Command "Start-Process PowerShell -Verb RunAs"
```

### Q: Modules won't load – "Module not found"

**A:** Check file paths:

```powershell
# Verify files exist
Test-Path "C:\Program Files\WinHarden\modules\Core.psm1"  # Should be True
Test-Path "C:\Program Files\WinHarden\modules\System.psm1"  # Should be True

# Use absolute paths, not relative
Import-Module "C:\Program Files\WinHarden\modules\Core.psm1" -ErrorAction Stop
```

### Q: Rules apply but don't take effect

**A:** Common causes:

1. **Service needs restart:**
```powershell
Restart-Computer -Force
```

2. **Group Policy needs refresh:**
```powershell
gpupdate /force
```

3. **Setting requires user logout:**
```powershell
logoff
```

4. **Windows Update overwrote setting:**
```powershell
# Reapply hardening
Invoke-SecurityHardening -Session $session
```

### Q: Compliance verification always fails

**A:** Debugging steps:

```powershell
# 1. Check detailed compliance
$compliance = Test-HardeningCompliance -Session $session -Detailed
$compliance.RuleResults | Where-Object Compliant -eq $false

# 2. Check specific rule state
Get-Item -Path "HKLM:\path\to\rule" -ErrorAction SilentlyContinue

# 3. Check service state
Get-Service -Name "ServiceName" | Select-Object Status

# 4. Check logs for errors
Get-Content logs/log_*.csv | Where-Object Level -eq ERROR

# 5. Run in administrator prompt (run `whoami /priv` to verify)
whoami /priv | find /i "SeRestorePrivilege"
```

### Q: Scripts blocked by execution policy

**A:** Set execution policy:

```powershell
# For current user
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# For all users (requires admin)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force

# Or run specific script with bypass
powershell -ExecutionPolicy Bypass -File "C:\Program Files\WinHarden\scripts\Deploy.ps1"
```

### Q: Can't connect to remote systems

**A:** Enable WinRM:

```powershell
# On target systems
Enable-PSRemoting -Force
Set-WSManInstance -ResourceURI winrm/config -ValueSet @{MaxTimeoutms=300000}

# Test connection
Test-WSMan -ComputerName SERVER01

# If fails, check firewall
Get-NetFirewallRule -DisplayName "*Windows Remote Management*" | Enable-NetFirewallRule
```

---

## Support & Resources

### Q: Where can I find more help?

**A:** Resources:

1. **[User Guide](01_USER_GUIDE.md)** – Step-by-step usage
2. **[Deployment Guide](02_DEPLOYMENT_GUIDE.md)** – Enterprise deployment
3. **[Architecture Guide](03_ARCHITECTURE.md)** – Technical details
4. **[SIEM Integration](04_SIEM_INTEGRATION.md)** – Monitoring setup
5. **[Performance Guide](05_PERFORMANCE.md)** – Optimization
6. **Logs** – Check `logs/log_*.csv` for detailed error messages

### Q: How do I report issues?

**A:** When reporting issues, include:

1. WinHarden version
2. Operating system (Windows Server 2019, Windows 11, etc.)
3. PowerShell version (`$PSVersionTable.PSVersion`)
4. Steps to reproduce
5. Relevant log entries from `logs/log_*.csv`
6. Error messages (sanitized of sensitive data)

### Q: Can I contribute improvements?

**A:** Yes! See CLAUDE.md in the project repository for:
- Development guidelines
- Pull request process
- Testing requirements
- Code standards

---

**End of FAQ**

For questions not covered here, consult the User Guide or contact your system administrator.
