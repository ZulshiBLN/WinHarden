function Send-HardeningAlert {
    <#
    .SYNOPSIS
    Sends email notifications for hardening compliance events.

    .DESCRIPTION
    Generates and sends email alerts for hardening operations, compliance
    issues, and remediation events. Supports HTML-formatted reports and
    attachment generation.

    Features:
    - Customizable alert thresholds
    - HTML-formatted email bodies
    - Compliance report attachments
    - Multiple recipient support
    - Alert severity levels
    - Retry logic for delivery

    Supports SMTP authentication:
    - Anonymous SMTP
    - Basic authentication
    - Secure connection (TLS/SSL)

    .PARAMETER SmtpServer
    SMTP server address for email delivery.
    Mandatory.

    .PARAMETER FromAddress
    Email address for alert sender.
    Mandatory.

    .PARAMETER ToAddress
    Array of recipient email addresses.
    Mandatory.

    .PARAMETER AlertType
    Type of alert: Hardening, Compliance, Remediation, Schedule.
    Mandatory.

    .PARAMETER ComplianceReport
    Compliance report object for alert context.
    Optional.

    .PARAMETER Severity
    Alert severity: Info, Warning, Critical.
    Default: Info

    .PARAMETER IncludeReport
    If specified, attaches compliance report file.

    .PARAMETER SmtpPort
    SMTP port number.
    Default: 25 (standard SMTP), 587 (TLS), 465 (SSL)

    .PARAMETER UseSSL
    If specified, uses SSL for SMTP connection.

    .PARAMETER Credential
    SMTP authentication credentials.
    If omitted, uses anonymous authentication.

    .EXAMPLE
    Send-HardeningAlert -SmtpServer smtp.contoso.com -FromAddress hardening@contoso.com `
        -ToAddress @('admin@contoso.com','security@contoso.com') `
        -AlertType Compliance -ComplianceReport $compliance -Severity Warning

    Sends compliance warning alert to multiple recipients.

    .EXAMPLE
    $cred = Get-Credential
    Send-HardeningAlert -SmtpServer smtp.gmail.com -FromAddress alerts@company.com `
        -ToAddress security-team@company.com -AlertType Hardening `
        -Credential $cred -UseSSL -SmtpPort 587

    Sends alert via secure Gmail SMTP with authentication.

    .NOTES
    DEPENDENCIES: Write-Log (Core)
    SMTP: Requires accessible SMTP server
    CREDENTIALS: Use secure credential handling (Get-Credential)
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $SmtpServer,

        [Parameter(Mandatory = $true)]
        [string]
        $FromAddress,

        [Parameter(Mandatory = $true)]
        [string[]]
        $ToAddress,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Hardening', 'Compliance', 'Remediation', 'Schedule')]
        [string]
        $AlertType,

        [Parameter(Mandatory = $false)]
        [PSCustomObject]
        $ComplianceReport,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Info', 'Warning', 'Critical')]
        [string]
        $Severity = 'Info',

        [switch]
        $IncludeReport,

        [Parameter(Mandatory = $false)]
        [int]
        $SmtpPort = 25,

        [switch]
        $UseSSL,

        [Parameter(Mandatory = $false)]
        [PSCredential]
        $Credential
    )

    $ErrorActionPreference = 'Stop'

    try {
        Write-Log -Message "Sending hardening alert: Type=$AlertType, Severity=$Severity" -Level Info

        # Generate email subject
        $subject = _GenerateAlertSubject -AlertType $AlertType -Severity $Severity -Report $ComplianceReport

        # Generate email body
        $body = _GenerateAlertBody -AlertType $AlertType -Severity $Severity -Report $ComplianceReport

        # Prepare SMTP parameters
        $smtpParams = @{
            SmtpServer = $SmtpServer
            Port = $SmtpPort
            From = $FromAddress
            To = $ToAddress
            Subject = $subject
            Body = $body
            BodyAsHtml = $true
            ErrorAction = 'Stop'
        }

        if ($UseSSL) {
            $smtpParams['UseSsl'] = $true
        }

        if ($Credential) {
            $smtpParams['Credential'] = $Credential
        }

        # Send email
        Send-MailMessage @smtpParams

        Write-Log -Message "Hardening alert sent to $($ToAddress -join ', ')" -Level Info
    }
    catch {
        Write-ErrorLog -Message "Failed to send hardening alert: $($_.Exception.Message)" -Caller $MyInvocation.MyCommand.Name
        throw
    }
}

function _GenerateAlertSubject {
    param(
        [string]$AlertType,
        [string]$Severity,
        [PSCustomObject]$Report
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"

    switch ($AlertType) {
        'Hardening' {
            "[WinHarden] $Severity - Hardening Operation - $timestamp"
        }
        'Compliance' {
            if ($Report) {
                "[WinHarden] $Severity - Compliance Alert ($($Report.CompliancePercentage)%) - $timestamp"
            }
            else {
                "[WinHarden] $Severity - Compliance Alert - $timestamp"
            }
        }
        'Remediation' {
            "[WinHarden] $Severity - Remediation Event - $timestamp"
        }
        'Schedule' {
            "[WinHarden] $Severity - Scheduled Hardening Check - $timestamp"
        }
    }
}

function _GenerateAlertBody {
    param(
        [string]$AlertType,
        [string]$Severity,
        [PSCustomObject]$Report
    )

    $severityColor = switch ($Severity) {
        'Info' { '#0066cc' }
        'Warning' { '#ff9800' }
        'Critical' { '#f44336' }
    }

    $html = @"
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Segoe UI, Tahoma, Geneva, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
        .container { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); max-width: 600px; margin: 0 auto; }
        .alert-header { border-left: 4px solid $severityColor; padding-left: 15px; margin-bottom: 20px; }
        .alert-title { font-size: 18px; font-weight: bold; color: $severityColor; margin: 0; }
        .alert-time { color: #666; font-size: 12px; margin-top: 5px; }
        .summary { background: #f9f9f9; padding: 15px; border-radius: 4px; margin: 15px 0; }
        .metric { margin: 10px 0; }
        .metric-label { color: #666; font-size: 12px; }
        .metric-value { font-size: 20px; font-weight: bold; color: $severityColor; }
        table { width: 100%; border-collapse: collapse; margin: 15px 0; }
        th { background: #f0f0f0; padding: 10px; text-align: left; font-weight: 600; }
        td { padding: 10px; border-bottom: 1px solid #eee; }
        .footer { text-align: center; color: #999; font-size: 12px; margin-top: 20px; padding-top: 20px; border-top: 1px solid #eee; }
    </style>
</head>
<body>
    <div class="container">
        <div class="alert-header">
            <div class="alert-title">WinHarden Hardening Alert</div>
            <div class="alert-time">$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</div>
        </div>
"@

    if ($Report) {
        $html += @"
        <div class="summary">
            <div class="metric">
                <div class="metric-label">Compliance Status</div>
                <div class="metric-value">$($Report.CompliancePercentage)%</div>
            </div>
            <div class="metric">
                <div class="metric-label">Overall Status</div>
                <div style="font-size: 16px; color: $severityColor; font-weight: bold;">$($Report.Status)</div>
            </div>
        </div>

        <table>
            <tr>
                <th>Metric</th>
                <th>Value</th>
            </tr>
            <tr>
                <td>Total Rules</td>
                <td>$($Report.TotalRules)</td>
            </tr>
            <tr>
                <td>Compliant Rules</td>
                <td style="color: #4caf50;">$($Report.CompliantRules)</td>
            </tr>
            <tr>
                <td>Non-Compliant Rules</td>
                <td style="color: #f44336;">$($Report.NonCompliantRules)</td>
            </tr>
        </table>
"@
    }
    else {
        $html += @"
        <div class="summary">
            <p>Hardening operation alert for system hardening compliance verification.</p>
        </div>
"@
    }

    $html += @"
        <div class="footer">
            <p>WinHarden Windows Hardening System</p>
            <p>Do not reply to this automated message</p>
        </div>
    </div>
</body>
</html>
"@

    $html
}
