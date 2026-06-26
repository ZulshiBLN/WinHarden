# WinHarden Hardening – SIEM Integration Guide

**Version:** 1.0  
**Last Updated:** 2026-06-26  
**Target Audience:** Security Operations, SIEM Administrators, Monitoring Engineers

---

## Table of Contents

1. [Overview](#overview)
2. [Log Format & Structure](#log-format--structure)
3. [Integration Methods](#integration-methods)
4. [Splunk Integration](#splunk-integration)
5. [ELK Stack Integration](#elk-stack-integration)
6. [Microsoft Sentinel Integration](#microsoft-sentinel-integration)
7. [Alert Configuration](#alert-configuration)
8. [Dashboards & Reporting](#dashboards--reporting)

---

## Overview

WinHarden generates comprehensive logs and metrics that integrate with enterprise SIEM platforms for centralized monitoring, compliance reporting, and threat detection.

### Key Log Sources

1. **Hardening Operation Logs** – Rule application, compliance checks
2. **System Event Logs** – Windows Event Viewer integration
3. **Compliance Reports** – Compliance percentage, non-compliant rules
4. **Performance Metrics** – Execution time, resource usage
5. **Alert Events** – Drift detection, failures, anomalies

### Supported SIEM Platforms

- Splunk Enterprise / Cloud
- ELK Stack (Elasticsearch, Logstash, Kibana)
- Microsoft Sentinel
- ArcSight
- Generic Syslog (rsyslog, syslog-ng)

---

## Log Format & Structure

### CSV Log Format

WinHarden logs to local CSV files in `logs/` directory:

**File Format:**
```
logs/
├── log_2026-06-26.csv
├── log_2026-06-25.csv
├── log_2026-06-24.csv
└── ... (7-day rotation)
```

**CSV Structure:**

| Column | Type | Example | Description |
|--------|------|---------|-------------|
| Timestamp | DateTime | 2026-06-26T14:23:45.123Z | ISO 8601 UTC timestamp |
| Level | String | INFO, WARNING, ERROR | Log severity level |
| Caller | String | Invoke-SecurityHardening:42 | Function:LineNumber |
| Function | String | Invoke-SecurityHardening | Function name |
| LineNumber | Integer | 42 | Source line number |
| Message | String | Starting security hardening | Log message |

**Example CSV Data:**

```csv
Timestamp,Level,Caller,Function,LineNumber,Message
2026-06-26T14:23:45.123Z,INFO,Invoke-SecurityHardening:42,Invoke-SecurityHardening,42,Starting security hardening: Profile=Recommended ComputerName=WORKSTATION01
2026-06-26T14:23:46.234Z,INFO,_ApplyHardeningRule:15,_ApplyHardeningRule,15,Applying rule: Account-MinimumPasswordLength
2026-06-26T14:23:47.345Z,INFO,_ApplyHardeningRule:22,_ApplyHardeningRule,22,Rule applied successfully: Account-MinimumPasswordLength=8
2026-06-26T14:23:48.456Z,INFO,Test-HardeningCompliance:50,Test-HardeningCompliance,50,Compliance verification completed: CompliancePercentage=100
```

### Sensitive Data Masking

**Automatic masking of sensitive fields:**

All CSV logs automatically mask sensitive patterns:

```csv
# Original (before masking):
Message="Connecting with password: SecureP@ssw0rd"

# In CSV (after masking):
Message="Connecting with password: ***"

# Masked keywords:
- password, passwd, pwd
- secret, secretkey
- token, apikey, api_key
- credential, cred, apitoken
```

---

## Integration Methods

### Method 1: Local Log Forwarding (Syslog/SNMP)

**Send logs to SIEM via syslog protocol:**

```powershell
# Create forwarding script
$scriptPath = "C:\Scripts\ForwardHardeningLogs.ps1"

# Content:
param(
    [string]$SyslogServer = "siem.company.com",
    [int]$SyslogPort = 514,
    [string]$LogPath = "C:\Program Files\WinHarden\logs"
)

# Read latest log file
$logFile = Get-ChildItem -Path $LogPath -Filter "log_*.csv" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$logs = Import-Csv -Path $logFile.FullName

# Forward each log entry to syslog
foreach ($log in $logs) {
    $syslogMessage = "$($log.Timestamp) WinHarden[$($log.Function):$($log.LineNumber)] $($log.Level): $($log.Message)"
    
    # Send via UDP to syslog server
    $udpClient = New-Object System.Net.Sockets.UdpClient
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($syslogMessage)
    $udpClient.Send($bytes, $bytes.Length, $SyslogServer, $SyslogPort) | Out-Null
    $udpClient.Close()
}
```

**Schedule forwarding:**

```powershell
# Run every hour
$trigger = New-ScheduledTaskTrigger -RepetitionInterval (New-TimeSpan -Hours 1) -RepeatIndefinitely -At 9am
$action = New-ScheduledTaskAction -Execute PowerShell.exe -Argument "-NoProfile -File $scriptPath"
Register-ScheduledTask -TaskName "ForwardHardeningLogs" -Trigger $trigger -Action $action
```

### Method 2: Direct API Integration

**Send logs directly to SIEM API:**

```powershell
# Function to send logs to SIEM HTTP endpoint
function Send-LogsToSIEM {
    param(
        [string]$SIEMUrl = "https://siem.company.com/api/logs",
        [string]$ApiKey = $env:SIEM_API_KEY,
        [string]$LogPath = "C:\Program Files\WinHarden\logs"
    )
    
    $logFile = Get-ChildItem -Path $LogPath -Filter "log_*.csv" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    $logs = Import-Csv -Path $logFile.FullName
    
    $payload = @{
        source = $env:COMPUTERNAME
        sourcetype = "WinHarden"
        events = $logs
    } | ConvertTo-Json
    
    $headers = @{
        "Authorization" = "Bearer $ApiKey"
        "Content-Type" = "application/json"
    }
    
    try {
        Invoke-RestMethod -Uri $SIEMUrl -Method Post -Headers $headers -Body $payload -ErrorAction Stop
        Write-Log -Message "Logs sent to SIEM successfully" -Level Info
    } catch {
        Write-ErrorLog -Message "Failed to send logs to SIEM: $($_.Exception.Message)" -Level Error
    }
}
```

### Method 3: File Forwarding (WinRM/SMB)

**Copy logs to central collection point:**

```powershell
# Copy logs to network share
$centralLogPath = "\\siem-server\WinHarden-Logs\$env:COMPUTERNAME"
New-Item -ItemType Directory -Path $centralLogPath -Force

$logPath = "C:\Program Files\WinHarden\logs"
Get-ChildItem -Path $logPath -Filter "log_*.csv" | Copy-Item -Destination $centralLogPath -Force

# SIEM can then ingest from network share
```

---

## Splunk Integration

### Step 1: Install Splunk Universal Forwarder

```powershell
# Download and install UF
Invoke-WebRequest -Uri "https://download.splunk.com/products/universalforwarder/releases/9.1.0/windows/splunkforwarder-9.1.0-8e2e6d7ef3c1-x64-release.msi" `
    -OutFile "C:\Temp\splunk-uf.msi"

# Install
msiexec.exe /i C:\Temp\splunk-uf.msi DEPLOYMENTSERVER="splunk-ds.company.com:8089" AGREETOLICENSE=yes
```

### Step 2: Configure Data Input

**Edit `$SPLUNK_HOME\etc\system\local\inputs.conf`:**

```ini
[monitor://C:\Program Files\WinHarden\logs\]
index = winharden
source = WinHarden
sourcetype = csv
disabled = false

# Set to parse CSV format
[csv]
definition = Timestamp,Level,Caller,Function,LineNumber,Message
```

### Step 3: Configure Index

**Create WinHarden index in Splunk:**

```splunk
index=main sourcetype=csv source=WinHarden | head 100
```

**Splunk Search Query Examples:**

```splunk
# All WinHarden events today
index=winharden earliest=-24h

# Errors and warnings
index=winharden Level IN (ERROR, WARNING)

# Compliance events
index=winharden "Test-HardeningCompliance"

# Failed rule applications
index=winharden "Rule applied successfully" | NOT "successfully"

# Specific computer
index=winharden Caller="WORKSTATION01"

# Timeline of hardening application
index=winharden "Invoke-SecurityHardening" | timechart count by ComputerName

# Non-compliant rules
index=winharden "CompliancePercentage" | where CompliancePercentage < 100
```

### Step 4: Create Splunk Dashboard

**Splunk Dashboard Definition (XML):**

```xml
<dashboard>
  <label>WinHarden Compliance</label>
  
  <row>
    <panel>
      <title>Overall Compliance Status</title>
      <table>
        <search>
          <query>index=winharden "CompliancePercentage" 
            | stats latest(CompliancePercentage) as Compliance by ComputerName
            | eval Status = if(Compliance >= 95, "COMPLIANT", "DRIFT")
          </query>
        </search>
      </table>
    </panel>
  </row>
  
  <row>
    <panel>
      <title>Recent Errors</title>
      <table>
        <search>
          <query>index=winharden Level=ERROR 
            | stats count by ComputerName, Function, Message
            | sort - count
          </query>
        </search>
      </table>
    </panel>
  </row>
  
  <row>
    <panel>
      <title>Hardening Activity Timeline</title>
      <timechart>
        <search>
          <query>index=winharden "Invoke-SecurityHardening" 
            | timechart count by ComputerName
          </query>
        </search>
      </timechart>
    </panel>
  </row>
</dashboard>
```

---

## ELK Stack Integration

### Step 1: Configure Logstash

**Create `winharden.conf` in Logstash:**

```
input {
  file {
    path => "C:\Program Files\WinHarden\logs\log_*.csv"
    start_position => "beginning"
    codec => plain { charset => "UTF-8" }
  }
}

filter {
  # Parse CSV
  csv {
    columns => ["Timestamp", "Level", "Caller", "Function", "LineNumber", "Message"]
    separator => ","
  }
  
  # Extract computer name from Caller field
  grok {
    match => { "Caller" => "%{DATA:FunctionName}:%{INT:SourceLine}" }
  }
  
  # Parse timestamp
  date {
    match => ["Timestamp", "ISO8601"]
  }
  
  # Add metadata
  mutate {
    add_field => { "source_system" => "WinHarden" }
    add_field => { "[@metadata][index_name]" => "winharden-%{+YYYY.MM.dd}" }
  }
}

output {
  elasticsearch {
    hosts => ["elasticsearch.company.com:9200"]
    index => "%{[@metadata][index_name]}"
  }
}
```

### Step 2: Configure Elasticsearch

**Create index template:**

```json
PUT _index_template/winharden
{
  "index_patterns": ["winharden-*"],
  "settings": {
    "number_of_shards": 2,
    "number_of_replicas": 1
  },
  "mappings": {
    "properties": {
      "Timestamp": { "type": "date" },
      "Level": { "type": "keyword" },
      "Function": { "type": "keyword" },
      "Message": { "type": "text" },
      "ComputerName": { "type": "keyword" }
    }
  }
}
```

### Step 3: Create Kibana Dashboard

**Kibana Dashboard:**

```json
{
  "dashboard": {
    "title": "WinHarden Compliance Overview",
    "panels": [
      {
        "id": "compliance-status",
        "type": "metric",
        "properties": {
          "query": "Level: ERROR",
          "metric": "count"
        }
      },
      {
        "id": "hardening-timeline",
        "type": "line",
        "properties": {
          "xAxis": "Timestamp",
          "yAxis": "count",
          "groupBy": "Function"
        }
      },
      {
        "id": "compliance-by-computer",
        "type": "bar",
        "properties": {
          "xAxis": "ComputerName",
          "yAxis": "compliance_percentage"
        }
      }
    ]
  }
}
```

**Kibana Query Examples:**

```
# Recent hardening operations
source_system: WinHarden AND Function: Invoke-SecurityHardening

# Compliance issues
source_system: WinHarden AND Level: ERROR

# Timeline of all changes
source_system: WinHarden | histogram(@timestamp, 1h)
```

---

## Microsoft Sentinel Integration

### Step 1: Install Log Analytics Agent

```powershell
# Download and install agent
$msiPath = "C:\Temp\MicrosoftMonitoringAgent.msi"
$workspaceId = "YOUR_WORKSPACE_ID"
$workspaceKey = "YOUR_WORKSPACE_KEY"

# Install
msiexec.exe /i $msiPath /qn /l*v install.log `
    NOAPM=1 `
    ADD_OPINSIGHTS_WORKSPACE=1 `
    OPINSIGHTS_WORKSPACE_ID=$workspaceId `
    OPINSIGHTS_WORKSPACE_KEY=$workspaceKey
```

### Step 2: Configure Custom Log Collection

**In Log Analytics Workspace:**

1. Go to Settings → Custom Logs
2. Create new custom log
3. Upload sample WinHarden CSV log
4. Set collection path: `C:\Program Files\WinHarden\logs\log_*.csv`
5. Name: `WinHarden_CL`

### Step 3: Create Sentinel Analytics Rules

**KQL Query for Compliance Drift:**

```kusto
WinHarden_CL
| where TimeGenerated > ago(24h)
| where Message_s contains "CompliancePercentage"
| parse Message_s with * "CompliancePercentage=" CompliancePercentage:int
| where CompliancePercentage < 95
| summarize LatestCompliance = max(CompliancePercentage) by Computer
| where LatestCompliance < 95
```

**KQL Query for Rule Failures:**

```kusto
WinHarden_CL
| where Level_s == "ERROR"
| where Function_s == "_ApplyHardeningRule"
| summarize ErrorCount = count() by Message_s, Computer
| where ErrorCount > 5
```

### Step 4: Create Sentinel Incidents

```kusto
// Scheduled Rule - Run every hour
WinHarden_CL
| where TimeGenerated > ago(1h)
| where Level_s in ("ERROR", "WARNING")
| summarize TotalIssues = count() by Computer, Level_s
| where TotalIssues > 3
```

---

## Alert Configuration

### Alert Rule 1: High Compliance Drift

```powershell
function Send-HardeningAlert {
    param(
        [PSCustomObject]$ComplianceStatus,
        [ValidateSet("LOW", "MEDIUM", "HIGH", "CRITICAL")]
        [string]$AlertLevel = "HIGH"
    )
    
    if ($ComplianceStatus.CompliancePercentage -lt 85) {
        $severity = "CRITICAL"
    } elseif ($ComplianceStatus.CompliancePercentage -lt 90) {
        $severity = "HIGH"
    } else {
        $severity = "MEDIUM"
    }
    
    $alert = @{
        ComputerName = $env:COMPUTERNAME
        Severity = $severity
        CompliancePercentage = $ComplianceStatus.CompliancePercentage
        NonCompliantRules = $ComplianceStatus.NonCompliantRuleCount
        AlertTime = Get-Date
        Status = "OPEN"
    }
    
    # Send to SIEM
    Send-LogsToSIEM -Alert $alert
}
```

### Alert Rule 2: Rule Application Failures

**Threshold:** >5 failures in 1 hour

```splunk
index=winharden Level=ERROR earliest=-1h | stats count | where count > 5
```

### Alert Rule 3: Unauthorized Changes

**Detect non-WinHarden modifications to hardening settings:**

```powershell
# Compare current state with baseline
$baseline = Get-HardeningProfile -ProfileName Recommended
$current = Test-HardeningCompliance -Session $session -Detailed

$driftRules = $current.RuleResults | Where-Object {
    $_.Compliant -eq $false -and
    $_.LastModifiedBy -ne "WinHarden"
}

if ($driftRules) {
    # Alert on unauthorized modifications
    Send-HardeningAlert -ComplianceStatus $current -AlertLevel CRITICAL
}
```

---

## Dashboards & Reporting

### Compliance Dashboard

**Key Metrics:**

```
┌─────────────────────────────────────────┐
│  Compliance Overview                    │
├─────────────────────────────────────────┤
│  Overall Compliance:        97.2%       │
│  Compliant Systems:         48/50       │
│  Non-Compliant Systems:     2/50        │
│  Last Verified:             2 mins ago  │
│  Average Rule Compliance:   98.1%       │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│  Compliance by Category                 │
├─────────────────────────────────────────┤
│  Account Policies:          100%        │
│  Registry Hardening:        95%         │
│  Firewall Rules:            87%         │
│  Audit Policies:            100%        │
│  Service Configuration:     98%         │
└─────────────────────────────────────────┘
```

### Weekly Compliance Report

```
WINHARDEN COMPLIANCE REPORT
Week of June 26, 2026

EXECUTIVE SUMMARY
================
Overall Compliance:     97.2% (↑2.1% from last week)
Compliant Systems:      48 of 50 (96%)
Non-Compliant Systems:  2 of 50 (4%)

SYSTEM STATUS BREAKDOWN
=======================
Basis Profile:
  Compliant Systems:    15/15 (100%)
  
Recommended Profile:
  Compliant Systems:    30/32 (93.8%)
  Non-Compliant:        SRV-02 (92%), SRV-15 (89%)
  
Strict Profile:
  Compliant Systems:    3/3 (100%)

ISSUES DETECTED
===============
Top Non-Compliant Rules:
1. Firewall-EnableWindowsDefender (8 systems, 91% compliant)
2. Account-MinimumPasswordLength (5 systems, 94% compliant)
3. Registry-DisableSMBv1 (2 systems, 98% compliant)

RECOMMENDATIONS
===============
1. Restart services on SRV-02 to restore Firewall compliance
2. Review password policies on 5 non-compliant systems
3. Force audit on 2 systems with registry drift
```

---

**End of SIEM Integration Guide**

For support, consult the User Guide or contact your SIEM administrator.
