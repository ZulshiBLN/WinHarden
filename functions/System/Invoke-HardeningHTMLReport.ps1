function Invoke-HardeningHTMLReport {
    <#
    .SYNOPSIS
    Generates HTML report from markdown documentation with module loading.

    .DESCRIPTION
    Convenience function that loads the Core module and calls New-HardeningHTMLReport
    to convert markdown documentation into a professional HTML report. Provides
    user-friendly error handling and output messages.

    .PARAMETER MarkdownFile
    Path to markdown file to convert. Default: COMPLETE_TESTING_GUIDE.md

    .PARAMETER OutputFile
    Path where HTML report will be saved.
    Default: C:\Reports\WinHarden\WinHarden_Testing_Report.html

    .PARAMETER Confirm
    Prompts for confirmation before generating the report.

    .PARAMETER WhatIf
    Shows what would happen without making changes.

    .EXAMPLE
    Invoke-HardeningHTMLReport

    Uses default paths to generate HTML report from COMPLETE_TESTING_GUIDE.md

    .EXAMPLE
    Invoke-HardeningHTMLReport -MarkdownFile "C:\Docs\Guide.md" -OutputFile "C:\Reports\Report.html"

    Generates report from custom markdown file.

    .EXAMPLE
    Invoke-HardeningHTMLReport -WhatIf

    Shows what would happen without creating the report.

    .NOTES
    - Loads Core module automatically if not already loaded
    - Calls New-HardeningHTMLReport from Core module
    - Returns FileInfo object for generated HTML file
    - Compatible with PowerShell 5.1+

    .OUTPUTS
    System.IO.FileInfo
    Returns file info object for the generated HTML report.
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$MarkdownFile = "C:\Repos\WinHarden\docs\testing\COMPLETE_TESTING_GUIDE.md",
        [string]$OutputFile = "C:\Reports\WinHarden\WinHarden_Testing_Report.html"
    )

    $ErrorActionPreference = 'Stop'

    try {
        # Determine Core module path
        $corePath = $null
        if (Test-Path ".\modules\Core.psm1") {
            $corePath = ".\modules\Core.psm1"
        }
        elseif (Test-Path "C:\Repos\WinHarden\modules\Core.psm1") {
            $corePath = "C:\Repos\WinHarden\modules\Core.psm1"
        }

        if ($null -eq $corePath) {
            throw "Core module not found in expected locations"
        }

        # Load Core module if not already loaded
        if (-not (Get-Module Core -ErrorAction SilentlyContinue)) {
            Import-Module $corePath -Force -ErrorAction Stop | Out-Null
            Write-Verbose "Loaded Core module from: $corePath"
        }
        else {
            Write-Verbose "Core module already loaded"
        }

        # Call New-HardeningHTMLReport function
        Write-Verbose "Invoking New-HardeningHTMLReport..."
        $result = New-HardeningHTMLReport -MarkdownFile $MarkdownFile -OutputFile $OutputFile -Confirm:$Confirm -WhatIf:$WhatIf

        if ($result) {
            Write-Output "[OK] HTML Report generated successfully"
            Write-Output "[OK] Output file: $($result.FullName)"
            Write-Output "[OK] File size: $([Math]::Round($result.Length / 1KB, 2)) KB"
        }

        return $result
    }
    catch {
        Write-Error -Message "Failed to generate HTML report: $_" -ErrorAction Stop
    }
}
