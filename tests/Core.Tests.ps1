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
        It "removes logs older than 7 days" {
            $logDir = "$PSScriptRoot\..\logs"

            if (-not (Test-Path $logDir)) {
                New-Item -ItemType Directory -Path $logDir -Force | Out-Null
            }

            $oldLogFile = Join-Path $logDir "log_2026-05-01.csv"
            "Timestamp,Level,Caller,Function,LineNumber,Message" | Set-Content -Path $oldLogFile

            (Get-Item $oldLogFile).LastWriteTime = (Get-Date).AddDays(-10)

            InModuleScope Core {
                _CleanupOldLogs -LogDir $using:logDir -DaysToKeep 7
            }

            Test-Path $oldLogFile | Should -Be $false
        }

        It "keeps logs newer than 7 days" {
            $logDir = "$PSScriptRoot\..\logs"
            if (-not (Test-Path $logDir)) {
                New-Item -ItemType Directory -Path $logDir -Force | Out-Null
            }

            $newLogFile = Join-Path $logDir "log_2026-06-20.csv"
            "Timestamp,Level,Caller,Function,LineNumber,Message" | Set-Content -Path $newLogFile

            (Get-Item $newLogFile).LastWriteTime = (Get-Date).AddDays(-3)

            InModuleScope Core {
                _CleanupOldLogs -LogDir $using:logDir -DaysToKeep 7
            }

            Test-Path $newLogFile | Should -Be $true
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
            $version.Module | Should -Be 'WinOpsKit'
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
    Context "Test-WinOpsKitDependencies function" {
        It "returns true when no required modules specified" {
            $result = Test-WinOpsKitDependencies -RequiredModules @()
            $result | Should -Be $true
        }

        It "returns false for missing required module" {
            $result = Test-WinOpsKitDependencies -RequiredModules @('NonExistentModule123xyz')
            $result | Should -Be $false
        }

        It "returns true for existing module" {
            $result = Test-WinOpsKitDependencies -RequiredModules @('Microsoft.PowerShell.Utility')
            $result | Should -Be $true
        }

        It "handles multiple modules" {
            $modules = @('Microsoft.PowerShell.Utility', 'NonExistentModule999')
            $result = Test-WinOpsKitDependencies -RequiredModules $modules
            $result | Should -Be $false
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
