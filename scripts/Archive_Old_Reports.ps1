# WinHarden Report Archiving Script
# Archives Monthly_Audit reports older than 6 months in ZIP files
# Schedule: 2nd of month @ 09:00 AM
# Run As: SYSTEM (Highest Privileges)

param(
    [ValidateRange(1, 360)][int]$MonthsOld = 6,
    [ValidateNotNullOrEmpty()][string]$LogsDir = "c:\Repos\WinHarden\logs",
    [ValidateNotNullOrEmpty()][string]$ArchiveDir = "c:\Repos\WinHarden\archive"
)

$ErrorActionPreference = "Stop"

# Import Core module for logging
try {
    Import-Module -Name "$PSScriptRoot\..\modules\Core.psm1" -DisableNameChecking -Force -ErrorAction Stop
    Import-Module -Name "$PSScriptRoot\..\modules\Maintenance.psm1" -DisableNameChecking -Force -ErrorAction Stop
}
catch {
    Write-Error "Failed to import required modules: $_"
    exit 2
}

Write-Log -Message "========== WINHARDEN REPORT ARCHIVING - AUTOMATED CLEANUP ==========" -Level Info
Write-Log -Message "Start Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level Info
Write-Log -Message "Logs Directory: $LogsDir" -Level Info
Write-Log -Message "Archive Directory: $ArchiveDir" -Level Info
Write-Log -Message "Archive Threshold: >$MonthsOld Months" -Level Info

# Create archive directory if not exists
if (-not (Test-Path -PathType Container $ArchiveDir)) {
    try {
        New-Item -ItemType Directory -Path $ArchiveDir -Force -ErrorAction Stop | Out-Null
        Write-Log -Message "Archive directory created: $ArchiveDir" -Level Info
    }
    catch {
        Write-ErrorLog -Message "Failed to create archive directory: $_" -ErrorRecord $_ -Caller "Archive_Old_Reports"
        exit 1
    }
}

Write-Log -Message "========== SCANNING FOR OLD REPORTS ==========" -Level Info

# Validate logs directory exists
if (-not (Test-Path -PathType Container $LogsDir)) {
    Write-ErrorLog -Message "Logs directory not found: $LogsDir" -Caller "Archive_Old_Reports"
    exit 1
}

# Find Monthly_Audit directories older than threshold
try {
    $cutoffDate = (Get-Date).AddMonths(-$MonthsOld)
    $oldReports = Get-ChildItem -Path $LogsDir -Directory -Filter "Monthly_Audit_*" -ErrorAction Stop |
        Where-Object { $_.CreationTime -lt $cutoffDate }
}
catch {
    Write-ErrorLog -Message "Failed to scan logs directory: $_" -ErrorRecord $_ -Caller "Archive_Old_Reports"
    exit 1
}

$foundCount = ($oldReports | Measure-Object).Count

if ($foundCount -eq 0) {
    Write-Log -Message "No reports older than $MonthsOld months found - all reports are recent" -Level Info
    exit 0
}

Write-Log -Message "Found $foundCount reports older than $MonthsOld months - starting archival process" -Level Info

# Process each old report
$archiveCount = 0
$failureCount = 0

foreach ($report in $oldReports) {
    $reportAge = ((Get-Date) - $report.CreationTime).Days
    Write-Log -Message "Processing report: $($report.Name) (age: $reportAge days)" -Level Info

    # Create ZIP archive
    $zipName = "$($report.Name).zip"
    $zipPath = Join-Path $ArchiveDir $zipName

    try {
        # Check if already archived
        if (Test-Path -PathType Leaf $zipPath) {
            Write-Log -Message "Report already archived, skipping: $($report.Name)" -Level Warning
            continue
        }

        # Create ZIP file
        Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction Stop
        [System.IO.Compression.ZipFile]::CreateFromDirectory(
            $report.FullName, $zipPath,
            [System.IO.Compression.CompressionLevel]::Optimal, $false
        )

        # Verify ZIP file was created
        if (-not (Test-Path -PathType Leaf $zipPath)) {
            throw "ZIP file was not created at $zipPath"
        }

        $zipSize = [math]::Round((Get-Item $zipPath).Length / 1MB, 2)
        Write-Log -Message "Successfully archived $($report.Name) to $zipName (size: $zipSize MB)" -Level Info

        # Delete original directory after successful ZIP
        try {
            Remove-Item -Path $report.FullName -Recurse -Force -ErrorAction Stop
            Write-Log -Message "Deleted original directory: $($report.Name)" -Level Info
            $archiveCount++
        }
        catch {
            Write-ErrorLog -Message "Failed to delete original directory: $($report.Name)" -ErrorRecord $_ -Caller "Archive_Old_Reports"
            $failureCount++
        }
    }
    catch {
        Write-ErrorLog -Message "Failed to archive report $($report.Name): $_" -ErrorRecord $_ -Caller "Archive_Old_Reports"
        $failureCount++
    }
}

Write-Log -Message "========== ARCHIVE SUMMARY ==========" -Level Info
Write-Log -Message "Reports Found: $foundCount" -Level Info
Write-Log -Message "Reports Archived: $archiveCount" -Level Info

$summaryLevel = if ($failureCount -eq 0) {
    "Info"
}
else {
    "Warning"
}

Write-Log -Message "Archive Failures: $failureCount" -Level $summaryLevel
Write-Log -Message "Archive Location: $ArchiveDir" -Level Info

# Show archive inventory
try {
    $archiveFiles = Get-ChildItem -Path $ArchiveDir -Filter "*.zip" -ErrorAction Stop
    if ($archiveFiles) {
        $archiveFiles | ForEach-Object {
            $size = [math]::Round($_.Length / 1MB, 2)
            Write-Log -Message "Archived report: $($_.Name) ($size MB)" -Level Info
        }
    }
}
catch {
    Write-ErrorLog -Message "Failed to enumerate archive files: $_" -ErrorRecord $_ -Caller "Archive_Old_Reports"
}

# Storage statistics
try {
    Write-Log -Message "========== STORAGE STATISTICS ==========" -Level Info
    $logsSize = [math]::Round((Get-ChildItem -Path $LogsDir -Recurse -ErrorAction Stop | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
    $archiveItems = Get-ChildItem -Path $ArchiveDir -Recurse -ErrorAction Stop
    $archiveSize = [math]::Round(($archiveItems | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
    $totalSize = $logsSize + $archiveSize

    Write-Log -Message "Active Logs Directory: $logsSize MB" -Level Info
    Write-Log -Message "Archive Directory: $archiveSize MB" -Level Info
    Write-Log -Message "Total Storage: $totalSize MB" -Level Info
}
catch {
    Write-ErrorLog -Message "Failed to calculate storage statistics: $_" -ErrorRecord $_ -Caller "Archive_Old_Reports"
}

Write-Log -Message "End Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level Info

# Determine exit code based on success/failure
$exitCode = if ($failureCount -eq 0 -and $archiveCount -eq $foundCount) {
    Write-Log -Message "Archiving completed successfully" -Level Info
    0
}
elseif ($failureCount -gt 0 -and $archiveCount -eq 0) {
    Write-ErrorLog -Message "Archiving failed for all $foundCount reports" -Caller "Archive_Old_Reports"
    1
}
else {
    Write-Log -Message "Archiving completed with $failureCount failures out of $foundCount reports" -Level Warning
    1
}

exit $exitCode
