# WinHarden Hardening - SIEM & Dashboard Integration

**Version:** 1.0  
**Last Updated:** 2026-06-26  
**Audience:** Security Operations, SIEM Administrators

---

## Overview

The WinHarden Hardening System generates compliance data in formats compatible with SIEM platforms and compliance dashboards.

---

## JSON Export Format

### Usage

```powershell
# Export to JSON
$compliance = Test-HardeningCompliance -Session $session
Export-HardeningReport -ComplianceReport $compliance `
    -Format JSON -OutputPath "compliance.json"
```

### JSON Schema

```json
{
  "CompliancePercentage": 85,
  "Status": "Mostly Compliant",
  "TotalRules": 20,
  "CompliantRules": 17,
  "NonCompliantRules": 3,
  "TargetSystem": "SERVER01",
  "Profile": "Recommended",
  "Timestamp": "2026-06-26T14:30:00Z",
  "RuleDetails": [
    {
      "Name": "Account-MinimumPasswordLength",
      "Status": "Compliant",
      "ExpectedValue": "12",
      "ActualValue": "12"
    },
    {
      "Name": "Firewall-EnableWindowsDefender",
      "Status": "NonCompliant",
      "ExpectedValue": "true",
      "ActualValue": "false"
    }
  ]
}
```

### SIEM Integration Examples

#### Splunk

```powershell
# Export and send to Splunk HEC
$compliance = Test-HardeningCompliance -Session $session
$json = Export-HardeningReport -ComplianceReport $compliance -Format JSON

$splunkHEC = "https://splunk.company.com:8088"
$token = "your-hec-token"

$headers = @{
    "Authorization" = "Splunk $token"
    "Content-Type" = "application/json"
}

$event = @{
    event = $json
    sourcetype = "_json"
    source = "winopskit_hardening"
    host = $compliance.TargetSystem
} | ConvertTo-Json

Invoke-RestMethod -Uri "$splunkHEC/services/collector" `
    -Method POST -Headers $headers -Body $event
```

#### Elasticsearch

```powershell
# Export and send to Elasticsearch
$compliance = Test-HardeningCompliance -Session $session
$json = Export-HardeningReport -ComplianceReport $compliance -Format JSON

$elasticUrl = "https://elasticsearch.company.com:9200"
$index = "winopskit-hardening-$(Get-Date -Format 'yyyy.MM.dd')"

$headers = @{
    "Content-Type" = "application/json"
    "Authorization" = "Basic $(([Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes('user:password')))))"
}

Invoke-RestMethod -Uri "$elasticUrl/$index/_doc" `
    -Method POST -Headers $headers -Body $json -SkipCertificateCheck
```

#### Azure Sentinel

```powershell
# Send to Azure Sentinel via Log Analytics API
$workspaceId = "your-workspace-id"
$sharedKey = "your-shared-key"
$logType = "HardeningCompliance"

$compliance = Test-HardeningCompliance -Session $session
$json = Export-HardeningReport -ComplianceReport $compliance -Format JSON

# Create signature for Log Analytics API
$method = "POST"
$contentType = "application/json"
$resource = "/api/logs"
$rfc1123date = [DateTime]::UtcNow.ToString("r")
$contentLength = $json.Length
$signature = "POST`n$contentLength`napplication/json`n$rfc1123date`n$resource"
$hmac = New-Object System.Security.Cryptography.HMACSHA256
$hmac.Key = [Convert]::FromBase64String($sharedKey)
$signatureHash = $hmac.ComputeHash([Text.Encoding]::UTF8.GetBytes($signature))
$authSignature = [Convert]::ToBase64String($signatureHash)
$authorization = "SharedKey ${workspaceId}:$authSignature"

$uri = "https://${workspaceId}.ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01"

$headers = @{
    "Authorization" = $authorization
    "Log-Type" = $logType
    "x-ms-date" = $rfc1123date
    "time-generated-field" = "Timestamp"
}

Invoke-WebRequest -Uri $uri -Method $method `
    -ContentType $contentType -Headers $headers -Body $json
```

---

## Compliance Dashboard Integration

### Grafana Dashboard

Create dashboard using JSON source:

```json
{
  "dashboard": {
    "title": "WinHarden Hardening Compliance",
    "panels": [
      {
        "title": "Overall Compliance",
        "targets": [
          {
            "expr": "hardening_compliance_percentage",
            "legendFormat": "{{ system }}"
          }
        ]
      },
      {
        "title": "Compliant Systems",
        "targets": [
          {
            "expr": "count(hardening_compliance_percentage > 90)"
          }
        ]
      },
      {
        "title": "Non-Compliant Rules",
        "targets": [
          {
            "expr": "hardening_non_compliant_rules"
          }
        ]
      }
    ]
  }
}
```

### PowerBI Integration

```powershell
# Export multiple compliance reports to CSV for PowerBI
$servers = @("Server1", "Server2", "Server3")

foreach ($server in $servers) {
    $session = New-HardeningSession -Profile Recommended `
        -TargetSystem Server -OSVersion 2022 `
        -ComputerName $server
    
    $compliance = Test-HardeningCompliance -Session $session
    
    Export-HardeningReport -ComplianceReport $compliance `
        -Format CSV -OutputPath "compliance_$server.csv"
}

# Combine and upload to PowerBI
$data = Get-ChildItem "compliance_*.csv" | 
    ForEach-Object { Import-Csv $_ }

# Load to PowerBI dataset via REST API
```

---

## Compliance Trending

### Track Compliance Over Time

```powershell
# Generate trend data
$trends = Get-HardeningTrendData -ComputerName "Server1" -Days 30

# Export trends to CSV for analysis
$trends | Export-Csv "trends.csv" -NoTypeInformation
```

### Trend Data Schema

```
Date,CompliancePercentage,CompliantRules,NonCompliantRules,Trend,VelocityPercent
2026-06-01,75,15,5,Stable,0
2026-06-08,80,16,4,Improving,5
2026-06-15,85,17,3,Improving,5
2026-06-22,90,18,2,Improving,5
```

---

## Alert Integration

### Email to SIEM Integration

Hardening alerts can be routed to SIEM via email parsing:

```powershell
# Send alert with SIEM-formatted fields
Send-HardeningAlert `
    -SmtpServer "smtp.company.com" `
    -FromAddress "hardening@company.com" `
    -ToAddress "siem-integration@company.com" `
    -AlertType Compliance `
    -Severity $(if($compliance.CompliancePercentage -lt 70) { "Critical" } else { "Warning" }) `
    -ComplianceReport $compliance
```

### Webhook Integration

```powershell
# Send to Slack via Webhook
$compliance = Test-HardeningCompliance -Session $session
$slackMessage = @{
    text = "WinHarden Hardening Alert"
    attachments = @(
        @{
            color = if($compliance.CompliancePercentage -ge 90) { "good" } else { "warning" }
            fields = @(
                @{ title = "System"; value = $compliance.TargetSystem; short = $true }
                @{ title = "Compliance"; value = "$($compliance.CompliancePercentage)%"; short = $true }
                @{ title = "Status"; value = $compliance.Status; short = $false }
            )
        }
    )
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://hooks.slack.com/services/YOUR/WEBHOOK/URL" `
    -Method POST -Body $slackMessage -ContentType "application/json"
```

---

## Metrics & KPIs

### Key Performance Indicators

1. **Overall Compliance Rate**
   - Metric: `(CompliantRules / TotalRules) * 100`
   - Target: >= 95%

2. **System Compliance Distribution**
   - Metric: % of systems with >= target compliance
   - Target: >= 90% of systems

3. **Rule Compliance Consistency**
   - Metric: Standard deviation of compliance across systems
   - Target: <= 10%

4. **Compliance Velocity**
   - Metric: Change in compliance percentage per day
   - Target: >= 0% (stable or improving)

5. **Time to Compliance**
   - Metric: Days from hardening initiation to target compliance
   - Target: <= 7 days

---

## Automated Reporting

### Daily Compliance Report to Email

```powershell
# Script for daily scheduled task
$servers = Get-ADComputer -Filter "OperatingSystem -like '*Server*'" | 
    Select-Object -ExpandProperty Name

$reports = foreach ($server in $servers) {
    try {
        $session = New-HardeningSession -Profile Recommended `
            -TargetSystem Server -OSVersion 2022 `
            -ComputerName $server
        
        Test-HardeningCompliance -Session $session
    }
    catch {
        Write-Error "Failed to check $server : $_"
    }
}

# Calculate aggregate metrics
$avgCompliance = ($reports | Measure-Object -Property CompliancePercentage -Average).Average
$nonCompliant = @($reports | Where-Object CompliancePercentage -lt 90).Count

# Send email
$body = @"
Daily WinHarden Hardening Report
=================================
Date: $(Get-Date)
Total Systems: $($reports.Count)
Average Compliance: $avgCompliance%
Non-Compliant Systems: $nonCompliant

Details:
$($reports | ConvertTo-Csv -NoTypeInformation | Out-String)
"@

Send-MailMessage -From "hardening@company.com" `
    -To "security-team@company.com" `
    -Subject "Daily Hardening Report" `
    -Body $body `
    -SmtpServer "smtp.company.com"
```

---

## Query Examples

### Get All Non-Compliant Rules

```powershell
# Export JSON and query
$compliance = Test-HardeningCompliance -Session $session
$json = $compliance | ConvertTo-Json

# Parse and filter
$rules = $compliance.NonCompliantRules
$rules | ForEach-Object { Write-Host "$($_.Name): Expected=$($_.ExpectedValue), Actual=$($_.ActualValue)" }
```

### Trending Query

```powershell
# Get systems with declining compliance
$trends = Get-HardeningTrendData -Days 30
$declining = $trends | Group-Object ComputerName | 
    Where-Object { $_.Group[-1].Trend -eq "Declining" }

Write-Host "Systems with declining compliance:"
$declining | ForEach-Object { Write-Host "  - $($_.Name)" }
```

---

## Best Practices

1. **Real-Time Streaming:** Stream JSON events to SIEM for real-time monitoring
2. **Regular Exports:** Schedule daily/weekly CSV exports for trending
3. **Alert Escalation:** Route Critical alerts to on-call security team
4. **Retention:** Keep 90+ days of historical data for trend analysis
5. **Alerting Thresholds:** Set alerts for compliance < 80%
6. **Automation:** Automate remediation for non-critical non-compliant rules
7. **Reporting:** Weekly reports to management with trend analysis

---

**Version:** 1.0  
**Last Updated:** 2026-06-26  
**Status:** Production Ready
