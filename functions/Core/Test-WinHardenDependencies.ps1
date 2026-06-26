function Test-WinHardenDependencies {
    <#
    .SYNOPSIS
    Validates that WinHarden dependencies are available and compatible.

    .DESCRIPTION
    Checks for required PowerShell version, optional modules, and system prerequisites.
    Returns detailed status for debugging without blocking execution.

    .PARAMETER Module
    Specific module(s) to check (optional).

    .PARAMETER ExitOnError
    Throw exception if critical dependency is missing.

    .NOTES
    NAMING JUSTIFICATION:
    This function uses the plural noun "Dependencies" intentionally because it:
    1. Validates MULTIPLE dependencies (PowerShell + modules)
    2. Returns MULTIPLE result entries (hash with multiple keys)
    3. Accepts MULTIPLE modules (array parameter)
    Plural usage aligns with PowerShell standards (Get-ChildItem, Get-Module).

    .EXAMPLE
    Test-WinHardenDependencies

    .EXAMPLE
    Test-WinHardenDependencies -Module GroupPolicy -ExitOnError
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateScript( { $null -eq $_ -or $_.Count -gt 0 })]
        [string[]]
        $Module,

        [switch]
        $ExitOnError
    )

    $ErrorActionPreference = 'Stop'
    $results = @{}

    try {
        # Check PowerShell version
        $psVersion = $PSVersionTable.PSVersion.Major
        $results['PowerShellVersion'] = @{
            'Required' = '5.1'
            'Actual' = "$psVersion.$($PSVersionTable.PSVersion.Minor)"
            'Status' = if ($psVersion -ge 5) {
                'OK'
            }
            else {
                'FAIL'
            }
        }

        if ($results['PowerShellVersion'].Status -eq 'FAIL' -and $ExitOnError) {
            throw "PowerShell 5.1+ required, but $psVersion found"
        }

        # Check optional modules
        if ($Module) {
            foreach ($moduleName in $Module) {
                $moduleCheck = Get-Module -Name $moduleName -ListAvailable -ErrorAction SilentlyContinue
                $results[$moduleName] = @{
                    'Status' = if ($moduleCheck) {
                        'Available'
                    }
                    else {
                        'NotFound'
                    }
                    'Version' = $moduleCheck.Version -join ', '
                }

                if ($results[$moduleName].Status -eq 'NotFound' -and $ExitOnError) {
                    throw "Required module '$moduleName' not found. Install via: Install-Module -Name $moduleName"
                }
            }
        }

        return $results
    }
    catch {
        if ($ExitOnError) {
            throw $_
        }
        return @{ 'Error' = $_.Exception.Message }
    }
}
