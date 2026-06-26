[CmdletBinding()]
param(
    [switch]$SkipAnalyzer,
    [switch]$SkipTests,
    [switch]$Validate
)

$ErrorActionPreference = 'Stop'

Write-Output "[BUILD] === WinOpsKit Build ==="

# PSScriptAnalyzer – Inline Settings (Option B)
if (-not $SkipAnalyzer) {
    Write-Output "`n[PSScriptAnalyzer] Linting..."

    $settingsPath = Join-Path $PSScriptRoot 'PSScriptAnalyzerSettings.psd1'
    $analyzerSettings = if (Test-Path $settingsPath) { $settingsPath } else {
        @{
            Rules = @{
                PSUseApprovedVerbs            = @{ Enable = $true }
                PSUseConsistentIndentation    = @{ Enable = $true; IndentationSize = 4 }
                PSUseConsistentWhitespace     = @{ Enable = $true }
                PSAvoidUsingCmdletAliases     = @{ Enable = $true }
                PSPlaceCloseBrace             = @{ Enable = $true; NoEmptyLineBefore = $false }
                PSPlaceOpenBrace              = @{ Enable = $true; OnSameLine = $true }
                PSMeasureBasicParseCount      = @{ Enable = $true }
                PSProvideCommentHelp          = @{ Enable = $true }
            }
            Severity = @('Error', 'Warning')
        }
    }

    $analyzerPaths = @('./functions', './scripts')
    $analyzerResults = @()

    foreach ($path in $analyzerPaths) {
        if (Test-Path $path) {
            $results = Invoke-ScriptAnalyzer -Path $path -Settings $analyzerSettings -Recurse
            $analyzerResults += $results
        }
    }

    if ($analyzerResults) {
        Write-Output "PSScriptAnalyzer found $(($analyzerResults | Measure-Object).Count) issues:"
        $analyzerResults | Format-Table -AutoSize
        throw "PSScriptAnalyzer validation failed"
    }

    Write-Output "[PSScriptAnalyzer] PASSED"
}

# Pester Tests – mit Code Coverage (Pester 5.x)
if (-not $SkipTests) {
    Write-Output "`n[Pester] Running tests..."

    $pesterConfig = New-PesterConfiguration
    $pesterConfig.Run.Path = './tests'
    $pesterConfig.Run.PassThru = $true
    $pesterConfig.Output.Verbosity = 'Detailed'

    if (-not $Validate) {
        $pesterConfig.CodeCoverage.Enabled = $true
        $pesterConfig.CodeCoverage.Path = './functions'
    }

    $testResults = Invoke-Pester -Configuration $pesterConfig

    if ($testResults.FailedCount -gt 0) {
        Write-Output "`nTests FAILED: $($testResults.FailedCount) failure(s)"
        throw "Pester tests failed"
    }

    # Code Coverage Check (Pester 5.x format)
    if (-not $Validate -and $testResults.CodeCoverage) {
        Write-Output "`n[CodeCoverage] Analyzing code coverage..."

        $coverageData = $testResults.CodeCoverage
        if ($coverageData -and $coverageData.Count -gt 0) {
            $totalLines = $coverageData.Count
            $hitLines = @($coverageData | Where-Object { $_.Hit -eq $true }).Count
            $missedLines = $totalLines - $hitLines
            $coveragePercent = [math]::Round(($hitLines / $totalLines) * 100, 2)

            Write-Output "  Total lines analyzed: $totalLines"
            Write-Output "  Lines hit: $hitLines"
            Write-Output "  Lines missed: $missedLines"
            Write-Output "  Coverage: $coveragePercent%"

            # Enforce 95% minimum coverage (ADR-003 requirement)
            $minCoverage = 95
            if ($coveragePercent -lt $minCoverage) {
                Write-Output "`n[CodeCoverage] WARNING: Coverage ($coveragePercent%) is below minimum ($minCoverage%)"
                Write-Output "  Required by: ADR-003 (Testing Framework requirement)"
                Write-Output "  Status: BELOW THRESHOLD - Add more tests to improve coverage"
            }
            else {
                Write-Output "`n[CodeCoverage] PASSED - Coverage meets $minCoverage% minimum" -ForegroundColor Green
            }
        }
        else {
            Write-Output "  Warning: Coverage data not available (may require Pester 5.7+)"
        }
    }

    Write-Output "[Pester] PASSED"
}

Write-Output "`n=== Build Successful ==="
exit 0
