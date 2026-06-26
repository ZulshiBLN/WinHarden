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
$stagedFiles = @(git diff --cached --name-only --diff-filter=d | Where-Object { $_ -match '\.ps1$' })

if (-not $stagedFiles) {
    exit 0
}

Write-Output "[PRE-COMMIT] Validating $($stagedFiles.Count) PowerShell file(s)..."

# Run PSScriptAnalyzer on staged files
$analysisResults = @()
foreach ($file in $stagedFiles) {
    if (Test-Path $file) {
        $results = Invoke-ScriptAnalyzer -Path $file -Recurse
        if ($results) {
            $analysisResults += $results
        }
    }
}

# Report findings
if ($analysisResults) {
    Write-Output "`n[ERROR] PSScriptAnalyzer found $($analysisResults.Count) issue(s):`n"
    $analysisResults | Format-Table -Property RuleName, Line, Message -AutoSize
    Write-Output "`n[ACTION] Fix issues or use: git commit --no-verify (not recommended)`n"
    exit 1
}

Write-Output "[OK] All checks passed`n"
exit 0
