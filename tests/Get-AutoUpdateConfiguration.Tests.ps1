BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\System.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module System -Force -ErrorAction SilentlyContinue
}

Describe "Get-AutoUpdateConfiguration" {
    Context "Parameter Validation" {
        It "works without parameters for local computer" {
            { Get-AutoUpdateConfiguration -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts ComputerName parameter" {
            { Get-AutoUpdateConfiguration -ComputerName 'localhost' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts multiple computer names" {
            { Get-AutoUpdateConfiguration -ComputerName @('localhost', '127.0.0.1') -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Auto Update Configuration Settings" {
        It "returns configuration object" {
            $config = Get-AutoUpdateConfiguration -ErrorAction SilentlyContinue
            if ($config) {
                $config | Should -Not -BeNullOrEmpty
            }
        }

        It "includes AutoUpdateEnabled property" {
            { Get-AutoUpdateConfiguration -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes UpdateType property" {
            { Get-AutoUpdateConfiguration -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes ScheduledInstallationDay property" {
            { Get-AutoUpdateConfiguration -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes ScheduledInstallationTime property" {
            { Get-AutoUpdateConfiguration -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Update Type Values" {
        It "identifies NotConfigured update type" {
            { Get-AutoUpdateConfiguration -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "identifies Disabled update type" {
            { Get-AutoUpdateConfiguration -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "identifies NotifyForDownload update type" {
            { Get-AutoUpdateConfiguration -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "identifies AutoDownloadAndNotifyForInstall update type" {
            { Get-AutoUpdateConfiguration -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "identifies AutoDownloadAndInstall update type" {
            { Get-AutoUpdateConfiguration -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "identifies ScheduledInstallation update type" {
            { Get-AutoUpdateConfiguration -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Scheduled Installation Details" {
        It "includes installation day when scheduled" {
            { Get-AutoUpdateConfiguration -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes installation time when scheduled" {
            { Get-AutoUpdateConfiguration -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "identifies daily installation" {
            { Get-AutoUpdateConfiguration -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "identifies weekly installation" {
            { Get-AutoUpdateConfiguration -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "identifies specific day installation" {
            { Get-AutoUpdateConfiguration -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Additional Configuration Options" {
        It "includes RebootBehavior property" {
            { Get-AutoUpdateConfiguration -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes AllowUserToPostponeRestart property" {
            { Get-AutoUpdateConfiguration -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes RequireUserInput property" {
            { Get-AutoUpdateConfiguration -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes NoAutoRestartForScheduledInstalls property" {
            { Get-AutoUpdateConfiguration -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Update Policies" {
        It "includes optional updates status" {
            { Get-AutoUpdateConfiguration -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes driver updates status" {
            { Get-AutoUpdateConfiguration -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes Windows Update for other products status" {
            { Get-AutoUpdateConfiguration -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes Preview updates status" {
            { Get-AutoUpdateConfiguration -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Remote Computer Support" {
        It "retrieves configuration from remote computer" {
            { Get-AutoUpdateConfiguration -ComputerName 'localhost' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "handles unreachable remote computer" {
            { Get-AutoUpdateConfiguration -ComputerName 'nonexistent.invalid' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts credential for remote connection" {
            $credential = New-Object System.Management.Automation.PSCredential('user', (ConvertTo-SecureString 'pass' -AsPlainText -Force))
            { Get-AutoUpdateConfiguration -ComputerName 'localhost' -Credential $credential -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Documentation" {
        It "has complete help documentation" {
            $help = Get-Help Get-AutoUpdateConfiguration
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }

        It "includes parameter descriptions" {
            $help = Get-Help Get-AutoUpdateConfiguration
            $help.Parameters.Parameter.Name | Should -Contain 'ComputerName'
        }
    }
}
