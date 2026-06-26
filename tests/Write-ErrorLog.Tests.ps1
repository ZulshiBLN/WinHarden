BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\Core.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module Core -Force -ErrorAction SilentlyContinue
}

Describe "Write-ErrorLog" {
    Context "Error logging with Message only" {
        It "logs message with Error level" {
            $testMessage = "Critical error occurred"

            $logDir = "$PSScriptRoot\..\logs"
            if (Test-Path $logDir) {
                Remove-Item $logDir -Recurse -Force
            }

            Write-ErrorLog -Message $testMessage

            $logFile = Get-ChildItem -Path $logDir -Filter "log_*.csv" | Select-Object -First 1
            $content = @(Get-Content -Path $logFile.FullName)
            $content[-1] | Should -Match "ERROR"
            $content[-1] | Should -Match $testMessage
        }
    }

    Context "Error logging with Caller parameter" {
        It "logs message with Error level and Caller" {
            $testMessage = "Operation failed"
            $testCaller = "Get-SystemInfo"

            $logDir = "$PSScriptRoot\..\logs"
            if (Test-Path $logDir) {
                Remove-Item $logDir -Recurse -Force
            }

            Write-ErrorLog -Message $testMessage -Caller $testCaller

            $logFile = Get-ChildItem -Path $logDir -Filter "log_*.csv" | Select-Object -First 1
            $content = @(Get-Content -Path $logFile.FullName)
            $content[-1] | Should -Match "ERROR"
            $content[-1] | Should -Match $testMessage
            $content[-1] | Should -Match $testCaller
        }
    }

    Context "WhatIf parameter support" {
        It "accepts WhatIf parameter without error" {
            $testMessage = "WhatIf test"

            # Should not throw error when WhatIf is specified
            { Write-ErrorLog -Message $testMessage -WhatIf } | Should -Not -Throw
        }

        It "accepts Confirm parameter without error" {
            $testMessage = "Confirm test"

            # Should not throw error when Confirm is specified
            { Write-ErrorLog -Message $testMessage -Confirm:$false } | Should -Not -Throw
        }
    }

    Context "Parameter validation" {
        It "throws error when Message is null" {
            { Write-ErrorLog -Message $null } | Should -Throw
        }

        It "throws error when Message is empty string" {
            { Write-ErrorLog -Message "" } | Should -Throw
        }
    }

    Context "Integration with Write-Log" {
        It "passes Message parameter to Write-Log" {
            $testMessage = "Integration test message"

            $logDir = "$PSScriptRoot\..\logs"
            if (Test-Path $logDir) {
                Remove-Item $logDir -Recurse -Force
            }

            Write-ErrorLog -Message $testMessage

            $logFile = Get-ChildItem -Path $logDir -Filter "log_*.csv" | Select-Object -First 1
            $content = @(Get-Content -Path $logFile.FullName)

            # Verify log entry contains both ERROR level and message
            $logEntry = $content[-1]
            $logEntry | Should -Match "ERROR"
            $logEntry | Should -Match $testMessage
            # Verify CSV format (comma-separated values)
            ($logEntry -split ',').Count | Should -BeGreaterThan 1
        }
    }
}
