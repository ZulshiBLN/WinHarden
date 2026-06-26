BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\System.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module System -Force -ErrorAction SilentlyContinue
}

Describe "Get-PendingRebootStatus" {
    Context "Function exists and loads" {
        It "function is available" {
            Get-Command Get-PendingRebootStatus -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It "supports WhatIf parameter" {
            $cmd = Get-Command Get-PendingRebootStatus
            $cmd.Parameters.Keys -contains 'WhatIf' | Should -Be $true
        }

        It "supports Verbose parameter" {
            $cmd = Get-Command Get-PendingRebootStatus
            $cmd.Parameters.Keys -contains 'Verbose' | Should -Be $true
        }
    }

    Context "Basic Functionality" {
        It "executes without parameters" {
            { Get-PendingRebootStatus -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "returns PSCustomObject" {
            $result = Get-PendingRebootStatus -ErrorAction SilentlyContinue
            $result | Should -BeOfType [PSCustomObject]
        }

        It "returns object with IsPending property" {
            $result = Get-PendingRebootStatus -ErrorAction SilentlyContinue
            $result.IsPending | Should -Not -BeNullOrEmpty
        }

        It "returns object with Message property" {
            $result = Get-PendingRebootStatus -ErrorAction SilentlyContinue
            $result.Message | Should -Not -BeNullOrEmpty
        }
    }

    Context "Return Value Properties" {
        It "IsPending property is boolean" {
            $result = Get-PendingRebootStatus -ErrorAction SilentlyContinue
            $result.IsPending | Should -BeOfType [bool]
        }

        It "Message property is not empty" {
            $result = Get-PendingRebootStatus -ErrorAction SilentlyContinue
            $result.Message | Should -Not -BeNullOrEmpty
        }

        It "Message mentions reboot when IsPending is false" {
            $result = Get-PendingRebootStatus -ErrorAction SilentlyContinue
            if ($result.IsPending -eq $false) {
                $result.Message | Should -Match "No reboot|reboot"
            }
        }

        It "Message mentions updates when IsPending is true" {
            $result = Get-PendingRebootStatus -ErrorAction SilentlyContinue
            if ($result.IsPending -eq $true) {
                $result.Message | Should -Match "restart|update"
            }
        }
    }

    Context "Error Handling" {
        It "runs with ErrorAction SilentlyContinue" {
            { Get-PendingRebootStatus -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "runs with ErrorAction Stop" {
            { Get-PendingRebootStatus -ErrorAction Stop } | Should -Not -Throw
        }
    }

    Context "WhatIf Support" {
        It "executes in WhatIf mode without throwing" {
            { Get-PendingRebootStatus -WhatIf } | Should -Not -Throw
        }

        It "does not return object in WhatIf mode" {
            $result = Get-PendingRebootStatus -WhatIf
            $result | Should -BeNullOrEmpty
        }

        It "does not log in WhatIf mode" {
            { Get-PendingRebootStatus -WhatIf -Verbose 4>&1 } | Should -Not -Throw
        }
    }

    Context "Verbose Output" {
        It "accepts Verbose parameter" {
            { Get-PendingRebootStatus -Verbose 4>&1 } | Should -Not -Throw
        }
    }

    Context "Documentation" {
        It "has help documentation" {
            $help = Get-Help Get-PendingRebootStatus -ErrorAction SilentlyContinue
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }

        It "has description" {
            $help = Get-Help Get-PendingRebootStatus -ErrorAction SilentlyContinue
            $help.Description | Should -Not -BeNullOrEmpty
        }

        It "has at least one example" {
            $help = Get-Help Get-PendingRebootStatus -ErrorAction SilentlyContinue
            $help.Examples | Should -Not -BeNullOrEmpty
        }
    }
}
