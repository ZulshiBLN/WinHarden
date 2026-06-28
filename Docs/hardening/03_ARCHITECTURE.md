# WinHarden - Architecture

**Technical design, components, and system architecture of WinHarden.**

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Component Architecture](#component-architecture)
3. [Hardening Categories](#hardening-categories)
4. [Baseline System](#baseline-system)
5. [Compliance Engine](#compliance-engine)
6. [Drift Detection](#drift-detection)
7. [Data Flow](#data-flow)
8. [Extensibility](#extensibility)

---

## System Overview

### Design Principles

WinHarden is built on the following architectural principles:

1. **Modularity** - Independent hardening categories
2. **Idempotency** - Safe to run multiple times
3. **Auditability** - All actions logged and trackable
4. **Compliance** - Standards-based hardening (CIS, NIST)
5. **Safety** - Graceful error handling, rollback capability
6. **Performance** - Minimal system impact

### High-Level Architecture

```
[User Interface Layer]
     |
     v
[PowerShell Cmdlets]
     |
     v
[Hardening Engine]
  |      |      |
  v      v      v
[Baseline] [Compliance] [Remediation]
  |      |      |
  v      v      v
[Windows Components]
  - Firewall Rules
  - Registry Settings
  - Service Configuration
  - Audit Policy
  - User Accounts
```

---

## Component Architecture

### Core Components

#### 1. Baseline Management Module

**Purpose:** Capture and manage system configuration baselines

**Components:**
- `New-HardeningBaseline` - Create baseline from current state
- `Get-HardeningBaseline` - Retrieve existing baselines
- `Update-HardeningBaseline` - Update baseline configuration
- `Compare-Baseline` - Compare two baselines

**Storage:**
```
<WINHARDEN_REPO>\baselines\
  ├── Default-Baseline.xml
  ├── Production-Baseline.xml
  ├── Development-Baseline.xml
  └── [Custom-Baselines].xml
```

**Baseline Format (XML):**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Baseline>
  <Name>Production-Baseline</Name>
  <Description>Production hardening baseline</Description>
  <CreatedDate>2026-06-27T10:00:00Z</CreatedDate>
  <Categories>
    <Category Name="Firewall">
      <Setting Name="Enabled" Value="true" />
      <Setting Name="DefaultInbound" Value="Block" />
      <Setting Name="DefaultOutbound" Value="Allow" />
    </Category>
    <Category Name="Services">
      <Service Name="RDP" Enabled="false" />
      <Service Name="WinRM" Enabled="false" />
    </Category>
    <Category Name="Registry">
      <Registry Path="HKLM:\System\CurrentControlSet\Control\Lsa" 
                Key="RestrictAnonymous" Value="2" Type="DWORD" />
    </Category>
  </Categories>
</Baseline>
```

#### 2. Compliance Engine

**Purpose:** Test system against baseline for compliance violations

**Components:**
- `Test-SystemCompliance` - Run compliance checks
- `Get-ComplianceResult` - Retrieve compliance results
- `Export-ComplianceReport` - Export compliance data

**Compliance Check Types:**
```
Account Policies
├── Password minimum length
├── Password maximum age
├── Account lockout threshold
└── Account lockout duration

Firewall
├── Firewall enabled
├── Inbound rules
├── Outbound rules
└── Exceptions

Services
├── Unnecessary services disabled
├── Critical services enabled
├── Service startup types
└── Service permissions

Registry
├── Security keys
├── Performance keys
├── System keys
└── User keys

Audit Policy
├── Account logon events
├── Account management
├── Privilege use
└── Object access
```

#### 3. Remediation Engine

**Purpose:** Apply hardening configurations to fix violations

**Components:**
- `Invoke-HardeningRemediation` - Apply hardening fixes
- `Get-RemediationStatus` - Check remediation progress
- `Undo-HardeningRemediation` - Rollback changes

**Remediation Process:**
```
[Compliance Check]
      |
      v
[Identify Violations]
      |
      v
[Generate Remediation Plan]
      |
      v
[Backup Current State]
      |
      v
[Apply Changes]
      |
      v
[Verify Changes]
      |
      v
[Log Results]
```

#### 4. Drift Detection Engine

**Purpose:** Identify unauthorized configuration changes

**Components:**
- `Get-SecurityDrift` - Detect drift from baseline
- `Report-SecurityDrift` - Generate drift reports
- `Remediate-Drift` - Restore to baseline

**Drift Types:**
```
Registry Drift
├── Key added
├── Key deleted
├── Value changed
└── Type changed

Firewall Drift
├── Rule added
├── Rule deleted
└── Rule modified

Service Drift
├── Service state changed
├── Startup type changed
└── Service deleted

User Account Drift
├── Account created
├── Account deleted
├── Password changed
└── Permissions changed
```

#### 5. Audit & Logging Module

**Purpose:** Track all hardening operations

**Components:**
- `Write-HardeningLog` - Log operations
- `Get-HardeningLog` - Retrieve logs
- `Export-AuditTrail` - Export audit data

**Log Locations:**
```
<WINHARDEN_REPO>\logs\
├── hardening_operations.log
├── compliance_*.csv
├── drift_*.csv
├── remediation_*.log
└── audit_*.txt
```

---

## Hardening Categories

### Category 1: Firewall Hardening

**Configuration Points:**
- Windows Defender Firewall state (Enabled/Disabled)
- Inbound policy (Block/Allow)
- Outbound policy (Allow/Block)
- Logging configuration
- Rule exceptions

**Applied Rules:**
```powershell
Disable-NetFirewallProfile  # Ensure all profiles hardened
Set-NetFirewallProfile -DefaultInboundAction Block -DefaultOutboundAction Allow
Add-NetFirewallRule -DisplayName "Allow RDP" -Direction Inbound -Protocol TCP -LocalPort 3389
```

### Category 2: Service Hardening

**Critical Services (Must Enable):**
- wuauserv (Windows Update)
- winlogon (Winlogon)
- lsass (Local Security Authority)
- EventLog (Event Log Service)
- Eventlog

**Unnecessary Services (Must Disable):**
- RDP (Terminal Services)
- WinRM (Windows Remote Management)
- SNMP (Simple Network Management)
- Telnet
- UPnP Device Host

**Service Hardening:**
```powershell
Set-Service -Name RDP -StartupType Disabled
Set-Service -Name WinRM -StartupType Disabled
# Verify service is disabled
Get-Service -Name RDP | Select-Object Status, StartType
```

### Category 3: Registry Hardening

**Critical Registry Settings:**
```
HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Lsa
├── RestrictAnonymous = 2 (Restrict Anonymous to no access)
├── RestrictRemoteSAM = "O:BAG:BAD:(A;;RC;;;BA)"
└── LimitBlankPasswordUse = 1

HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Winlogon
├── AutoLogonSID = "" (No auto-logon)
└── DefaultUserName = "" (No default user)

HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies
├── System\DontDisplayLastUserName = 1
├── System\EnableUIADesktopToggle = 0
└── System\PromptOnSecureDesktopTermination = 1
```

### Category 4: Audit Policy Hardening

**Enabled Audit Categories:**
- Account Logon Events
- Account Management
- Directory Service Access
- Logon/Logoff
- Object Access
- Policy Change
- Privilege Use
- Process Tracking
- System

**Audit Policy Configuration:**
```powershell
auditpol /set /category:"Account Logon" /success:enable /failure:enable
auditpol /set /category:"Account Management" /success:enable /failure:enable
auditpol /set /category:"Logon/Logoff" /success:enable /failure:enable
```

### Category 5: User Account Hardening

**Password Policies:**
- Minimum password length: 14 characters
- Password complexity: Enabled
- Password history: 24 passwords
- Maximum password age: 60 days
- Minimum password age: 1 day

**Account Lockout Policies:**
- Account lockout threshold: 5 invalid attempts
- Account lockout duration: 30 minutes
- Reset account lockout counter: 30 minutes

**Configuration:**
```powershell
net accounts /minpwlen:14
net accounts /uniquepw:24
net accounts /maxpwage:60
net accounts /minpwage:1
net accounts /lockoutthreshold:5
net accounts /lockoutduration:30
```

### Category 6: Windows Update Hardening

**Configuration:**
- Automatic updates: Enabled
- Download updates: Automatic
- Install updates: Scheduled (monthly)
- Quality updates: Install immediately
- Definition updates: Auto-install

**Implementation:**
```powershell
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" `
    -Name "NoAutoUpdate" -Value 0
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" `
    -Name "AUOptions" -Value 3  # Auto-download and notify for install
```

---

## Baseline System

### Baseline Structure

```
Baseline
├── Metadata
│   ├── Name
│   ├── Description
│   ├── CreatedDate
│   ├── CreatedBy
│   └── Version
├── Configuration
│   ├── Firewall Rules
│   ├── Service States
│   ├── Registry Settings
│   ├── Audit Policies
│   └── Account Settings
└── Policies
    ├── Enforcement Level
    ├── Severity Mappings
    └── Remediation Actions
```

### Baseline Lifecycle

```
[Create Baseline]
      |
      v
[Test Baseline]
      |
      v
[Approve Baseline]
      |
      v
[Deploy Baseline]
      |
      v
[Monitor Baseline Compliance]
      |
      v
[Update Baseline] (as needed)
      |
      v
[Archive Old Baseline]
```

---

## Compliance Engine

### Compliance Check Process

```
1. Load Baseline Configuration
   ├── Read baseline file (XML)
   ├── Parse settings
   └── Create check list

2. Run Compliance Checks
   ├── Check each category
   │   ├── Firewall rules
   │   ├── Service states
   │   ├── Registry settings
   │   ├── Account policies
   │   └── Audit policies
   └── Collect results

3. Compare Results
   ├── Current state vs Expected state
   ├── Identify violations
   └── Classify severity

4. Generate Report
   ├── Compliance percentage
   ├── Failed checks
   ├── Passed checks
   └── Recommendations
```

### Compliance Scoring

```
Compliance Score = (Passed Checks / Total Checks) * 100

Example:
Passed: 95 checks
Failed: 5 checks
Total: 100 checks
Compliance: 95%
```

### Severity Levels

| Level | Range | Impact | Action |
|-------|-------|--------|--------|
| Critical | 95-100% | System highly exposed | Immediate remediation |
| High | 85-94% | Significant vulnerabilities | Urgent remediation |
| Medium | 75-84% | Notable issues | Schedule remediation |
| Low | <75% | Minor violations | Planned remediation |

---

## Drift Detection

### Drift Detection Process

```
1. Load Baseline State
   ├── Read baseline configuration
   └── Create expected-state model

2. Capture Current State
   ├── Query firewall rules
   ├── Query service states
   ├── Query registry settings
   ├── Query account policies
   └── Query audit configuration

3. Compare States
   ├── For each configuration item:
   │   ├── Current == Expected?
   │   └── If NO: Mark as DRIFT
   └── Classify drift severity

4. Report Drift
   ├── List all drift items
   ├── Provide remediation steps
   └── Export to CSV/JSON
```

### Drift Types

```
Addition Drift
├── New firewall rule added
├── New service installed
└── New user account created

Deletion Drift
├── Rule deleted
├── Service removed
└── Account deleted

Modification Drift
├── Setting value changed
├── Service startup type changed
└── Account permissions modified

Configuration Drift
├── Sensitive settings changed
├── Security policies relaxed
└── Hardening controls disabled
```

---

## Data Flow

### Hardening Operation Flow

```
User Input
    |
    v
Cmdlet Execution
    |
    v
[Pre-checks]
├── Admin verification
├── Baseline validation
└── Dependency check
    |
    v
[Execution]
├── Backup current state
├── Apply changes
├── Verify changes
└── Log operation
    |
    v
Output Report
    |
    v
Logs & Artifacts
```

### Compliance Check Flow

```
Start Compliance Test
    |
    v
Load Baseline
    |
    v
For Each Check:
├── Collect current setting
├── Compare to baseline
├── Record result (Pass/Fail)
└── Classify severity
    |
    v
Generate Results
├── Calculate compliance %
├── List violations
└── Provide remediation
    |
    v
Export Report
```

---

## Extensibility

### Adding Custom Hardening Rules

```powershell
# Structure for custom hardening function
function New-CustomHardeningRule {
    param(
        [string]$RuleName,
        [string]$Description,
        [scriptblock]$CheckScript,
        [scriptblock]$RemediationScript
    )
    
    # Define rule
    $rule = @{
        Name = $RuleName
        Description = $Description
        Check = $CheckScript
        Remediation = $RemediationScript
    }
    
    # Register rule
    Add-HardeningRule -Rule $rule
}
```

### Integration Points

1. **Baseline Export/Import**
   - Support for external baseline sources
   - XML, JSON format support

2. **Custom Remediation Scripts**
   - Plugin-based remediation
   - Custom severity mappings

3. **SIEM Integration**
   - Export to Splunk, ELK, ArcSight
   - Webhook notifications

4. **Configuration Management**
   - Integration with Ansible, Puppet, Chef
   - Infrastructure-as-Code support

5. **Compliance Frameworks**
   - CIS Benchmarks
   - NIST guidelines
   - Custom compliance mappings

---

**Document Version:** 2.0  
**Last Updated:** 2026-06-27  
**Target Audience:** Architects, Security Engineers, System Designers  
**Complexity Level:** Advanced
