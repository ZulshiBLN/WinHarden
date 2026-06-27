function New-SecurityDriftReport {
    <#
    .SYNOPSIS
    Creates and exports security drift detection report.
    
    .DESCRIPTION
    Compiles drift findings from all detection functions into a structured report.
    Exports as CSV with summary metadata and detailed findings.
    
    .PARAMETER DriftFindings
    PSCustomObject array of drift findings from Get-*Drift functions.
    
    .PARAMETER OutputDirectory
    Output directory for CSV report (default: logs/).
    
    .EXAMPLE
    $findings = @()
    $findings += Get-AccountPoliciesDrift
    $findings += Get-NetworkSecurityDrift
    $report = New-SecurityDriftReport -DriftFindings $findings
    
    .NOTES
    DEPENDENCIES: Write-Log (Core)
    APPLIES TO: All Windows Servers
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [PSCustomObject[]]$DriftFindings = @(),
        [string]$OutputDirectory = "$(Split-Path $PSScriptRoot -Parent)\logs"
    )
    
    try {
        # Ensure output directory exists
        if (-not (Test-Path $OutputDirectory)) {
            New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
            Write-Log -Message "Created output directory: $OutputDirectory" -Level Info `
                -Caller $MyInvocation.MyCommand.Name
        }
    
        # Generate report filename with timestamp
        $reportDate = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        $reportFile = Join-Path $OutputDirectory "Drift_Detection_$reportDate.csv"
    
        # Determine overall status and severity
        if ($DriftFindings.Count -eq 0) {
            $status = "COMPLIANT"
        }
        else {
            $status = "NON-COMPLIANT"
        }
        $criticalCount = @($DriftFindings | Where-Object Severity -eq "CRITICAL").Count
        $highCount = @($DriftFindings | Where-Object Severity -eq "HIGH").Count
        $mediumCount = @($DriftFindings | Where-Object Severity -eq "MEDIUM").Count
        if ($criticalCount -gt 0) {
            $overallSeverity = "CRITICAL"
        }
        elseif ($highCount -gt 0) {
            $overallSeverity = "HIGH"
        }
        else {
            $overallSeverity = "MEDIUM"
        }
    
        # Create summary object
        $summary = [PSCustomObject]@{
            'Scan_Date' = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            'Hostname' = $env:COMPUTERNAME
            'Status' = $status
            'Total_Drifts' = $DriftFindings.Count
            'Critical_Count' = $criticalCount
            'High_Count' = $highCount
            'Medium_Count' = $mediumCount
            'Overall_Severity' = $overallSeverity
        }
    
        # Export summary
        $summary | Export-Csv -Path $reportFile -NoTypeInformation -Force
        Write-Log -Message "Drift report exported: $reportFile (Status: $status, Drifts: $($DriftFindings.Count))" `
            -Level Info -Caller $MyInvocation.MyCommand.Name
    
        # Append detailed findings
        if ($DriftFindings.Count -gt 0) {
            $DriftFindings | Export-Csv -Path $reportFile -NoTypeInformation -Append -Force
        }
    
        return [PSCustomObject]@{
            ReportPath = $reportFile
            Status = $status
            DriftCount = $DriftFindings.Count
            Severity = $overallSeverity
        }
    }
    catch {
        Write-Log -Message "Error creating drift report: $_" -Level Error -Caller $MyInvocation.MyCommand.Name
        throw
    }
}
