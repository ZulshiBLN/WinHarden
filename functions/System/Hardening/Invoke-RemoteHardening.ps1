function Invoke-RemoteHardening {
    <#
    .SYNOPSIS
    Applies hardening rules to remote Windows systems via PowerShell Remoting.

    .DESCRIPTION
    Orchestrates hardening on remote systems using PowerShell remoting over WinRM.
    Supports batch operations on multiple systems with progress tracking.

    Features:
    - Apply hardening to single or multiple remote systems
    - Parallel execution on multiple targets
    - Progress tracking and reporting
    - Error handling with per-system reporting
    - Optional remediation verification
    - Session credential management

    Requires:
    - PowerShell Remoting enabled on remote systems (Enable-PSRemoting)
    - WinRM service running (port 5985/5986)
    - Network connectivity to remote systems
    - Administrative credentials on remote systems

    .PARAMETER ComputerName
    Array of remote computer names to harden.
    Mandatory.

    .PARAMETER Profile
    Hardening profile: Basis, Recommended, or Strict.
    Mandatory.

    .PARAMETER Credential
    PSCredential object for remote authentication.
    If omitted, uses current user credentials (must have admin rights).
    Optional.

    .PARAMETER SkipVerification
    If specified, skips compliance verification after hardening.
    Useful for speed in fast operations.

    .PARAMETER Parallel
    If specified, hardens multiple systems in parallel.
    Default: Sequential processing.

    .PARAMETER Port
    WinRM port: 5985 (HTTP) or 5986 (HTTPS).
    Default: 5985

    .PARAMETER UseSSL
    If specified, uses HTTPS for remote connections.
    Requires WinRM HTTPS listener configured.

    .EXAMPLE
    Invoke-RemoteHardening -ComputerName 'Server1', 'Server2' -Profile Recommended

    Applies Recommended hardening to two servers sequentially.

    .EXAMPLE
    Invoke-RemoteHardening -ComputerName @('Web1','Web2','Web3') -Profile Basis -Parallel

    Applies hardening to three servers in parallel.

    .EXAMPLE
    $cred = Get-Credential
    Invoke-RemoteHardening -ComputerName 'RemoteServer' -Profile Strict -Credential $cred -UseSSL

    Applies strict hardening with explicit credentials over HTTPS.

    .NOTES
    DEPENDENCIES: Write-Log (Core), New-HardeningSession, Invoke-SecurityHardening
    REMOTING: Requires PowerShell Remoting enabled on targets
    ADMIN: Requires administrative rights on remote systems
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $ComputerName,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Basis', 'Recommended', 'Strict')]
        [string]
        $Profile,

        [Parameter(Mandatory = $false)]
        [PSCredential]
        $Credential,

        [switch]
        $SkipVerification,

        [switch]
        $Parallel,

        [Parameter(Mandatory = $false)]
        [ValidateSet(5985, 5986)]
        [int]
        $Port = 5985,

        [switch]
        $UseSSL
    )

    $ErrorActionPreference = 'Stop'

    try {
        Write-Log -Message "Starting remote hardening: Computers=$($ComputerName.Count), Profile=$Profile" -Level Info

        $results = @()
        $sessionParams = @{
            ComputerName = $ComputerName
            Port = $Port
            ErrorAction = 'SilentlyContinue'
        }

        if ($UseSSL) {
            $sessionParams['UseSSL'] = $true
        }

        if ($Credential) {
            $sessionParams['Credential'] = $Credential
        }

        # Create remote sessions
        Write-Verbose "Establishing remote sessions..."
        $remoteSessions = New-PSSession @sessionParams

        if ($null -eq $remoteSessions) {
            throw "Failed to establish remote sessions. Check connectivity and WinRM status."
        }

        $processingSessions = if ($Parallel) { $remoteSessions } else { @($remoteSessions) }

        # Execute hardening on remote systems
        $hardening_code = {
            param($Profile, $SkipVerification)

            # Import modules on remote system
            Import-Module "$PSScriptRoot\..\modules\System.psm1" -Force -ErrorAction SilentlyContinue

            # Create and apply hardening
            $session = New-HardeningSession -Profile $Profile -TargetSystem Client -SkipPrerequisiteCheck
            $result = Invoke-SecurityHardening -Session $session -SkipVerification:$SkipVerification

            $result
        }

        foreach ($rs in $processingSessions) {
            Write-Verbose "Invoking hardening on $($rs.ComputerName)..."

            try {
                $remoteResult = Invoke-Command -Session $rs -ScriptBlock $hardening_code -ArgumentList $Profile, $SkipVerification

                $results += [PSCustomObject]@{
                    ComputerName = $rs.ComputerName
                    Success = $true
                    Profile = $Profile
                    AppliedRules = $remoteResult.AppliedRules.Count
                    FailedRules = $remoteResult.FailedRules.Count
                    CompliancePercentage = $remoteResult.ComplianceReport.CompliancePercentage
                    Status = $remoteResult.ComplianceReport.Status
                    Duration = $remoteResult.Duration
                }

                Write-Log -Message "Hardening succeeded on $($rs.ComputerName): $($remoteResult.AppliedRules.Count) rules applied" -Level Info
            }
            catch {
                $results += [PSCustomObject]@{
                    ComputerName = $rs.ComputerName
                    Success = $false
                    Error = $_.Exception.Message
                }

                Write-Log -Message "Hardening failed on $($rs.ComputerName): $($_.Exception.Message)" -Level Error
            }
        }

        # Cleanup sessions
        Remove-PSSession -Session $remoteSessions -ErrorAction SilentlyContinue

        Write-Log -Message "Remote hardening complete: $(($results | Where-Object Success).Count)/$($ComputerName.Count) systems succeeded" -Level Info

        $results
    }
    catch {
        Write-ErrorLog -Message "Failed to execute remote hardening: $($_.Exception.Message)" -Caller $MyInvocation.MyCommand.Name
        throw
    }
}
