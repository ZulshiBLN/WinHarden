# WinHarden Documentation

Comprehensive documentation for the WinHarden PowerShell automation and security hardening toolkit for Windows Server.

**Status:** Infrastructure complete (9 ADRs accepted) | Implementation in progress  
**Updated:** 2026-06-27

---

## Three Core Documentation Areas

### [Hardening](./hardening/) - Windows Server Security
Deploy, configure, and monitor security hardening measures.

**Start here if you want to:**
- Lock down Windows Server security posture
- Understand what hardening rules apply to your system
- Deploy hardening changes and verify compliance

**Key documents:**
- [01_USER_GUIDE.md](./hardening/01_USER_GUIDE.md) — Getting started
- [02_DEPLOYMENT_GUIDE.md](./hardening/02_DEPLOYMENT_GUIDE.md) — Production deployment
- [03_ARCHITECTURE.md](./hardening/03_ARCHITECTURE.md) — System design
- [04_SIEM_INTEGRATION.md](./hardening/04_SIEM_INTEGRATION.md) — Logging integration
- [05_PERFORMANCE.md](./hardening/05_PERFORMANCE.md) — Tuning and optimization
- [06_FAQ.md](./hardening/06_FAQ.md) — Troubleshooting and answers
- [07_FULL_REPORT.md](./hardening/07_FULL_REPORT.md) — Complete implementation report

### [Automations](./automations/) - Scheduled Monitoring Tasks
Set up and manage automated security monitoring in Windows Task Scheduler.

**Start here if you want to:**
- Enable continuous security monitoring
- Deploy scheduled tasks for drift detection and compliance audits
- Configure task recovery and error handling

**Key documents:**
- [01_QUICKSTART_GUIDE.md](./automations/01_QUICKSTART_GUIDE.md) — 5-minute setup
- [02_AUTOMATION_SETUP_GUIDE.md](./automations/02_AUTOMATION_SETUP_GUIDE.md) — Full configuration
- [03_CATCHUP_CONFIGURATION_GUIDE.md](./automations/03_CATCHUP_CONFIGURATION_GUIDE.md) — Missed task recovery

### [Audit](./audit/) - Compliance and Security Assessment
Verify compliance status, security posture, and code quality metrics.

**Start here if you want to:**
- Generate compliance reports for stakeholders
- Understand security gaps and remediations
- Review code quality and test coverage

**Key documents:**
- [00_AUDIT_REPORT_EXECUTIVE_SUMMARY.md](./audit/00_AUDIT_REPORT_EXECUTIVE_SUMMARY.md) — Overview for decision makers
- [01_SECURITY_ASSESSMENT.md](./audit/01_SECURITY_ASSESSMENT.md) — Detailed security analysis
- [02_QUALITY_METRICS.md](./audit/02_QUALITY_METRICS.md) — Code and test metrics
- [03_COMPLIANCE_VERIFICATION.md](./audit/03_COMPLIANCE_VERIFICATION.md) — Verification sign-off

---

## Quick Navigation by Task

**I'm deploying hardening to Windows Server**

1. Read [hardening/01_USER_GUIDE.md](./hardening/01_USER_GUIDE.md)
2. Follow [hardening/02_DEPLOYMENT_GUIDE.md](./hardening/02_DEPLOYMENT_GUIDE.md)
3. Review [hardening/03_ARCHITECTURE.md](./hardening/03_ARCHITECTURE.md) for architectural details

**I'm setting up automated monitoring**

1. Quick setup: [automations/01_QUICKSTART_GUIDE.md](./automations/01_QUICKSTART_GUIDE.md)
2. Full configuration: [automations/02_AUTOMATION_SETUP_GUIDE.md](./automations/02_AUTOMATION_SETUP_GUIDE.md)
3. Advanced recovery: [automations/03_CATCHUP_CONFIGURATION_GUIDE.md](./automations/03_CATCHUP_CONFIGURATION_GUIDE.md)

**I need to verify compliance**

1. Start with: [audit/00_AUDIT_REPORT_EXECUTIVE_SUMMARY.md](./audit/00_AUDIT_REPORT_EXECUTIVE_SUMMARY.md)
2. Details: [audit/01_SECURITY_ASSESSMENT.md](./audit/01_SECURITY_ASSESSMENT.md)
3. Sign-off: [audit/03_COMPLIANCE_VERIFICATION.md](./audit/03_COMPLIANCE_VERIFICATION.md)

**I need to integrate logging with SIEM**

See [hardening/04_SIEM_INTEGRATION.md](./hardening/04_SIEM_INTEGRATION.md)

**I have performance concerns**

See [hardening/05_PERFORMANCE.md](./hardening/05_PERFORMANCE.md)

**I have questions**

See [hardening/06_FAQ.md](./hardening/06_FAQ.md)

---

## Useful PowerShell Commands

View task status and logs:

```powershell
# List all WinHarden scheduled tasks
Get-ScheduledTask -TaskPath '\Hardening\*' | Format-Table TaskName, State

# Show task execution details
Get-ScheduledTask -TaskPath '\Hardening\*' | Get-ScheduledTaskInfo

# Run a task manually (for testing)
schtasks /run /tn "Hardening\Daily-Security-Monitor"

# View recent task execution events
Get-EventLog -LogName System -Source "TaskScheduler" -Newest 20
```

---

## Key Paths and Locations

| Resource | Location |
|----------|----------|
| Logs and reports | `C:\Repos\WinHarden\logs\` |
| Archived reports | `C:\Repos\WinHarden\logs\archive\` |
| Scheduled tasks | Task Scheduler > Hardening folder |
| Task events | Event Viewer > Windows Logs > System |
| Security audit logs | Event Viewer > Windows Logs > Security |

---

## Document Organization

**Setup & Deployment** — Get started and deploy to production
- Quickstart guides with minimal steps
- Detailed deployment procedures
- Prerequisites and prerequisites verification

**Configuration & Tuning** — Customize behavior and optimize performance
- Task scheduling and automation configuration
- Performance optimization and resource allocation
- Catchup and recovery mechanisms

**Architecture & Reference** — Technical background and integration
- System design and architectural decisions
- SIEM and logging integration
- Compliance framework alignment

**Assessment & Reporting** — Verify status and document compliance
- Executive summaries for stakeholders
- Detailed security assessments
- Code quality and test coverage metrics
- Compliance verification and sign-off

---

## Getting Help

**For setup issues:**
Review the troubleshooting section in the relevant setup guide:
- [automations/01_QUICKSTART_GUIDE.md#troubleshooting](./automations/01_QUICKSTART_GUIDE.md#troubleshooting)
- [automations/02_AUTOMATION_SETUP_GUIDE.md#troubleshooting](./automations/02_AUTOMATION_SETUP_GUIDE.md#troubleshooting)
- [hardening/01_USER_GUIDE.md](./hardening/01_USER_GUIDE.md)

**For common questions:**
See [hardening/06_FAQ.md](./hardening/06_FAQ.md)

**For automation problems:**
See [automations/03_CATCHUP_CONFIGURATION_GUIDE.md#troubleshooting](./automations/03_CATCHUP_CONFIGURATION_GUIDE.md#troubleshooting)

**For compliance questions:**
See [audit/03_COMPLIANCE_VERIFICATION.md](./audit/03_COMPLIANCE_VERIFICATION.md)

---

**Last Updated:** 2026-06-27  
**Documentation Version:** 1.0  
**Maintained By:** WinHarden Project Team
