<#
.SYNOPSIS
Wrapper script to generate HTML report from markdown documentation.

.DESCRIPTION
Convenience wrapper that calls New-HardeningHTMLReport function to convert markdown
documentation into a professional HTML report. Loads Core module and provides
user-friendly output.

.PARAMETER MarkdownFile
Path to markdown file to convert. Default: COMPLETE_TESTING_GUIDE.md

.PARAMETER OutputFile
Path where HTML report will be saved. Default: C:\Reports\WinHarden\WinHarden_Testing_Report.html

.PARAMETER Confirm
Prompts for confirmation before generating the report.

.PARAMETER WhatIf
Shows what would happen without making changes.

.EXAMPLE
.\Generate-HTML-Report.ps1

Uses default paths to generate HTML report.

.EXAMPLE
.\Generate-HTML-Report.ps1 -MarkdownFile "C:\Docs\Guide.md" -OutputFile "C:\Reports\Report.html"

Generates report from custom markdown file.

.NOTES
Requires Core module with New-HardeningHTMLReport function.
Uses Write-Output for compatibility with all PowerShell execution contexts.
#>

[CmdletBinding(SupportsShouldProcess)]
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
    Write-Output "[OK] Core module loaded"

    Write-Output "[INFO] Generating HTML report..."
    $result = New-HardeningHTMLReport -MarkdownFile $MarkdownFile -OutputFile $OutputFile -Confirm:$Confirm -WhatIf:$WhatIf

    if ($result) {
        Write-Output "[OK] HTML Report generated successfully"
        Write-Output "[OK] Output file: $($result.FullName)"
        Write-Output "[OK] File size: $([Math]::Round($result.Length / 1KB, 2)) KB"
    }
}
catch {
    Write-Error "[ERROR] $_" -ErrorAction Stop
}
