function Export-HardeningReport {
    <#
    .SYNOPSIS
    Exports hardening compliance reports in multiple formats.

    .DESCRIPTION
    Generates comprehensive hardening reports from compliance verification results.
    Supports multiple export formats for different use cases:
    - JSON: Structured data for programmatic analysis
    - CSV: Tabular format for Excel/spreadsheets
    - HTML: Formatted report for documentation/dashboards
    - Text: Human-readable summary report

    Reports include:
    - Executive summary with compliance metrics
    - Category-level breakdown
    - Per-rule compliance details
    - Remediation recommendations
    - Trending data (if historical reports available)

    .PARAMETER ComplianceReport
    The compliance report object from Test-HardeningCompliance.
    Mandatory.

    .PARAMETER Format
    Export format: JSON, CSV, HTML, or Text.
    Default: Text (console output)

    .PARAMETER OutputPath
    File path for exported report.
    If omitted with file format, outputs to console.

    .PARAMETER IncludeRuleDetails
    If specified, includes per-rule details in report.
    Useful for detailed compliance documentation.

    .PARAMETER IncludeTrending
    If specified, includes compliance trending data.
    Requires historical reports for comparison.

    .PARAMETER HistoricalReports
    Array of previous compliance reports for trending analysis.
    Optional. Used with -IncludeTrending.

    .EXAMPLE
    $compliance = Test-HardeningCompliance -Session $session
    Export-HardeningReport -ComplianceReport $compliance -Format HTML -OutputPath report.html

    Exports detailed HTML compliance report.

    .EXAMPLE
    $compliance = Test-HardeningCompliance -Session $session
    Export-HardeningReport -ComplianceReport $compliance -Format JSON | ConvertFrom-Json

    Exports JSON report for programmatic processing.

    .EXAMPLE
    $compliance = Test-HardeningCompliance -Session $session
    Export-HardeningReport -ComplianceReport $compliance -Format CSV -OutputPath compliance.csv -IncludeRuleDetails

    Exports CSV with detailed per-rule compliance data.

    .NOTES
    DEPENDENCIES: Write-Log (Core)
    OUTPUT FORMATS: JSON, CSV, HTML, Text
    FILE OUTPUT: Supports UTF-8 encoding with BOM
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject]
        $ComplianceReport,

        [Parameter(Mandatory = $false)]
        [ValidateSet('JSON', 'CSV', 'HTML', 'Text')]
        [string]
        $Format = 'Text',

        [Parameter(Mandatory = $false)]
        [string]
        $OutputPath,

        [switch]
        $IncludeRuleDetails,

        [switch]
        $IncludeTrending,

        [Parameter(Mandatory = $false)]
        [PSCustomObject[]]
        $HistoricalReports
    )

    begin {
        $ErrorActionPreference = 'Stop'
    }

    process {
        try {
            Write-Log -Message "Generating $Format hardening report" -Level Info

            # Generate report content based on format
            $reportContent = switch ($Format) {
                'JSON' {
                    _GenerateJsonReport -Report $ComplianceReport -IncludeRuleDetails:$IncludeRuleDetails
                }
                'CSV' {
                    _GenerateCsvReport -Report $ComplianceReport -IncludeRuleDetails:$IncludeRuleDetails
                }
                'HTML' {
                    _GenerateHtmlReport -Report $ComplianceReport `
                        -IncludeRuleDetails:$IncludeRuleDetails `
                        -IncludeTrending:$IncludeTrending `
                        -HistoricalReports $HistoricalReports
                }
                'Text' {
                    _GenerateTextReport -Report $ComplianceReport `
                        -IncludeRuleDetails:$IncludeRuleDetails `
                        -IncludeTrending:$IncludeTrending `
                        -HistoricalReports $HistoricalReports
                }
            }

            # Output or save report
            if ($OutputPath) {
                $reportContent | Out-File -FilePath $OutputPath -Encoding UTF8 -Force
                Write-Log -Message "Report exported to: $OutputPath" -Level Info
                Get-Item -Path $OutputPath
            }
            else {
                $reportContent
            }
        }
        catch {
            $errMsg = "Failed to export hardening report: $($_.Exception.Message)"
            Write-ErrorLog -Message $errMsg -Caller $MyInvocation.MyCommand.Name
            throw
        }
    }
}

# ================================================================================
# Private Report Generation Functions
# ================================================================================

function _GenerateJsonReport {
    <#
    .SYNOPSIS
    Internal helper: Generates JSON compliance report from verification results.
    #>
    param(
        [PSCustomObject]$Report,
        [bool]$IncludeRuleDetails
    )

    $jsonReport = [ordered]@{
        ReportMetadata = @{
            GeneratedTime = $Report.VerificationTime
            Profile = $Report.Profile
            TargetSystem = $Report.TargetSystem
            SessionId = $Report.SessionId
        }
        ComplianceSummary = @{
            TotalRules = $Report.TotalRules
            CompliantRules = $Report.CompliantRules
            NonCompliantRules = $Report.NonCompliantRules
            CompliancePercentage = $Report.CompliancePercentage
            Status = $Report.Status
        }
        CategoryBreakdown = $Report.CategoryBreakdown
    }

    if ($IncludeRuleDetails) {
        $jsonReport['RuleDetails'] = @($Report.RuleResults | ForEach-Object {
                [ordered]@{
                    RuleName = $_.RuleName
                    Category = $_.Category
                    Severity = $_.Severity
                    Compliant = $_.Compliant
                    ExpectedValue = $_.ExpectedValue
                    ActualValue = $_.ActualValue
                }
            })
    }

    $jsonReport | ConvertTo-Json -Depth 10
}

function _GenerateCsvReport {
    <#
    .SYNOPSIS
    Internal helper: Generates CSV compliance report for spreadsheet analysis.
    #>
    param(
        [PSCustomObject]$Report,
        [bool]$IncludeRuleDetails
    )

    if ($IncludeRuleDetails) {
        $csvData = @($Report.RuleResults | ForEach-Object {
                [PSCustomObject]@{
                    RuleName = $_.RuleName
                    Category = $_.Category
                    Severity = $_.Severity
                    Compliant = $_.Compliant
                    ExpectedValue = $_.ExpectedValue
                    ActualValue = $_.ActualValue
                    Profile = $Report.Profile
                    TargetSystem = $Report.TargetSystem
                }
            })
    }
    else {
        $csvData = [PSCustomObject]@{
            Profile = $Report.Profile
            TargetSystem = $Report.TargetSystem
            TotalRules = $Report.TotalRules
            CompliantRules = $Report.CompliantRules
            NonCompliantRules = $Report.NonCompliantRules
            CompliancePercentage = $Report.CompliancePercentage
            Status = $Report.Status
            GeneratedTime = $Report.VerificationTime
        }
    }

    $csvData | ConvertTo-Csv -NoTypeInformation
}

function _GenerateHtmlReport {
    <#
    .SYNOPSIS
    Internal helper: Generates formatted HTML compliance report for dashboards and documentation.
    #>
    param(
        [PSCustomObject]$Report,
        [bool]$IncludeRuleDetails,
        [bool]$IncludeTrending,
        [PSCustomObject[]]$HistoricalReports
    )

    $statusColor = switch ($Report.Status) {
        'Fully Compliant' { '#28a745' 
        }
        'Highly Compliant' { '#17a2b8' 
        }
        'Mostly Compliant' { '#ffc107' 
        }
        'Partially Compliant' { '#fd7e14' 
        }
        default { '#dc3545' 
        }
    }

    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>WinHarden Hardening Compliance Report</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: #333; border-bottom: 3px solid $statusColor; padding-bottom: 10px; }
        h2 { color: #555; margin-top: 30px; }
        .summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin: 20px 0; }
        .metric { background: #f9f9f9; padding: 15px; border-left: 4px solid $statusColor; border-radius: 4px; }
        .metric-label { font-size: 0.9em; color: #666; }
        .metric-value { font-size: 1.8em; font-weight: bold; color: $statusColor; }
        .status-badge { display: inline-block; padding: 8px 16px; background: $statusColor; color: white; border-radius: 4px; font-weight: bold; }
        table { width: 100%; border-collapse: collapse; margin: 15px 0; }
        th { background: #f0f0f0; padding: 12px; text-align: left; font-weight: 600; border-bottom: 2px solid #ddd; }
        td { padding: 10px 12px; border-bottom: 1px solid #eee; }
        tr:hover { background: #f9f9f9; }
        .compliant { color: #28a745; font-weight: 500; }
        .non-compliant { color: #dc3545; font-weight: 500; }
        .category-row { background: #f5f5f5; font-weight: 600; }
        .footer { margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee; color: #666; font-size: 0.9em; }
    </style>
</head>
<body>
    <div class="container">
        <h1>WinHarden Hardening Compliance Report</h1>

        <div style="margin: 15px 0;">
            <strong>Report Generated:</strong> $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        </div>

        <div style="margin: 15px 0;">
            <strong>Status:</strong> <span class="status-badge">$($Report.Status)</span>
        </div>

        <h2>Executive Summary</h2>
        <div class="summary">
            <div class="metric">
                <div class="metric-label">Total Rules</div>
                <div class="metric-value">$($Report.TotalRules)</div>
            </div>
            <div class="metric">
                <div class="metric-label">Compliant</div>
                <div class="metric-value compliant">$($Report.CompliantRules)</div>
            </div>
            <div class="metric">
                <div class="metric-label">Non-Compliant</div>
                <div class="metric-value non-compliant">$($Report.NonCompliantRules)</div>
            </div>
            <div class="metric">
                <div class="metric-label">Compliance Rate</div>
                <div class="metric-value">$($Report.CompliancePercentage)%</div>
            </div>
        </div>

        <h2>Compliance by Category</h2>
        <table>
            <thead>
                <tr>
                    <th>Category</th>
                    <th>Total</th>
                    <th>Compliant</th>
                    <th>Non-Compliant</th>
                    <th>Compliance %</th>
                </tr>
            </thead>
            <tbody>
"@

    foreach ($category in $Report.CategoryBreakdown.Keys | Sort-Object) {
        $stats = $Report.CategoryBreakdown[$category]
        $html += @"
                <tr class="category-row">
                    <td>$category</td>
                    <td>$($stats.Total)</td>
                    <td class="compliant">$($stats.Compliant)</td>
                    <td class="non-compliant">$($stats.NonCompliant)</td>
                    <td>$($stats.Percentage)%</td>
                </tr>
"@
    }

    $html += @"
            </tbody>
        </table>
"@

    if ($IncludeRuleDetails) {
        $html += @"
        <h2>Rule Details</h2>
        <table>
            <thead>
                <tr>
                    <th>Rule Name</th>
                    <th>Category</th>
                    <th>Severity</th>
                    <th>Status</th>
                </tr>
            </thead>
            <tbody>
"@
        foreach ($rule in $Report.RuleResults) {
            $statusClass = if ($rule.Compliant) { 'compliant' 
            }
            else { 'non-compliant' 
            }
            $statusText = if ($rule.Compliant) { 'Compliant' 
            }
            else { 'Non-Compliant' 
            }
            $html += @"
                <tr>
                    <td>$($rule.RuleName)</td>
                    <td>$($rule.Category)</td>
                    <td>$($rule.Severity)</td>
                    <td class="$statusClass">$statusText</td>
                </tr>
"@
        }
        $html += @"
            </tbody>
        </table>
"@
    }

    if ($IncludeTrending -and $HistoricalReports) {
        $html += _GenerateTrendingSection -CurrentReport $Report -HistoricalReports $HistoricalReports
    }

    $html += @"
        <div class="footer">
            <p>WinHarden Windows Hardening System</p>
            <p>Profile: $($Report.Profile) | Target: $($Report.TargetSystem)</p>
        </div>
    </div>
</body>
</html>
"@

    $html
}

function _GenerateTextReport {
    <#
    .SYNOPSIS
    Internal helper: Generates human-readable text compliance report for console output.
    #>
    param(
        [PSCustomObject]$Report,
        [bool]$IncludeRuleDetails,
        [bool]$IncludeTrending,
        [PSCustomObject[]]$HistoricalReports
    )

    $text = @"
================================================================================
                 WinHarden HARDENING COMPLIANCE REPORT
================================================================================

Report Generated:      $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Profile:              $($Report.Profile)
Target System:        $($Report.TargetSystem)
Session ID:           $($Report.SessionId)

================================================================================
COMPLIANCE SUMMARY
================================================================================

Status:               $($Report.Status)
Total Rules:          $($Report.TotalRules)
Compliant Rules:      $($Report.CompliantRules)
Non-Compliant Rules:  $($Report.NonCompliantRules)
Compliance Rate:      $($Report.CompliancePercentage)%

================================================================================
CATEGORY BREAKDOWN
================================================================================
"@

    foreach ($category in $Report.CategoryBreakdown.Keys | Sort-Object) {
        $stats = $Report.CategoryBreakdown[$category]
        $text += @"

$category
  Total Rules:       $($stats.Total)
  Compliant:         $($stats.Compliant)
  Non-Compliant:     $($stats.NonCompliant)
  Compliance Rate:   $($stats.Percentage)%
"@
    }

    if ($IncludeRuleDetails) {
        $text += @"

================================================================================
RULE DETAILS
================================================================================
"@
        foreach ($rule in $Report.RuleResults) {
            $status = if ($rule.Compliant) { 'COMPLIANT' 
            }
            else { 'NON-COMPLIANT' 
            }
            $text += @"

Rule:     $($rule.RuleName)
Category: $($rule.Category)
Severity: $($rule.Severity)
Status:   $status
"@
        }
    }

    if ($IncludeTrending -and $HistoricalReports) {
        $text += _GenerateTrendingTextSection -CurrentReport $Report -HistoricalReports $HistoricalReports
    }

    $text += @"

================================================================================
END OF REPORT
================================================================================
"@

    $text
}

function _GenerateTrendingSection {
    <#
    .SYNOPSIS
    Internal helper: Generates trending data section with compliance velocity and trend direction for HTML reports.
    #>
    param(
        [PSCustomObject]$CurrentReport,
        [PSCustomObject[]]$HistoricalReports
    )

    if ($null -eq $HistoricalReports -or $HistoricalReports.Count -eq 0) {
        return ""
    }

    $sorted = @($HistoricalReports | Sort-Object -Property VerificationTime)
    $previous = $sorted[-1]
    $percentDiff = $CurrentReport.CompliancePercentage - $previous.CompliancePercentage
    $trend = if ($percentDiff -gt 0) { "UP" 
    }
    elseif ($percentDiff -lt 0) { "DOWN" 
    }
    else { "STABLE" 
    }

    $html = @"
        <h2>Compliance Trending</h2>
        <table>
            <thead>
                <tr>
                    <th>Date</th>
                    <th>Compliance %</th>
                    <th>Compliant Rules</th>
                    <th>Status</th>
                </tr>
            </thead>
            <tbody>
"@

    foreach ($report in $sorted + @($CurrentReport)) {
        $html += @"
                <tr>
                    <td>$(($report.VerificationTime).ToString('yyyy-MM-dd HH:mm'))</td>
                    <td>$($report.CompliancePercentage)%</td>
                    <td>$($report.CompliantRules)/$($report.TotalRules)</td>
                    <td>$($report.Status)</td>
                </tr>
"@
    }

    $html += @"
            </tbody>
        </table>
        <p>Trend: <strong>$trend</strong> | Change: $([Math]::Abs($percentDiff))%</p>
"@

    $html
}

function _GenerateTrendingTextSection {
    param(
        [PSCustomObject]$CurrentReport,
        [PSCustomObject[]]$HistoricalReports
    )

    if ($null -eq $HistoricalReports -or $HistoricalReports.Count -eq 0) {
        return ""
    }

    $sorted = @($HistoricalReports | Sort-Object -Property VerificationTime)
    $previous = $sorted[-1]
    $percentDiff = $CurrentReport.CompliancePercentage - $previous.CompliancePercentage
    $trend = if ($percentDiff -gt 0) { "IMPROVING" 
    }
    elseif ($percentDiff -lt 0) { "DECLINING" 
    }
    else { "STABLE" 
    }

    $text = @"

================================================================================
COMPLIANCE TRENDING
================================================================================

Trend:           $trend
Change:          $([Math]::Abs($percentDiff))%
Previous Score:  $($previous.CompliancePercentage)%
Current Score:   $($CurrentReport.CompliancePercentage)%
"@

    $text
}
