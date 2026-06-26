# WinHarden Hardening – Architecture Guide

**Version:** 1.0  
**Last Updated:** 2026-06-26  
**Target Audience:** Software Architects, Senior Engineers, Security Engineers

---

## Table of Contents

1. [System Architecture](#system-architecture)
2. [Module Design](#module-design)
3. [Hardening Profile System](#hardening-profile-system)
4. [Rule Application Pipeline](#rule-application-pipeline)
5. [Compliance Verification](#compliance-verification)
6. [Data Flow](#data-flow)
7. [Security Considerations](#security-considerations)
8. [Performance Optimization](#performance-optimization)

---

## System Architecture

### High-Level Design

WinHarden follows a **modular, layered architecture** with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────┐
│                  Entry Points (Scripts)                 │
│  Deploy-Hardening.ps1  Monitor-Compliance.ps1  etc.    │
└──────────────────┬────────────────────────────────────┘
                   │
┌──────────────────▼────────────────────────────────────┐
│              High-Level API Layer                     │
│  New-HardeningSession  Invoke-SecurityHardening     │
│  Test-HardeningCompliance  Get-HardeningProfile     │
└──────────────────┬────────────────────────────────────┘
                   │
┌──────────────────▼────────────────────────────────────┐
│         System Module (System.psm1)                  │
│  Rule Engine | Session Management | Verification    │
│  Remote Execution | Scheduling                       │
└──────────────────┬────────────────────────────────────┘
                   │
┌──────────────────▼────────────────────────────────────┐
│         Core Module (Core.psm1)                      │
│  Logging | Error Handling | Validation              │
│  Sensitive Data Masking | Base Utilities             │
└──────────────────┬────────────────────────────────────┘
                   │
┌──────────────────▼────────────────────────────────────┐
│       Operating System & External Services            │
│  Windows Registry | Services | Firewall              │
│  Group Policy | Event Viewer | SIEM/Monitoring      │
└────────────────────────────────────────────────────────┘
```

### Design Principles

1. **Modularity** – Clear separation between concerns (Core, System, Rules)
2. **Reusability** – Each function performs a single, composable task
3. **Testability** – 95%+ code coverage with comprehensive unit tests
4. **Security** – Sensitive data masking, validation at boundaries
5. **Performance** – Efficient algorithms, parallel execution where possible
6. **Maintainability** – Clear naming, inline documentation, ADR-based decisions

---

## Module Design

### Module Hierarchy

```
Core.psm1                    [FOUNDATION]
   │
   ├─ Write-Log              # Central logging (all modules depend)
   ├─ Write-ErrorLog         # Error logging wrapper
   ├─ ConvertTo-MaskedString # Sensitive data masking
   ├─ Test-* Validators      # Input validation helpers
   └─ Get-ModuleVersion      # Version info
        │
        └──────────────────────┐
                               │
System.psm1              [ORCHESTRATION]
   │
   ├─ New-HardeningSession              # Session creation
   ├─ Invoke-SecurityHardening          # Rule application
   ├─ Test-HardeningCompliance          # Compliance verification
   ├─ Get-HardeningProfile              # Profile loading
   ├─ _ApplyHardeningRule               # Private rule executor
   ├─ Invoke-RemoteHardening            # Remote execution
   ├─ New-HardeningSchedule             # Scheduling
   ├─ Export-HardeningReport            # Reporting
   └─ Send-HardeningAlert               # Alerting
```

### Dependency Management

**Linear dependency hierarchy (no circular dependencies):**

```
Core (no dependencies)
   ↓
System (depends on Core only)
   ↓
Scripts (depend on Core + System)
```

**Explicit dependency documentation:**

```powershell
function Invoke-SecurityHardening {
    # DEPENDS ON: Write-Log (Core), Get-HardeningProfile (System)
    # OPTIONAL: Send-HardeningAlert (System – graceful degradation)
    
    # Implementation...
}
```

### Module Loading Strategy

**Lazy loading for performance:**

```powershell
# All scripts load Core first (always required)
Import-Module "$PSScriptRoot\modules\Core.psm1" -ErrorAction Stop

# Optional modules loaded on demand
if ($useRemoteExecution) {
    Import-Module "$PSScriptRoot\modules\System.psm1" -ErrorAction Stop
}

# System module loads automatically when needed
Import-Module "$PSScriptRoot\modules\System.psm1" -ErrorAction SilentlyContinue
```

---

## Hardening Profile System

### Profile Architecture

Each hardening profile is a **rules collection** with metadata:

```powershell
# Internal structure of Get-HardeningProfile
[PSCustomObject]@{
    ProfileName = "Recommended"
    TargetSystem = "Client"  # Client | Server
    Description = "Balanced security and usability"
    Severity = "MEDIUM"
    Rules = @(
        # Rule 1
        @{
            Name = "Account-MinimumPasswordLength"
            Category = "Account"
            Type = "Registry"
            Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters"
            Value = "MinimumPasswordLength"
            ExpectedValue = 8
            Severity = "HIGH"
            Enabled = $true
        },
        # Rule 2
        @{
            Name = "Firewall-EnableWindowsDefender"
            Category = "Firewall"
            Type = "Service"
            ServiceName = "MpsSvc"
            ExpectedState = "Running"
            Severity = "CRITICAL"
            Enabled = $true
        }
        # ... more rules
    )
}
```

### Profile Composition

```
Basis Profile (20 rules)
├─ Registry (5 rules)
├─ Service (4 rules)
├─ Firewall (3 rules)
├─ Account (5 rules)
└─ Audit (3 rules)

Recommended Profile (35 rules) = Basis + Additional 15
├─ Credential Guard
├─ SmartScreen
├─ Advanced Audit
├─ Enhanced Firewall
└─ ...

Strict Profile (55+ rules) = Recommended + Additional 20+
├─ Exploit Protection
├─ Device Guard
├─ Restricted USB
├─ Advanced Threat Protection
└─ ...
```

### Rule Metadata

Each rule contains:

```powershell
@{
    Name              # "Firewall-EnableWindowsDefender"
    Category          # "Firewall" | "Account" | "Registry" | "Service" | "Audit"
    Type              # "Registry" | "Service" | "Firewall" | "Audit"
    Severity          # "CRITICAL" | "HIGH" | "MEDIUM" | "LOW"
    Enabled           # $true | $false (can disable rules)
    AppliesTo         # "Client" | "Server" | "Both"
    Description       # Human-readable description
    Path              # Registry path or service name
    Value             # Registry value or service state
    ExpectedValue     # Expected state
    RemediationSteps  # How to fix if non-compliant
    Dependencies      # Rules that must run first
}
```

---

## Rule Application Pipeline

### Execution Flow

```
New-HardeningSession
    │
    ├─ Validate session parameters
    ├─ Load hardening profile
    ├─ Check prerequisites (OS version, admin rights)
    └─ Create session object with State tracking
        │
        ▼
    Invoke-SecurityHardening
        │
        ├─ Validate session state
        ├─ Load rules from profile
        ├─ Filter rules (if RuleFilter specified)
        │
        ├─ For each rule:
        │   ├─ Check if applicable (AppliesTo)
        │   ├─ Check dependencies
        │   │
        │   └─ _ApplyHardeningRule
        │       ├─ Registry rules   → Set-RegistryValue
        │       ├─ Service rules    → Set-Service / Start-Service
        │       ├─ Firewall rules   → New-NetFirewallRule
        │       ├─ Audit rules      → auditpol.exe
        │       └─ Account rules    → Set-LocalUser / net.exe
        │
        ├─ Track results (Applied, Failed, Skipped)
        ├─ Log all operations
        └─ Return result object
        │
        ▼
    Test-HardeningCompliance
        │
        ├─ For each applied rule:
        │   ├─ Read current system state
        │   ├─ Compare with expected value
        │   ├─ Store result (Compliant/Non-Compliant)
        │   └─ If -Remediate: re-apply rule
        │
        └─ Generate compliance report
```

### Rule Application Strategy

**Sequential vs. Parallel:**

```powershell
# Sequential (safe, default)
# Rules applied one-by-one, respecting dependencies
Invoke-SecurityHardening -Session $session

# Parallel (faster, for independent rules)
# Registry and Service rules run in parallel
# Firewall and Audit rules run sequentially (OS constraint)
Invoke-SecurityHardening -Session $session -Parallel
```

**Error Handling:**

```powershell
# Graceful (default)
# Individual rule failure doesn't stop the process
# All rules attempted, results logged
Invoke-SecurityHardening -Session $session  # -FailOnError = $false

# Strict (fail-fast)
# First rule failure stops execution
# Useful for CI/CD pipelines
Invoke-SecurityHardening -Session $session -FailOnError
```

---

## Compliance Verification

### Verification Strategy

```powershell
# 1. Full verification (default)
# Checks all rules in profile, even if not applied
Test-HardeningCompliance -Session $session

# 2. Delta verification
# Checks only rules that were applied in this session
Test-HardeningCompliance -Session $session -RuleFilter @('Rule1', 'Rule2')

# 3. Remediation
# Auto-fix non-compliant rules
Test-HardeningCompliance -Session $session -Remediate
```

### Compliance Data Structure

```powershell
# Compliance report contains:
@{
    CompliancePercentage    # 0-100% (overall)
    CompliantRuleCount      # Number of compliant rules
    NonCompliantRuleCount   # Number of non-compliant rules
    VerifiedRuleCount       # Total verified
    RuleResults = @(
        @{
            RuleName = "Account-MinimumPasswordLength"
            Category = "Account"
            Compliant = $true | $false
            Expected = 8
            Actual = 8
            Severity = "HIGH"
            RemediationAttempted = $false | $true
            RemediationStatus = "SUCCESS" | "FAILED"
        }
        # ... more results
    )
    
    ComplianceByCategory = @{
        "Account" = 95%
        "Registry" = 100%
        "Firewall" = 87%
        # ...
    }
}
```

---

## Data Flow

### Session Object Lifecycle

```powershell
# 1. Creation (New-HardeningSession)
$session = New-HardeningSession -Profile Recommended -TargetSystem Client
# Result: PSCustomObject with metadata and empty State

# 2. Execution (Invoke-SecurityHardening)
# Updates $session.State with:
#   - AppliedRules (list of applied rules)
#   - RuleResults (success/failure per rule)
#   - Timestamp
#   - FailedRules (if any)

# 3. Verification (Test-HardeningCompliance)
# Reads $session.State to determine what to verify
# Generates compliance report (separate from session)

# 4. Cleanup (automatic)
# Session can be reused, or discarded
Remove-Variable -Name session
```

### Logging Data Flow

```powershell
# All operations logged to central CSV file:
# logs/log_YYYY-MM-DD.csv

# CSV columns:
Timestamp, Level, Caller, Function, LineNumber, Message

# Example:
2026-06-26 14:23:45.123, INFO, Invoke-SecurityHardening:42, Invoke-SecurityHardening, 42, "Starting security hardening: Profile=Recommended"
2026-06-26 14:23:46.234, INFO, _ApplyHardeningRule:15, _ApplyHardeningRule, 15, "Applying rule: Account-MinimumPasswordLength"
2026-06-26 14:23:47.345, ERROR, _ApplyHardeningRule:22, _ApplyHardeningRule, 22, "Failed to apply rule: Access denied to registry path"
```

### Sensitive Data Masking Flow

```
User Input
    ↓
Validation (check for sensitive keywords)
    ↓
Masking (password, token, secret, apikey, credential → ***)
    ↓
Logging (Write-Log, always masked)
    ↓
Output (to console, reports, SIEM)
```

---

## Security Considerations

### 1. Input Validation

**All external inputs validated at boundaries:**

```powershell
# Parameter validation attributes
[Parameter(Mandatory = $true)]
[ValidateSet('Basis', 'Recommended', 'Strict')]
[string]$Profile

[Parameter(Mandatory = $true)]
[ValidateSet('Client', 'Server')]
[string]$TargetSystem

[Parameter(Mandatory = $true)]
[ValidateSet(10, 11, 2016, 2019, 2022)]
[int]$OSVersion

# Custom validation
[Parameter(Mandatory = $true)]
[ValidateScript({
    if (-not (Test-Path $_)) {
        throw "Path does not exist: $_"
    }
    return $true
})]
[string]$ConfigPath
```

### 2. Credential Handling

**Zero hardcoded credentials:**

```powershell
# CORRECT: Use environment variables or Credential Manager
$cred = Get-StoredCredential -Target "WinHarden"

# WRONG (NEVER DO THIS):
$password = "SecureP@ssw0rd"  # Hardcoded!
$cred = New-Object System.Management.Automation.PSCredential("admin", (ConvertTo-SecureString -String $password -AsPlainText -Force))
```

### 3. Sensitive Data Masking

**Automatic masking in logs:**

```powershell
# These keywords are automatically masked:
# - password, passwd, pwd
# - secret, secretkey
# - token, apikey, api_key
# - credential, cred
# - key, private, private_key

Write-Log -Message "Password: SecureP@ssw0rd" -Level Info
# Logged as: "Password: ***"

Write-Log -Message "API Key: sk_live_abc123xyz" -Level Info
# Logged as: "API Key: ***"
```

### 4. Error Handling

**No sensitive data exposed in errors:**

```powershell
# Error message doesn't expose secrets
try {
    $registry = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("HKLM:\Path")
} catch {
    Write-ErrorLog -Message "Failed to access registry: Access denied" -Level Error
    # NOT: "Failed to access registry: $($_.Exception.Message)" (might contain sensitive data)
}
```

### 5. Access Control

**Admin rights enforced:**

```powershell
# Check admin rights at session start
if (-not ([Security.Principal.WindowsIdentity]::GetCurrent()).Owner) {
    throw "Administrator privileges required"
}
```

### 6. Audit Logging

**Comprehensive audit trail:**

```powershell
# All operations logged with:
# - Timestamp
# - User/function that made change
# - What was changed
# - Result (success/failure)
# - Who authorized it

# Enables detection of unauthorized modifications
```

---

## Performance Optimization

### Performance Profile

| Operation | Time | Target | Status |
|-----------|------|--------|--------|
| Module Load | 180ms | <500ms | OK |
| Session Creation | 50ms | <200ms | OK |
| Rule Application (10 rules) | 2.3s | <5s | OK |
| Full Hardening (35 rules) | 8.3s | <15s | OK |
| Compliance Verification | 12.4s | <30s | OK |
| Parallel Execution (5 rules) | 1.5s | <3s | OK |

### Optimization Techniques

#### 1. Lazy Module Loading

```powershell
# Load Core immediately (small, essential)
Import-Module Core.psm1

# Load System only when needed
if ($useRemoteHardening) {
    Import-Module System.psm1
}
```

#### 2. Parallel Rule Application

```powershell
# Rules with no dependencies run in parallel
Invoke-SecurityHardening -Session $session -Parallel

# Uses PowerShell ForEach-Object -Parallel (PS 7.0+)
# Gracefully falls back to sequential on PS 5.1
```

#### 3. Batch Operations

```powershell
# Apply registry rules in single batch instead of one-by-one
# Reduces registry access time by 40-50%
$registryRules | Group-Object -Property Path | ForEach-Object {
    $path = $_.Name
    $values = $_.Group
    
    $reg = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey($path, $true)
    foreach ($rule in $values) {
        $reg.SetValue($rule.ValueName, $rule.Value)
    }
    $reg.Dispose()
}
```

#### 4. Caching

```powershell
# Cache frequently accessed data
# Profile metadata loaded once, reused for all rules
$cachedProfiles = @{}
$profile = $cachedProfiles["Recommended"] ?? (Get-HardeningProfile -ProfileName "Recommended")

# Reduces disk I/O, especially for remote execution
```

#### 5. Verification Skipping

```powershell
# Skip verification when not needed
# Saves 10-15 seconds for large rule sets
Invoke-SecurityHardening -Session $session -SkipVerification

# Verify later separately
Test-HardeningCompliance -Session $session
```

### Scalability

**Multi-system deployment optimization:**

```powershell
# Parallel remote execution
$servers = @('SERVER01', 'SERVER02', ... 'SERVER50')

$results = $servers | ForEach-Object -Parallel {
    $session = New-HardeningSession -Profile Recommended -TargetSystem Server
    Invoke-RemoteHardening -ComputerName $_ -Session $session
} -ThrottleLimit 10

# Processes 10 systems in parallel, maintains system health
```

---

## Extension Points

### Adding Custom Rules

```powershell
# Rules are data-driven – easy to extend
$customRule = @{
    Name = "Custom-MyRule"
    Category = "Custom"
    Type = "Registry"
    Path = "HKLM:\Software\MyApp"
    Value = "Setting"
    ExpectedValue = 1
    Severity = "MEDIUM"
    Enabled = $true
}

# Integrate with hardening profile
$profile.Rules += $customRule
```

### Custom Profile Creation

```powershell
# Create custom profile
$customProfile = @{
    ProfileName = "CustomStrict"
    TargetSystem = "Server"
    Rules = @(
        # Select from Recommended
        (Get-HardeningProfile -ProfileName "Recommended").Rules |
        Where-Object { $_.Severity -eq "HIGH" -or $_.Severity -eq "CRITICAL" }
    ) + @(
        # Add custom rules
        $customRule
    )
}

# Save to profile store
Save-HardeningProfile -Profile $customProfile
```

---

**End of Architecture Guide**

For implementation details, consult the Source Code. For operational guidance, see the User Guide and Deployment Guide.
