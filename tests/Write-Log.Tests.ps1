BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\Core.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module Core -Force -ErrorAction SilentlyContinue
}

Describe "Write-Log" {
    Context "Error level logging" {
        It "logs message with correct format" {
            $testMessage = "Test error message"
            $logDir = "$PSScriptRoot\..\logs"

            if (Test-Path $logDir) {
                Remove-Item $logDir -Recurse -Force
            }

            Write-Log -Message $testMessage -Level Error

            $logFile = Get-ChildItem -Path $logDir -Filter "log_*.csv" | Select-Object -First 1
            $logFile | Should -Not -BeNullOrEmpty

            $content = @(Get-Content -Path $logFile.FullName)
            $content[-1] | Should -Match "ERROR"
            $content[-1] | Should -Match $testMessage
        }

        It "creates logs directory if not exists" {
            $logDir = "$PSScriptRoot\..\logs"
            if (Test-Path $logDir) {
                Remove-Item $logDir -Recurse -Force
            }

            Write-Log -Message "Test" -Level Error

            Test-Path $logDir | Should -Be $true
        }
    }

    Context "Warning level logging" {
        It "logs warning message" {
            $testMessage = "Test warning"
            Write-Log -Message $testMessage -Level Warning

            $logFile = Get-ChildItem -Path "$PSScriptRoot\..\logs" -Filter "log_*.csv" | Select-Object -First 1
            $content = @(Get-Content -Path $logFile.FullName)
            $content[-1] | Should -Match "WARNING"
        }
    }

    Context "Info level logging" {
        It "logs info message" {
            $testMessage = "Test info"
            Write-Log -Message $testMessage -Level Info

            $logFile = Get-ChildItem -Path "$PSScriptRoot\..\logs" -Filter "log_*.csv" | Select-Object -First 1
            $content = @(Get-Content -Path $logFile.FullName)
            $content[-1] | Should -Match "INFO"
        }
    }

    Context "Sensitive data masking" {
        It "masks password in log message" {
            $testMessage = "User login with password=SecureP@ssw0rd"
            Write-Log -Message $testMessage -Level Info

            $logFile = Get-ChildItem -Path "$PSScriptRoot\..\logs" -Filter "log_*.csv" | Select-Object -First 1
            $content = @(Get-Content -Path $logFile.FullName)
            $content[-1] | Should -Match "password=\*\*\*"
            $content[-1] | Should -Not -Match "SecureP@ssw0rd"
        }

        It "masks token in log message" {
            $testMessage = "API token=abc123xyz789"
            Write-Log -Message $testMessage -Level Info

            $logFile = Get-ChildItem -Path "$PSScriptRoot\..\logs" -Filter "log_*.csv" | Select-Object -First 1
            $content = @(Get-Content -Path $logFile.FullName)
            $content[-1] | Should -Match "token=\*\*\*"
            $content[-1] | Should -Not -Match "abc123xyz789"
        }

        It "masks api_key in log message" {
            $testMessage = "Configure api_key=secret_key_12345"
            Write-Log -Message $testMessage -Level Info

            $logFile = Get-ChildItem -Path "$PSScriptRoot\..\logs" -Filter "log_*.csv" | Select-Object -First 1
            $content = @(Get-Content -Path $logFile.FullName)
            $content[-1] | Should -Match "api_key=\*\*\*"
            $content[-1] | Should -Not -Match "secret_key"
        }
    }
}
