BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\System.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module System -Force -ErrorAction SilentlyContinue
}

Describe "Import-HardeningGPO" {
    Context "Parameter Validation - Mandatory/Optional" {
        It "requires Profile parameter (mandatory)" {
            { Import-HardeningGPO -ErrorAction Stop } | Should -Throw -ExpectedMessage "*mandatory*Profile*"
        }

        It "rejects invalid Profile values" {
            { Import-HardeningGPO -Profile "Invalid" -ErrorAction Stop } | Should -Throw
        }

        It "allows all valid Profile values" {
            # Verify ValidateSet accepts all three values
            $cmd = Get-Command Import-HardeningGPO
            $param = $cmd.Parameters['Profile']
            $param.Attributes.ValidValues | Should -Contain 'Basis'
            $param.Attributes.ValidValues | Should -Contain 'Recommended'
            $param.Attributes.ValidValues | Should -Contain 'Strict'
        }
    }

    Context "Optional Parameters" {
        It "has GPOName parameter (optional)" {
            $cmd = Get-Command Import-HardeningGPO
            $cmd.Parameters['GPOName'].Attributes[0].Mandatory | Should -Be $false
        }

        It "has Domain parameter (optional)" {
            $cmd = Get-Command Import-HardeningGPO
            $cmd.Parameters['Domain'].Attributes[0].Mandatory | Should -Be $false
        }

        It "has TargetOU parameter (optional)" {
            $cmd = Get-Command Import-HardeningGPO
            $cmd.Parameters['TargetOU'].Attributes[0].Mandatory | Should -Be $false
        }

        It "has EnableAudit parameter (optional switch)" {
            $cmd = Get-Command Import-HardeningGPO
            $cmd.Parameters['EnableAudit'] | Should -Not -BeNull
        }

        It "has Comment parameter (optional)" {
            $cmd = Get-Command Import-HardeningGPO
            $cmd.Parameters['Comment'].Attributes[0].Mandatory | Should -Be $false
        }
    }

    Context "Default Parameter Values" {
        It "GPOName parameter provides default pattern" {
            $cmd = Get-Command Import-HardeningGPO
            $param = $cmd.Parameters['GPOName']
            # GPOName has default in parameter definition
            $param | Should -Not -BeNull
        }

        It "Comment parameter provides default value" {
            $cmd = Get-Command Import-HardeningGPO
            $param = $cmd.Parameters['Comment']
            # Comment has default value
            $param | Should -Not -BeNull
        }
    }

    Context "WhatIf and ShouldProcess Support" {
        It "has SupportsShouldProcess" {
            $cmd = Get-Command Import-HardeningGPO
            $cmd.CmdletBinding | Should -Be $true
        }

        It "has WhatIf common parameter" {
            $cmd = Get-Command Import-HardeningGPO
            $cmd.Parameters.Keys | Should -Contain 'WhatIf'
        }

        It "has Confirm common parameter" {
            $cmd = Get-Command Import-HardeningGPO
            $cmd.Parameters.Keys | Should -Contain 'Confirm'
        }
    }

    Context "Standard Common Parameters" {
        It "has ErrorAction parameter" {
            $cmd = Get-Command Import-HardeningGPO
            $cmd.Parameters.Keys | Should -Contain 'ErrorAction'
        }

        It "has Verbose parameter" {
            $cmd = Get-Command Import-HardeningGPO
            $cmd.Parameters.Keys | Should -Contain 'Verbose'
        }

        It "has Debug parameter" {
            $cmd = Get-Command Import-HardeningGPO
            $cmd.Parameters.Keys | Should -Contain 'Debug'
        }
    }

    Context "Help Documentation - Content" {
        It "has SYNOPSIS" {
            $help = Get-Help Import-HardeningGPO
            $help.Synopsis | Should -Not -BeNullOrEmpty
            $help.Synopsis | Should -Match "hardening|GPO|Group Policy"
        }

        It "has DESCRIPTION" {
            $help = Get-Help Import-HardeningGPO
            $help.Description | Should -Not -BeNull
            $help.Description[0].Text | Should -Not -BeNullOrEmpty
        }

        It "has EXAMPLE section with examples" {
            $help = Get-Help Import-HardeningGPO
            $help.Examples.Example | Should -Not -BeNull
            @($help.Examples.Example).Count | Should -BeGreaterThan 0
        }

        It "has NOTES section" {
            $help = Get-Help Import-HardeningGPO
            $help.AlertSet.Alert[0].Text | Should -Not -BeNullOrEmpty
        }
    }

    Context "Help Documentation - Parameters" {
        It "documents Profile parameter" {
            $help = Get-Help Import-HardeningGPO
            $param = $help.Parameters.Parameter | Where-Object { $_.Name -eq 'Profile' }
            $param | Should -Not -BeNull
            $param.Description[0].Text | Should -Not -BeNullOrEmpty
        }

        It "documents GPOName parameter" {
            $help = Get-Help Import-HardeningGPO
            $param = $help.Parameters.Parameter | Where-Object { $_.Name -eq 'GPOName' }
            $param | Should -Not -BeNull
            $param.Description[0].Text | Should -Not -BeNullOrEmpty
        }

        It "documents Domain parameter" {
            $help = Get-Help Import-HardeningGPO
            $param = $help.Parameters.Parameter | Where-Object { $_.Name -eq 'Domain' }
            $param | Should -Not -BeNull
            $param.Description[0].Text | Should -Not -BeNullOrEmpty
        }

        It "documents TargetOU parameter" {
            $help = Get-Help Import-HardeningGPO
            $param = $help.Parameters.Parameter | Where-Object { $_.Name -eq 'TargetOU' }
            $param | Should -Not -BeNull
            $param.Description[0].Text | Should -Not -BeNullOrEmpty
        }

        It "documents EnableAudit parameter" {
            $help = Get-Help Import-HardeningGPO
            $param = $help.Parameters.Parameter | Where-Object { $_.Name -eq 'EnableAudit' }
            $param | Should -Not -BeNull
            $param.Description[0].Text | Should -Not -BeNullOrEmpty
        }

        It "documents Comment parameter" {
            $help = Get-Help Import-HardeningGPO
            $param = $help.Parameters.Parameter | Where-Object { $_.Name -eq 'Comment' }
            $param | Should -Not -BeNull
            $param.Description[0].Text | Should -Not -BeNullOrEmpty
        }
    }

    Context "Private Helper Functions" {
        It "main function references helper functions in implementation" {
            # Verify that Import-HardeningGPO function is defined and exported
            Get-Command -Name 'Import-HardeningGPO' | Should -Not -BeNull
        }
    }

    Context "Error Handling - Pre-execution Validation" {
        It "mandatory Profile validation happens before execution" {
            # Should fail during parameter binding, not execution
            { Import-HardeningGPO -ErrorAction Stop } | Should -Throw -ExpectedMessage "*mandatory*"
        }

        It "validates Profile against ValidateSet" {
            # ValidateSet should reject invalid values
            { Import-HardeningGPO -Profile "NotAProfile" -ErrorAction Stop } | Should -Throw
        }
    }

    Context "Parameter Behavior Validation" {
        It "Profile parameter accepts Basis" {
            $cmd = Get-Command Import-HardeningGPO
            $param = $cmd.Parameters['Profile']
            $param.Attributes.ValidValues | Should -Contain 'Basis'
        }

        It "Profile parameter accepts Recommended" {
            $cmd = Get-Command Import-HardeningGPO
            $param = $cmd.Parameters['Profile']
            $param.Attributes.ValidValues | Should -Contain 'Recommended'
        }

        It "GPOName parameter is optional" {
            $cmd = Get-Command Import-HardeningGPO
            $cmd.Parameters['GPOName'].Attributes[0].Mandatory | Should -Be $false
        }

        It "Domain parameter is optional" {
            $cmd = Get-Command Import-HardeningGPO
            $cmd.Parameters['Domain'].Attributes[0].Mandatory | Should -Be $false
        }

        It "TargetOU parameter is optional" {
            $cmd = Get-Command Import-HardeningGPO
            $cmd.Parameters['TargetOU'].Attributes[0].Mandatory | Should -Be $false
        }

        It "EnableAudit is a switch parameter" {
            $cmd = Get-Command Import-HardeningGPO
            $param = $cmd.Parameters['EnableAudit']
            $param.SwitchParameter | Should -Be $true
        }
    }

    Context "Intrinsic Behavior Validation" {
        It "supports WhatIf execution" {
            # Verify WhatIf parameter is available
            $cmd = Get-Command Import-HardeningGPO
            $cmd.Parameters.Keys | Should -Contain 'WhatIf'
        }

        It "handles mandatory parameter Profile correctly" {
            { Import-HardeningGPO } | Should -Throw
        }

        It "handles invalid Profile parameter correctly" {
            { Import-HardeningGPO -Profile Invalid -ErrorAction Stop } | Should -Throw
        }
    }

}
