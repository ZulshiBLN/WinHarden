<#
.SYNOPSIS
Monthly Windows Compliance Audit Report für WinHarden

.DESCRIPTION
Führt monatlich eine vollständige Compliance-Überprüfung durch und erstellt einen Audit-Report.
Wird typischerweise via Scheduled Task am 1. des Monats ausgeführt.

.PARAMETER HardeningProfile
Das Hardening-Profil zu testen: "Recommended", "Strict", oder "Minimal". Standard: Recommended

.PARAMETER TargetSystem
Ziel-System-Typ: "Client" oder "Server". Standard: Client

.PARAMETER OSVersion
Windows-Version: 10 oder 11. Standard: 11

.PARAMETER OutputDir
Pfad zum Report-Verzeichnis. Standard: c:\Repos\WinHarden\logs

.EXAMPLE
PS> .\Monthly_Compliance_Audit.ps1 -HardeningProfile "Strict" -OutputDir "C:\Audits\2026-06"

.NOTES
DEPENDS ON: Write-Log, Test-WinHardenDependencies, New-HardeningSession, Test-HardeningCompliance, Export-HardeningReport
AUTO-GENERATED for: GAMINGPC
SCHEDULE: 1st of every month at 08:00 AM
#>

param(
    [ValidateSet("Recommended", "Strict", "Minimal")]
    [string]$HardeningProfile = "Recommended",

    [ValidateSet("Client", "Server")]
    [string]$TargetSystem = "Client",

    [ValidateRange(10, 11)]
    [int]$OSVersion = 11,

    [ValidateNotNullOrEmpty()]
    [string]$OutputDir = "c:\Repos\WinHarden\logs"
)

$ErrorActionPreference = "Stop"

$reportDate = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$reportPath = Join-Path $OutputDir "Monthly_Audit_$reportDate"

if (-not (Test-Path $reportPath)) {
    $null = New-Item -ItemType Directory -Path $reportPath -Force
}

Write-Output ""
Write-Output "[MONTHLY COMPLIANCE AUDIT] $reportDate"
Write-Output "==========================================================="

# Load WinHarden Core functions (required for Write-Log)
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
    if (Test-Path $path) {
        . $path
    }
    else {
        Write-Error "Required Core function not found: $path" -ErrorAction Stop
    }
}

# Load Hardening functions
$hardeningFunctions = @(
    "System\Hardening\New-HardeningSession.ps1",
    "System\Hardening\Get-HardeningProfile.ps1",
    "System\Hardening\Test-HardeningCompliance.ps1",
    "System\Hardening\Export-HardeningReport.ps1"
)

foreach ($fn in $hardeningFunctions) {
    $path = Join-Path $basePath $fn
    if (Test-Path $path) {
        . $path
    }
    else {
        Write-Error "Required Hardening function not found: $path" -ErrorAction Stop
    }
}

Write-Log -Message "WinHarden functions loaded successfully" -Level Info -Caller "Monthly_Compliance_Audit"
Write-Output ""
Write-Log -Message "Creating hardening session with HardeningProfile=$HardeningProfile, TargetSystem=$TargetSystem, OSVersion=$OSVersion" -Level Info -Caller "Monthly_Compliance_Audit"

try {
    $session = New-HardeningSession -Profile $HardeningProfile -TargetSystem $TargetSystem -OSVersion $OSVersion -SkipPrerequisiteCheck
    Write-Log -Message "Session created: $($session.SessionId)" -Level Info -Caller "Monthly_Compliance_Audit"
    Write-Output "Session created: $($session.SessionId)"
}
catch {
    Write-Log -Message "Failed to create session: $_" -Level Error -Caller "Monthly_Compliance_Audit"
    Write-Error "Failed to create session: $_" -ErrorAction Stop
}

Write-Output ""
Write-Log -Message "Testing compliance..." -Level Info -Caller "Monthly_Compliance_Audit"

try {
    $compliance = Test-HardeningCompliance -Session $session -Detailed
    Write-Log -Message "Compliance test completed. Score: $($compliance.CompliancePercentage)%" -Level Info -Caller "Monthly_Compliance_Audit"
    Write-Output "Compliance test completed"
    Write-Output "Score: $($compliance.CompliancePercentage)%"
}
catch {
    Write-Log -Message "Compliance test failed: $_" -Level Error -Caller "Monthly_Compliance_Audit"
    Write-Error "Compliance test failed: $_" -ErrorAction Stop
}

Write-Output ""
Write-Log -Message "Exporting compliance report..." -Level Info -Caller "Monthly_Compliance_Audit"

try {
    $reportFile = Export-HardeningReport -SessionId $session.SessionId -OutputPath $reportPath -Format CSV
    Write-Log -Message "Report exported to: $reportFile" -Level Info -Caller "Monthly_Compliance_Audit"
    Write-Output "Report exported: $reportFile"
}
catch {
    Write-Log -Message "Report export had issues: $_" -Level Warning -Caller "Monthly_Compliance_Audit"
    Write-Warning "Report export had issues: $_"
}

if ($compliance.CompliancePercentage -ge 80) {
    $auditStatus = "PASS"
}
else {
    $auditStatus = "FAIL"
}

$summary = @{
    "Audit Date" = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "Profile" = $HardeningProfile
    "Compliance Score" = "$($compliance.CompliancePercentage)%"
    "Compliant Rules" = $compliance.CompliantRules
    "Total Rules" = $compliance.TotalRules
    "Status" = $auditStatus
}

$summaryPath = Join-Path $reportPath "Summary.txt"
$summary | Out-File -FilePath $summaryPath -Encoding UTF8

$auditLevel = if ($summary.Status -eq "PASS") {
    "Info"
}
else {
    "Warning"
}
Write-Log -Message "Audit completed. Status: $($summary.Status), Score: $($summary['Compliance Score'])" -Level $auditLevel -Caller "Monthly_Compliance_Audit"

Write-Output ""
Write-Output "==========================================================="
Write-Output "[AUDIT COMPLETE]"
Write-Output "Report Location: $reportPath"
Write-Output "Status: $($summary.Status)"
Write-Output "Compliance: $($summary['Compliance Score'])"
Write-Output "==========================================================="

exit 0
