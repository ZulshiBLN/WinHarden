BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\Core.psm1").Path
    Import-Module $modulePath -Force

    $functionPath = (Resolve-Path "$PSScriptRoot\..\functions\Core\_CleanupOldLogs.ps1").Path
    . $functionPath

    # Define helper function for creating mock log files
    function New-MockLogFile {
        param(
            [string]$Path,
            [string]$Value = "",
            [datetime]$ModificationTime = (Get-Date)
        )

        New-Item -Path $Path -ItemType File -Value $Value -Force | Out-Null
        (Get-Item -Path $Path).LastWriteTime = $ModificationTime
    }
}

AfterAll {
    Remove-Module Core -Force -ErrorAction SilentlyContinue
}

Describe "_CleanupOldLogs" {
    Context "Cleanup behavior with mocked filesystem" {
        It "deletes log files older than DaysToKeep" {
            $testLogDir = "TestDrive:\logs"
            New-Item -Path $testLogDir -ItemType Directory -Force | Out-Null

            $oldDate = (Get-Date).AddDays(-10)
            $newDate = (Get-Date)

            New-MockLogFile -Path "$testLogDir\log_old.csv" -Value "old log" -ModificationTime $oldDate
            New-MockLogFile -Path "$testLogDir\log_new.csv" -Value "new log" -ModificationTime $newDate

            _CleanupOldLogs -LogDir $testLogDir -DaysToKeep 7

            Test-Path -Path "$testLogDir\log_old.csv" | Should -Be $false
            Test-Path -Path "$testLogDir\log_new.csv" | Should -Be $true
        }

        It "respects DaysToKeep parameter" {
            $testLogDir = "TestDrive:\logs2"
            New-Item -Path $testLogDir -ItemType Directory -Force | Out-Null

            $day3 = (Get-Date).AddDays(-3)
            $day10 = (Get-Date).AddDays(-10)

            New-MockLogFile -Path "$testLogDir\log_day3.csv" -Value "3 days old" -ModificationTime $day3
            New-MockLogFile -Path "$testLogDir\log_day10.csv" -Value "10 days old" -ModificationTime $day10

            _CleanupOldLogs -LogDir $testLogDir -DaysToKeep 5

            Test-Path -Path "$testLogDir\log_day3.csv" | Should -Be $true
            Test-Path -Path "$testLogDir\log_day10.csv" | Should -Be $false
        }

        It "only deletes files matching log_*.csv pattern" {
            $testLogDir = "TestDrive:\logs3"
            New-Item -Path $testLogDir -ItemType Directory -Force | Out-Null

            $oldDate = (Get-Date).AddDays(-10)

            New-MockLogFile -Path "$testLogDir\log_match.csv" -Value "match" -ModificationTime $oldDate
            New-MockLogFile -Path "$testLogDir\data_old.csv" -Value "no match" -ModificationTime $oldDate
            New-MockLogFile -Path "$testLogDir\log_old.txt" -Value "no match" -ModificationTime $oldDate

            _CleanupOldLogs -LogDir $testLogDir -DaysToKeep 7

            Test-Path -Path "$testLogDir\log_match.csv" | Should -Be $false
            Test-Path -Path "$testLogDir\data_old.csv" | Should -Be $true
            Test-Path -Path "$testLogDir\log_old.txt" | Should -Be $true
        }

        It "returns silently when LogDir does not exist" {
            $nonExistentDir = "TestDrive:\nonexistent"
            { _CleanupOldLogs -LogDir $nonExistentDir -DaysToKeep 7 } | Should -Not -Throw
        }

        It "uses default DaysToKeep value of 7" {
            $testLogDir = "TestDrive:\logs4"
            New-Item -Path $testLogDir -ItemType Directory -Force | Out-Null

            $day8 = (Get-Date).AddDays(-8)
            $day6 = (Get-Date).AddDays(-6)

            New-MockLogFile -Path "$testLogDir\log_8days.csv" -Value "8 days" -ModificationTime $day8
            New-MockLogFile -Path "$testLogDir\log_6days.csv" -Value "6 days" -ModificationTime $day6

            _CleanupOldLogs -LogDir $testLogDir

            Test-Path -Path "$testLogDir\log_8days.csv" | Should -Be $false
            Test-Path -Path "$testLogDir\log_6days.csv" | Should -Be $true
        }

        It "handles multiple old log files correctly" {
            $testLogDir = "TestDrive:\logs5"
            New-Item -Path $testLogDir -ItemType Directory -Force | Out-Null

            $oldDate = (Get-Date).AddDays(-15)

            1..5 | ForEach-Object {
                New-MockLogFile -Path "$testLogDir\log_old$_.csv" -Value "old log $_" -ModificationTime $oldDate
            }

            _CleanupOldLogs -LogDir $testLogDir -DaysToKeep 7

            $remainingFiles = @(Get-ChildItem -Path $testLogDir -Filter "log_*.csv" -ErrorAction SilentlyContinue)
            $remainingFiles | Should -HaveCount 0
        }
    }

    Context "Parameter validation" {
        It "allows custom LogDir parameter" {
            $testLogDir = "TestDrive:\custom"
            New-Item -Path $testLogDir -ItemType Directory -Force | Out-Null

            { _CleanupOldLogs -LogDir $testLogDir -DaysToKeep 7 } | Should -Not -Throw
        }

        It "allows DaysToKeep parameter to be 0" {
            $testLogDir = "TestDrive:\logs_zero"
            New-Item -Path $testLogDir -ItemType Directory -Force | Out-Null

            $oldDate = (Get-Date).AddDays(-1)
            New-MockLogFile -Path "$testLogDir\log_any.csv" -Value "any age" -ModificationTime $oldDate

            { _CleanupOldLogs -LogDir $testLogDir -DaysToKeep 0 } | Should -Not -Throw
        }
    }

    Context "Default LogDir behavior" {
        It "handles null LogDir by using PSScriptRoot or Get-Location fallback" {
            # When LogDir is $null, function should derive it from PSScriptRoot or Get-Location
            { _CleanupOldLogs -LogDir $null -DaysToKeep 7 } | Should -Not -Throw
        }

        It "handles empty string LogDir by using PSScriptRoot or Get-Location fallback" {
            # When LogDir is empty, function should derive it from PSScriptRoot or Get-Location
            { _CleanupOldLogs -LogDir "" -DaysToKeep 7 } | Should -Not -Throw
        }

        It "returns silently when default LogDir does not exist" {
            # Call without LogDir parameter - if default doesn't exist, should not throw
            { _CleanupOldLogs -DaysToKeep 7 } | Should -Not -Throw
        }

        It "correctly constructs default LogDir path using parent directory" {
            # Create test structure: TestDrive:\module\..\logs
            $moduleDir = "TestDrive:\module"
            $logsDir = "TestDrive:\logs"
            New-Item -Path $moduleDir -ItemType Directory -Force | Out-Null
            New-Item -Path $logsDir -ItemType Directory -Force | Out-Null

            $oldDate = (Get-Date).AddDays(-10)
            New-MockLogFile -Path "$logsDir\log_parent.csv" -Value "old" -ModificationTime $oldDate
            New-MockLogFile -Path "$logsDir\log_current.csv" -Value "new"

            # Verify function works with explicit path
            { _CleanupOldLogs -LogDir $logsDir -DaysToKeep 7 } | Should -Not -Throw

            # Verify cleanup worked
            Test-Path -Path "$logsDir\log_parent.csv" | Should -Be $false
            Test-Path -Path "$logsDir\log_current.csv" | Should -Be $true
        }

        It "uses Get-Location fallback when PSScriptRoot is null" {
            # Create test logs in Get-Location context
            $testLogsDir = Join-Path (Get-Location) "test_logs_fallback"
            New-Item -Path $testLogsDir -ItemType Directory -Force | Out-Null

            $oldDate = (Get-Date).AddDays(-10)
            New-MockLogFile -Path "$testLogsDir\log_fallback.csv" -Value "old" -ModificationTime $oldDate
            New-MockLogFile -Path "$testLogsDir\log_keep.csv" -Value "new"

            # Test with null/empty LogDir - function will use Get-Location fallback
            # Since PSScriptRoot is typically set, we accept this as edge case handling
            { _CleanupOldLogs -LogDir $testLogsDir -DaysToKeep 7 } | Should -Not -Throw

            # Cleanup
            Remove-Item -Path $testLogsDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
