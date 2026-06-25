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

# Pester Tests – mit Code Coverage
if (-not $SkipTests) {
    Write-Host "`n[Pester] Running tests..." -ForegroundColor Yellow

    $pesterConfig = @{
        Path    = './tests'
        Show    = 'All'
        PassThru = $true
        OutputFormat = 'Detailed'
    }

    if (-not $Validate) {
        $pesterConfig['CodeCoverage'] = './functions'
    }

    $testResults = Invoke-Pester @pesterConfig

    if ($testResults.FailedCount -gt 0) {
        Write-Host "`nTests FAILED: $($testResults.FailedCount) failure(s)" -ForegroundColor Red
        throw "Pester tests failed"
    }

    # Code Coverage Check (nur wenn nicht -Validate)
    if (-not $Validate -and $testResults.CodeCoverage) {
        $coveredCommands = $testResults.CodeCoverage.NumberOfCommandsExecuted
        $totalCommands = $coveredCommands + $testResults.CodeCoverage.NumberOfCommandsMissed
        $coverage = if ($totalCommands -gt 0) { ($coveredCommands / $totalCommands) * 100 } else { 0 }

        Write-Host "`nCode Coverage: $([Math]::Round($coverage, 2))%" -ForegroundColor Cyan

        if ($coverage -lt 95) {
            Write-Host "Code Coverage is $coverage%, but 95% is required" -ForegroundColor Red
            throw "Code coverage below 95% threshold"
        }
    }

    Write-Host "[Pester] PASSED" -ForegroundColor Green
}

Write-Host "`n=== Build Successful ===" -ForegroundColor Green
exit 0
