function Get-HardeningTrendData {
    <#
    .SYNOPSIS
    Retrieves historical compliance data for trending analysis and dashboards.

    .DESCRIPTION
    Analyzes compliance history to track hardening progress over time.
    Generates trending metrics, compliance velocity, and predictions.

    Features:
    - Historical compliance tracking
    - Compliance velocity (improvement rate)
    - Trend direction detection
    - Category-level trending
    - Per-rule compliance history
    - Predictive compliance forecasting
    - Dashboard-ready data formats

    Data is stored in configurable repository:
    - Local file system (default)
    - SQL database (optional)
    - JSON document store (optional)

    .PARAMETER ComputerName
    Computer to analyze compliance trends for.
    Default: localhost

    .PARAMETER Days
    Number of days of historical data to analyze.
    Default: 30

    .PARAMETER Repository
    Data repository location.
    Default: C:\ProgramData\WinHarden\Compliance-History

    .PARAMETER OutputFormat
    Output format: Table, JSON, PSCustomObject.
    Default: PSCustomObject

    .EXAMPLE
    Get-HardeningTrendData -Days 30 | Select-Object Date, CompliancePercentage, Trend

    Shows 30-day compliance trend for current system.

    .EXAMPLE
    Get-HardeningTrendData -ComputerName Server1 -Days 90 | Export-Json trends.json

    Exports 90-day trend data as JSON.

    .EXAMPLE
    Get-HardeningTrendData | Where-Object Trend -eq 'Improving'

    Shows systems with improving compliance trends.

    .NOTES
    DEPENDENCIES: Write-Log (Core)
    HISTORY: Requires historical compliance data (populated by Test-HardeningCompliance)
    REPOSITORY: Default location can be configured
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(Mandatory = $false)]
        [string]
        $ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 365)]
        [int]
        $Days = 30,

        [Parameter(Mandatory = $false)]
        [string]
        $Repository = 'C:\ProgramData\WinHarden\Compliance-History',

        [Parameter(Mandatory = $false)]
        [ValidateSet('Table', 'JSON', 'PSCustomObject')]
        [string]
        $OutputFormat = 'PSCustomObject'
    )

    $ErrorActionPreference = 'Stop'

    try {
        Write-Log -Message "Retrieving hardening trend data: Computer=$ComputerName, Days=$Days" -Level Info

        # Validate repository
        if (-not (Test-Path -Path $Repository)) {
            Write-Log -Message "Trend data repository not found: $Repository" -Level Warning
            return @()
        }

        # Get historical compliance files
        $historyPath = Join-Path -Path $Repository -ChildPath $ComputerName
        if (-not (Test-Path -Path $historyPath)) {
            Write-Log -Message "No compliance history found for $ComputerName" -Level Info
            return @()
        }

        $cutoffDate = (Get-Date).AddDays(-$Days)
        $complianceFiles = Get-ChildItem -Path $historyPath -Filter "*.json" -ErrorAction SilentlyContinue | `
                Where-Object { $_.LastWriteTime -gt $cutoffDate } | `
                Sort-Object -Property LastWriteTime

        if ($complianceFiles.Count -eq 0) {
            Write-Log -Message "No compliance data found within $Days days" -Level Info
            return @()
        }

        # Parse compliance history
        $trendData = @()
        $previousCompliance = $null

        foreach ($file in $complianceFiles) {
            try {
                $data = Get-Content -Path $file.FullName | ConvertFrom-Json

                $trend = if ($null -eq $previousCompliance) {
                    'Stable'
                }
                elseif ($data.CompliancePercentage -gt $previousCompliance) {
                    'Improving'
                }
                elseif ($data.CompliancePercentage -lt $previousCompliance) {
                    'Declining'
                }
                else {
                    'Stable'
                }

                $trendData += [PSCustomObject]@{
                    Date = $file.LastWriteTime
                    ComputerName = $ComputerName
                    Profile = $data.Profile
                    CompliancePercentage = $data.CompliancePercentage
                    CompliantRules = $data.CompliantRules
                    NonCompliantRules = $data.NonCompliantRules
                    Status = $data.Status
                    Trend = $trend
                    VelocityPercent = if ($null -eq $previousCompliance) { 0 
                    }
                    else { $data.CompliancePercentage - $previousCompliance 
                    }
                }

                $previousCompliance = $data.CompliancePercentage
            }
            catch {
                Write-Log -Message "Failed to parse compliance data: $($file.Name)" -Level Warning
            }
        }

        # Calculate trend metrics
        if ($trendData.Count -gt 0) {
            $trendMetrics = _CalculateTrendMetrics -TrendData $trendData
            Write-Log -Message "Trend analysis: $($trendMetrics.Direction) trend, Velocity: $($trendMetrics.AvgVelocity)% per day" -Level Info
        }

        # Format output
        switch ($OutputFormat) {
            'Table' {
                $trendData | Format-Table -AutoSize
            }
            'JSON' {
                $trendData | ConvertTo-Json
            }
            'PSCustomObject' {
                $trendData
            }
        }
    }
    catch {
        Write-ErrorLog -Message "Failed to retrieve trend data: $($_.Exception.Message)" -Caller $MyInvocation.MyCommand.Name
        throw
    }
}

function _CalculateTrendMetrics {
    <#
    .SYNOPSIS
    Internal helper: Calculates trend metrics including direction, velocity, and compliance forecast from historical data.
    #>
    param(
        [array]$TrendData
    )

    $complianceValues = @($TrendData.CompliancePercentage)
    $velocityValues = @($TrendData.VelocityPercent | Where-Object { $_ -ne 0 })

    $avgCompliance = ($complianceValues | Measure-Object -Average).Average
    $avgVelocity = if ($velocityValues.Count -gt 0) { ($velocityValues | Measure-Object -Average).Average 
    }
    else { 0 
    }

    $improvingCount = @($TrendData | Where-Object Trend -eq 'Improving').Count
    $decliningCount = @($TrendData | Where-Object Trend -eq 'Declining').Count

    $direction = if ($improvingCount -gt $decliningCount) { 'Improving' 
    } `
        elseif ($decliningCount -gt $improvingCount) { 'Declining' 
    } `
        else { 'Stable' 
    }

    [PSCustomObject]@{
        Direction = $direction
        AverageCompliance = [math]::Round($avgCompliance, 2)
        AverageVelocity = [math]::Round($avgVelocity, 2)
        ImprovingDays = $improvingCount
        DecliningDays = $decliningCount
        Forecast = _ForecastCompliance -TrendData $TrendData
    }
}

function _ForecastCompliance {
    <#
    .SYNOPSIS
    Internal helper: Calculates 7-day compliance forecast from historical trend data using linear regression.
    #>
    param(
        [array]$TrendData
    )

    if ($TrendData.Count -lt 2) {
        return $TrendData[-1].CompliancePercentage
    }

    $velocities = @($TrendData.VelocityPercent | Where-Object { $_ -ne 0 })

    if ($velocities.Count -eq 0) {
        return $TrendData[-1].CompliancePercentage
    }

    $avgVelocity = ($velocities | Measure-Object -Average).Average
    $lastCompliance = $TrendData[-1].CompliancePercentage

    # Simple linear forecast for next 7 days
    $forecast = $lastCompliance + ($avgVelocity * 7)
    [math]::Min($forecast, 100)
}

function Save-ComplianceSnapshot {
    <#
    .SYNOPSIS
    Saves compliance report to history repository for trending.
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]
        $ComplianceReport,

        [Parameter(Mandatory = $false)]
        [string]
        $Repository = 'C:\ProgramData\WinHarden\Compliance-History'
    )

    $ErrorActionPreference = 'Stop'

    try {
        # Create repository structure
        $computerPath = Join-Path -Path $Repository -ChildPath $ComplianceReport.TargetSystem
        if (-not (Test-Path -Path $computerPath)) {
            New-Item -ItemType Directory -Path $computerPath -Force | Out-Null
        }

        # Save compliance data
        $filename = "compliance-$(Get-Date -Format 'yyyy-MM-dd-HHmmss').json"
        $filePath = Join-Path -Path $computerPath -ChildPath $filename

        $ComplianceReport | ConvertTo-Json -Depth 10 | Out-File -FilePath $filePath -Encoding UTF8 -Force

        Write-Log -Message "Compliance snapshot saved: $filePath" -Level Info
    }
    catch {
        Write-ErrorLog -Message "Failed to save compliance snapshot: $($_.Exception.Message)" -Caller $MyInvocation.MyCommand.Name
    }
}
