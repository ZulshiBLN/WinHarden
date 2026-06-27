[CmdletBinding()]
param(
    [switch]$SkipAnalyzer,
    [switch]$SkipTests,
    [switch]$Validate
)

$ErrorActionPreference = 'Stop'

Write-Output "[BUILD] === WinHarden Build ==="

# PSScriptAnalyzer - Inline Settings (removed - use external config file)
if (-not $SkipAnalyzer) {
    Write-Output "`n[PSScriptAnalyzer] Linting..."

    $analyzerSettings = Join-Path $PSScriptRoot 'PSScriptAnalyzerSettings.psd1'

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

# Pester Tests - Code Coverage (Pester 5.x)
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

    # Code Coverage Check (Pester 5.x format) - ADR-003 Enforcement
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
            Write-Output "  Overall Coverage: $coveragePercent%"

            # Enforce 95% minimum coverage (ADR-003 requirement)
            $minCoverage = 95
            if ($coveragePercent -lt $minCoverage) {
                Write-Output "`n[CodeCoverage] ERROR: Coverage ($coveragePercent%) is BELOW minimum ($minCoverage%)"
                Write-Output "  Required by: ADR-003 (Testing Framework requirement)"
                Write-Output "  Status: COVERAGE THRESHOLD NOT MET"

                # Show per-file coverage analysis
                Write-Output "`n  Per-File Coverage Analysis:"
                $fileGroups = $coverageData | Group-Object -Property File
                foreach ($fileGroup in $fileGroups) {
                    $filePath = $fileGroup.Name
                    $fileName = Split-Path $filePath -Leaf
                    $fileTotalLines = $fileGroup.Count
                    $fileHitLines = @($fileGroup.Group | Where-Object { $_.Hit -eq $true }).Count
                    $fileCoveragePercent = [math]::Round(($fileHitLines / $fileTotalLines) * 100, 2)

                    $status = if ($fileCoveragePercent -lt $minCoverage) {
                        "[LOW]"
                    }
                    else {
                        "[OK]"
                    }
                    Write-Output "    $status $fileName : $fileCoveragePercent% ($fileHitLines/$fileTotalLines lines)"
                }

                throw "[ADR-003] Code coverage check failed: $coveragePercent% < $minCoverage% minimum"
            }
            else {
                Write-Output "`n[OK] CodeCoverage PASSED - Coverage $coveragePercent% meets $minCoverage% minimum (ADR-003)"
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
