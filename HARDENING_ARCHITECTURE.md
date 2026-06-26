# WinOpsKit Hardening System - Architecture Guide

**Version:** 1.0  
**Last Updated:** 2026-06-26  
**Audience:** Architects, System Designers

---

## System Architecture

### High-Level Component Diagram

```
┌─────────────────────────────────────────────────────────┐
│         WinOpsKit Hardening System                       │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌─────────────────┐        ┌──────────────────┐        │
│  │  User Interface │        │  Hardening Rules │        │
│  │  (PowerShell)   │        │  (Profiles)      │        │
│  └────────┬────────┘        └────────┬─────────┘        │
│           │                          │                   │
│           └──────────────┬───────────┘                   │
│                          │                               │
│              ┌───────────▼────────────┐                 │
│              │  Hardening Engine      │                 │
│              │  - Session Management  │                 │
│              │  - Rule Application    │                 │
│              │  - Compliance Testing  │                 │
│              └───────────┬────────────┘                 │
│                          │                               │
│        ┌─────────────────┼─────────────────┐            │
│        │                 │                 │            │
│  ┌─────▼──────┐   ┌─────▼──────┐  ┌──────▼─────┐     │
│  │  Registry  │   │  Services  │  │  Firewall  │     │
│  │  Rules     │   │  Rules     │  │  Rules     │     │
│  └────────────┘   └────────────┘  └────────────┘     │
│                                                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  Audit       │  │  UAC         │  │  Encryption  │  │
│  │  Rules       │  │  Rules       │  │  Rules       │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│                                                           │
└─────────────────────────────────────────────────────────┘
        │                      │                  │
        ▼                      ▼                  ▼
  ┌──────────────┐    ┌──────────────┐   ┌──────────────┐
  │   Reporting  │    │   Alerting   │   │   Automation │
  │   (4 formats)│    │   (Email)    │   │   (Scheduler)│
  └──────────────┘    └──────────────┘   └──────────────┘
```

---

## Core Components

### 1. Hardening Engine

**Responsibility:** Orchestrates hardening operations

**Key Functions:**
- `New-HardeningSession`: Initialize hardening session
- `Invoke-SecurityHardening`: Apply hardening rules
- `Test-HardeningCompliance`: Verify compliance
- `Invoke-RemoteHardening`: Remote deployment

**Features:**
- Profile-based rule application
- Session state management
- Parallel rule execution
- WhatIf support for dry-runs
- Comprehensive error handling

### 2. Profile System

**Responsibility:** Define security rules by profile

**Profiles:**
- **Basis:** 12 foundational rules
- **Recommended:** 18 enhanced rules
- **Strict:** 14+ maximum security rules

**Format:** PowerShell Data Files (.psd1)

**Rule Structure:**
```powershell
@{
    Rules = @(
        @{
            Name = "Account-MinimumPasswordLength"
            Type = "Registry"
            Description = "..."
            RuleDefinition = @{
                Path = "HKLM:\..."
                Name = "MinPasswordLength"
                Value = 12
            }
        }
    )
}
```

### 3. Rule Application Engine

**Responsibility:** Apply rules to system components

**Supported Rule Types:**
- **Registry:** Direct registry modifications
- **Service:** Windows service configuration
- **Firewall:** Windows Firewall rules
- **Audit:** Audit policy configuration
- **UAC:** User Access Control settings
- **Encryption:** Encryption policy settings

**Execution Strategy:**
- Registry/Service rules: Parallel execution
- Firewall/Audit rules: Sequential execution
- Error handling: Per-rule with continuation

### 4. Compliance Verification

**Responsibility:** Verify rule compliance

**Verification Process:**
1. Load profile rules
2. For each rule:
   - Execute verification command
   - Compare actual vs. expected value
   - Assign compliance status
3. Aggregate results
4. Generate compliance report

**Status Levels:**
- **Compliant:** Matches expected value
- **NonCompliant:** Doesn't match
- **Unknown:** Verification not available
- **Error:** Verification failed

### 5. Reporting System

**Responsibility:** Generate compliance reports

**Export Formats:**
- **JSON:** Programmatic processing
- **CSV:** Excel/spreadsheet analysis
- **HTML:** Dashboard/documentation
- **Text:** Human-readable format

**Report Contents:**
- Compliance percentage
- Per-rule details
- Category breakdown
- Trending data (if available)
- Timestamp and metadata

### 6. Advanced Features

**Email Alerting:**
- Compliance alerts
- Severity-based routing
- SMTP TLS/SSL support
- HTML-formatted messages

**Scheduling:**
- OneTime/Daily/Weekly/Monthly
- Auto-remediation option
- Report generation
- Windows Task Scheduler integration

**Remote Deployment:**
- PowerShell Remoting
- Batch operations
- Parallel execution
- Multi-system management

**Group Policy Integration:**
- GPO creation from profiles
- Domain-wide deployment
- Registry policy configuration
- Organizational Unit linking

**Trending & Analytics:**
- Historical compliance tracking
- Compliance velocity calculation
- Trend direction detection
- 7-day forecasting

---

## Module Dependency Hierarchy

```
┌──────────────────────────────────────────┐
│  User Scripts / Automation               │
└────────────────┬─────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────┐
│  System Module (System.psm1)             │
│  - Hardening Functions                   │
│  - Remote Deployment                     │
│  - Scheduling                            │
└────────────────┬─────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────┐
│  Core Module (Core.psm1)                 │
│  - Logging (Write-Log)                   │
│  - Error Handling (Write-ErrorLog)       │
│  - Utility Functions                     │
└────────────────┬─────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────┐
│  PowerShell Built-ins                    │
│  - Registry (Registry provider)          │
│  - Services (Get-Service, etc.)          │
│  - Firewall (NetSecurity cmdlets)        │
│  - WMI (Get-WmiObject, etc.)            │
└──────────────────────────────────────────┘
```

---

## Data Flow

### Hardening Operation Flow

```
User Request
    │
    ▼
New-HardeningSession
    │
    ├─ Validate Profile
    ├─ Validate OS Version
    └─ Create Session Object
    │
    ▼
Invoke-SecurityHardening
    │
    ├─ Load Profile Rules
    ├─ Filter Rules (if specified)
    ├─ For each rule:
    │  ├─ Route to handler (Registry/Service/Firewall/etc.)
    │  ├─ Apply rule
    │  └─ Log result
    └─ Return summary
    │
    ▼
Compliance Verification
    │
    ├─ Load Profile Rules
    ├─ For each rule:
    │  ├─ Execute verification command
    │  ├─ Compare actual vs. expected
    │  └─ Assign status
    └─ Aggregate results
    │
    ▼
Report Generation
    │
    ├─ Format output (JSON/CSV/HTML/Text)
    ├─ Add metadata
    └─ Write to file/output
    │
    ▼
Complete
```

---

## Security Considerations

### Rule Safety

- **No Destructive Operations:** Rules don't delete data
- **Reversible:** Most changes can be manually reverted
- **Logging:** All operations logged with details
- **Preview Mode:** -WhatIf shows changes before applying

### Credential Handling

- **No Plaintext Storage:** Credentials never stored
- **PSCredential Support:** Secure credential passing
- **TLS/SSL:** Email alerts use encrypted SMTP

### Access Control

- **Admin Required:** System modifications need admin rights
- **Session Isolation:** Each session is independent
- **Input Validation:** All parameters validated

---

## Performance Characteristics

### Execution Time

- **Profile Loading:** < 1 second
- **Rule Application:** 5-10 seconds (depending on rule count)
- **Compliance Verification:** 5-20 seconds
- **Report Generation:** < 1 second

### Scalability

- **Single System:** Instant
- **10 Systems (Remote):** 30-60 seconds
- **100 Systems (Remote, Parallel):** 5-10 minutes
- **Large Rule Sets:** Linear performance with rule count

### Resource Usage

- **Memory:** ~50-100 MB typical
- **CPU:** Minimal, mostly waiting on system operations
- **Disk:** < 10 MB for reports
- **Network:** Minimal for local operations

---

## Extension Points

### Adding Custom Rules

1. Modify profile .psd1 file
2. Add rule definition with Type and RuleDefinition
3. Ensure rule type handler exists or add new handler
4. Test with -WhatIf before full deployment

### Adding New Report Format

1. Create format generation function
2. Add to Export-HardeningReport switch statement
3. Test with real compliance data

### Adding New Alert Type

1. Extend Send-HardeningAlert AlertType validation
2. Add alert type handler logic
3. Test with real data

---

## Compliance Standards

The hardening rules implement standards from:

- **CIS Benchmarks:** Center for Internet Security
- **DISA STIGs:** Defense Information Systems Agency
- **Windows Security Baselines:** Microsoft
- **NIST SP 800-53:** NIST Cybersecurity Framework

---

**Version:** 1.0  
**Last Updated:** 2026-06-26  
**Status:** Production Ready
