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

Describe "Get-SecurityEvents" {
    Context "When querying security events successfully" {
        It "returns events from the last 24 hours by default" {
            $mockEvents = @(
                [PSCustomObject]@{ TimeCreated = (Get-Date).AddHours(-2); Message = "Event 1"; Id = 4648 }
                [PSCustomObject]@{ TimeCreated = (Get-Date).AddHours(-5); Message = "Event 2"; Id = 4649 }
            )

            Mock Get-WinEvent { return $mockEvents } -ParameterFilter {
                $FilterHashtable.LogName -eq "Security" -and
                $FilterHashtable.Keys -contains "StartTime" -and
                $MaxEvents -eq 100
            }

            Mock Write-Log { }

            $result = Get-SecurityEvents

            $result | Should -HaveCount 2
            $result[0].TimeCreated | Should -BeGreaterThan $result[1].TimeCreated
            Assert-MockCalled Get-WinEvent -Times 1
            Assert-MockCalled Write-Log -Times 1
        }

        It "returns events from the specified hours" {
            $mockEvents = @(
                [PSCustomObject]@{ TimeCreated = (Get-Date).AddHours(-1); Message = "Event 1"; Id = 4648 }
            )

            Mock Get-WinEvent { return $mockEvents } -ParameterFilter {
                $FilterHashtable.LogName -eq "Security"
            }

            Mock Write-Log { }

            $result = Get-SecurityEvents -Hours 1

            $result | Should -HaveCount 1
            Assert-MockCalled Get-WinEvent -Times 1
        }

        It "returns empty array when no events found" {
            Mock Get-WinEvent { return @() } -ParameterFilter {
                $FilterHashtable.LogName -eq "Security"
            }

            Mock Write-Log { }

            $result = Get-SecurityEvents -Hours 24

            $result | Should -HaveCount 0
            Assert-MockCalled Write-Log -Times 1
        }

        It "logs success message with event count" {
            $mockEvents = @(
                [PSCustomObject]@{ TimeCreated = (Get-Date); Message = "Event 1"; Id = 4648 }
                [PSCustomObject]@{ TimeCreated = (Get-Date).AddHours(-1); Message = "Event 2"; Id = 4649 }
            )

            Mock Get-WinEvent { return $mockEvents }
            Mock Write-Log { }

            Get-SecurityEvents -Hours 12

            Assert-MockCalled Write-Log -ParameterFilter {
                $Message -match "Retrieved 2 security events" -and
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

            # Suppress the actual error output
            Get-SecurityEvents -ErrorAction SilentlyContinue

            Assert-MockCalled Write-Log -ParameterFilter {
                $Message -match "Failed to query Security event log" -and
                $Level -eq "Error"
            } -Times 1

            Assert-MockCalled Write-Error -Times 1
        }

        It "handles network timeout and logs error" {
            Mock Get-WinEvent {
                throw [System.Net.NetworkInformationException]"Timeout"
            }

            Mock Write-Log { }
            Mock Write-Error { }

            Get-SecurityEvents -Hours 6 -ErrorAction SilentlyContinue

            Assert-MockCalled Write-Log -ParameterFilter {
                $Level -eq "Error"
            } -Times 1
        }
    }

    Context "When using WhatIf parameter" {
        It "does not query events in WhatIf mode" {
            Mock Get-WinEvent { }
            Mock Write-Log { }

            Get-SecurityEvents -WhatIf

            Assert-MockCalled Get-WinEvent -Times 0
        }

        It "respects WhatIf and does not execute Get-WinEvent" {
            Mock Get-WinEvent { }
            Mock Write-Log { }

            Get-SecurityEvents -WhatIf

            # Verify Get-WinEvent was not called
            Assert-MockCalled Get-WinEvent -Times 0
        }
    }

    Context "Parameter validation" {
        It "accepts Hours as positive integer" {
            Mock Get-WinEvent { return @() }
            Mock Write-Log { }

            { Get-SecurityEvents -Hours 72 } | Should -Not -Throw

            Assert-MockCalled Get-WinEvent -Times 1
        }

        It "works with Hours = 1" {
            Mock Get-WinEvent { return @() }
            Mock Write-Log { }

            { Get-SecurityEvents -Hours 1 } | Should -Not -Throw

            Assert-MockCalled Get-WinEvent -Times 1
        }
    }

    Context "Output sorting" {
        It "sorts events by TimeCreated in descending order" {
            $mockEvents = @(
                [PSCustomObject]@{ TimeCreated = (Get-Date).AddHours(-10); Message = "Oldest"; Id = 4648 }
                [PSCustomObject]@{ TimeCreated = (Get-Date).AddHours(-2); Message = "Newest"; Id = 4649 }
                [PSCustomObject]@{ TimeCreated = (Get-Date).AddHours(-5); Message = "Middle"; Id = 4650 }
            )

            Mock Get-WinEvent { return $mockEvents }
            Mock Write-Log { }

            $result = Get-SecurityEvents

            $result[0].Message | Should -Be "Newest"
            $result[1].Message | Should -Be "Middle"
            $result[2].Message | Should -Be "Oldest"
        }
    }
}
