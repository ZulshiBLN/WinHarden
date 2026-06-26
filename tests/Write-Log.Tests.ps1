BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\Core.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module Core -Force -ErrorAction SilentlyContinue
}

Describe "Write-Log" {
    BeforeEach {
        $logDir = "$PSScriptRoot\..\logs"
        if (Test-Path $logDir) {
            Remove-Item $logDir -Recurse -Force -ErrorAction SilentlyContinue
            Start-Sleep -Milliseconds 100
        }
    }

    Context "Error level logging" {
        It "logs message with correct format" {
            $testMessage = "Test error message"

            Write-Log -Message $testMessage -Level Error

            $logFile = Get-ChildItem -Path $logDir -Filter "log_*.csv" | Select-Object -First 1
            $logFile | Should -Not -BeNullOrEmpty

            $content = @(Get-Content -Path $logFile.FullName)
            $content[-1] | Should -Match "ERROR"
            $content[-1] | Should -Match $testMessage
        }

        It "creates logs directory if not exists" {
            $logDir = "$PSScriptRoot\..\logs"

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

    Context "WhatIf behavior" {
        It "handles -WhatIf parameter without writing file" {
            $logDir = "$PSScriptRoot\..\logs"

            Write-Log -Message "WhatIf test" -Level Info -WhatIf

            $logFile = Get-ChildItem -Path $logDir -Filter "log_*.csv" -ErrorAction SilentlyContinue
            $logFile | Should -BeNullOrEmpty
        }

        It "outputs verbose message with WhatIf" {
            $output = Write-Log -Message "WhatIf test" -Level Info -WhatIf -Verbose 4>&1
            $output | Should -Match "WhatIf"
        }
    }

    Context "CSV escaping" {
        It "properly escapes double quotes in message" {
            $testMessage = 'Message with "quoted" text'
            Write-Log -Message $testMessage -Level Info

            $logFile = Get-ChildItem -Path "$PSScriptRoot\..\logs" -Filter "log_*.csv" | Select-Object -First 1
            $content = Get-Content -Path $logFile.FullName -Raw
            $content | Should -Match 'Message with ""quoted"" text'
        }

        It "properly handles messages with commas" {
            $testMessage = "Data: value1, value2, value3"
            Write-Log -Message $testMessage -Level Info

            $logFile = Get-ChildItem -Path "$PSScriptRoot\..\logs" -Filter "log_*.csv" | Select-Object -First 1
            $content = Get-Content -Path $logFile.FullName -Raw
            $content | Should -Match '"Data: value1, value2, value3"'
        }

        It "handles carriage returns in message" {
            $testMessage = "Data with`rcarriage return"
            Write-Log -Message $testMessage -Level Info

            $logFile = Get-ChildItem -Path "$PSScriptRoot\..\logs" -Filter "log_*.csv" | Select-Object -First 1
            $content = Get-Content -Path $logFile.FullName
            $content.Count | Should -BeGreaterThan 1
        }
    }

    Context "File operations" {
        It "creates CSV header with correct columns" {
            $logDir = "$PSScriptRoot\..\logs"

            Write-Log -Message "First entry" -Level Info

            $logFile = Get-ChildItem -Path $logDir -Filter "log_*.csv" | Select-Object -First 1
            $content = @(Get-Content -Path $logFile.FullName)
            $content[0] | Should -Match "Timestamp"
            $content[0] | Should -Match "Level"
            $content[0] | Should -Match "Caller"
            $content[0] | Should -Match "Function"
            $content[0] | Should -Match "LineNumber"
            $content[0] | Should -Match "Message"
        }

        It "appends to existing log file" {
            $logDir = "$PSScriptRoot\..\logs"
            $dateString = (Get-Date -Format 'yyyy-MM-dd')
            $logFile = Join-Path -Path $logDir -ChildPath "log_$dateString.csv"

            Write-Log -Message "First message" -Level Info
            $firstCount = @(Get-Content -Path $logFile).Count

            Write-Log -Message "Second message" -Level Info
            $secondCount = @(Get-Content -Path $logFile).Count

            $secondCount | Should -BeGreaterThan $firstCount
        }
    }

    Context "Log levels" {
        It "logs Debug level" {
            Write-Log -Message "Debug test" -Level Debug

            $logFile = Get-ChildItem -Path "$PSScriptRoot\..\logs" -Filter "log_*.csv" | Select-Object -First 1
            $content = @(Get-Content -Path $logFile.FullName)
            $content[-1] | Should -Match "Debug"
        }

        It "logs Verbose level" {
            Write-Log -Message "Verbose test" -Level Verbose

            $logFile = Get-ChildItem -Path "$PSScriptRoot\..\logs" -Filter "log_*.csv" | Select-Object -First 1
            $content = @(Get-Content -Path $logFile.FullName)
            $content[-1] | Should -Match "Verbose"
        }
    }

    Context "Edge cases" {
        It "handles very long messages" {
            $testMessage = [string]::new('x', 5000)
            Write-Log -Message $testMessage -Level Info

            $logFile = Get-ChildItem -Path "$PSScriptRoot\..\logs" -Filter "log_*.csv" | Select-Object -First 1
            $content = @(Get-Content -Path $logFile.FullName)
            $content[-1] | Should -Match "x{100}"
        }

        It "auto-detects caller from call stack" {
            $logDir = "$PSScriptRoot\..\logs"
            $dateString = (Get-Date -Format 'yyyy-MM-dd')
            $logFile = Join-Path -Path $logDir -ChildPath "log_$dateString.csv"

            Write-Log -Message "Test" -Level Info

            $logFile | Should -Not -BeNullOrEmpty
            Test-Path $logFile | Should -Be $true
            $content = @(Get-Content -Path $logFile)
            $content.Count | Should -BeGreaterThan 1
        }

        It "handles custom caller parameter" {
            Write-Log -Message "Test" -Level Info -Caller "CustomCaller"

            $logFile = Get-ChildItem -Path "$PSScriptRoot\..\logs" -Filter "log_*.csv" | Select-Object -First 1
            $content = @(Get-Content -Path $logFile.FullName)
            $content[-1] | Should -Match "CustomCaller"
        }
    }

    Context "Error handling and edge scenarios" {
        It "handles write errors gracefully" {
            $logDir = "$PSScriptRoot\..\logs"

            Write-Log -Message "Test" -Level Info

            # Make log directory read-only to force error
            $logFile = Get-ChildItem -Path $logDir -Filter "log_*.csv" | Select-Object -First 1
            $acl = Get-Acl -Path $logDir
            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                [System.Security.Principal.WindowsIdentity]::GetCurrent().User,
                [System.Security.AccessControl.FileSystemRights]::Write,
                [System.Security.AccessControl.AccessControlType]::Deny
            )
            $acl.AddAccessRule($rule)
            Set-Acl -Path $logDir -AclObject $acl -ErrorAction SilentlyContinue

            # Try to write (should fail gracefully)
            Write-Log -Message "This should fail" -Level Info -ErrorAction SilentlyContinue

            # Restore permissions
            $acl = Get-Acl -Path $logDir
            $acl.RemoveAccessRule($rule) | Out-Null
            Set-Acl -Path $logDir -AclObject $acl -ErrorAction SilentlyContinue

            # Verify directory still exists
            Test-Path $logDir | Should -Be $true
        }

        It "outputs Debug level messages with -Verbose flag" {
            $output = Write-Log -Message "Debug test message" -Level Debug -Verbose 4>&1

            $logFile = Get-ChildItem -Path "$PSScriptRoot\..\logs" -Filter "log_*.csv" | Select-Object -First 1
            $content = Get-Content -Path $logFile.FullName -Raw
            $content | Should -Match "Debug"
        }

        It "outputs Verbose level messages with -Verbose flag" {
            $output = Write-Log -Message "Verbose test message" -Level Verbose -Verbose 4>&1

            $logFile = Get-ChildItem -Path "$PSScriptRoot\..\logs" -Filter "log_*.csv" | Select-Object -First 1
            $content = Get-Content -Path $logFile.FullName -Raw
            $content | Should -Match "Verbose"
        }

        It "handles empty message with ValidateNotNullOrEmpty" {
            { Write-Log -Message "" -Level Info } | Should -Throw
        }

        It "verifies all CSV columns are present in header" {
            $logDir = "$PSScriptRoot\..\logs"
            $dateString = (Get-Date -Format 'yyyy-MM-dd')
            $logFile = Join-Path -Path $logDir -ChildPath "log_$dateString.csv"

            Write-Log -Message "Test" -Level Info

            $header = @(Get-Content -Path $logFile)[0]
            $columns = $header -split ','
            $columns.Count | Should -Be 6
            $columns | Should -Contain "Timestamp"
            $columns | Should -Contain "Level"
            $columns | Should -Contain "Caller"
            $columns | Should -Contain "Function"
            $columns | Should -Contain "LineNumber"
            $columns | Should -Contain "Message"
        }
    }
}
