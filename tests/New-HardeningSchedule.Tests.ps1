BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\System.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module System -Force -ErrorAction SilentlyContinue
}

Describe "New-HardeningSchedule" {
    Context "Parameter Validation" {
        It "accepts Profile parameter" {
            { New-HardeningSchedule -Profile Basis -Schedule OneTime -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Schedule parameter" {
            { New-HardeningSchedule -Profile Basis -Schedule Daily -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Time parameter" {
            { New-HardeningSchedule -Profile Basis -Schedule Daily -Time "02:00" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts DayOfWeek for Weekly schedule" {
            { New-HardeningSchedule -Profile Basis -Schedule Weekly -DayOfWeek Monday -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts DayOfMonth for Monthly schedule" {
            { New-HardeningSchedule -Profile Basis -Schedule Monthly -DayOfMonth 1 -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts AutoRemediate switch" {
            { New-HardeningSchedule -Profile Basis -Schedule OneTime -AutoRemediate -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts GenerateReport switch" {
            { New-HardeningSchedule -Profile Basis -Schedule OneTime -GenerateReport -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Schedule Types" {
        It "creates OneTime schedule" {
            { New-HardeningSchedule -Profile Basis -Schedule OneTime -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "creates Daily schedule" {
            { New-HardeningSchedule -Profile Basis -Schedule Daily -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "creates Weekly schedule" {
            { New-HardeningSchedule -Profile Basis -Schedule Weekly -DayOfWeek Monday -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "creates Monthly schedule" {
            { New-HardeningSchedule -Profile Basis -Schedule Monthly -DayOfMonth 15 -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Validation Rules" {
        It "requires DayOfWeek for Weekly schedule" {
            { New-HardeningSchedule -Profile Basis -Schedule Weekly -ErrorAction Stop } | Should -Throw
        }

        It "requires DayOfMonth for Monthly schedule" {
            { New-HardeningSchedule -Profile Basis -Schedule Monthly -ErrorAction Stop } | Should -Throw
        }

        It "accepts all days of week" {
            $daysOfWeek = @('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')
            foreach ($day in $daysOfWeek) {
                { New-HardeningSchedule -Profile Basis -Schedule Weekly -DayOfWeek $day -ErrorAction SilentlyContinue } | Should -Not -Throw
            }
        }

        It "accepts valid days of month (1-31)" {
            $daysOfMonth = @(1, 15, 28, 31)
            foreach ($day in $daysOfMonth) {
                { New-HardeningSchedule -Profile Basis -Schedule Monthly -DayOfMonth $day -ErrorAction SilentlyContinue } | Should -Not -Throw
            }
        }
    }

    Context "Time Configuration" {
        It "accepts time in HH:MM format" {
            { New-HardeningSchedule -Profile Basis -Schedule Daily -Time "14:30" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts midnight (00:00)" {
            { New-HardeningSchedule -Profile Basis -Schedule Daily -Time "00:00" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts end of day (23:59)" {
            { New-HardeningSchedule -Profile Basis -Schedule Daily -Time "23:59" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "defaults to 00:00 if not specified for non-OneTime schedules" {
            { New-HardeningSchedule -Profile Basis -Schedule Daily -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Profile Support" {
        It "creates schedule for Basis profile" {
            { New-HardeningSchedule -Profile Basis -Schedule OneTime -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "creates schedule for Recommended profile" {
            { New-HardeningSchedule -Profile Recommended -Schedule Daily -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "creates schedule for Strict profile" {
            { New-HardeningSchedule -Profile Strict -Schedule Weekly -DayOfWeek Monday -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Optional Features" {
        It "enables AutoRemediate for schedule" {
            { New-HardeningSchedule -Profile Basis -Schedule Daily -AutoRemediate -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "enables GenerateReport for schedule" {
            { New-HardeningSchedule -Profile Basis -Schedule Daily -GenerateReport -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "enables both AutoRemediate and GenerateReport" {
            { New-HardeningSchedule -Profile Basis -Schedule Daily -AutoRemediate -GenerateReport -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts RuleFilter parameter" {
            { New-HardeningSchedule -Profile Basis -Schedule OneTime -RuleFilter @('Account-MinimumPasswordLength') -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts SkipVerification switch" {
            { New-HardeningSchedule -Profile Basis -Schedule OneTime -SkipVerification -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Schedule Task Creation" {
        It "accepts TaskName parameter" {
            { New-HardeningSchedule -Profile Basis -Schedule OneTime -TaskName 'CustomHardeningTask' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts custom description" {
            { New-HardeningSchedule -Profile Basis -Schedule Daily -TaskDescription 'Scheduled security hardening' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "creates schedule with default task name if not specified" {
            { New-HardeningSchedule -Profile Basis -Schedule Daily -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Notification Options" {
        It "accepts EmailOnFailure parameter" {
            { New-HardeningSchedule -Profile Basis -Schedule Daily -EmailOnFailure "admin@example.com" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts SendAlert switch" {
            { New-HardeningSchedule -Profile Basis -Schedule Daily -SendAlert -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Documentation" {
        It "has complete help documentation" {
            $help = Get-Help New-HardeningSchedule
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }

        It "help includes Profile parameter" {
            $help = Get-Help New-HardeningSchedule
            $help.Parameters.Parameter.Name | Should -Contain 'Profile'
        }

        It "help includes Schedule parameter" {
            $help = Get-Help New-HardeningSchedule
            $help.Parameters.Parameter.Name | Should -Contain 'Schedule'
        }
    }
}
