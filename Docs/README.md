# WinHarden Documentation Index

Complete documentation for the WinHarden PowerShell automation and hardening toolkit.

---

## Documentation Structure

### [Automation Setup](./automations/)

Deployment and configuration guides for WinHarden automated tasks in Windows Task Scheduler.

| Document | Purpose |
|----------|---------|
| [01_QUICKSTART_GUIDE.md](./automations/01_QUICKSTART_GUIDE.md) | 5-minute deployment guide for initial setup |
| [02_AUTOMATION_SETUP_GUIDE.md](./automations/02_AUTOMATION_SETUP_GUIDE.md) | Comprehensive setup and configuration reference |
| [03_CATCHUP_CONFIGURATION_GUIDE.md](./automations/03_CATCHUP_CONFIGURATION_GUIDE.md) | Missed task recovery and catchup mechanisms |

**Best for:** Getting automated security monitoring running on your system

**Tasks covered:**
- Daily-Security-Monitor
- Monitor-Windows-Updates
- Detect-Configuration-Drift
- Monthly-Compliance-Audit
- Archive-Old-Reports

---

### [Hardening Documentation](./hardening/)

Deployment, configuration, and operational guides for Windows hardening.

| Document | Purpose |
|----------|---------|
| [01_USER_GUIDE.md](./hardening/01_USER_GUIDE.md) | Getting started with hardening deployment |
| [02_DEPLOYMENT_GUIDE.md](./hardening/02_DEPLOYMENT_GUIDE.md) | Production deployment instructions |
| [03_ARCHITECTURE.md](./hardening/03_ARCHITECTURE.md) | System design and architectural decisions |
| [04_SIEM_INTEGRATION.md](./hardening/04_SIEM_INTEGRATION.md) | Logging and SIEM integration setup |
| [05_PERFORMANCE.md](./hardening/05_PERFORMANCE.md) | Performance tuning and optimization |
| [06_FAQ.md](./hardening/06_FAQ.md) | Frequently asked questions and troubleshooting |
| [07_FULL_REPORT.md](./hardening/07_FULL_REPORT.md) | Complete hardening implementation report |

**Best for:** Understanding and implementing Windows Server security hardening

**Topics covered:**
- Account policies and restrictions
- Password policies
- User account control (UAC)
- Windows Firewall configuration
- Audit policies and logging
- Security services hardening

---

### [Audit & Compliance](./audit/)

Compliance verification, security assessments, and audit documentation.

| Document | Purpose |
|----------|---------|
| [00_AUDIT_REPORT_EXECUTIVE_SUMMARY.md](./audit/00_AUDIT_REPORT_EXECUTIVE_SUMMARY.md) | High-level compliance status overview |
| [01_SECURITY_ASSESSMENT.md](./audit/01_SECURITY_ASSESSMENT.md) | Detailed security posture evaluation |
| [02_QUALITY_METRICS.md](./audit/02_QUALITY_METRICS.md) | Code quality and testing metrics |
| [03_COMPLIANCE_VERIFICATION.md](./audit/03_COMPLIANCE_VERIFICATION.md) | Compliance validation and sign-off |

**Best for:** Compliance reporting, security assessments, and executive dashboards

**Topics covered:**
- Hardening compliance status
- Security gaps and remediations
- Code quality metrics
- Test coverage reports
- Compliance certification sign-off

---

## Quick Start by Use Case

### I want to deploy hardening to Windows Server
1. Start with [hardening/01_USER_GUIDE.md](./hardening/01_USER_GUIDE.md)
2. Follow deployment steps in [hardening/02_DEPLOYMENT_GUIDE.md](./hardening/02_DEPLOYMENT_GUIDE.md)
3. Review architecture at [hardening/03_ARCHITECTURE.md](./hardening/03_ARCHITECTURE.md)

### I want to set up automated monitoring
1. Quick start: [automations/01_QUICKSTART_GUIDE.md](./automations/01_QUICKSTART_GUIDE.md)
2. Deep dive: [automations/02_AUTOMATION_SETUP_GUIDE.md](./automations/02_AUTOMATION_SETUP_GUIDE.md)
3. Advanced recovery: [automations/03_CATCHUP_CONFIGURATION_GUIDE.md](./automations/03_CATCHUP_CONFIGURATION_GUIDE.md)

### I need to verify compliance
1. Executive overview: [audit/00_AUDIT_REPORT_EXECUTIVE_SUMMARY.md](./audit/00_AUDIT_REPORT_EXECUTIVE_SUMMARY.md)
2. Detailed assessment: [audit/01_SECURITY_ASSESSMENT.md](./audit/01_SECURITY_ASSESSMENT.md)
3. Verification sign-off: [audit/03_COMPLIANCE_VERIFICATION.md](./audit/03_COMPLIANCE_VERIFICATION.md)

### I need to integrate with SIEM
1. Integration guide: [hardening/04_SIEM_INTEGRATION.md](./hardening/04_SIEM_INTEGRATION.md)
2. Logging verification: Check automation logs at `C:\Repos\WinHarden\logs\`

### I have performance concerns
1. Optimization guide: [hardening/05_PERFORMANCE.md](./hardening/05_PERFORMANCE.md)
2. Task scheduling: [automations/02_AUTOMATION_SETUP_GUIDE.md#performance-considerations](./automations/02_AUTOMATION_SETUP_GUIDE.md#performance-considerations)

---

## Document Types

### Setup Guides
Quick-start and step-by-step deployment instructions.
- [automations/01_QUICKSTART_GUIDE.md](./automations/01_QUICKSTART_GUIDE.md)
- [hardening/01_USER_GUIDE.md](./hardening/01_USER_GUIDE.md)
- [hardening/02_DEPLOYMENT_GUIDE.md](./hardening/02_DEPLOYMENT_GUIDE.md)

### Configuration Guides
Detailed configuration, tuning, and optimization documentation.
- [automations/02_AUTOMATION_SETUP_GUIDE.md](./automations/02_AUTOMATION_SETUP_GUIDE.md)
- [automations/03_CATCHUP_CONFIGURATION_GUIDE.md](./automations/03_CATCHUP_CONFIGURATION_GUIDE.md)
- [hardening/05_PERFORMANCE.md](./hardening/05_PERFORMANCE.md)

### Reference Documentation
Architecture, design, and technical reference materials.
- [hardening/03_ARCHITECTURE.md](./hardening/03_ARCHITECTURE.md)
- [hardening/04_SIEM_INTEGRATION.md](./hardening/04_SIEM_INTEGRATION.md)

### Assessment & Compliance
Audit reports, compliance verification, and security assessments.
- [audit/00_AUDIT_REPORT_EXECUTIVE_SUMMARY.md](./audit/00_AUDIT_REPORT_EXECUTIVE_SUMMARY.md)
- [audit/01_SECURITY_ASSESSMENT.md](./audit/01_SECURITY_ASSESSMENT.md)
- [audit/02_QUALITY_METRICS.md](./audit/02_QUALITY_METRICS.md)
- [audit/03_COMPLIANCE_VERIFICATION.md](./audit/03_COMPLIANCE_VERIFICATION.md)

### Support & FAQs
Troubleshooting, common questions, and help resources.
- [hardening/06_FAQ.md](./hardening/06_FAQ.md)
- [automations/01_QUICKSTART_GUIDE.md#troubleshooting](./automations/01_QUICKSTART_GUIDE.md#troubleshooting)
- [automations/02_AUTOMATION_SETUP_GUIDE.md#troubleshooting](./automations/02_AUTOMATION_SETUP_GUIDE.md#troubleshooting)
- [automations/03_CATCHUP_CONFIGURATION_GUIDE.md#troubleshooting](./automations/03_CATCHUP_CONFIGURATION_GUIDE.md#troubleshooting)

---

## Key Resources

### Logs & Reports
- **Audit Logs:** `C:\Repos\WinHarden\logs\`
- **Report Archive:** `C:\Repos\WinHarden\logs\archive\`
- **Task Scheduler:** `taskschd.msc` (Hardening folder)

### Event Viewer
- **Task Scheduler Events:** Event Viewer > Windows Logs > System
- **Security Audits:** Event Viewer > Windows Logs > Security

### PowerShell Commands

```powershell
# List all WinHarden scheduled tasks
Get-ScheduledTask -TaskPath '\Hardening\*' | Format-Table TaskName, State

# View task status and next run time
Get-ScheduledTask -TaskPath '\Hardening\*' | Get-ScheduledTaskInfo

# Run a task manually (for testing)
schtasks /run /tn "Hardening\Daily-Security-Monitor"

# View recent task execution events
Get-EventLog -LogName System -Source "TaskScheduler" -Newest 20 | Format-Table TimeGenerated, Message
```

---

## Document Navigation

**Automation Setup:**
- [Quickstart](./automations/01_QUICKSTART_GUIDE.md) [Setup](./automations/02_AUTOMATION_SETUP_GUIDE.md) [Catchup](./automations/03_CATCHUP_CONFIGURATION_GUIDE.md)

**Hardening Implementation:**
- [User Guide](./hardening/01_USER_GUIDE.md) [Deployment](./hardening/02_DEPLOYMENT_GUIDE.md) [Architecture](./hardening/03_ARCHITECTURE.md) [SIEM](./hardening/04_SIEM_INTEGRATION.md) [Performance](./hardening/05_PERFORMANCE.md) [FAQ](./hardening/06_FAQ.md) [Full Report](./hardening/07_FULL_REPORT.md)

**Audit & Compliance:**
- [Executive Summary](./audit/00_AUDIT_REPORT_EXECUTIVE_SUMMARY.md) [Security Assessment](./audit/01_SECURITY_ASSESSMENT.md) [Quality Metrics](./audit/02_QUALITY_METRICS.md) [Compliance Verification](./audit/03_COMPLIANCE_VERIFICATION.md)

---

## Version Information

| Component | Version | Updated |
|-----------|---------|---------|
| Automation Guides | 1.0 | 2026-06-26 |
| Hardening Guides | 1.0 | 2026-06-26 |
| Audit Reports | 1.0 | 2026-06-26 |
| Documentation Index | 1.0 | 2026-06-26 |

---

## Getting Help

1. **Quick Questions:** See [hardening/06_FAQ.md](./hardening/06_FAQ.md) for common issues
2. **Setup Issues:** Review troubleshooting sections in relevant setup guide
3. **Automation Problems:** Check [automations/03_CATCHUP_CONFIGURATION_GUIDE.md#troubleshooting](./automations/03_CATCHUP_CONFIGURATION_GUIDE.md#troubleshooting)
4. **Compliance Questions:** Review [audit/03_COMPLIANCE_VERIFICATION.md](./audit/03_COMPLIANCE_VERIFICATION.md)

---

## Documentation Standards

All documentation follows these standards:
- ASCII-only characters (no Unicode symbols)
- Clear navigation between related documents
- Organized by audience level (Quick-start to Advanced)
- Task-oriented (how-to before theory)
- Troubleshooting sections in every setup guide

---

**Last Updated:** 2026-06-26  
**Documentation Version:** 1.0  
**Maintained By:** WinHarden Project Team
