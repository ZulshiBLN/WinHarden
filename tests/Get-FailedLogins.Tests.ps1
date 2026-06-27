BeforeAll {
    $PSScriptRoot | Should -Not -BeNullOrEmpty

    # Load Core module first (required by Monitoring_Functions)
    $corePath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\Core.psm1"
    $corePath | Should -Exist
    Import-Module -Name $corePath -Force -Verbose:$false

    # Load Monitoring Functions script
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\scripts\Monitoring_Functions.ps1"
    $scriptPath | Should -Exist

    . $scriptPath
}

Describe "Get-FailedLogins" {
    Context "When querying failed login events successfully" {
        It "returns failed login events from the last hour by default" {
            $mockEvents = @(
                [PSCustomObject]@{ TimeCreated = (Get-Date).AddMinutes(-15); Message = "Failed login"; Id = 4625 }
                [PSCustomObject]@{ TimeCreated = (Get-Date).AddMinutes(-45); Message = "Failed login"; Id = 4625 }
            )

            Mock Get-WinEvent { return $mockEvents } -ParameterFilter {
                $FilterHashtable.LogName -eq "Security" -and
                $FilterHashtable.ID -eq 4625 -and
                $FilterHashtable.Keys -contains "StartTime"
            }

            Mock Write-Log { }

            $result = Get-FailedLogins

            $result | Should -HaveCount 2
            $result[0].Id | Should -Be 4625
            $result[1].Id | Should -Be 4625
            Assert-MockCalled Get-WinEvent -Times 1
            Assert-MockCalled Write-Log -Times 1
        }

        It "returns failed login events from specified hours" {
            $mockEvents = @(
                [PSCustomObject]@{ TimeCreated = (Get-Date).AddHours(-8); Message = "Failed login"; Id = 4625 }
                [PSCustomObject]@{ TimeCreated = (Get-Date).AddHours(-18); Message = "Failed login"; Id = 4625 }
                [PSCustomObject]@{ TimeCreated = (Get-Date).AddHours(-20); Message = "Failed login"; Id = 4625 }
            )

            Mock Get-WinEvent { return $mockEvents }

            Mock Write-Log { }

            $result = Get-FailedLogins -Hours 24

            $result | Should -HaveCount 3
            Assert-MockCalled Get-WinEvent -Times 1
        }

        It "returns empty array when no failed logins found" {
            Mock Get-WinEvent { return @() } -ParameterFilter {
                $FilterHashtable.ID -eq 4625
            }

            Mock Write-Log { }

            $result = Get-FailedLogins -Hours 1

            $result | Should -HaveCount 0
            Assert-MockCalled Write-Log -Times 1
        }

        It "filters for Event ID 4625 only" {
            $mockEvents = @(
                [PSCustomObject]@{ TimeCreated = (Get-Date); Message = "Failed login"; Id = 4625 }
            )

            Mock Get-WinEvent { return $mockEvents }
            Mock Write-Log { }

            Get-FailedLogins

            Assert-MockCalled Get-WinEvent -ParameterFilter {
                $FilterHashtable.ID -eq 4625
            } -Times 1
        }

        It "logs success message with event count" {
            $mockEvents = @(
                [PSCustomObject]@{ TimeCreated = (Get-Date); Id = 4625 }
                [PSCustomObject]@{ TimeCreated = (Get-Date).AddMinutes(-30); Id = 4625 }
            )

            Mock Get-WinEvent { return $mockEvents }
            Mock Write-Log { }

            Get-FailedLogins -Hours 6

            Assert-MockCalled Write-Log -ParameterFilter {
                $Message -match "Retrieved 2 failed login attempts" -and
                $Level -eq "Info"
            } -Times 1
        }
    }

    Context "When Get-WinEvent fails" {
        It "logs error and writes error message" {
            Mock Get-WinEvent {
                throw [System.UnauthorizedAccessException]"Access Denied"
            }

            Mock Write-Log { }
            Mock Write-Error { }

            Get-FailedLogins -ErrorAction SilentlyContinue

            Assert-MockCalled Write-Log -ParameterFilter {
                $Message -match "Failed to query failed login events" -and
                $Level -eq "Error"
            } -Times 1

            Assert-MockCalled Write-Error -Times 1
        }

        It "handles event log service unavailable and logs error" {
            Mock Get-WinEvent {
                throw [System.InvalidOperationException]"The event log is not available"
            }

            Mock Write-Log { }
            Mock Write-Error { }

            Get-FailedLogins -Hours 12 -ErrorAction SilentlyContinue

            Assert-MockCalled Write-Log -ParameterFilter {
                $Level -eq "Error"
            } -Times 1
        }
    }

    Context "When using WhatIf parameter" {
        It "does not query events in WhatIf mode" {
            Mock Get-WinEvent { }
            Mock Write-Log { }

            Get-FailedLogins -WhatIf

            Assert-MockCalled Get-WinEvent -Times 0
        }

        It "respects WhatIf and does not execute Get-WinEvent" {
            Mock Get-WinEvent { }
            Mock Write-Log { }

            Get-FailedLogins -WhatIf

            # Verify Get-WinEvent was not called
            Assert-MockCalled Get-WinEvent -Times 0
        }
    }

    Context "Parameter validation" {
        It "accepts Hours as positive integer" {
            Mock Get-WinEvent { return @() }
            Mock Write-Log { }

            { Get-FailedLogins -Hours 48 } | Should -Not -Throw

            Assert-MockCalled Get-WinEvent -Times 1
        }

        It "works with Hours = 1" {
            Mock Get-WinEvent { return @() }
            Mock Write-Log { }

            { Get-FailedLogins -Hours 1 } | Should -Not -Throw

            Assert-MockCalled Get-WinEvent -Times 1
        }

        It "default Hours is 1" {
            Mock Get-WinEvent { return @() } -ParameterFilter {
                # Verify the StartTime is approximately 1 hour ago (within 2 minutes tolerance)
                $expectedStartTime = (Get-Date).AddHours(-1)
                $actualStartTime = $FilterHashtable.StartTime
                $timeDiff = [Math]::Abs(($expectedStartTime - $actualStartTime).TotalMinutes)
                $timeDiff -lt 2
            }

            Mock Write-Log { }

            Get-FailedLogins

            Assert-MockCalled Get-WinEvent -Times 1
        }
    }

    Context "Output sorting" {
        It "sorts events by TimeCreated in descending order (most recent first)" {
            $mockEvents = @(
                [PSCustomObject]@{ TimeCreated = (Get-Date).AddMinutes(-50); Message = "Oldest"; Id = 4625 }
                [PSCustomObject]@{ TimeCreated = (Get-Date).AddMinutes(-5); Message = "Newest"; Id = 4625 }
                [PSCustomObject]@{ TimeCreated = (Get-Date).AddMinutes(-25); Message = "Middle"; Id = 4625 }
            )

            Mock Get-WinEvent { return $mockEvents }
            Mock Write-Log { }

            $result = Get-FailedLogins

            $result[0].Message | Should -Be "Newest"
            $result[1].Message | Should -Be "Middle"
            $result[2].Message | Should -Be "Oldest"
        }
    }

    Context "Multiple failed logins detection" {
        It "handles large number of failed login events" {
            $mockEvents = 1..50 | ForEach-Object {
                [PSCustomObject]@{
                    TimeCreated = (Get-Date).AddMinutes(-$_)
                    Message = "Failed login attempt $_"
                    Id = 4625
                }
            }

            Mock Get-WinEvent { return $mockEvents }
            Mock Write-Log { }

            $result = Get-FailedLogins -Hours 2

            $result | Should -HaveCount 50
            Assert-MockCalled Write-Log -ParameterFilter {
                $Message -match "Retrieved 50 failed login attempts"
            } -Times 1
        }
    }
}
