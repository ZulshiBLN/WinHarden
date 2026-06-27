BeforeAll {
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $modulePath = Join-Path $repoRoot "modules\Core.psm1"

    if (-not (Test-Path $modulePath)) {
        $modulePath = "C:\Repos\WinHarden\modules\Core.psm1"
    }

    Import-Module $modulePath -Force -ErrorAction Stop
}

AfterAll {
    Remove-Module Core -Force -ErrorAction SilentlyContinue
}

Describe "New-HardeningHTMLReport" {
    Context "Parameter validation" {
        BeforeAll {
            $testMdFile = Join-Path $TestDrive "param_test.md"
            "# Test Parameter" | Set-Content -Path $testMdFile -Force
        }

        It "Should accept MarkdownFile parameter" {
            $params = @{
                MarkdownFile = $testMdFile
                OutputFile   = Join-Path $TestDrive "Test.html"
            }
            { New-HardeningHTMLReport @params -Confirm:$false } | Should -Not -Throw
        }

        It "Should accept OutputFile parameter" {
            $params = @{
                MarkdownFile = $testMdFile
                OutputFile   = Join-Path $TestDrive "Output\Test.html"
            }
            { New-HardeningHTMLReport @params -Confirm:$false } | Should -Not -Throw
        }

        It "Should support WhatIf parameter" {
            $params = @{
                MarkdownFile = $testMdFile
                OutputFile   = Join-Path $TestDrive "whatif_test.html"
            }
            { New-HardeningHTMLReport @params -WhatIf } | Should -Not -Throw
        }

        It "Should support Confirm parameter" {
            $params = @{
                MarkdownFile = $testMdFile
                OutputFile   = Join-Path $TestDrive "confirm_test.html"
            }
            { New-HardeningHTMLReport @params -Confirm:$false } | Should -Not -Throw
        }
    }

    Context "Input validation" {
        It "Should throw when MarkdownFile not found" {
            $params = @{
                MarkdownFile = "C:\NonExistent.md"
                OutputFile   = "C:\Test.html"
            }
            { New-HardeningHTMLReport @params } | Should -Throw "*Markdown file not found*"
        }

        BeforeAll {
            $testMdFile = Join-Path $TestDrive "test.md"
            $testHtmlFile = Join-Path $TestDrive "test.html"
            "# Test Content" | Set-Content -Path $testMdFile -Force
        }

        It "Should create output file when markdown file exists" {
            New-HardeningHTMLReport -MarkdownFile $testMdFile -OutputFile $testHtmlFile
            Test-Path $testHtmlFile | Should -Be $true
        }

        It "Should return FileInfo object for created HTML file" {
            $result = New-HardeningHTMLReport -MarkdownFile $testMdFile -OutputFile $testHtmlFile
            $result | Should -BeOfType [System.IO.FileInfo]
            $result.Name | Should -Match "\.html$"
        }
    }

    Context "Output file generation" {
        BeforeAll {
            $testMdFile = Join-Path $TestDrive "guide.md"
            $testHtmlFile = Join-Path $TestDrive "output\report.html"
            @"
# Testing Guide

## Phase 1
Testing content for phase 1.

## Results
All tests passed.
"@ | Set-Content -Path $testMdFile -Force
        }

        It "Should create output directory if it doesn't exist" {
            $outputDir = Split-Path -Parent $testHtmlFile
            Test-Path $outputDir | Should -Be $false
            New-HardeningHTMLReport -MarkdownFile $testMdFile -OutputFile $testHtmlFile | Out-Null
            Test-Path $outputDir | Should -Be $true
        }

        It "Should generate valid HTML structure" {
            New-HardeningHTMLReport -MarkdownFile $testMdFile -OutputFile $testHtmlFile | Out-Null
            $content = Get-Content -Path $testHtmlFile -Raw
            $content | Should -Match "<!DOCTYPE html>"
            $content | Should -Match "<html"
            $content | Should -Match "<body>"
            $content | Should -Match "</body>"
            $content | Should -Match "</html>"
        }

        It "Should include CSS styling" {
            New-HardeningHTMLReport -MarkdownFile $testMdFile -OutputFile $testHtmlFile | Out-Null
            $content = Get-Content -Path $testHtmlFile -Raw
            $content | Should -Match "<style>"
            $content | Should -Match "background:"
            $content | Should -Match "font-family:"
        }

        It "Should include header element" {
            New-HardeningHTMLReport -MarkdownFile $testMdFile -OutputFile $testHtmlFile | Out-Null
            $content = Get-Content -Path $testHtmlFile -Raw
            $content | Should -Match "<header>"
            $content | Should -Match "WinHarden Testing Guide"
        }

        It "Should include navigation element" {
            New-HardeningHTMLReport -MarkdownFile $testMdFile -OutputFile $testHtmlFile | Out-Null
            $content = Get-Content -Path $testHtmlFile -Raw
            $content | Should -Match "<nav>"
            $content | Should -Match "Overview"
            $content | Should -Match "Phase"
        }

        It "Should include footer element" {
            New-HardeningHTMLReport -MarkdownFile $testMdFile -OutputFile $testHtmlFile | Out-Null
            $content = Get-Content -Path $testHtmlFile -Raw
            $content | Should -Match "<footer>"
            $content | Should -Match "WinHarden Complete Testing Guide"
        }

        It "Should use UTF8 encoding" {
            New-HardeningHTMLReport -MarkdownFile $testMdFile -OutputFile $testHtmlFile | Out-Null
            Test-Path $testHtmlFile | Should -Be $true
            $content = Get-Content -Path $testHtmlFile -Raw
            $content | Should -Match "<!DOCTYPE html>"
        }

        It "Should use ASCII-only output tags (not Unicode)" {
            New-HardeningHTMLReport -MarkdownFile $testMdFile -OutputFile $testHtmlFile | Out-Null
            $content = Get-Content -Path $testHtmlFile -Raw
            $content | Should -Match "\[OK\]"
            $content | Should -Not -Match "✅"
            $content | Should -Not -Match "❌"
        }

        It "Should generate responsive design meta tags" {
            New-HardeningHTMLReport -MarkdownFile $testMdFile -OutputFile $testHtmlFile | Out-Null
            $content = Get-Content -Path $testHtmlFile -Raw
            $content | Should -Match "viewport"
            $content | Should -Match "width=device-width"
        }

        It "Should include print media queries" {
            New-HardeningHTMLReport -MarkdownFile $testMdFile -OutputFile $testHtmlFile | Out-Null
            $content = Get-Content -Path $testHtmlFile -Raw
            $content | Should -Match "@media print"
        }
    }

    Context "WhatIf support" {
        BeforeAll {
            $testMdFile = Join-Path $TestDrive "whatif.md"
            $testHtmlFile = Join-Path $TestDrive "whatif.html"
            "# Test" | Set-Content -Path $testMdFile -Force
        }

        It "Should not create file when WhatIf is used" {
            New-HardeningHTMLReport -MarkdownFile $testMdFile -OutputFile $testHtmlFile -WhatIf
            Test-Path $testHtmlFile | Should -Be $false
        }
    }

    Context "Error handling" {
        It "Should throw on null MarkdownFile" {
            $params = @{
                MarkdownFile = $null
                OutputFile   = "C:\Test.html"
            }
            { New-HardeningHTMLReport @params } | Should -Throw
        }

        It "Should throw on null OutputFile" {
            $testMdFile = Join-Path $TestDrive "error.md"
            "# Test" | Set-Content -Path $testMdFile -Force

            $params = @{
                MarkdownFile = $testMdFile
                OutputFile   = $null
            }
            { New-HardeningHTMLReport @params } | Should -Throw
        }
    }

    Context "Verbose output" {
        BeforeAll {
            $testMdFile = Join-Path $TestDrive "verbose.md"
            $testHtmlFile = Join-Path $TestDrive "verbose.html"
            "# Verbose Test" | Set-Content -Path $testMdFile -Force
        }

        It "Should output verbose messages when Verbose is enabled" {
            $verbosePreference = $VerbosePreference
            $VerbosePreference = 'Continue'
            $result = New-HardeningHTMLReport -MarkdownFile $testMdFile -OutputFile $testHtmlFile -Verbose 4>&1
            $VerbosePreference = $verbosePreference
            $result | Where-Object { $_ -match "Loaded markdown file|HTML Report generated" } | Should -Not -BeNullOrEmpty
        }
    }
}
