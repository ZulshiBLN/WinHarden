# WinHarden Report Archiving Script
# Archives Monthly_Audit reports older than 6 months in ZIP files
# Schedule: 2nd of month @ 09:00 AM
# Run As: SYSTEM (Highest Privileges)

param(
    [int]$MonthsOld = 6,
    [string]$LogsDir = "c:\Repos\WinHarden\logs",
    [string]$ArchiveDir = "c:\Repos\WinHarden\archive"
)

$ErrorActionPreference = "Continue"

Write-Output ""
Write-Output "=========================================================="
Write-Output "   WINHARDEN REPORT ARCHIVING - AUTOMATED CLEANUP"
Write-Output "=========================================================="
Write-Output ""
Write-Output "Start Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Output "Logs Directory: $LogsDir"
Write-Output "Archive Directory: $ArchiveDir"
Write-Output "Archive Threshold: >$MonthsOld Months"

# Create archive directory if not exists
if (-not (Test-Path $ArchiveDir)) {
    New-Item -ItemType Directory -Path $ArchiveDir -Force | Out-Null
    Write-Output ""
    Write-Output "[OK] Archive directory created: $ArchiveDir"
}

Write-Output ""
Write-Output "[SCANNING FOR OLD REPORTS]"
Write-Output "=========================================================="

# Find Monthly_Audit directories older than threshold
$cutoffDate = (Get-Date).AddMonths(-$MonthsOld)
$oldReports = Get-ChildItem -Path $LogsDir -Directory -Filter "Monthly_Audit_*" -ErrorAction SilentlyContinue |
    Where-Object { $_.CreationTime -lt $cutoffDate }

$foundCount = ($oldReports | Measure-Object).Count

if ($foundCount -eq 0) {
    Write-Output ""
    Write-Output "[OK] No reports older than $MonthsOld months found"
    Write-Output "All reports are recent (less than $MonthsOld months old)"
    exit 0
}

Write-Output ""
Write-Output "[OK] Found $foundCount reports older than $MonthsOld months"
Write-Output "These will be archived:"

# Process each old report
$archiveCount = 0
foreach ($report in $oldReports) {
    $reportAge = ((Get-Date) - $report.CreationTime).Days
    Write-Output ""
    Write-Output "  * $($report.Name) - ${reportAge} days old"

    # Create ZIP archive
    $zipName = "$($report.Name).zip"
    $zipPath = Join-Path $ArchiveDir $zipName

    try {
        # Check if already archived
        if (Test-Path $zipPath) {
            Write-Output "    [WARN] Already archived (skipping)"
            continue
        }

        # Create ZIP file
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::CreateFromDirectory(
            $report.FullPath, $zipPath,
            [System.IO.Compression.CompressionLevel]::Optimal, $false
        )

        Write-Output "    [OK] Archived to: $zipName"

        # Verify ZIP file size
        $zipSize = [math]::Round((Get-Item $zipPath).Length / 1MB, 2)
        Write-Output "    Archive size: $zipSize MB"

        # Delete original directory after successful ZIP
        Remove-Item -Path $report.FullPath -Recurse -Force
        Write-Output "    [OK] Original directory deleted"

        $archiveCount++
    }
    catch {
        Write-Output "    [ERROR] Error archiving: $_"
    }
}

Write-Output ""
Write-Output "[ARCHIVE SUMMARY]"
Write-Output "=========================================================="
Write-Output ""
Write-Output "Reports Found: $foundCount"
Write-Output "Reports Archived: $archiveCount"
Write-Output "Archive Location: $ArchiveDir"

# Show archive inventory
$archiveFiles = Get-ChildItem -Path $ArchiveDir -Filter "*.zip" -ErrorAction SilentlyContinue
if ($archiveFiles) {
    Write-Output ""
    Write-Output "Archived Reports:"
    $archiveFiles | ForEach-Object {
        $size = [math]::Round($_.Length / 1MB, 2)
        Write-Output "  * $($_.Name) - $size MB"
    }
}

# Storage statistics
Write-Output ""
Write-Output "[STORAGE STATISTICS]"
Write-Output "=========================================================="
Write-Output ""
$logsSize = [math]::Round((Get-ChildItem -Path $LogsDir -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
$archiveItems = Get-ChildItem -Path $ArchiveDir -Recurse
$archiveSize = [math]::Round(($archiveItems | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
$totalSize = $logsSize + $archiveSize

Write-Output "Active Logs Directory: $logsSize MB"
Write-Output "Archive Directory: $archiveSize MB"
Write-Output "Total Storage: $totalSize MB"

Write-Output ""
Write-Output "[NEXT STEPS]"
Write-Output "=========================================================="
Write-Output ""
Write-Output "[OK] Automated monthly archiving is active:"
Write-Output "  * Schedule: 2nd day of each month @ 09:00 AM"
Write-Output "  * Action: ZIP reports >6 months old"
Write-Output "  * Result: Free up storage space, keep archive for compliance"
Write-Output ""
Write-Output "[INFO] Archive Maintenance Tips:"
Write-Output "  1. Periodically move old ZIPs to external storage"
Write-Output "  2. Keep 1-2 years of archives for compliance audits"
Write-Output "  3. Document archival process in security procedures"
Write-Output ""
Write-Output "[AUDIT LOG]"
Write-Output "=========================================================="

$logEntry = @{
    'Timestamp' = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    'Action' = 'Report Archiving'
    'Reports_Archived' = $archiveCount
    'Reports_Found' = $foundCount
    'Archive_Location' = $ArchiveDir
    'Status' = if ($archiveCount -eq $foundCount) { 'SUCCESS' } else { 'PARTIAL' }
}

$logEntry | Format-Table -AutoSize

Write-Output ""
Write-Output "End Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Output ""
Write-Output "=========================================================="

exit 0
