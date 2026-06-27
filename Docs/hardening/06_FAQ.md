# WinHarden - FAQ

**Frequently asked questions and troubleshooting solutions.**

---

## Table of Contents

1. [General Questions](#general-questions)
2. [Installation & Setup](#installation--setup)
3. [Baseline & Compliance](#baseline--compliance)
4. [Remediation](#remediation)
5. [Drift Detection](#drift-detection)
6. [Performance & Optimization](#performance--optimization)
7. [Troubleshooting](#troubleshooting)
8. [Security & Compliance](#security--compliance)

---

## General Questions

### Q: What is WinHarden?

A: WinHarden is a PowerShell-based security hardening framework for Windows systems. It automates:
- Security hardening based on CIS benchmarks
- Compliance verification against baselines
- Drift detection to identify unauthorized changes
- Remediation of security violations
- Comprehensive audit logging

### Q: What Windows versions are supported?

A: WinHarden supports:
- Windows Server 2016 and later
- Windows 10 and later
- Windows 11

Minimum requirement: Windows 7+ with PowerShell 5.1

### Q: Do I need Administrator privileges?

A: Yes. All WinHarden operations require Administrator privileges because they:
- Modify firewall rules (requires admin)
- Change service configurations (requires admin)
- Modify registry settings (requires admin)
- Manage user accounts (requires admin)
- Enable audit policies (requires admin)

### Q: How much does WinHarden cost?

A: WinHarden is open-source and free to use. The repository is available on GitHub.

### Q: Can WinHarden be used in production?

A: Yes, WinHarden is designed for production use. However:
- Test in staging environment first
- Create backups before deployment
- Follow the deployment guide procedures
- Monitor system performance after deployment

### Q: Is WinHarden certified for compliance?

A: WinHarden itself is not officially certified, but it implements:
- CIS Benchmarks
- NIST guidelines
- DoD STIG recommendations
- GDPR hardening controls

---

## Installation & Setup

### Q: Where should I install WinHarden?

A: The recommended location is:
```
C:\Repos\WinHarden
```

However, you can install anywhere by:
```powershell
cd [Your-Path]
git clone https://github.com/your-org/WinHarden.git
```

### Q: How do I import WinHarden functions?

A: There are three methods:

**Method 1: Import Module**
```powershell
Import-Module C:\Repos\WinHarden -Force
Get-Command -Module WinHarden
```

**Method 2: Dot-source specific function**
```powershell
. C:\Repos\WinHarden\functions\Hardening\New-HardeningBaseline.ps1
```

**Method 3: Load all functions**
```powershell
Get-ChildItem C:\Repos\WinHarden\functions -Recurse -Filter *.ps1 | ForEach-Object {
    . $_.FullName
}
```

### Q: What if I get "execution policy" error?

A: Set execution policy to allow scripts:

```powershell
# For current session only
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force

# For current user
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# For all users (admin required)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force
```

### Q: Can I run WinHarden on remote servers?

A: Yes, using PowerShell Remoting:

```powershell
$session = New-PSSession -ComputerName "RemoteServer"
Invoke-Command -Session $session -ScriptBlock {
    Import-Module C:\Repos\WinHarden
    Invoke-HardeningRemediation -BaselineName "Production-Baseline" -Force
}
```

---

## Baseline & Compliance

### Q: What is a baseline?

A: A baseline is a snapshot of desired system security configuration. It contains:
- Firewall rules
- Service states
- Registry settings
- Account policies
- Audit policies

### Q: How do I create a baseline?

A: Create from current system state:

```powershell
New-HardeningBaseline `
    -Name "MyBaseline" `
    -Description "Production baseline"
```

Or customize manually by editing the XML file.

### Q: Can I have multiple baselines?

A: Yes. Create different baselines for different environments:
```
Production-Baseline
Development-Baseline
Testing-Baseline
```

And apply the appropriate baseline to each environment.

### Q: What does "compliance" mean?

A: Compliance is how well the current system matches the baseline configuration.

```
Compliance = (Passed Checks / Total Checks) * 100

Example:
95 passed checks out of 100 = 95% compliance
```

### Q: What compliance score is considered acceptable?

A: General guidelines:
- **95-100%**: Excellent (well-hardened)
- **85-94%**: Good (acceptable for most environments)
- **75-84%**: Fair (needs attention)
- **<75%**: Poor (immediate remediation needed)

### Q: How often should I run compliance checks?

A: Recommended frequencies:
- **Critical systems**: Daily
- **Production systems**: Weekly
- **Development systems**: Monthly
- **After major changes**: Immediately

### Q: Can I exclude certain checks from compliance?

A: Not directly, but you can:
1. Create a custom baseline without those checks
2. Modify baseline XML to disable specific checks
3. Use custom compliance categories

---

## Remediation

### Q: What does remediation do?

A: Remediation applies hardening configurations to fix compliance violations. It:
1. Backs up current configuration
2. Applies hardening changes
3. Verifies changes were applied
4. Logs all operations

### Q: Is remediation reversible?

A: Mostly yes. Before remediation, WinHarden creates backups. However:
- Some registry changes may require system restart
- Service configuration changes may need restart
- Always test in staging first

### Q: How long does remediation take?

A: Typical times:
- Single server: 5-10 minutes
- 5 servers (parallel): 10-15 minutes
- 20+ servers: 20-30 minutes

Performance depends on:
- Hardware speed
- Network latency
- System configuration complexity

### Q: What happens if remediation fails?

A: If remediation fails:
1. Check error message in log file
2. Verify prerequisites are met
3. Review backup was created
4. Retry with verbose output:
   ```powershell
   Invoke-HardeningRemediation `
       -BaselineName "Production-Baseline" `
       -Verbose -Force
   ```

### Q: Can I undo remediation?

A: Yes, using pre-remediation backup:

```powershell
# Restore from backup
# (Requires manual restoration or rollback script)

# Or re-baseline to current state
New-HardeningBaseline -Name "Rollback-Baseline"
```

### Q: Should I use WhatIf before remediation?

A: Absolutely. Always preview changes first:

```powershell
Invoke-HardeningRemediation `
    -BaselineName "Production-Baseline" `
    -WhatIf  # Preview only
```

---

## Drift Detection

### Q: What is drift?

A: Drift is when the current system configuration differs from the baseline. Examples:
- Firewall rule manually added
- Service restarted outside of schedule
- Registry key manually changed
- Account policy manually relaxed

### Q: How often does drift occur?

A: Drift can occur when:
- Administrators make manual changes
- Software installation changes configuration
- Windows Update modifies settings
- Malware/compromise attempts change settings

### Q: How do I detect drift?

A: Use the drift detection function:

```powershell
$drift = Get-SecurityDrift -BaselineName "Production-Baseline"
$drift | Format-Table
```

### Q: Should I be concerned about drift?

A: It depends:
- **Authorized drift**: If manually approved, document and update baseline
- **Unauthorized drift**: Indicates possible compromise, investigate immediately
- **Minor drift**: May be acceptable depending on security policy

### Q: How do I fix drift?

A: Use remediation to restore to baseline:

```powershell
Invoke-HardeningRemediation -BaselineName "Production-Baseline" -Force
```

Or manually adjust and update baseline.

### Q: Can I automatically alert on drift?

A: Yes, create a scheduled monitoring task:

```powershell
# Create monitoring script that alerts on high-severity drift
# Schedule as daily task via Task Scheduler
```

---

## Performance & Optimization

### Q: Is WinHarden slow?

A: No. Typical performance:
- Compliance check: 2-3 minutes
- Remediation: 5-10 minutes
- Drift detection: 1-2 minutes

Performance depends on system specs and configuration complexity.

### Q: How can I speed up operations?

A: Several strategies:

1. **Incremental checks**: Only check specific categories
   ```powershell
   Test-SystemCompliance -Category "Firewall"
   ```

2. **Parallel execution**: Run on multiple servers simultaneously
3. **Caching**: Reuse baseline in memory for multiple checks
4. **Filtering**: Skip non-critical categories

### Q: Does WinHarden impact system performance?

A: Minimal impact:
- Idle memory usage: 50-100 MB
- During operations: 100-200 MB
- CPU impact: 10-40% during operations, 0% when idle
- No continuous background processes

### Q: Can I run WinHarden on low-spec systems?

A: Yes, but with adjustments:
- Run compliance checks during off-peak hours
- Use single-category checks instead of full scans
- Avoid parallel multi-server deployments
- Monitor memory usage

---

## Troubleshooting

### Q: Getting "file not found" error

A: Verify module location:

```powershell
Test-Path C:\Repos\WinHarden\functions
Get-ChildItem C:\Repos\WinHarden\functions -Recurse -Filter *.ps1 | Measure-Object
```

If files missing, clone repository again:
```powershell
cd C:\Repos
git clone https://github.com/your-org/WinHarden.git
```

### Q: Getting "access denied" error

A: Verify administrator privileges:

```powershell
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
Write-Host "Admin: $isAdmin"
```

If not admin, restart PowerShell as Administrator.

### Q: Baseline file corrupted

A: Restore from backup:

```powershell
# Find backup
Get-ChildItem C:\Repos\WinHarden\backups -Filter *.xml

# Restore
Copy-Item C:\Repos\WinHarden\backups\backup_baseline.xml `
    -Destination C:\Repos\WinHarden\baselines\Production-Baseline.xml -Force
```

### Q: Compliance reports missing

A: Check logs directory:

```powershell
Get-ChildItem C:\Repos\WinHarden\logs -Filter *.csv | Select-Object Name, LastWriteTime

# Verify directory permissions
icacls C:\Repos\WinHarden\logs
```

### Q: System became unstable after remediation

A: Follow emergency rollback procedure:

```powershell
# Restore from pre-remediation backup
# (See Deployment Guide - Rollback Procedures)
```

---

## Security & Compliance

### Q: Is WinHarden secure?

A: Yes. WinHarden:
- Uses PowerShell 5.1 security features
- Avoids Invoke-Expression (injection risk)
- Validates all inputs at system boundaries
- Logs all operations for audit trail
- Implements OWASP security practices

### Q: Does WinHarden meet compliance requirements?

A: WinHarden implements:
- CIS Benchmarks
- NIST SP 800-171
- DoD STIG guidelines
- GDPR technical controls

But you should still verify against your specific compliance requirements.

### Q: Can I use WinHarden for HIPAA/PCI/SOC2?

A: WinHarden can help meet hardening requirements for:
- HIPAA (security controls)
- PCI-DSS (system hardening)
- SOC2 (security baseline)

However, compliance involves more than just hardening. Consult your compliance team.

### Q: How are credentials handled?

A: WinHarden:
- Never stores credentials in plaintext
- Never logs sensitive information
- Uses Windows authentication
- Requires administrator context

### Q: What should I do if a server is compromised?

A: Steps to recover:

1. Isolate the compromised system
2. Run emergency remediation:
   ```powershell
   Invoke-HardeningRemediation -BaselineName "Secure-Baseline" -Force -Aggressive
   ```
3. Run drift detection to verify:
   ```powershell
   $drift = Get-SecurityDrift -BaselineName "Secure-Baseline"
   $drift | Where-Object Status -eq "Drift"
   ```
4. Change all credentials
5. Review logs for unauthorized access
6. Perform forensic analysis

---

## Common Error Messages

### Error: "Cannot find baseline"

**Solution:**
```powershell
# List available baselines
Get-ChildItem C:\Repos\WinHarden\baselines\ -Filter "*.xml" | Select-Object Name

# Create baseline if missing
New-HardeningBaseline -Name "Default-Baseline"
```

### Error: "Access denied" on registry modification

**Solution:**
```powershell
# Ensure running as Administrator
# Verify UAC is not blocking
# Check registry permissions

icacls "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Lsa"
```

### Error: "Service cannot be modified"

**Solution:**
```powershell
# Check if service is running
Get-Service -Name RDP | Select-Object Status, StartType

# Stop service before modifying
Stop-Service -Name RDP -Force

# Then apply hardening
```

---

**Document Version:** 2.0  
**Last Updated:** 2026-06-27  
**Target Audience:** All Users, Support Teams  
**Complexity Level:** Beginner to Intermediate
