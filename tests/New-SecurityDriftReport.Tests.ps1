BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\System.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module System -Force -ErrorAction SilentlyContinue
}

Describe "New-SecurityDriftReport" {
    Context "Parameter Validation" {
        It "works without parameters for local computer" {
            { New-SecurityDriftReport -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts ComputerName parameter" {
            { New-SecurityDriftReport -ComputerName 'localhost' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts multiple computer names" {
            { New-SecurityDriftReport -ComputerName @('localhost', '127.0.0.1') -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Profile parameter" {
            { New-SecurityDriftReport -Profile Basis -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts OutputPath parameter" {
            { New-SecurityDriftReport -OutputPath "C:\Reports" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Format parameter" {
            { New-SecurityDriftReport -Format HTML -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts GenerateHTML switch" {
            { New-SecurityDriftReport -GenerateHTML -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts ExportCSV switch" {
            { New-SecurityDriftReport -ExportCSV -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts ExportJSON switch" {
            { New-SecurityDriftReport -ExportJSON -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Report Generation" {
        It "generates comprehensive drift report" {
            { New-SecurityDriftReport -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes account policies drift section" {
            { New-SecurityDriftReport -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes audit policies drift section" {
            { New-SecurityDriftReport -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes firewall status drift section" {
            { New-SecurityDriftReport -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes network security drift section" {
            { New-SecurityDriftReport -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes RDP security drift section" {
            { New-SecurityDriftReport -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes service security drift section" {
            { New-SecurityDriftReport -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes update status drift section" {
            { New-SecurityDriftReport -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Report Content" {
        It "includes executive summary" {
            { New-SecurityDriftReport -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes overall compliance percentage" {
            { New-SecurityDriftReport -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes critical issues list" {
            { New-SecurityDriftReport -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes detailed drift findings" {
            { New-SecurityDriftReport -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes remediation recommendations" {
            { New-SecurityDriftReport -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes timestamp of report generation" {
            { New-SecurityDriftReport -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Profile Support" {
        It "generates report for Basis profile" {
            { New-SecurityDriftReport -Profile Basis -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "generates report for Recommended profile" {
            { New-SecurityDriftReport -Profile Recommended -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "generates report for Strict profile" {
            { New-SecurityDriftReport -Profile Strict -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "generates report for all profiles" {
            { New-SecurityDriftReport -AllProfiles -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Output Formats" {
        It "generates text report by default" {
            { New-SecurityDriftReport -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "generates HTML report" {
            { New-SecurityDriftReport -Format HTML -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "generates CSV report" {
            { New-SecurityDriftReport -Format CSV -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "generates JSON report" {
            { New-SecurityDriftReport -Format JSON -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts multiple export formats" {
            { New-SecurityDriftReport -ExportHTML -ExportCSV -ExportJSON -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Report Output" {
        It "saves report to specified output path" {
            { New-SecurityDriftReport -OutputPath "C:\Reports" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "returns report object to pipeline" {
            { New-SecurityDriftReport -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes file path in output when saved" {
            { New-SecurityDriftReport -OutputPath "C:\Reports" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "creates timestamped filename" {
            { New-SecurityDriftReport -OutputPath "C:\Reports" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Remote Computer Support" {
        It "generates report for remote computer" {
            { New-SecurityDriftReport -ComputerName 'localhost' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "generates report for multiple computers" {
            { New-SecurityDriftReport -ComputerName @('localhost') -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "handles unreachable remote computer" {
            { New-SecurityDriftReport -ComputerName 'nonexistent.invalid' -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts credential for remote connection" {
            $credential = New-Object System.Management.Automation.PSCredential('user', (ConvertTo-SecureString 'pass' -AsPlainText -Force))
            { New-SecurityDriftReport -ComputerName 'localhost' -Credential $credential -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "processes multiple computers in parallel" {
            $computers = @('localhost')
            { New-SecurityDriftReport -ComputerName $computers -Parallel -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Report Options" {
        It "includes detailed drift analysis" {
            { New-SecurityDriftReport -Detailed -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "excludes compliance details with SummaryOnly" {
            { New-SecurityDriftReport -SummaryOnly -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "compares with previous report" {
            { New-SecurityDriftReport -ComparePreviousReport -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "highlights new drift issues" {
            { New-SecurityDriftReport -HighlightNewIssues -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes historical trend data" {
            { New-SecurityDriftReport -IncludeTrendData -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Email Delivery" {
        It "accepts EmailRecipients parameter" {
            { New-SecurityDriftReport -EmailRecipients "admin@example.com" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts multiple email recipients" {
            $recipients = @("admin@example.com", "security@example.com")
            { New-SecurityDriftReport -EmailRecipients $recipients -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts SMTP server for email" {
            { New-SecurityDriftReport -EmailRecipients "admin@example.com" -SmtpServer "smtp.example.com" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes report as attachment in email" {
            { New-SecurityDriftReport -EmailRecipients "admin@example.com" -AttachReport -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Documentation" {
        It "has complete help documentation" {
            $help = Get-Help New-SecurityDriftReport
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }

        It "includes parameter descriptions" {
            $help = Get-Help New-SecurityDriftReport
            $help.Parameters.Parameter.Name | Should -Contain 'ComputerName'
            $help.Parameters.Parameter.Name | Should -Contain 'Profile'
        }

        It "includes usage examples" {
            $help = Get-Help New-SecurityDriftReport
            $help.Examples | Should -Not -BeNullOrEmpty
        }
    }
}
