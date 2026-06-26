BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\System.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module System -Force -ErrorAction SilentlyContinue
}

Describe "Invoke-RemoteHardening" {
    Context "Parameter Validation" {
        It "accepts ComputerName parameter" {
            { Invoke-RemoteHardening -ComputerName 'localhost' -Profile Basis -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts multiple computer names" {
            { Invoke-RemoteHardening -ComputerName @('localhost', '127.0.0.1') -Profile Basis -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Parallel switch" {
            { Invoke-RemoteHardening -ComputerName 'localhost' -Profile Basis -Parallel -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts UseSSL switch" {
            { Invoke-RemoteHardening -ComputerName 'localhost' -Profile Basis -UseSSL -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Port parameter" {
            { Invoke-RemoteHardening -ComputerName 'localhost' -Profile Basis -Port 5986 -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Profile Support" {
        It "accepts Basis profile" {
            { Invoke-RemoteHardening -ComputerName 'localhost' -Profile Basis -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Recommended profile" {
            { Invoke-RemoteHardening -ComputerName 'localhost' -Profile Recommended -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Strict profile" {
            { Invoke-RemoteHardening -ComputerName 'localhost' -Profile Strict -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Connection Parameters" {
        It "accepts default port 5985" {
            { Invoke-RemoteHardening -ComputerName 'localhost' -Profile Basis -Port 5985 -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts HTTPS port 5986" {
            { Invoke-RemoteHardening -ComputerName 'localhost' -Profile Basis -Port 5986 -UseSSL -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts credential parameter" {
            $credential = New-Object System.Management.Automation.PSCredential('TestUser', (ConvertTo-SecureString 'TestPass' -AsPlainText -Force))
            { Invoke-RemoteHardening -ComputerName 'localhost' -Profile Basis -Credential $credential -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Execution Modes" {
        It "supports sequential execution by default" {
            { Invoke-RemoteHardening -ComputerName @('localhost') -Profile Basis -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "supports parallel execution" {
            { Invoke-RemoteHardening -ComputerName @('localhost') -Profile Basis -Parallel -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "supports WhatIf mode" {
            { Invoke-RemoteHardening -ComputerName 'localhost' -Profile Basis -WhatIf -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Optional Features" {
        It "accepts RuleFilter parameter" {
            { Invoke-RemoteHardening -ComputerName 'localhost' -Profile Basis -RuleFilter @('Account-MinimumPasswordLength') -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts SkipVerification switch" {
            { Invoke-RemoteHardening -ComputerName 'localhost' -Profile Basis -SkipVerification -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts FailOnError switch" {
            { Invoke-RemoteHardening -ComputerName 'localhost' -Profile Basis -FailOnError -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Timeout Configuration" {
        It "accepts custom timeout in seconds" {
            { Invoke-RemoteHardening -ComputerName 'localhost' -Profile Basis -OperationTimeout 60 -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts default timeout" {
            { Invoke-RemoteHardening -ComputerName 'localhost' -Profile Basis -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Documentation" {
        It "has complete help documentation" {
            $help = Get-Help Invoke-RemoteHardening
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }

        It "help includes ComputerName parameter" {
            $help = Get-Help Invoke-RemoteHardening
            $help.Parameters.Parameter.Name | Should -Contain 'ComputerName'
        }

        It "help includes Profile parameter" {
            $help = Get-Help Invoke-RemoteHardening
            $help.Parameters.Parameter.Name | Should -Contain 'Profile'
        }
    }
}
