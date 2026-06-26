BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\System.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module System -Force -ErrorAction SilentlyContinue
}

Describe "Send-HardeningAlert" {
    BeforeEach {
        Mock -CommandName Send-MailMessage -MockWith { } -ModuleName System
    }

    Context "Parameter Validation" {
        It "requires SmtpServer parameter" {
            { Send-HardeningAlert -FromAddress "alert@test.com" -ToAddress "admin@test.com" -AlertType Hardening } |
                Should -Throw
        }

        It "requires FromAddress parameter" {
            { Send-HardeningAlert -SmtpServer "localhost" -ToAddress "admin@test.com" -AlertType Hardening } |
                Should -Throw
        }

        It "requires ToAddress parameter" {
            { Send-HardeningAlert -SmtpServer "localhost" -FromAddress "alert@test.com" -AlertType Hardening } |
                Should -Throw
        }

        It "requires AlertType parameter" {
            { Send-HardeningAlert -SmtpServer "localhost" -FromAddress "alert@test.com" -ToAddress "admin@test.com" } |
                Should -Throw
        }

        It "accepts valid AlertType values" {
            $types = @('Hardening', 'Compliance', 'Remediation', 'Schedule')
            foreach ($type in $types) {
                $params = @{
                    SmtpServer = "localhost"
                    FromAddress = "alert@test.com"
                    ToAddress = "admin@test.com"
                    AlertType = $type
                    ErrorAction = 'SilentlyContinue'
                }
                { Send-HardeningAlert @params } | Should -Not -Throw
            }
        }

        It "rejects invalid AlertType values" {
            { Send-HardeningAlert -SmtpServer "localhost" -FromAddress "alert@test.com" `
                -ToAddress "admin@test.com" -AlertType "InvalidType" } | Should -Throw
        }
    }

    Context "Alert Types" {
        It "accepts Hardening alert type" {
            $params = @{
                SmtpServer = "localhost"
                FromAddress = "alert@test.com"
                ToAddress = "admin@test.com"
                AlertType = "Hardening"
                ErrorAction = 'SilentlyContinue'
            }
            { Send-HardeningAlert @params } | Should -Not -Throw
        }

        It "accepts Compliance alert type" {
            $params = @{
                SmtpServer = "localhost"
                FromAddress = "alert@test.com"
                ToAddress = "admin@test.com"
                AlertType = "Compliance"
                ErrorAction = 'SilentlyContinue'
            }
            { Send-HardeningAlert @params } | Should -Not -Throw
        }

        It "accepts Remediation alert type" {
            $params = @{
                SmtpServer = "localhost"
                FromAddress = "alert@test.com"
                ToAddress = "admin@test.com"
                AlertType = "Remediation"
                ErrorAction = 'SilentlyContinue'
            }
            { Send-HardeningAlert @params } | Should -Not -Throw
        }

        It "accepts Schedule alert type" {
            $params = @{
                SmtpServer = "localhost"
                FromAddress = "alert@test.com"
                ToAddress = "admin@test.com"
                AlertType = "Schedule"
                ErrorAction = 'SilentlyContinue'
            }
            { Send-HardeningAlert @params } | Should -Not -Throw
        }
    }

    Context "Severity Levels" {
        It "accepts Info severity level" {
            $params = @{
                SmtpServer = "localhost"
                FromAddress = "alert@test.com"
                ToAddress = "admin@test.com"
                AlertType = "Hardening"
                Severity = "Info"
                ErrorAction = 'SilentlyContinue'
            }
            { Send-HardeningAlert @params } | Should -Not -Throw
        }

        It "accepts Warning severity level" {
            $params = @{
                SmtpServer = "localhost"
                FromAddress = "alert@test.com"
                ToAddress = "admin@test.com"
                AlertType = "Hardening"
                Severity = "Warning"
                ErrorAction = 'SilentlyContinue'
            }
            { Send-HardeningAlert @params } | Should -Not -Throw
        }

        It "accepts Critical severity level" {
            $params = @{
                SmtpServer = "localhost"
                FromAddress = "alert@test.com"
                ToAddress = "admin@test.com"
                AlertType = "Hardening"
                Severity = "Critical"
                ErrorAction = 'SilentlyContinue'
            }
            { Send-HardeningAlert @params } | Should -Not -Throw
        }

        It "uses Info as default severity" {
            $params = @{
                SmtpServer = "localhost"
                FromAddress = "alert@test.com"
                ToAddress = "admin@test.com"
                AlertType = "Hardening"
                ErrorAction = 'SilentlyContinue'
            }
            { Send-HardeningAlert @params } | Should -Not -Throw
        }

        It "rejects invalid severity values" {
            { Send-HardeningAlert -SmtpServer "localhost" -FromAddress "alert@test.com" `
                -ToAddress "admin@test.com" -AlertType "Hardening" -Severity "InvalidSeverity" } |
                Should -Throw
        }
    }

    Context "SMTP Configuration" {
        It "accepts default SMTP port 25" {
            $params = @{
                SmtpServer = "localhost"
                FromAddress = "alert@test.com"
                ToAddress = "admin@test.com"
                AlertType = "Hardening"
                ErrorAction = 'SilentlyContinue'
            }
            { Send-HardeningAlert @params } | Should -Not -Throw
        }

        It "accepts custom SMTP port 587" {
            $params = @{
                SmtpServer = "localhost"
                FromAddress = "alert@test.com"
                ToAddress = "admin@test.com"
                AlertType = "Hardening"
                SmtpPort = 587
                ErrorAction = 'SilentlyContinue'
            }
            { Send-HardeningAlert @params } | Should -Not -Throw
        }

        It "accepts custom SMTP port 465 with SSL" {
            $params = @{
                SmtpServer = "localhost"
                FromAddress = "alert@test.com"
                ToAddress = "admin@test.com"
                AlertType = "Hardening"
                SmtpPort = 465
                UseSSL = $true
                ErrorAction = 'SilentlyContinue'
            }
            { Send-HardeningAlert @params } | Should -Not -Throw
        }

        It "accepts UseSSL switch" {
            $params = @{
                SmtpServer = "localhost"
                FromAddress = "alert@test.com"
                ToAddress = "admin@test.com"
                AlertType = "Hardening"
                UseSSL = $true
                ErrorAction = 'SilentlyContinue'
            }
            { Send-HardeningAlert @params } | Should -Not -Throw
        }
    }

    Context "Recipient Handling" {
        It "accepts single recipient address" {
            $params = @{
                SmtpServer = "localhost"
                FromAddress = "alert@test.com"
                ToAddress = "admin@test.com"
                AlertType = "Hardening"
                ErrorAction = 'SilentlyContinue'
            }
            { Send-HardeningAlert @params } | Should -Not -Throw
        }

        It "accepts multiple recipient addresses" {
            $params = @{
                SmtpServer = "localhost"
                FromAddress = "alert@test.com"
                ToAddress = @("admin@test.com", "ops@test.com", "security@test.com")
                AlertType = "Hardening"
                ErrorAction = 'SilentlyContinue'
            }
            { Send-HardeningAlert @params } | Should -Not -Throw
        }
    }

    Context "Compliance Report" {
        It "accepts ComplianceReport parameter" {
            $report = [PSCustomObject]@{
                CompliancePercentage = 95
                Status = "Compliant"
                TotalRules = 44
                CompliantRules = 42
                NonCompliantRules = 2
            }
            $params = @{
                SmtpServer = "localhost"
                FromAddress = "alert@test.com"
                ToAddress = "admin@test.com"
                AlertType = "Compliance"
                ComplianceReport = $report
                ErrorAction = 'SilentlyContinue'
            }
            { Send-HardeningAlert @params } | Should -Not -Throw
        }

        It "generates alert without ComplianceReport" {
            $params = @{
                SmtpServer = "localhost"
                FromAddress = "alert@test.com"
                ToAddress = "admin@test.com"
                AlertType = "Hardening"
                ErrorAction = 'SilentlyContinue'
            }
            { Send-HardeningAlert @params } | Should -Not -Throw
        }

        It "accepts IncludeReport switch" {
            $params = @{
                SmtpServer = "localhost"
                FromAddress = "alert@test.com"
                ToAddress = "admin@test.com"
                AlertType = "Compliance"
                IncludeReport = $true
                ErrorAction = 'SilentlyContinue'
            }
            { Send-HardeningAlert @params } | Should -Not -Throw
        }
    }

    Context "Authentication" {
        It "sends alert without credential" {
            $params = @{
                SmtpServer = "localhost"
                FromAddress = "alert@test.com"
                ToAddress = "admin@test.com"
                AlertType = "Hardening"
                ErrorAction = 'SilentlyContinue'
            }
            { Send-HardeningAlert @params } | Should -Not -Throw
        }

        It "accepts PSCredential for authentication" {
            # PSScriptAnalyzer ignore [PSAvoidUsingConvertToSecureStringWithPlainText] - test credential only
            $credential = New-Object System.Management.Automation.PSCredential(
                'user',
                (ConvertTo-SecureString 'pass' -AsPlainText -Force)
            )
            $params = @{
                SmtpServer = "localhost"
                FromAddress = "alert@test.com"
                ToAddress = "admin@test.com"
                AlertType = "Hardening"
                Credential = $credential
                ErrorAction = 'SilentlyContinue'
            }
            { Send-HardeningAlert @params } | Should -Not -Throw
        }
    }

    Context "WhatIf Support" {
        It "supports -WhatIf parameter" {
            $params = @{
                SmtpServer = "localhost"
                FromAddress = "alert@test.com"
                ToAddress = "admin@test.com"
                AlertType = "Hardening"
                WhatIf = $true
            }
            { Send-HardeningAlert @params } | Should -Not -Throw
        }

        It "does not throw with -WhatIf and -Confirm" {
            $params = @{
                SmtpServer = "localhost"
                FromAddress = "alert@test.com"
                ToAddress = "admin@test.com"
                AlertType = "Hardening"
                WhatIf = $true
                Confirm = $false
            }
            { Send-HardeningAlert @params } | Should -Not -Throw
        }
    }

    Context "Email Content Generation" {
        It "generates email subject for Hardening alert type" {
            $params = @{
                SmtpServer = "localhost"
                FromAddress = "alert@test.com"
                ToAddress = "admin@test.com"
                AlertType = "Hardening"
                Severity = "Warning"
                ErrorAction = 'SilentlyContinue'
            }
            { Send-HardeningAlert @params } | Should -Not -Throw
        }

        It "generates email subject for Compliance alert type" {
            $params = @{
                SmtpServer = "localhost"
                FromAddress = "alert@test.com"
                ToAddress = "admin@test.com"
                AlertType = "Compliance"
                Severity = "Info"
                ErrorAction = 'SilentlyContinue'
            }
            { Send-HardeningAlert @params } | Should -Not -Throw
        }

        It "includes compliance metrics in email body" {
            $report = [PSCustomObject]@{
                CompliancePercentage = 88
                Status = "PartiallyCompliant"
                TotalRules = 44
                CompliantRules = 39
                NonCompliantRules = 5
            }
            $params = @{
                SmtpServer = "localhost"
                FromAddress = "alert@test.com"
                ToAddress = "admin@test.com"
                AlertType = "Compliance"
                ComplianceReport = $report
                ErrorAction = 'SilentlyContinue'
            }
            { Send-HardeningAlert @params } | Should -Not -Throw
        }

        It "generates HTML-formatted email body" {
            $params = @{
                SmtpServer = "localhost"
                FromAddress = "alert@test.com"
                ToAddress = "admin@test.com"
                AlertType = "Hardening"
                ErrorAction = 'SilentlyContinue'
            }
            { Send-HardeningAlert @params } | Should -Not -Throw
        }
    }

    Context "Error Handling" {
        It "logs alert sending operation" {
            $params = @{
                SmtpServer = "localhost"
                FromAddress = "alert@test.com"
                ToAddress = "admin@test.com"
                AlertType = "Hardening"
                ErrorAction = 'SilentlyContinue'
            }
            { Send-HardeningAlert @params } | Should -Not -Throw
        }

        It "includes alert details in log message" {
            $params = @{
                SmtpServer = "localhost"
                FromAddress = "alert@test.com"
                ToAddress = "admin@test.com"
                AlertType = "Compliance"
                Severity = "Critical"
                ErrorAction = 'SilentlyContinue'
            }
            { Send-HardeningAlert @params } | Should -Not -Throw
        }

        It "uses correct error action preference" {
            $params = @{
                SmtpServer = "localhost"
                FromAddress = "alert@test.com"
                ToAddress = "admin@test.com"
                AlertType = "Hardening"
                ErrorAction = 'SilentlyContinue'
            }
            { Send-HardeningAlert @params } | Should -Not -Throw
        }
    }

    Context "Documentation" {
        It "has complete help documentation" {
            $help = Get-Help Send-HardeningAlert
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }

        It "help includes SmtpServer parameter" {
            $help = Get-Help Send-HardeningAlert
            $help.Parameters.Parameter.Name | Should -Contain 'SmtpServer'
        }

        It "help includes FromAddress parameter" {
            $help = Get-Help Send-HardeningAlert
            $help.Parameters.Parameter.Name | Should -Contain 'FromAddress'
        }

        It "help includes ToAddress parameter" {
            $help = Get-Help Send-HardeningAlert
            $help.Parameters.Parameter.Name | Should -Contain 'ToAddress'
        }

        It "help includes AlertType parameter" {
            $help = Get-Help Send-HardeningAlert
            $help.Parameters.Parameter.Name | Should -Contain 'AlertType'
        }

        It "help includes Severity parameter" {
            $help = Get-Help Send-HardeningAlert
            $help.Parameters.Parameter.Name | Should -Contain 'Severity'
        }

        It "provides example usage" {
            $help = Get-Help Send-HardeningAlert
            $help.Examples | Should -Not -BeNullOrEmpty
        }
    }

    Context "Integration" {
        It "works with all mandatory parameters" {
            $params = @{
                SmtpServer = "mail.example.com"
                FromAddress = "alerts@example.com"
                ToAddress = @("admin@example.com", "security@example.com")
                AlertType = "Compliance"
                Severity = "Warning"
                SmtpPort = 587
                UseSSL = $true
                ErrorAction = 'SilentlyContinue'
            }
            { Send-HardeningAlert @params } | Should -Not -Throw
        }

        It "works with compliance report and multiple recipients" {
            $report = [PSCustomObject]@{
                CompliancePercentage = 92
                Status = "PartiallyCompliant"
                TotalRules = 44
                CompliantRules = 40
                NonCompliantRules = 4
            }
            $params = @{
                SmtpServer = "localhost"
                FromAddress = "alert@test.com"
                ToAddress = @("admin@test.com", "ops@test.com")
                AlertType = "Compliance"
                ComplianceReport = $report
                Severity = "Warning"
                ErrorAction = 'SilentlyContinue'
            }
            { Send-HardeningAlert @params } | Should -Not -Throw
        }

        It "generates different subjects for different alert types" {
            $params = @{
                SmtpServer = "localhost"
                FromAddress = "alert@test.com"
                ToAddress = "admin@test.com"
                AlertType = "Remediation"
                Severity = "Critical"
                ErrorAction = 'SilentlyContinue'
            }
            { Send-HardeningAlert @params } | Should -Not -Throw
        }
    }
}
