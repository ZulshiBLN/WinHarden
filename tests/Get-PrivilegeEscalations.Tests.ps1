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

Describe "Get-PrivilegeEscalations" {
    Context "When querying privilege escalation events successfully" {
        It "returns privilege escalation events from the last 24 hours by default" {
            $mockEvents = @(
                [PSCustomObject]@{ TimeCreated = (Get-Date).AddHours(-2); Message = "Special Logon"; Id = 4672 }
                [PSCustomObject]@{ TimeCreated = (Get-Date).AddHours(-8); Message = "Sensitive Privilege"; Id = 4673 }
            )

            Mock Get-WinEvent { return $mockEvents } -ParameterFilter {
                $FilterHashtable.LogName -eq "Security" -and
                $FilterHashtable.ID -contains 4672 -and
                $FilterHashtable.ID -contains 4673 -and
                $FilterHashtable.Keys -contains "StartTime"
            }

            Mock Write-Log { }

            $result = Get-PrivilegeEscalations

            $result | Should -HaveCount 2
            $result.Id | Should -Contain 4672
            $result.Id | Should -Contain 4673
            Assert-MockCalled Get-WinEvent -Times 1
            Assert-MockCalled Write-Log -Times 1
        }

        It "returns privilege escalation events from specified hours" {
            $mockEvents = @(
                [PSCustomObject]@{ TimeCreated = (Get-Date).AddHours(-48); Message = "Special Logon"; Id = 4672 }
                [PSCustomObject]@{ TimeCreated = (Get-Date).AddHours(-100); Message = "Sensitive Privilege"; Id = 4673 }
            )

            Mock Get-WinEvent { return $mockEvents }

            Mock Write-Log { }

            $result = Get-PrivilegeEscalations -Hours 168

            $result | Should -HaveCount 2
            Assert-MockCalled Get-WinEvent -Times 1
        }

        It "returns empty array when no escalation events found" {
            Mock Get-WinEvent { return @() } -ParameterFilter {
                $FilterHashtable.ID -contains 4672
            }

            Mock Write-Log { }

            $result = Get-PrivilegeEscalations -Hours 24

            $result | Should -HaveCount 0
            Assert-MockCalled Write-Log -Times 1
        }

        It "filters for Event IDs 4672 and 4673" {
            $mockEvents = @(
                [PSCustomObject]@{ TimeCreated = (Get-Date); Id = 4672 }
                [PSCustomObject]@{ TimeCreated = (Get-Date).AddHours(-1); Id = 4673 }
            )

            Mock Get-WinEvent { return $mockEvents }
            Mock Write-Log { }

            Get-PrivilegeEscalations

            Assert-MockCalled Get-WinEvent -ParameterFilter {
                $FilterHashtable.ID -contains 4672 -and
                $FilterHashtable.ID -contains 4673
            } -Times 1
        }

        It "distinguishes between Event ID 4672 (Special Logon)" {
            $mockEvents = @(
                [PSCustomObject]@{ TimeCreated = (Get-Date); Id = 4672; Message = "Special Logon" }
            )

            Mock Get-WinEvent { return $mockEvents }
            Mock Write-Log { }

            $result = Get-PrivilegeEscalations

            $result.Id | Should -Be 4672
            $result.Message | Should -Be "Special Logon"
        }

        It "distinguishes between Event ID 4673 (Sensitive Privilege Use)" {
            $mockEvents = @(
                [PSCustomObject]@{ TimeCreated = (Get-Date); Id = 4673; Message = "Sensitive Privilege" }
            )

            Mock Get-WinEvent { return $mockEvents }
            Mock Write-Log { }

            $result = Get-PrivilegeEscalations

            $result.Id | Should -Be 4673
            $result.Message | Should -Be "Sensitive Privilege"
        }

        It "logs success message with event count" {
            $mockEvents = @(
                [PSCustomObject]@{ TimeCreated = (Get-Date); Id = 4672 }
                [PSCustomObject]@{ TimeCreated = (Get-Date).AddHours(-6); Id = 4673 }
                [PSCustomObject]@{ TimeCreated = (Get-Date).AddHours(-12); Id = 4672 }
            )

            Mock Get-WinEvent { return $mockEvents }
            Mock Write-Log { }

            Get-PrivilegeEscalations -Hours 48

            Assert-MockCalled Write-Log -ParameterFilter {
                $Message -match "Retrieved 3 privilege escalation events" -and
                $Level -eq "Info"
            } -Times 1
        }
    }

    Context "When Get-WinEvent fails" {
        It "logs error and writes error message on access denied" {
            Mock Get-WinEvent {
                throw [System.UnauthorizedAccessException]"Access Denied to Security log"
            }

            Mock Write-Log { }
            Mock Write-Error { }

            Get-PrivilegeEscalations -ErrorAction SilentlyContinue

            Assert-MockCalled Write-Log -ParameterFilter {
                $Message -match "Failed to query privilege escalation events" -and
                $Level -eq "Error"
            } -Times 1

            Assert-MockCalled Write-Error -Times 1
        }

        It "handles corrupted event log and logs error" {
            Mock Get-WinEvent {
                throw [System.InvalidOperationException]"Event log corrupted"
            }

            Mock Write-Log { }
            Mock Write-Error { }

            Get-PrivilegeEscalations -Hours 72 -ErrorAction SilentlyContinue

            Assert-MockCalled Write-Log -ParameterFilter {
                $Level -eq "Error"
            } -Times 1
        }
    }

    Context "When using WhatIf parameter" {
        It "does not query events in WhatIf mode" {
            Mock Get-WinEvent { }
            Mock Write-Log { }

            Get-PrivilegeEscalations -WhatIf

            Assert-MockCalled Get-WinEvent -Times 0
        }

        It "respects WhatIf and does not execute Get-WinEvent" {
            Mock Get-WinEvent { }
            Mock Write-Log { }

            Get-PrivilegeEscalations -WhatIf

            # Verify Get-WinEvent was not called
            Assert-MockCalled Get-WinEvent -Times 0
        }
    }

    Context "Parameter validation" {
        It "accepts Hours as positive integer" {
            Mock Get-WinEvent { return @() }
            Mock Write-Log { }

            { Get-PrivilegeEscalations -Hours 168 } | Should -Not -Throw

            Assert-MockCalled Get-WinEvent -Times 1
        }

        It "works with Hours = 24" {
            Mock Get-WinEvent { return @() }
            Mock Write-Log { }

            { Get-PrivilegeEscalations -Hours 24 } | Should -Not -Throw

            Assert-MockCalled Get-WinEvent -Times 1
        }

        It "default Hours is 24" {
            Mock Get-WinEvent { return @() } -ParameterFilter {
                # Verify the StartTime is approximately 24 hours ago (within 2 minutes tolerance)
                $expectedStartTime = (Get-Date).AddHours(-24)
                $actualStartTime = $FilterHashtable.StartTime
                $timeDiff = [Math]::Abs(($expectedStartTime - $actualStartTime).TotalMinutes)
                $timeDiff -lt 2
            }

            Mock Write-Log { }

            Get-PrivilegeEscalations

            Assert-MockCalled Get-WinEvent -Times 1
        }
    }

    Context "Output sorting" {
        It "sorts events by TimeCreated in descending order (most recent first)" {
            $mockEvents = @(
                [PSCustomObject]@{ TimeCreated = (Get-Date).AddHours(-20); Message = "Oldest"; Id = 4672 }
                [PSCustomObject]@{ TimeCreated = (Get-Date).AddHours(-1); Message = "Newest"; Id = 4673 }
                [PSCustomObject]@{ TimeCreated = (Get-Date).AddHours(-10); Message = "Middle"; Id = 4672 }
            )

            Mock Get-WinEvent { return $mockEvents }
            Mock Write-Log { }

            $result = Get-PrivilegeEscalations

            $result[0].Message | Should -Be "Newest"
            $result[1].Message | Should -Be "Middle"
            $result[2].Message | Should -Be "Oldest"
        }
    }

    Context "Security monitoring scenarios" {
        It "detects sustained privilege escalation attempts" {
            $mockEvents = 1..10 | ForEach-Object {
                [PSCustomObject]@{
                    TimeCreated = (Get-Date).AddMinutes(-$_)
                    Message = "Privilege escalation attempt $_"
                    Id = 4672
                }
            }

            Mock Get-WinEvent { return $mockEvents }
            Mock Write-Log { }

            $result = Get-PrivilegeEscalations -Hours 1

            $result | Should -HaveCount 10
            @($result.Id).ForEach({ $_ | Should -Be 4672 })
            Assert-MockCalled Write-Log -ParameterFilter {
                $Message -match "Retrieved 10 privilege escalation events"
            } -Times 1
        }

        It "mixes Event ID 4672 and 4673 in results" {
            $mockEvents = @(
                [PSCustomObject]@{ TimeCreated = (Get-Date); Id = 4672 }
                [PSCustomObject]@{ TimeCreated = (Get-Date).AddMinutes(-5); Id = 4673 }
                [PSCustomObject]@{ TimeCreated = (Get-Date).AddMinutes(-10); Id = 4672 }
                [PSCustomObject]@{ TimeCreated = (Get-Date).AddMinutes(-15); Id = 4673 }
            )

            Mock Get-WinEvent { return $mockEvents }
            Mock Write-Log { }

            $result = Get-PrivilegeEscalations

            @($result.Id).Where({ $_ -eq 4672 }) | Should -HaveCount 2
            @($result.Id).Where({ $_ -eq 4673 }) | Should -HaveCount 2
        }
    }
}
