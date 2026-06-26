function Write-Log {
    <#
    .SYNOPSIS
    Centralized logging function with CSV format and sensitive data masking.

    .DESCRIPTION
    Writes structured log entries to CSV file with automatic daily rotation and sensitive data masking.
    Logs are stored in logs/log_YYYY-MM-DD.csv with automatic 7-day retention.

    .PARAMETER Message
    Log message content.

    .PARAMETER Level
    Log level: Error, Warning, Info, Debug, Verbose (hierarchical order).

    .PARAMETER Caller
    Optional caller identifier (auto-populated from call stack if not provided).

    .EXAMPLE
    Write-Log -Message "Operation completed successfully" -Level Info

    .EXAMPLE
    Write-Log -Message "Failed to connect to server" -Level Error

    .NOTES
    Requires helper functions: _CleanupOldLogs, _MaskSensitiveData, _TestLogLevel
    CSV daily rotation with 7-day retention policy
    Encoding: UTF8 with proper CSV escaping for special characters
    Supports -WhatIf for dry-run logging verification
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Error', 'Warning', 'Info', 'Debug', 'Verbose')]
        [string]
        $Level = 'Info',

        [Parameter(Mandatory = $false)]
        [string]
        $Caller
    )

    $ErrorActionPreference = 'Stop'

    try {
        # Determine log directory - handle both module and direct script contexts
        $logDir = $null

        if ($PSScriptRoot) {
            # Calculate project root: functions/Core -> ../../ = project root
            $projectRoot = Split-Path -Path $PSScriptRoot -Parent | Split-Path -Parent
            $logDir = Join-Path -Path $projectRoot -ChildPath 'logs'

            # Verify we got a reasonable path (should contain 'WinHarden' or 'logs')
            if (-not ($logDir -like '*logs')) {
                $logDir = $null
            }
        }

        # Fallback: use current directory
        if (-not $logDir) {
            $logDir = Join-Path -Path (Get-Location) -ChildPath 'logs'
        }

        # Create log directory if needed
        if (-not (Test-Path -Path $logDir -PathType Container)) {
            $null = New-Item -ItemType Directory -Path $logDir -Force -ErrorAction SilentlyContinue
        }

        # Log file with daily rotation
        $dateString = (Get-Date -Format 'yyyy-MM-dd')
        $logFile = Join-Path -Path $logDir -ChildPath "log_$dateString.csv"

        # Cleanup old logs (7-day retention)
        _CleanupOldLogs -LogDir $logDir

        # Determine caller info from call stack if not provided
        if (-not $Caller) {
            $callStack = Get-PSCallStack
            if ($callStack.Count -gt 1) {
                $Caller = $callStack[1].FunctionName
            }
            else {
                $Caller = 'Unknown'
            }
        }

        # Mask sensitive data in message
        $maskedMessage = _MaskSensitiveData -InputString $Message

        # Get Function and LineNumber from call stack for logging context
        $callStack = Get-PSCallStack
        $callerFunction = if ($callStack.Count -gt 1) {
            $callStack[1].FunctionName
        }
        else {
            'Unknown'
        }
        $callerLineNumber = if ($callStack.Count -gt 1) {
            $callStack[1].ScriptLineNumber
        }
        else {
            0
        }

        # Prepare CSV entry (6 columns per ADR-005)
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
        $csvEntry = [ordered]@{
            'Timestamp' = $timestamp
            'Level' = $Level
            'Caller' = $Caller
            'Function' = $callerFunction
            'LineNumber' = $callerLineNumber
            'Message' = $maskedMessage
        }

        # Handle -WhatIf parameter (gracefully handle in both Interactive and NonInteractive modes)
        if ($WhatIfPreference) {
            Write-Verbose "WhatIf: Would log '$Message' (level: $Level) to $logFile"
            return
        }

        # Write header if file doesn't exist
        if (-not (Test-Path -Path $logFile -PathType Leaf)) {
            try {
                $header = $csvEntry.Keys -join ','
                Add-Content -Path $logFile -Value $header -Encoding UTF8 -ErrorAction Stop
            }
            catch {
                Write-Error -Message "Failed to write log header: $_" -ErrorAction Continue
            }
        }

        # Append CSV entry
        $values = $csvEntry.Values | ForEach-Object {
            # Escape CSV values
            if ($_ -match '[",\r\n]') {
                '"' + ($_ -replace '"', '""') + '"'
            }
            else {
                $_
            }
        }
        $csvRow = $values -join ','

        try {
            Add-Content -Path $logFile -Value $csvRow -Encoding UTF8 -ErrorAction Stop
        }
        catch {
            Write-Error -Message "Failed to append log entry: $_" -ErrorAction Continue
        }

        # Also output to PowerShell stream based on level
        if (_TestLogLevel -Level $Level) {
            switch ($Level) {
                'Error' {
                    Write-Error -Message $maskedMessage -ErrorAction Continue
                }
                'Warning' {
                    Write-Warning -Message $maskedMessage
                }
                'Debug' {
                    Write-Debug -Message $maskedMessage
                }
                'Verbose' {
                    Write-Verbose -Message $maskedMessage
                }
                'Info' {
                    Write-Verbose -Message $maskedMessage
                }
            }
        }

    }
    catch {
        # Fallback: write to stderr if log file fails
        Write-Error -Message "Logging failed: $($_.Exception.Message)"
    }
}
