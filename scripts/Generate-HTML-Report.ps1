<#
.SYNOPSIS
Wrapper script to generate HTML report from markdown documentation.

.DESCRIPTION
Convenience wrapper that calls New-HardeningHTMLReport function to convert markdown
documentation into a professional HTML report. Import Core module before running.

.PARAMETER MarkdownFile
Path to markdown file to convert.

.PARAMETER OutputFile
Path where HTML report will be saved.

.EXAMPLE
.\Generate-HTML-Report.ps1 -MarkdownFile "C:\Docs\GUIDE.md" -OutputFile "C:\Reports\Report.html"

.NOTES
Requires New-HardeningHTMLReport function from functions/Core module.
#>

param(
    [string]$MarkdownFile = "C:\Repos\WinHarden\docs\testing\COMPLETE_TESTING_GUIDE.md",
    [string]$OutputFile = "C:\Reports\WinHarden\WinHarden_Testing_Report.html"
)

$ErrorActionPreference = 'Stop'

try {
    $corePath = $null
    if (Test-Path ".\modules\Core.psm1") {
        $corePath = ".\modules\Core.psm1"
    }
    elseif (Test-Path "C:\Repos\WinHarden\modules\Core.psm1") {
        $corePath = "C:\Repos\WinHarden\modules\Core.psm1"
    }

    if ($null -eq $corePath) {
        Write-Error "[ERROR] Core module not found" -ErrorAction Stop
    }

    Import-Module $corePath -Force -ErrorAction Stop | Out-Null

    $result = New-HardeningHTMLReport -MarkdownFile $MarkdownFile -OutputFile $OutputFile
    Write-Output "[OK] HTML Report generated successfully"
    Write-Output "[OK] Output file: $($result.FullName)"
    Write-Output "[OK] File size: $([Math]::Round($result.Length / 1KB, 2)) KB"
}
catch {
    Write-Error "[ERROR] $_" -ErrorAction Stop
}
