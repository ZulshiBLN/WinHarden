# Private helper function - verifies ExchangeOnlineManagement module is available
function _ValidateExchangeModuleAvailable {
    <#
    .SYNOPSIS
    Verifies that ExchangeOnlineManagement module is available.

    .DESCRIPTION
    Checks if the ExchangeOnlineManagement module is installed and provides
    helpful error message with installation instructions if not found.
    #>

    if (-not (Get-Command Connect-ExchangeOnline -ErrorAction SilentlyContinue)) {
        $message = "ExchangeOnlineManagement module not found. Install via: Install-Module -Name ExchangeOnlineManagement -Repository PSGallery"
        Write-Error -Message $message
        throw $message
    }
}
