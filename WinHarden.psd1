@{
    RootModule        = 'modules/System.psm1'
    ModuleVersion = '1.13.0'
    GUID              = 'f5c8d1a4-2b9e-4c7f-8a1b-9d3e5f2a1b8c'
    Author            = 'Michel Brosche'
    CompanyName       = 'WinHarden Project'
    Description       = 'PowerShell Automation & Operations Toolkit for Windows Server Administration. Secure hardening, compliance verification, and remote deployment automation.'
    PowerShellVersion = '5.1'

    # Version history for PowerShell Gallery
    FunctionsToExport = @(
        # Core functions
        'Write-Log'
        'Write-ErrorLog'
        'ConvertTo-MaskedString'
        'Test-NotNullOrEmpty'
        'Test-ValidPath'
        'Get-ModuleVersion'
        'Test-WinHardenDependencies'
        'New-HardeningHTMLReport'

        # Hardening functions
        'New-HardeningSession'
        'Get-HardeningProfile'
        'Invoke-SecurityHardening'
        'Test-HardeningCompliance'
        'Export-HardeningReport'
        'Invoke-RemoteHardening'
        'New-HardeningSchedule'
        'Import-HardeningGPO'
        'Send-HardeningAlert'
        'Get-HardeningTrendData'

        # Drift detection functions
        'Get-AccountPoliciesDrift'
        'Get-NetworkSecurityDrift'
        'Get-RDPSecurityDrift'
        'Get-FirewallStatusDrift'
        'Get-AuditPoliciesDrift'
        'Get-UpdateStatusDrift'
        'Get-ServiceSecurityDrift'
        'Get-AutoUpdateConfiguration'
        'New-SecurityDriftReport'

        # System status functions
        'Get-PendingRebootStatus'
        'Get-WindowsUpdateStatus'
        'Get-UpdateHistory'

        # Task scheduling functions
        'Set-TaskScheduleCatchup'

        # Reporting functions
        'Invoke-HardeningHTMLReport'
    )

    # Module dependencies
    RequiredModules   = @()

    # Additional metadata (PowerShell 5.1 compatible format)
    PrivateData       = @{
        PSData = @{
            # License and project information
            LicenseUri     = 'https://github.com/ZulshiBLN/WinHarden/blob/main/LICENSE'
            ProjectUri     = 'https://github.com/ZulshiBLN/WinHarden'
            ReleaseNotes   = 'https://github.com/ZulshiBLN/WinHarden/releases'

            # Tags for discovery
            Tags           = @(
                'PowerShell'
                'Windows'
                'Hardening'
                'Security'
                'Compliance'
                'Automation'
                'Drift-Detection'
                'System-Administration'
                'Windows-Server'
                'DevOps'
            )

            # Release prerelease status
            Prerelease     = ''
        }
    }
}

