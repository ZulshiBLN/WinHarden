# WinOpsKit Hardening System - Frequently Asked Questions

**Version:** 1.0  
**Last Updated:** 2026-06-26

---

## General Questions

### Q: What is the WinOpsKit Hardening System?
**A:** The WinOpsKit Hardening System is an automated security hardening solution for Windows Client (11) and Server (2019/2022/2025) systems. It provides profile-based security rule application, compliance verification, and remediation capabilities.

### Q: Why do I need it?
**A:** Manual hardening is time-consuming and error-prone. This system automates the application of security baselines, ensures consistency across systems, and tracks compliance.

### Q: Can I use it on non-Windows systems?
**A:** No, it's Windows-only. The hardening rules target Windows-specific components (Registry, Services, Firewall, Audit policies).

### Q: What license/cost is involved?
**A:** WinOpsKit is part of your Windows/Server installation and PowerShell environment. No additional licensing required beyond standard Windows licenses.

---

## Installation & Setup

### Q: How do I install WinOpsKit?
**A:** WinOpsKit is provided as PowerShell modules. Import them using:
```powershell
Import-Module "C:\Path\To\WinOpsKit\modules\Core.psm1"
Import-Module "C:\Path\To\WinOpsKit\modules\System.psm1"
```

### Q: Do I need Administrator rights?
**A:** Yes, modifying system security settings requires administrator rights. Always run PowerShell as Administrator.

### Q: What PowerShell version is required?
**A:** PowerShell 5.1 (built-in Windows PowerShell) or PowerShell 7.x (Core). Version 5.1 is recommended for maximum compatibility.

### Q: Can I use it on PowerShell Core?
**A:** Yes, it's compatible with PowerShell 7.x, but some features (like certain registry operations) work better with PowerShell 5.1.

---

## Hardening Profiles

### Q: Which profile should I use?
**A:** Start with **Recommended** for production. Use **Basis** for development/test. Use **Strict** only if you fully understand the impact and need maximum security.

### Q: What's the difference between profiles?
**A:** 
- **Basis:** 12 foundational rules (minimum baseline)
- **Recommended:** 18 rules (standard production)
- **Strict:** 14+ rules (maximum security, most restrictive)

### Q: Can I apply just some rules from a profile?
**A:** Yes, use the `-RuleFilter` parameter to apply specific rules:
```powershell
Invoke-SecurityHardening -Session $session -RuleFilter @("Firewall*", "Account*")
```

### Q: Can I create custom profiles?
**A:** Not easily in the current version. You can modify .psd1 files, but custom development is required.

---

## Operation & Usage

### Q: How do I apply hardening?
**A:** Three steps:
1. Create session: `New-HardeningSession`
2. Apply rules: `Invoke-SecurityHardening`
3. Verify: `Test-HardeningCompliance`

### Q: What does WhatIf mode do?
**A:** It shows what changes will be made WITHOUT actually applying them:
```powershell
Invoke-SecurityHardening -Session $session -WhatIf
```

### Q: How long does hardening take?
**A:** Typically 5-15 seconds depending on the profile and rule count.

### Q: Can I undo hardening?
**A:** No automated undo. You'd need to manually revert settings or restore from backup.

### Q: What if hardening breaks an application?
**A:** Use WhatIf first to see what will change. If issues occur, you can:
1. Manually revert settings
2. Use a less restrictive profile (Basis instead of Strict)
3. Exclude specific rules using -RuleFilter

### Q: Can I apply hardening multiple times?
**A:** Yes, it's safe to re-apply. Already-compliant rules won't cause issues.

---

## Compliance & Verification

### Q: How do I check if my system is hardened?
**A:** Run compliance test:
```powershell
$compliance = Test-HardeningCompliance -Session $session
Write-Host "Compliance: $($compliance.CompliancePercentage)%"
```

### Q: What does the compliance percentage mean?
**A:** It's `(CompliantRules / TotalRules) * 100`. 100% means all rules are applied correctly.

### Q: Can I remediate non-compliant rules automatically?
**A:** Yes:
```powershell
Test-HardeningCompliance -Session $session -Remediate
```

### Q: How does remediation work?
**A:** It applies the same rules that were originally applied to fix any that became non-compliant.

---

## Reporting

### Q: What report formats are available?
**A:** JSON, CSV, HTML, and Text.

### Q: Which format should I use?
**A:** 
- **JSON:** For SIEM/programmatic processing
- **CSV:** For Excel/spreadsheet analysis
- **HTML:** For dashboards/documentation
- **Text:** For human-readable output

### Q: Can I export multiple reports?
**A:** Yes:
```powershell
Export-HardeningReport -ComplianceReport $compliance -Format JSON -OutputPath "report.json"
Export-HardeningReport -ComplianceReport $compliance -Format HTML -OutputPath "report.html"
```

---

## Remote & Deployment

### Q: Can I harden multiple systems at once?
**A:** Yes, use remote hardening:
```powershell
Invoke-RemoteHardening -ComputerName @("Server1", "Server2") -Profile Recommended
```

### Q: What's required for remote hardening?
**A:** PowerShell Remoting (WinRM) must be enabled on target systems.

### Q: Can I deploy via Group Policy?
**A:** Yes, use `Import-HardeningGPO` to create a GPO and link it to an OU.

### Q: How many systems can I harden remotely?
**A:** Limited by PowerShell Remoting capacity and network bandwidth. Typically, 10-100 systems is practical. For larger deployments, use Group Policy or batch in groups.

---

## Scheduling & Automation

### Q: Can I automate hardening checks?
**A:** Yes, use `New-HardeningSchedule`:
```powershell
New-HardeningSchedule -Profile Recommended -Schedule Daily -Time "02:00"
```

### Q: What schedule options are available?
**A:** OneTime, Daily, Weekly (specific day), Monthly (specific date).

### Q: Can I auto-remediate on schedule?
**A:** Yes:
```powershell
New-HardeningSchedule -Profile Recommended -Schedule Daily -AutoRemediate
```

### Q: Where are scheduled reports saved?
**A:** Default: `C:\ProgramData\WinOpsKit\Reports\`

---

## Email & Alerts

### Q: Can I get email alerts?
**A:** Yes, use `Send-HardeningAlert`.

### Q: What SMTP servers are supported?
**A:** Any SMTP server. Built-in support for TLS/SSL encryption.

### Q: How do I configure email alerts for non-compliance?
**A:** 
```powershell
if ($compliance.CompliancePercentage -lt 90) {
    Send-HardeningAlert -SmtpServer "smtp.company.com" `
        -AlertType Compliance -Severity Warning `
        -ComplianceReport $compliance
}
```

---

## Troubleshooting

### Q: I get "Access Denied" error
**A:** You're not running PowerShell as Administrator. Restart as Admin.

### Q: Compliance check says "Unknown" status
**A:** The verification command couldn't run. This is usually harmless. Check the Error property for details.

### Q: Remote hardening fails with connection error
**A:** 
1. Verify target system is reachable: `Test-Connection ServerName`
2. Verify WinRM is running: `Get-Service WinRM`
3. Check firewall allows port 5985/5986

### Q: Email alerts not sending
**A:** 
1. Verify SMTP connectivity: `Test-NetConnection smtp.server.com -Port 587`
2. Check credentials are correct
3. Verify SSL/TLS settings match server

### Q: Scheduled task not running
**A:** 
1. Check Task Scheduler for errors
2. Verify SYSTEM account has rights
3. Check PowerShell execution policy allows scripts

### Q: Report is empty or missing data
**A:** Ensure compliance check completed successfully before exporting:
```powershell
$compliance = Test-HardeningCompliance -Session $session
if ($null -eq $compliance) { Write-Host "Compliance check failed" }
```

---

## Security & Compliance

### Q: Is this GDPR/HIPAA compliant?
**A:** The system can help with compliance requirements. Always consult your compliance team for specific requirements.

### Q: Does it support specific compliance standards?
**A:** Rules are based on CIS Benchmarks, DISA STIGs, and NIST guidelines.

### Q: How do I track compliance over time?
**A:** Use `Get-HardeningTrendData`:
```powershell
Get-HardeningTrendData -ComputerName "Server1" -Days 30
```

### Q: Can I integrate with SIEM?
**A:** Yes, export to JSON and send to Splunk, Elasticsearch, Azure Sentinel, etc.

---

## Performance & Optimization

### Q: How much time does full hardening take?
**A:** 
- Single system: 5-15 seconds
- 10 systems remote: 30-60 seconds
- 100 systems remote: 5-10 minutes (with parallelization)

### Q: Is parallel execution safe?
**A:** Yes, rules are designed to execute safely in parallel.

### Q: Will hardening impact system performance?
**A:** No measurable impact. Hardening changes settings, not system processes.

---

## Advanced Usage

### Q: Can I write custom rules?
**A:** Yes, but it requires PowerShell and .psd1 file knowledge. Edit the profile .psd1 files to add custom rules.

### Q: How do I integrate with existing tools?
**A:** Export to JSON/CSV and import into your tools. Also supports direct SIEM integration via APIs.

### Q: Can I use this with Configuration Manager (SCCM)?
**A:** Yes, deploy hardening scripts as SCCM applications or package the modules for distribution.

---

## Support & Resources

### Q: Where can I get help?
**A:** Consult:
- [User Guide](HARDENING_USER_GUIDE.md)
- [Deployment Guide](HARDENING_DEPLOYMENT_GUIDE.md)
- [Architecture Guide](HARDENING_ARCHITECTURE.md)
- Function help: `Get-Help New-HardeningSession -Full`

### Q: How do I report bugs?
**A:** Use your internal support channels or the WinOpsKit GitHub issues (if applicable).

### Q: Is there a roadmap?
**A:** Check the project documentation for planned features.

---

**Version:** 1.0  
**Last Updated:** 2026-06-26  
**Status:** Production Ready
