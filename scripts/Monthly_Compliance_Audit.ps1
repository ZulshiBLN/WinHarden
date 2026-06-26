# WinHarden Monthly Compliance Audit Script
# Auto-generated for GAMINGPC
# Schedule: 1st of every month at 08:00 AM

param(
    [string]$Profile = "Recommended",
    [string]$TargetSystem = "Client",
    [int]$OSVersion = 11,
    [string]$OutputDir = "c:\Repos\WinHarden\logs"
)

$ErrorActionPreference = "Continue"

# Timestamp for report
$reportDate = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$reportPath = Join-Path $OutputDir "Monthly_Audit_$reportDate"

# Create report directory
if (-not (Test-Path $reportPath)) {
    New-Item -ItemType Directory -Path $reportPath -Force | Out-Null
}

Write-Output ""
Write-Output "[MONTHLY COMPLIANCE AUDIT] $reportDate"
Write-Output "==========================================================="
# Load WinHarden functions
$basePath = "c:\Repos\WinHarden\functions"

$coreFunctions = @(
    "Core\Write-Log.ps1",
    "Core\Write-ErrorLog.ps1",
    "Core\Test-NotNullOrEmpty.ps1",
    "Core\Test-ValidPath.ps1",
    "Core\ConvertTo-MaskedString.ps1",
    "Core\_MaskSensitiveData.ps1",
    "Core\_TestLogLevel.ps1",
    "Core\_CleanupOldLogs.ps1",
    "Core\Get-ModuleVersion.ps1",
    "Core\Test-WinHardenDependencies.ps1"
)

foreach ($fn in $coreFunctions) {
    $path = Join-Path $basePath $fn
    if (Test-Path $path) { . $path }
}

$hardeningFunctions = @(
    "System\Hardening\New-HardeningSession.ps1",
    "System\Hardening\Get-HardeningProfile.ps1",
    "System\Hardening\Test-HardeningCompliance.ps1",
    "System\Hardening\Export-HardeningReport.ps1"
)

foreach ($fn in $hardeningFunctions) {
    $path = Join-Path $basePath $fn
    if (Test-Path $path) { . $path }
}

Write-Output "Functions loaded successfully"
# Create session
Write-Output ""
Write-Output "Creating hardening session..."
try {
    $session = New-HardeningSession -Profile $Profile -TargetSystem $TargetSystem -OSVersion $OSVersion -SkipPrerequisiteCheck
    Write-Output "Session created: $($session.SessionId)"
}
catch {
    Write-Output "ERROR: Failed to create session: $_"
    exit 1
}

# Test compliance
Write-Output ""
Write-Output "Testing compliance..."
try {
    $compliance = Test-HardeningCompliance -Session $session -Detailed
    Write-Output "Compliance test completed"
    Write-Output "Score: $($compliance.CompliancePercentage)%"
}
catch {
    Write-Output "ERROR: Compliance test failed: $_"
    exit 1
}

# Export report
Write-Output ""
Write-Output "Exporting compliance report..."
try {
    $reportFile = Export-HardeningReport -SessionId $session.SessionId -OutputPath $reportPath -Format CSV
    Write-Output "Report exported: $reportFile"
}
catch {
    Write-Output "WARNING: Report export had issues: $_"
}

# Generate summary
$summary = @{
    "Audit Date" = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "Profile" = $Profile
    "Compliance Score" = "$($compliance.CompliancePercentage)%"
    "Compliant Rules" = $compliance.CompliantRules
    "Total Rules" = $compliance.TotalRules
    "Status" = if ($compliance.CompliancePercentage -ge 80) { "PASS" } else { "FAIL" }
}

# Save summary
$summaryPath = Join-Path $reportPath "Summary.txt"
$summary | Out-File -FilePath $summaryPath -Encoding UTF8

Write-Output ""
Write-Output "==========================================================="
Write-Output "[AUDIT COMPLETE]"
Write-Output "Report Location: $reportPath"
Write-Output "Status: $($summary.Status)"
Write-Output "Compliance: $($summary['Compliance Score'])"
Write-Output "==========================================================="
# Email notification (optional - requires SMTP configured)
# Send-MailMessage -To admin@example.com -From audit@winharden.local -Subject "Monthly Audit Report" -Body "See attached report" -SmtpServer smtp.example.com

exit 0
