# Private helper function - verifies Exchange Online connection is active
function _VerifyExchangeOnlineConnection {
    <#
    .SYNOPSIS
    Verifies that Exchange Online connection is active and accessible.

    .DESCRIPTION
    Tests the current Exchange Online connection by querying mailbox information.
    Throws exception if connection verification fails.
    #>

    try {
        $null = @(Get-Mailbox -ResultSize 1 -ErrorAction Stop)
        Write-Verbose "Exchange Online connection verified - mailbox query successful"
        return $true
    }
    catch {
        $message = "Exchange Online connection verification failed: $($_.Exception.Message)"
        Write-Error -Message $message
        throw $message
    }
}
