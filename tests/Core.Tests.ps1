BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\Core.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module Core -Force -ErrorAction SilentlyContinue
}

Describe "Core Module – Logging Functions" {
    Context "Write-Log with Error level" {
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

    Context "Write-Log with Warning level" {
        It "logs warning message" {
            $testMessage = "Test warning"
            Write-Log -Message $testMessage -Level Warning

            $logFile = Get-ChildItem -Path "$PSScriptRoot\..\logs" -Filter "log_*.csv" | Select-Object -First 1
            $content = @(Get-Content -Path $logFile.FullName)
            $content[-1] | Should -Match "WARNING"
        }
    }

    Context "Write-Log with Info level" {
        It "logs info message" {
            $testMessage = "Test info"
            Write-Log -Message $testMessage -Level Info

            $logFile = Get-ChildItem -Path "$PSScriptRoot\..\logs" -Filter "log_*.csv" | Select-Object -First 1
            $content = @(Get-Content -Path $logFile.FullName)
            $content[-1] | Should -Match "INFO"
        }
    }

    Context "Sensitive data masking in logs" {
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

    Context "_CleanupOldLogs private function" {
        It "function exists in Core module" {
            $funcCode = Get-Content -Path "$PSScriptRoot\..\functions\Core\_CleanupOldLogs.ps1" -Raw
            $funcCode | Should -Match "function _CleanupOldLogs"
        }

        It "has proper 7-day retention logic" {
            $funcCode = Get-Content -Path "$PSScriptRoot\..\functions\Core\_CleanupOldLogs.ps1" -Raw
            $funcCode | Should -Match "AddDays\(-"
            $funcCode | Should -Match "DaysToKeep"
        }

        It "is called by Write-Log for cleanup" {
            $logCode = Get-Content -Path "$PSScriptRoot\..\functions\Core\Write-Log.ps1" -Raw
            $logCode | Should -Match "_CleanupOldLogs"
        }
    }
}

Describe "Core Module – Error Handling Functions" {
    Context "Write-ErrorLog function" {
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
}

Describe "Core Module – Validation Functions" {
    Context "Test-NotNullOrEmpty function" {
        It "returns true for valid value" {
            { Test-NotNullOrEmpty -Value "ValidValue" -Name "TestParam" } | Should -Not -Throw
        }

        It "throws error for null value" {
            { Test-NotNullOrEmpty -Value $null -Name "TestParam" } | Should -Throw
        }

        It "throws error for empty string" {
            { Test-NotNullOrEmpty -Value "" -Name "TestParam" } | Should -Throw
        }

        It "throws error for whitespace-only string" {
            { Test-NotNullOrEmpty -Value "   " -Name "TestParam" } | Should -Throw
        }

        It "includes parameter name in error message" {
            { Test-NotNullOrEmpty -Value "" -Name "ComputerName" } | Should -Throw "*ComputerName*"
        }
    }

    Context "Test-ValidPath function" {
        It "returns true for existing path" {
            $testPath = $PSScriptRoot
            { Test-ValidPath -Path $testPath -Name "TestPath" } | Should -Not -Throw
        }

        It "throws error for non-existent path" {
            $invalidPath = "C:\NonExistent\Path\That\Does\Not\Exist"
            { Test-ValidPath -Path $invalidPath -Name "TestPath" } | Should -Throw
        }

        It "includes path in error message" {
            $invalidPath = "C:\InvalidPath"
            { Test-ValidPath -Path $invalidPath -Name "TestPath" } | Should -Throw "*$invalidPath*"
        }
    }
}

Describe "Core Module – Data Masking Functions" {
    Context "ConvertTo-MaskedString function" {
        It "masks password" {
            $testInput = "password=MySecret123"
            $output = ConvertTo-MaskedString -InputString $testInput
            $output | Should -Match "password=\*\*\*"
            $output | Should -Not -Match "MySecret123"
        }

        It "masks multiple sensitive keywords" {
            $testInput = "password=secret1 token=token2 apikey=key3"
            $output = ConvertTo-MaskedString -InputString $testInput
            $output | Should -Match "password=\*\*\*"
            $output | Should -Match "token=\*\*\*"
            $output | Should -Match "apikey=\*\*\*"
        }

        It "preserves non-sensitive content" {
            $testInput = "Server connection to SRV01 successful"
            $output = ConvertTo-MaskedString -InputString $testInput
            $output | Should -Be $testInput
        }
    }
}

Describe "Core Module – Module Info Functions" {
    Context "Get-ModuleVersion function" {
        It "returns version information" {
            $version = Get-ModuleVersion
            $version | Should -Not -BeNullOrEmpty
            $version.Module | Should -Be 'WinHarden'
            $version.Version | Should -Not -BeNullOrEmpty
            $version.PowerShellVersion | Should -Not -BeNullOrEmpty
        }

        It "returns hashtable with expected keys" {
            $version = Get-ModuleVersion
            $version.Keys | Should -Contain 'Module'
            $version.Keys | Should -Contain 'Version'
            $version.Keys | Should -Contain 'PowerShellVersion'
            $version.Keys | Should -Contain 'BuildDate'
            $version.Keys | Should -Contain 'Phase'
        }
    }
}

Describe "Core Module – Dependency Functions" {
    Context "Test-WinHardenDependencies function" {
        It "returns hashtable with PowerShell version" {
            $result = Test-WinHardenDependencies
            $result | Should -BeOfType [hashtable]
            $result.Keys | Should -Contain 'PowerShellVersion'
        }

        It "checks PowerShell version requirement" {
            $result = Test-WinHardenDependencies
            $result.PowerShellVersion.Status | Should -Match 'OK|FAIL'
            $result.PowerShellVersion.Required | Should -Be '5.1'
        }

        It "checks optional modules when specified" {
            $result = Test-WinHardenDependencies -Module @('Pester')
            $result['Pester'] | Should -Not -BeNullOrEmpty
            $result['Pester'].Status | Should -Match 'Available|NotFound'
        }

        It "handles empty module array" {
            $result = Test-WinHardenDependencies -Module @()
            $result | Should -BeOfType [hashtable]
            $result.Keys | Should -Contain 'PowerShellVersion'
        }
    }
}

Describe "Core Module – Private Functions (InModuleScope)" {
    Context "_MaskSensitiveData private function" {
        It "masks password parameter" {
            InModuleScope Core {
                $result = _MaskSensitiveData -InputString "password=secret123"
                $result | Should -Match "password=\*\*\*"
                $result | Should -Not -Match "secret123"
            }
        }

        It "masks multiple parameters" {
            InModuleScope Core {
                $result = _MaskSensitiveData -InputString "user=admin password=pass123 token=token456"
                $result | Should -Match "password=\*\*\*"
                $result | Should -Match "token=\*\*\*"
            }
        }

        It "is case-insensitive" {
            InModuleScope Core {
                $result = _MaskSensitiveData -InputString "PASSWORD=secret123 Token=token123"
                $result | Should -Match "password=\*\*\*"
                $result | Should -Match "token=\*\*\*"
            }
        }
    }

    Context "_TestLogLevel private function" {
        BeforeEach {
            $env:LOG_LEVEL = 'Info'
        }

        It "returns true for Error level when LOG_LEVEL is Info" {
            InModuleScope Core {
                $result = _TestLogLevel -Level 'Error'
                $result | Should -Be $true
            }
        }

        It "returns true for Info level when LOG_LEVEL is Info" {
            InModuleScope Core {
                $result = _TestLogLevel -Level 'Info'
                $result | Should -Be $true
            }
        }

        It "returns false for Debug level when LOG_LEVEL is Info" {
            InModuleScope Core {
                $result = _TestLogLevel -Level 'Debug'
                $result | Should -Be $false
            }
        }

        It "respects LOG_LEVEL env variable" {
            $env:LOG_LEVEL = 'Debug'
            InModuleScope Core {
                $result = _TestLogLevel -Level 'Debug'
                $result | Should -Be $true
            }
        }
    }
}
