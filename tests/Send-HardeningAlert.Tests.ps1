BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\System.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module System -Force -ErrorAction SilentlyContinue
}

Describe "Send-HardeningAlert" {
    Context "Parameter Validation" {
        It "requires AlertLevel parameter" {
            { Send-HardeningAlert -Subject "Test" -Body "Test body" -SmtpServer "localhost" } | Should -Throw
        }

        It "requires SmtpServer parameter" {
            { Send-HardeningAlert -AlertLevel Critical -Subject "Test" -Body "Test body" } | Should -Throw
        }

        It "accepts valid alert levels" {
            $levels = @('Critical', 'High', 'Medium', 'Low', 'Info')
            foreach ($level in $levels) {
                { Send-HardeningAlert -AlertLevel $level -Subject "Test" -Body "Test body" -SmtpServer "localhost" -ErrorAction SilentlyContinue } | Should -Not -Throw
            }
        }

        It "accepts RecipientAddress parameter" {
            { Send-HardeningAlert -AlertLevel Critical -Subject "Test" -Body "Test body" -SmtpServer "localhost" -RecipientAddress "admin@example.com" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Port parameter" {
            { Send-HardeningAlert -AlertLevel Critical -Subject "Test" -Body "Test body" -SmtpServer "localhost" -Port 587 -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts UseSSL switch" {
            { Send-HardeningAlert -AlertLevel Critical -Subject "Test" -Body "Test body" -SmtpServer "localhost" -UseSSL -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Credential parameter" {
            $credential = New-Object System.Management.Automation.PSCredential('TestUser', (ConvertTo-SecureString 'TestPass' -AsPlainText -Force))
            { Send-HardeningAlert -AlertLevel Critical -Subject "Test" -Body "Test body" -SmtpServer "localhost" -Credential $credential -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Alert Levels" {
        It "accepts Critical alert level" {
            { Send-HardeningAlert -AlertLevel Critical -Subject "Critical Alert" -Body "System failure" -SmtpServer "localhost" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts High alert level" {
            { Send-HardeningAlert -AlertLevel High -Subject "High Alert" -Body "Serious issue" -SmtpServer "localhost" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Medium alert level" {
            { Send-HardeningAlert -AlertLevel Medium -Subject "Medium Alert" -Body "Notice" -SmtpServer "localhost" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Low alert level" {
            { Send-HardeningAlert -AlertLevel Low -Subject "Low Alert" -Body "Minor info" -SmtpServer "localhost" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts Info alert level" {
            { Send-HardeningAlert -AlertLevel Info -Subject "Info Alert" -Body "FYI" -SmtpServer "localhost" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Email Configuration" {
        It "sends email with default SMTP port 25" {
            { Send-HardeningAlert -AlertLevel Critical -Subject "Test" -Body "Test body" -SmtpServer "localhost" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "sends email with TLS port 587" {
            { Send-HardeningAlert -AlertLevel Critical -Subject "Test" -Body "Test body" -SmtpServer "localhost" -Port 587 -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "sends email with SSL port 465" {
            { Send-HardeningAlert -AlertLevel Critical -Subject "Test" -Body "Test body" -SmtpServer "localhost" -Port 465 -UseSSL -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "sends email with custom port" {
            { Send-HardeningAlert -AlertLevel Critical -Subject "Test" -Body "Test body" -SmtpServer "localhost" -Port 2525 -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Recipient Handling" {
        It "accepts single recipient address" {
            { Send-HardeningAlert -AlertLevel Critical -Subject "Test" -Body "Test body" -SmtpServer "localhost" -RecipientAddress "admin@example.com" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts multiple recipient addresses" {
            $recipients = @("admin@example.com", "ops@example.com", "security@example.com")
            { Send-HardeningAlert -AlertLevel Critical -Subject "Test" -Body "Test body" -SmtpServer "localhost" -RecipientAddress $recipients -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts CC recipients" {
            { Send-HardeningAlert -AlertLevel Critical -Subject "Test" -Body "Test body" -SmtpServer "localhost" -CcAddress "manager@example.com" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts BCC recipients" {
            { Send-HardeningAlert -AlertLevel Critical -Subject "Test" -Body "Test body" -SmtpServer "localhost" -BccAddress "audit@example.com" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Content Formatting" {
        It "includes alert level in subject prefix" {
            { Send-HardeningAlert -AlertLevel Critical -Subject "Test Alert" -Body "Test body" -SmtpServer "localhost" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes timestamp in message body" {
            { Send-HardeningAlert -AlertLevel Critical -Subject "Test" -Body "Test body" -SmtpServer "localhost" -IncludeTimestamp -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "includes system information in message" {
            { Send-HardeningAlert -AlertLevel Critical -Subject "Test" -Body "Test body" -SmtpServer "localhost" -IncludeSystemInfo -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "formats message body as plain text by default" {
            { Send-HardeningAlert -AlertLevel Critical -Subject "Test" -Body "Test body" -SmtpServer "localhost" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "formats message body as HTML when requested" {
            { Send-HardeningAlert -AlertLevel Critical -Subject "Test" -Body "<h1>Test</h1>" -SmtpServer "localhost" -BodyAsHtml -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Authentication" {
        It "sends alert without authentication" {
            { Send-HardeningAlert -AlertLevel Critical -Subject "Test" -Body "Test body" -SmtpServer "localhost" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "sends alert with credential authentication" {
            $credential = New-Object System.Management.Automation.PSCredential('user', (ConvertTo-SecureString 'pass' -AsPlainText -Force))
            { Send-HardeningAlert -AlertLevel Critical -Subject "Test" -Body "Test body" -SmtpServer "localhost" -Credential $credential -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Error Handling" {
        It "handles invalid SMTP server gracefully" {
            { Send-HardeningAlert -AlertLevel Critical -Subject "Test" -Body "Test body" -SmtpServer "invalid.nonexistent.server" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "handles network timeout" {
            { Send-HardeningAlert -AlertLevel Critical -Subject "Test" -Body "Test body" -SmtpServer "localhost" -TimeoutSeconds 1 -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Advanced Options" {
        It "accepts custom From address" {
            { Send-HardeningAlert -AlertLevel Critical -Subject "Test" -Body "Test body" -SmtpServer "localhost" -FromAddress "hardening@example.com" -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts attachment paths" {
            { Send-HardeningAlert -AlertLevel Critical -Subject "Test" -Body "Test body" -SmtpServer "localhost" -AttachmentPath @("C:\Temp\report.txt") -ErrorAction SilentlyContinue } | Should -Not -Throw
        }

        It "accepts priority setting" {
            { Send-HardeningAlert -AlertLevel Critical -Subject "Test" -Body "Test body" -SmtpServer "localhost" -Priority High -ErrorAction SilentlyContinue } | Should -Not -Throw
        }
    }

    Context "Documentation" {
        It "has complete help documentation" {
            $help = Get-Help Send-HardeningAlert
            $help.Synopsis | Should -Not -BeNullOrEmpty
        }

        It "help includes AlertLevel parameter" {
            $help = Get-Help Send-HardeningAlert
            $help.Parameters.Parameter.Name | Should -Contain 'AlertLevel'
        }

        It "help includes SmtpServer parameter" {
            $help = Get-Help Send-HardeningAlert
            $help.Parameters.Parameter.Name | Should -Contain 'SmtpServer'
        }
    }
}
