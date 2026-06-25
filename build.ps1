[CmdletBinding()]
param(
    [switch]$SkipAnalyzer,
    [switch]$SkipTests,
    [switch]$Validate
)

$ErrorActionPreference = 'Stop'

Write-Host "=== WinOpsKit Build ===" -ForegroundColor Cyan

# PSScriptAnalyzer – Inline Settings (Option B)
if (-not $SkipAnalyzer) {
    Write-Host "`n[PSScriptAnalyzer] Linting..." -ForegroundColor Yellow

    $analyzerSettings = @{
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

    $analyzerPaths = @('./functions', './scripts', './tests')
    $analyzerResults = @()

    foreach ($path in $analyzerPaths) {
        if (Test-Path $path) {
            $results = Invoke-ScriptAnalyzer -Path $path -Settings $analyzerSettings -Recurse
            $analyzerResults += $results
        }
    }

    if ($analyzerResults) {
        Write-Host "PSScriptAnalyzer found $(($analyzerResults | Measure-Object).Count) issues:" -ForegroundColor Red
        $analyzerResults | Format-Table -AutoSize
        throw "PSScriptAnalyzer validation failed"
    }

    Write-Host "[PSScriptAnalyzer] PASSED" -ForegroundColor Green
}

# Pester Tests – mit Code Coverage (Pester 5.x)
if (-not $SkipTests) {
    Write-Host "`n[Pester] Running tests..." -ForegroundColor Yellow

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
        Write-Host "`nTests FAILED: $($testResults.FailedCount) failure(s)" -ForegroundColor Red
        throw "Pester tests failed"
    }

    # Code Coverage Check (Pester 5.x format)
    if (-not $Validate -and $testResults.CodeCoverage) {
        Write-Host "`n[CodeCoverage] Coverage report generated - detailed analysis in Pester output" -ForegroundColor Cyan
        Write-Host "Note: Coverage validation requires Pester 5.x parsing - implement detailed check in next iteration" -ForegroundColor Yellow
    }

    Write-Host "[Pester] PASSED" -ForegroundColor Green
}

Write-Host "`n=== Build Successful ===" -ForegroundColor Green
exit 0
