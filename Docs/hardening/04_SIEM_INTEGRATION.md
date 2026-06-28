# WinHarden - SIEM Integration Guide

**Integration procedures for security information and event management systems.**

---

## Table of Contents

1. [SIEM Integration Overview](#siem-integration-overview)
2. [Data Export Formats](#data-export-formats)
3. [Splunk Integration](#splunk-integration)
4. [ELK Stack Integration](#elk-stack-integration)
5. [Webhook Integration](#webhook-integration)
6. [Alert Configuration](#alert-configuration)
7. [Dashboards](#dashboards)

---

## SIEM Integration Overview

### Supported SIEM Platforms

| Platform | Method | Export Format | Real-time |
|----------|--------|---------------|-----------|
| Splunk | HEC/File | JSON | Yes |
| Elastic Stack | API/File | JSON | Yes |
| Splunk Cloud | HEC | JSON | Yes |
| ArcSight | Syslog/API | JSON | Yes |
| QRadar | API | JSON | Yes |
| Generic SIEM | Webhook | JSON | Yes |

### Integration Points

```
WinHarden
├── Compliance Reports
│   └── Export to SIEM
├── Drift Detection
│   └── Alert to SIEM
├── Remediation Actions
│   └── Log to SIEM
├── Audit Events
│   └── Stream to SIEM
└── Performance Metrics
    └── Send to SIEM
```

---

## Data Export Formats

### JSON Export Format

```json
{
  "event_type": "compliance_check",
  "timestamp": "2026-06-27T10:30:00Z",
  "source_system": "Server01",
  "baseline": "Production-Baseline",
  "compliance_data": {
    "overall_compliance": 95,
    "total_checks": 100,
    "passed_checks": 95,
    "failed_checks": 5,
    "categories": {
      "firewall": {
        "status": "pass",
        "compliance": 100
      },
      "services": {
        "status": "fail",
        "compliance": 80,
        "violations": [
          {
            "service": "RDP",
            "expected": "disabled",
            "actual": "enabled",
            "severity": "high"
          }
        ]
      }
    }
  }
}
```

### CSV Export Format

```
timestamp,event_type,source_system,baseline,category,check_name,status,expected,actual,severity
2026-06-27T10:30:00Z,compliance,Server01,Production-Baseline,Firewall,InboundPolicy,pass,block,block,low
2026-06-27T10:30:15Z,compliance,Server01,Production-Baseline,Services,RDP,fail,disabled,enabled,high
2026-06-27T10:30:30Z,compliance,Server01,Production-Baseline,Registry,LSARestrict,pass,2,2,low
```

### Syslog Format

```
<134>Jun 27 10:30:00 Server01 WinHarden[1234]: event_type=compliance baseline=Production-Baseline compliance=95% failed_checks=5
```

### Custom Format Definition

```xml
<ExportFormat>
  <Name>Custom-SIEM</Name>
  <Fields>
    <Field Name="timestamp" Source="Event.Timestamp" />
    <Field Name="event_type" Source="Event.Type" />
    <Field Name="severity" Source="Event.Severity" />
    <Field Name="message" Source="Event.Message" />
    <Field Name="source_system" Source="Environment.ComputerName" />
    <Field Name="user" Source="Environment.UserName" />
  </Fields>
  <Delimiter>,</Delimiter>
  <IncludeHeaders>true</IncludeHeaders>
</ExportFormat>
```

---

## Splunk Integration

### Splunk HTTP Event Collector (HEC) Setup

#### Step 1: Configure Splunk HEC Endpoint

```powershell
# In Splunk, create HTTP Event Collector token
# Settings -> Data Inputs -> HTTP Event Collector
# Create new token with:
# - Name: WinHarden
# - Source type: json
# - Index: winharden (create if needed)
# - Token: [Generated Token]

# Note the HEC endpoint and token:
$splunkHEC = "https://splunk.example.com:8088"
$splunkToken = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

#### Step 2: Configure WinHarden for Splunk

```powershell
# Create Splunk export configuration
$splunkConfig = @{
    Enabled = $true
    Endpoint = "https://splunk.example.com:8088/services/collector"
    Token = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    Index = "winharden"
    SourceType = "winharden_compliance"
    BatchSize = 10
    RetryAttempts = 3
    VerifySSL = $false  # For self-signed certs
}

# Save configuration
$splunkConfig | ConvertTo-Json | Out-File "<WINHARDEN_REPO>\config\splunk_hec.json"
```

#### Step 3: Export Compliance to Splunk

```powershell
# Export compliance data to Splunk
function Export-ComplianceToSplunk {
    param(
        [string]$BaselineName,
        [string]$ConfigPath = "<WINHARDEN_REPO>\config\splunk_hec.json"
    )
    
    # Load configuration
    $config = Get-Content $ConfigPath | ConvertFrom-Json
    
    # Get compliance data
    $compliance = Test-SystemCompliance -BaselineName $BaselineName
    
    # Prepare event
    $event = @{
        time = (Get-Date).ToUniversalTime().ToString("o")
        source = $env:COMPUTERNAME
        sourcetype = $config.SourceType
        index = $config.Index
        event = @{
            event_type = "compliance"
            baseline = $BaselineName
            overall_compliance = $compliance.ComplianceRate
            total_checks = $compliance.TotalChecks
            passed_checks = $compliance.PassedChecks
            failed_checks = $compliance.FailedChecks
        }
    }
    
    # Send to Splunk
    $body = $event | ConvertTo-Json
    $headers = @{
        "Authorization" = "Splunk $($config.Token)"
        "Content-Type" = "application/json"
    }
    
    try {
        Invoke-RestMethod `
            -Uri $config.Endpoint `
            -Method POST `
            -Body $body `
            -Headers $headers `
            -SkipCertificateCheck:$(-not $config.VerifySSL)
        
        Write-Host "Compliance data sent to Splunk"
    } catch {
        Write-Error "Failed to send to Splunk: $_"
    }
}

# Export compliance
Export-ComplianceToSplunk -BaselineName "Production-Baseline"
```

#### Step 4: Create Splunk Search

```spl
index=winharden source=Server01
| stats
    latest(overall_compliance) as compliance,
    latest(failed_checks) as failures
    by baseline

| eval compliance_status=if(compliance>=95, "Good", "Poor")
| table baseline, compliance, failures, compliance_status
```

---

## ELK Stack Integration

### Elasticsearch Setup

#### Step 1: Configure Elasticsearch

```powershell
# Elasticsearch endpoint configuration
$elasticsearchConfig = @{
    Endpoint = "https://elasticsearch.example.com:9200"
    Index = "winharden-compliance"
    Username = "elastic"
    Password = "password"
    VerifySSL = $false
}

# Save configuration
$elasticsearchConfig | ConvertTo-Json | Out-File "<WINHARDEN_REPO>\config\elasticsearch.json"
```

#### Step 2: Create Index Template

```json
{
  "template": "winharden-*",
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": 1
  },
  "mappings": {
    "properties": {
      "timestamp": { "type": "date" },
      "event_type": { "type": "keyword" },
      "source_system": { "type": "keyword" },
      "baseline": { "type": "keyword" },
      "compliance": { "type": "integer" },
      "failed_checks": { "type": "integer" },
      "passed_checks": { "type": "integer" },
      "violations": { "type": "nested" }
    }
  }
}
```

#### Step 3: Export to Elasticsearch

```powershell
# Export compliance to Elasticsearch
function Export-ComplianceToElasticsearch {
    param(
        [string]$BaselineName,
        [string]$ConfigPath = "<WINHARDEN_REPO>\config\elasticsearch.json"
    )
    
    # Load configuration
    $config = Get-Content $ConfigPath | ConvertFrom-Json
    
    # Get compliance data
    $compliance = Test-SystemCompliance -BaselineName $BaselineName
    
    # Prepare document
    $doc = @{
        timestamp = Get-Date -AsUTC -Format "o"
        event_type = "compliance_check"
        source_system = $env:COMPUTERNAME
        baseline = $BaselineName
        compliance = $compliance.ComplianceRate
        total_checks = $compliance.TotalChecks
        passed_checks = $compliance.PassedChecks
        failed_checks = $compliance.FailedChecks
    }
    
    # Send to Elasticsearch
    $body = $doc | ConvertTo-Json
    $auth = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("$($config.Username):$($config.Password)"))
    $headers = @{
        "Authorization" = "Basic $auth"
        "Content-Type" = "application/json"
    }
    
    $indexName = "$($config.Index)-$(Get-Date -Format 'yyyy.MM.dd')"
    
    try {
        Invoke-RestMethod `
            -Uri "$($config.Endpoint)/$indexName/_doc" `
            -Method POST `
            -Body $body `
            -Headers $headers `
            -SkipCertificateCheck
        
        Write-Host "Document indexed in Elasticsearch"
    } catch {
        Write-Error "Failed to send to Elasticsearch: $_"
    }
}

# Export compliance
Export-ComplianceToElasticsearch -BaselineName "Production-Baseline"
```

#### Step 4: Create Kibana Dashboard

```json
{
  "dashboard": {
    "title": "WinHarden Compliance Overview",
    "panels": [
      {
        "title": "Overall Compliance Trend",
        "type": "line",
        "query": "select compliance from winharden-* group by date_histogram(1h)"
      },
      {
        "title": "Failed Checks by Category",
        "type": "bar",
        "query": "select category, count(*) from winharden-* where status='fail' group by category"
      },
      {
        "title": "Systems by Compliance Level",
        "type": "table",
        "query": "select source_system, compliance, failed_checks from winharden-*"
      }
    ]
  }
}
```

---

## Webhook Integration

### Generic Webhook Configuration

```powershell
# Configure webhook for any SIEM
$webhookConfig = @{
    Url = "https://monitoring.example.com/api/events"
    Method = "POST"
    ContentType = "application/json"
    Headers = @{
        "Authorization" = "Bearer token123"
        "X-Source" = "WinHarden"
    }
    Timeout = 30
    RetryAttempts = 3
}

# Save configuration
$webhookConfig | ConvertTo-Json | Out-File "<WINHARDEN_REPO>\config\webhook.json"
```

### Send Events via Webhook

```powershell
function Send-WinHardenEventToWebhook {
    param(
        [string]$EventType,
        [hashtable]$EventData,
        [string]$ConfigPath = "<WINHARDEN_REPO>\config\webhook.json"
    )
    
    # Load configuration
    $config = Get-Content $ConfigPath | ConvertFrom-Json
    
    # Prepare payload
    $payload = @{
        timestamp = Get-Date -AsUTC -Format "o"
        source = $env:COMPUTERNAME
        event_type = $EventType
        data = $EventData
    }
    
    $body = $payload | ConvertTo-Json
    
    # Send to webhook
    for ($attempt = 1; $attempt -le $config.RetryAttempts; $attempt++) {
        try {
            $response = Invoke-WebRequest `
                -Uri $config.Url `
                -Method $config.Method `
                -Body $body `
                -ContentType $config.ContentType `
                -Headers $config.Headers `
                -TimeoutSec $config.Timeout
            
            Write-Host "Event sent successfully (HTTP $($response.StatusCode))"
            return
        } catch {
            Write-Host "Attempt $attempt failed: $_"
            if ($attempt -lt $config.RetryAttempts) {
                Start-Sleep -Seconds 5
            }
        }
    }
    
    Write-Error "Failed to send event after $($config.RetryAttempts) attempts"
}

# Example: Send compliance event
$eventData = @{
    baseline = "Production-Baseline"
    compliance = 95
    failed_checks = 5
}

Send-WinHardenEventToWebhook -EventType "compliance_check" -EventData $eventData
```

---

## Alert Configuration

### High-Severity Drift Alert

```powershell
# Configure alert for high-severity drift
function New-DriftAlert {
    param(
        [string]$BaselineName,
        [string]$AlertThreshold = "High"  # Critical, High, Medium, Low
    )
    
    # Detect drift
    $drift = Get-SecurityDrift -BaselineName $BaselineName
    
    # Filter by severity
    $alertItems = $drift | Where-Object Severity -eq $AlertThreshold
    
    if ($alertItems.Count -gt 0) {
        Write-Host "[ALERT] $($alertItems.Count) $AlertThreshold severity drift items detected"
        
        # Send alert to SIEM
        foreach ($item in $alertItems) {
            $alertData = @{
                alert_type = "security_drift"
                severity = $item.Severity
                category = $item.Category
                setting = $item.Setting
                expected = $item.ExpectedValue
                actual = $item.ActualValue
                remediation = $item.RemediationStep
            }
            
            Send-WinHardenEventToWebhook -EventType "security_alert" -EventData $alertData
        }
    }
}

# Run drift alert check
New-DriftAlert -BaselineName "Production-Baseline" -AlertThreshold "Critical"
```

### Compliance Threshold Alert

```powershell
# Alert if compliance drops below threshold
function Test-ComplianceThreshold {
    param(
        [string]$BaselineName,
        [int]$Threshold = 90  # Alert if below 90%
    )
    
    $compliance = Test-SystemCompliance -BaselineName $BaselineName
    
    if ($compliance.ComplianceRate -lt $Threshold) {
        Write-Host "[ALERT] Compliance $($compliance.ComplianceRate)% is below threshold $Threshold%"
        
        $alertData = @{
            alert_type = "low_compliance"
            baseline = $BaselineName
            current_compliance = $compliance.ComplianceRate
            threshold = $Threshold
            failed_checks = $compliance.FailedChecks
            total_checks = $compliance.TotalChecks
        }
        
        Send-WinHardenEventToWebhook -EventType "compliance_alert" -EventData $alertData
    }
}

# Run threshold check
Test-ComplianceThreshold -BaselineName "Production-Baseline" -Threshold 90
```

---

## Dashboards

### Splunk Dashboard Definition

```xml
<dashboard>
  <label>WinHarden Compliance Overview</label>
  <refresh>300</refresh>
  
  <row>
    <panel>
      <title>Overall Compliance Rate</title>
      <single>
        <search>
          <query>
            index=winharden event_type=compliance
            | stats latest(overall_compliance) as compliance
            | fields compliance
          </query>
        </search>
        <option name="underLabel">% Compliant</option>
        <option name="colorMode">block</option>
        <option name="rangeColors">["0x D93F35","0x F7BC38","0x 65A637"]</option>
        <option name="rangeValues">[85,95]</option>
      </single>
    </panel>
    
    <panel>
      <title>Failed Checks</title>
      <single>
        <search>
          <query>
            index=winharden event_type=compliance
            | stats latest(failed_checks) as failures
            | fields failures
          </query>
        </search>
      </single>
    </panel>
  </row>
  
  <row>
    <panel>
      <title>Compliance Trend</title>
      <chart>
        <search>
          <query>
            index=winharden event_type=compliance
            | timechart latest(overall_compliance) by source
          </query>
        </search>
        <option name="charting.chart">line</option>
      </chart>
    </panel>
  </row>
  
  <row>
    <panel>
      <title>Failed Checks by Category</title>
      <table>
        <search>
          <query>
            index=winharden event_type=compliance failures
            | stats sum(failures) as count by category
            | sort - count
          </query>
        </search>
      </table>
    </panel>
  </row>
</dashboard>
```

---

**Document Version:** 2.0  
**Last Updated:** 2026-06-27  
**Target Audience:** Security Operations Center, SIEM Administrators  
**Complexity Level:** Intermediate to Advanced
