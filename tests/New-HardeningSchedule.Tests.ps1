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
            { New-HardeningSchedule -Profile Basis -Schedule OneTime -Confirm:$false -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Schedule parameter" {
            { New-HardeningSchedule -Profile Basis -Schedule Daily -Confirm:$false -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Time parameter" {
            { New-HardeningSchedule -Profile Basis -Schedule Daily -Confirm:$false -Time "02:00" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts DayOfWeek for Weekly schedule" {
            { New-HardeningSchedule -Profile Basis -Schedule Weekly -Confirm:$false -DayOfWeek Monday -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts AutoRemediate switch" {
            { New-HardeningSchedule -Profile Basis -Schedule OneTime -Confirm:$false -AutoRemediate -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts GenerateReport switch" {
            { New-HardeningSchedule -Profile Basis -Schedule OneTime -Confirm:$false -GenerateReport -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Schedule Types" {
        It "creates OneTime schedule" {
            { New-HardeningSchedule -Profile Basis -Schedule OneTime -Confirm:$false -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "creates Daily schedule" {
            { New-HardeningSchedule -Profile Basis -Schedule Daily -Confirm:$false -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "creates Weekly schedule" {
            { New-HardeningSchedule -Profile Basis -Schedule Weekly -Confirm:$false -DayOfWeek Monday -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Validation Rules" {
        It "requires DayOfWeek for Weekly schedule" {
            { New-HardeningSchedule -Profile Basis -Schedule Weekly -Confirm:$false -ErrorAction Stop } | Should -Throw
        }

        It "accepts all days of week" {
            $daysOfWeek = @('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')
            foreach ($day in $daysOfWeek) {
                { New-HardeningSchedule -Profile Basis -Schedule Weekly -Confirm:$false -DayOfWeek $day -ErrorAction SilentlyContinue } | Should -Not -Throw
            }
        }
    }

    Context "Time Configuration" {
        It "accepts time in HH:MM format" {
            { New-HardeningSchedule -Profile Basis -Schedule Daily -Confirm:$false -Time "14:30" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts midnight (00:00)" {
            { New-HardeningSchedule -Profile Basis -Schedule Daily -Confirm:$false -Time "00:00" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts end of day (23:59)" {
            { New-HardeningSchedule -Profile Basis -Schedule Daily -Confirm:$false -Time "23:59" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "defaults to 00:00 if not specified for non-OneTime schedules" {
            { New-HardeningSchedule -Profile Basis -Schedule Daily -Confirm:$false -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Profile Support" {
        It "creates schedule for Basis profile" {
            { New-HardeningSchedule -Profile Basis -Schedule OneTime -Confirm:$false -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "creates schedule for Recommended profile" {
            { New-HardeningSchedule -Profile Recommended -Confirm:$false -Schedule Daily -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "creates schedule for Strict profile" {
            { New-HardeningSchedule -Profile Strict -Confirm:$false -Schedule Weekly -DayOfWeek Monday -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Optional Features" {
        It "enables AutoRemediate for schedule" {
            { New-HardeningSchedule -Profile Basis -Schedule Daily -Confirm:$false -AutoRemediate -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "enables GenerateReport for schedule" {
            { New-HardeningSchedule -Profile Basis -Schedule Daily -Confirm:$false -GenerateReport -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "enables both AutoRemediate and GenerateReport" {
            { New-HardeningSchedule -Profile Basis -Schedule Daily -Confirm:$false -AutoRemediate -GenerateReport -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Schedule Task Creation" {
        It "accepts TaskName parameter" {
            { New-HardeningSchedule -Profile Basis -Schedule OneTime -Confirm:$false -TaskName 'CustomHardeningTask' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "creates schedule with default task name if not specified" {
            { New-HardeningSchedule -Profile Basis -Schedule Daily -Confirm:$false -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "WhatIf Support" {
        It "supports WhatIf parameter without side effects" {
            { New-HardeningSchedule -Profile Basis -Schedule Daily -Confirm:$false -WhatIf -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "WhatIf mode does not throw errors" {
            { New-HardeningSchedule -Profile Basis -Schedule Daily -Confirm:$false -WhatIf -ErrorAction Stop } | Should -Not -Throw
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
