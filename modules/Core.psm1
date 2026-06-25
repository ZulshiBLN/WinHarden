#region Logging (ADR-005)

function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [ValidateSet('Error', 'Warning', 'Info', 'Debug', 'Verbose')]
        [string]$Level = 'Info',

        [string]$Caller = (Get-PSCallStack)[1].FunctionName
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
    $logDir = Join-Path $PSScriptRoot '..\logs'

    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    $logFile = Join-Path $logDir "log_$(Get-Date -Format 'yyyy-MM-dd').csv"
    $maskedMessage = _Mask-SensitiveData -InputString $Message

    $logEntry = "$timestamp,$Level,$Caller,<function>,<line>,$maskedMessage"

    try {
        Add-Content -Path $logFile -Value $logEntry -ErrorAction Stop
    }
    catch {
        Write-Host "[LOG ERROR] Failed to write log: $_" -ForegroundColor Red
    }

    if (_Should-LogLevel -Level $Level) {
        $color = switch ($Level) {
            'Error' { 'Red' }
            'Warning' { 'Yellow' }
            'Info' { 'Green' }
            'Debug' { 'Cyan' }
            'Verbose' { 'White' }
            default { 'White' }
        }
        Write-Host "[$Level] $maskedMessage" -ForegroundColor $color
    }

    Clean-OldLogs
}

function _Mask-SensitiveData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$InputString
    )

    $sensitivePrefixes = @(
        'password',
        'token',
        'secret',
        'apikey',
        'credential',
        'api_key',
        'private_key',
        'auth'
    )

    $maskedString = $InputString
    foreach ($prefix in $sensitivePrefixes) {
        $maskedString = $maskedString -replace "(?i)$prefix\s*[:=]\s*[^\s,;`"']*", "$prefix=***"
    }

    return $maskedString
}

function _Should-LogLevel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Level
    )

    $logLevel = $env:LOG_LEVEL ?? 'Info'
    $hierarchy = @('Error', 'Warning', 'Info', 'Debug', 'Verbose')

    $currentIndex = $hierarchy.IndexOf($Level)
    $maxIndex = $hierarchy.IndexOf($logLevel)

    return $currentIndex -le $maxIndex
}

function Clean-OldLogs {
    [CmdletBinding()]
    param(
        [int]$DaysToKeep = 7
    )

    $logDir = Join-Path $PSScriptRoot '..\logs'
    if (-not (Test-Path $logDir)) {
        return
    }

    $cutoffDate = (Get-Date).AddDays(-$DaysToKeep)

    try {
        Get-ChildItem -Path $logDir -Filter 'log_*.csv' -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -lt $cutoffDate } |
            Remove-Item -Force -ErrorAction SilentlyContinue
    }
    catch {
        Write-Host "[LOG CLEANUP ERROR] $_" -ForegroundColor Red
    }
}

#endregion Logging

#region Error Handling (ADR-004)

function Write-ErrorLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    Write-Log -Message $Message -Level Error
}

#endregion Error Handling

#region Validation Helpers (ADR-004, ADR-009)

function Test-NotNullOrEmpty {
    [CmdletBinding()]
    param(
        [string]$Value,

        [string]$Name = 'Value'
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        $errorMessage = "$Name cannot be null or empty"
        Write-Log -Message $errorMessage -Level Error
        throw $errorMessage
    }

    return $true
}

function Test-ValidPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [string]$Name = 'Path'
    )

    if (-not (Test-Path -Path $Path)) {
        $errorMessage = "$Name does not exist: $Path"
        Write-Log -Message $errorMessage -Level Error
        throw $errorMessage
    }

    return $true
}

#endregion Validation Helpers

#region Data Masking (ADR-005)

function ConvertTo-MaskedString {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$InputString
    )

    return _Mask-SensitiveData -InputString $InputString
}

#endregion Data Masking

#region Module Version (ADR-008)

function Get-ModuleVersion {
    [CmdletBinding()]
    param()

    return @{
        Module              = 'WinOpsKit'
        Version             = '0.1.0'
        PowerShellVersion   = $PSVersionTable.PSVersion.ToString()
        BuildDate           = (Get-Date).ToString('yyyy-MM-dd')
        Infrastructure      = 'Complete (9 ADRs)'
        Phase               = 'Implementation'
    }
}

#endregion Module Version

#region Dependencies (ADR-009)

function Test-WinOpsKitDependencies {
    [CmdletBinding()]
    param(
        [string[]]$RequiredModules = @()
    )

    if ($RequiredModules.Count -eq 0) {
        return $true
    }

    $missing = @()
    foreach ($module in $RequiredModules) {
        if (-not (Get-Module -Name $module -ListAvailable -ErrorAction SilentlyContinue)) {
            $missing += $module
            Write-Log -Message "Missing external module: $module" -Level Warning
        }
    }

    if ($missing.Count -gt 0) {
        Write-Host "Missing modules: $($missing -join ', ')" -ForegroundColor Yellow
        Write-Host "Install with: Install-Module $($missing -join ', ')" -ForegroundColor Yellow
        return $false
    }

    return $true
}

#endregion Dependencies

#region Exports

Export-ModuleMember -Function @(
    'Write-Log',
    'Clean-OldLogs',
    'Write-ErrorLog',
    'Test-NotNullOrEmpty',
    'Test-ValidPath',
    'ConvertTo-MaskedString',
    'Get-ModuleVersion',
    'Test-WinOpsKitDependencies'
)

#endregion Exports
