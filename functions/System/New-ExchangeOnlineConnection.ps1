function New-ExchangeOnlineConnection {
    <#
    .SYNOPSIS
    Establishes a connection to Exchange Online using various authentication methods.

    .DESCRIPTION
    Connects to Exchange Online using one of three authentication methods:
    1. User credentials (interactive)
    2. Azure App Registration with shared secret
    3. Azure App Registration with certificate

    After successful connection, the function verifies connectivity by querying mailbox count.

    .PARAMETER Credential
    User credentials for interactive authentication. Uses the current user's credentials if not specified.

    .PARAMETER AppId
    Azure Application ID for app-based authentication.

    .PARAMETER TenantId
    Azure Tenant ID for app-based authentication.

    .PARAMETER ClientSecret
    Shared secret for app-based authentication (for use with -AppId).

    .PARAMETER CertificatePath
    Path to certificate file for certificate-based authentication (for use with -AppId).

    .PARAMETER CertificateThumbprint
    Thumbprint of certificate in local certificate store (alternative to -CertificatePath).

    .PARAMETER Organization
    Exchange Online organization name (optional, for specific tenant routing).

    .PARAMETER SkipVerification
    Skip verification of connection after establishing it (useful for fast connections).

    .PARAMETER WhatIf
    Shows what would happen if the function runs without making any changes.

    .EXAMPLE
    New-ExchangeOnlineConnection -Credential (Get-Credential)

    .EXAMPLE
    New-ExchangeOnlineConnection -AppId "12345678-1234-1234-1234-123456789012" `
        -TenantId "12345678-1234-1234-1234-123456789012" `
        -ClientSecret "your_secret_here"

    .EXAMPLE
    New-ExchangeOnlineConnection -AppId "12345678-1234-1234-1234-123456789012" `
        -TenantId "12345678-1234-1234-1234-123456789012" `
        -CertificateThumbprint "A1B2C3D4E5F6G7H8I9J0"
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium', DefaultParameterSetName = 'Credential')]
    param(
        [Parameter(ParameterSetName = 'Credential', Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter(ParameterSetName = 'AppSecret', Mandatory = $true)]
        [Parameter(ParameterSetName = 'AppCertPath', Mandatory = $true)]
        [Parameter(ParameterSetName = 'AppCertThumb', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $AppId,

        [Parameter(ParameterSetName = 'AppSecret', Mandatory = $true)]
        [Parameter(ParameterSetName = 'AppCertPath', Mandatory = $true)]
        [Parameter(ParameterSetName = 'AppCertThumb', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $TenantId,

        [Parameter(ParameterSetName = 'AppSecret', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [securestring]
        $ClientSecret,

        [Parameter(ParameterSetName = 'AppCertPath', Mandatory = $true)]
        [ValidateScript( { Test-Path -Path $_ -PathType Leaf })]
        [string]
        $CertificatePath,

        [Parameter(ParameterSetName = 'AppCertThumb', Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $CertificateThumbprint,

        [Parameter(Mandatory = $false)]
        [string]
        $Organization,

        [switch]
        $SkipVerification
    )

    $ErrorActionPreference = 'Stop'

    # DEPENDS ON: Write-Log (Core), error handling via ADR-004
    # REQUIRES (optional): ExchangeOnlineManagement module 3.0+

    if ($PSCmdlet.ShouldProcess("Exchange Online", "Establish connection")) {
        try {
            _ValidateExchangeModuleAvailable

            $connectParams = @{
                ErrorAction = 'Stop'
            }

            switch ($PSCmdlet.ParameterSetName) {
                'Credential' {
                    Write-Verbose "Initiating Exchange Online connection with user credentials"
                    if ($Credential) {
                        $connectParams['Credential'] = $Credential
                    }
                }

                'AppSecret' {
                    Write-Verbose "Initiating Exchange Online connection with app secret"
                    $connectParams['AppId'] = $AppId
                    $connectParams['TenantId'] = $TenantId
                    $connectParams['ClientSecret'] = $ClientSecret
                }

                'AppCertPath' {
                    Write-Verbose "Initiating Exchange Online connection with certificate file"
                    $connectParams['AppId'] = $AppId
                    $connectParams['TenantId'] = $TenantId
                    $connectParams['CertificatePath'] = $CertificatePath
                }

                'AppCertThumb' {
                    Write-Verbose "Initiating Exchange Online connection with certificate thumbprint"
                    $connectParams['AppId'] = $AppId
                    $connectParams['TenantId'] = $TenantId
                    $connectParams['CertificateThumbprint'] = $CertificateThumbprint
                }
            }

            if ($Organization) {
                $connectParams['Organization'] = $Organization
            }

            Connect-ExchangeOnline @connectParams

            # Verify connection if not skipped
            if (-not $SkipVerification) {
                _VerifyExchangeOnlineConnection
            }

            Write-Verbose "Exchange Online connection established and verified"
        }
        catch {
            Write-Error -Message "Failed to establish Exchange Online connection: $($_.Exception.Message)" -Exception $_
            throw
        }
    }
}
