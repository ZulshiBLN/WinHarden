#!/usr/bin/env pwsh
<#
.SYNOPSIS
Pre-commit hook for WinHarden – validates PowerShell code quality.

.DESCRIPTION
Runs PSScriptAnalyzer on staged PowerShell files. Aborts commit if validation fails.

.NOTES
Executed automatically by Git before each commit.
Bypass (emergency only): git commit --no-verify
#>

$ErrorActionPreference = 'Stop'

# Get staged PowerShell files
$stagedFiles = @(git diff --cached --name-only --diff-filter=d -q | Where-Object { $_ -match '\.ps1$' })

if ($stagedFiles.Count -eq 0) {
    exit 0
}

Write-Output "[PRE-COMMIT] Validating $($stagedFiles.Count) PowerShell file(s)..."

# Load PSScriptAnalyzer settings from project root
$repoRoot = git rev-parse --show-toplevel 2>$null
$settingsPath = if ($repoRoot) {
    Join-Path $repoRoot 'PSScriptAnalyzerSettings.psd1'
}
else {
    $null
}
$settings = if ($settingsPath -and (Test-Path $settingsPath)) {
    $settingsPath
}
else {
    $null
}

# Run PSScriptAnalyzer on staged files
$analysisResults = @()
foreach ($file in $stagedFiles) {
    if (Test-Path $file) {
        $results = Invoke-ScriptAnalyzer -Path $file -Recurse -Settings $settings
        if ($results) {
            $analysisResults += $results
        }
    }
}

# Report findings
if ($analysisResults) {
    Write-Output "`n[ERROR] PSScriptAnalyzer found $($analysisResults.Count) issue(s):`n"
    $analysisResults | Select-Object File, RuleName, Line, Message | Format-Table -AutoSize
    Write-Output "`n[ACTION] Fix issues or use: git commit --no-verify (not recommended)`n"
    exit 1
}

Write-Output "[OK] All checks passed`n"
exit 0
