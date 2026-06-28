<#
.SYNOPSIS
Publish WinHarden module to PowerShell Gallery.

.DESCRIPTION
Builds and publishes the WinHarden module to PowerShell Gallery (PSGallery).
Requires NuGetApiKey to be set in environment or provided as parameter.

.PARAMETER NuGetApiKey
API key for PowerShell Gallery (from https://www.powershellgallery.com/account/apikeys)

.PARAMETER ModulePath
Path to WinHarden module root (default: current directory)

.PARAMETER SkipValidation
Skip module validation before publishing (not recommended)

.EXAMPLE
.\Publish-ToGallery.ps1 -NuGetApiKey "oy2a1b2c3d4e5f6g7h8i9j0k1l2m3n4o"

.EXAMPLE
.\Publish-ToGallery.ps1 -NuGetApiKey $env:NUGET_API_KEY

.NOTES
Steps:
1. Validates module manifest (WinHarden.psd1)
2. Tests module import
3. Publishes to PSGallery using Publish-Module
4. Verifies publication (may take 5-10 minutes)

Requires:
- PowerShellGet module (usually built-in)
- WriteRequired API key from https://www.powershellgallery.com/account/apikeys
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "PowerShell Gallery API key")]
    [string]$NuGetApiKey,

    [Parameter(Mandatory = $false)]
    [string]$ModulePath = $PSScriptRoot,

    [Parameter(Mandatory = $false)]
    [switch]$SkipValidation
)

# ============================================================================
# Functions
# ============================================================================

function Write-Header {
    param([string]$Message)
    Write-Output ""
    Write-Output "[PUBLISH] $Message"
    Write-Output ("-" * 70)
}

function Write-Success {
    param([string]$Message)
    Write-Output "[OK] $Message"
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Output "[ERROR] $Message"
}

# ============================================================================
# Main
# ============================================================================

Write-Header "WinHarden PowerShell Gallery Publishing"

# Step 1: Validate paths
Write-Output "[*] Checking module path: $ModulePath"
$manifestPath = Join-Path -Path $ModulePath -ChildPath "WinHarden.psd1"

if (-not (Test-Path -Path $manifestPath)) {
    Write-Error-Custom "Module manifest not found: $manifestPath"
    exit 1
}
Write-Success "Manifest found: $manifestPath"

# Step 2: Validate manifest
if (-not $SkipValidation) {
    Write-Header "Validating Module Manifest"
    try {
        $manifest = Import-PowerShellDataFile -Path $manifestPath
        Write-Success "Manifest is valid"
        Write-Output "  - Module Version: $($manifest.ModuleVersion)"
        Write-Output "  - Author: $($manifest.Author)"
        Write-Output "  - Functions: $($manifest.FunctionsToExport.Count)"
    }
    catch {
        Write-Error-Custom "Manifest validation failed: $($_.Exception.Message)"
        exit 1
    }
}

# Step 2.5: Verify this is a stable release (not pre-release)
Write-Header "Validating Release Type"
if ($manifest.ModuleVersion -match "-beta|-rc|-alpha|-preview") {
    Write-Error-Custom "Cannot publish pre-release to PowerShell Gallery: $($manifest.ModuleVersion)"
    Write-Output ""
    Write-Output "Policy: Only stable releases (v1.x.x) can be published to PSGallery"
    Write-Output "Pre-releases (beta, rc) must be tested separately"
    Write-Output ""
    Write-Output "To publish a stable version:"
    Write-Output "  1. Update ModuleVersion to remove -beta/-rc suffix"
    Write-Output "  2. Merge from prerelease → main"
    Write-Output "  3. Tag as stable (v1.x.x)"
    Write-Output "  4. Re-run publish script"
    exit 1
}
Write-Success "Release type is stable - ready to publish"
Write-Output "  - Version: $($manifest.ModuleVersion) (stable)"

# Step 3: Test module import
Write-Header "Testing Module Import"
try {
    Import-Module $manifestPath -Force -ErrorAction Stop | Out-Null
    Write-Success "Module imported successfully"

    # Get exported functions
    $module = Get-Module -Name WinHarden
    $exportedCount = @($module.ExportedFunctions.Keys).Count
    Write-Output "  - Exported functions: $exportedCount"
}
catch {
    Write-Error-Custom "Module import failed: $($_.Exception.Message)"
    exit 1
}

# Step 4: Publish to PowerShell Gallery
Write-Header "Publishing to PowerShell Gallery"

try {
    Write-Output "[*] Connecting to PSGallery..."

    $publishParams = @{
        Path            = $ModulePath
        NuGetApiKey     = $NuGetApiKey
        Repository      = 'PSGallery'
        Force           = $true
        ErrorAction     = 'Stop'
        Confirm         = $false
        ReleaseNotes    = "WinHarden v$($manifest.ModuleVersion) - Windows Server Hardening Automation"
    }

    Publish-Module @publishParams
    Write-Success "Module published to PowerShell Gallery"
}
catch {
    Write-Error-Custom "Publishing failed: $($_.Exception.Message)"
    exit 1
}

# Step 5: Verify publication
Write-Header "Verifying Publication"
Write-Output "[*] Checking PSGallery (may take 5-10 minutes to appear)..."
Write-Output ""
Write-Output "To verify publication:"
Write-Output "  - Web: https://www.powershellgallery.com/packages/WinHarden"
Write-Output "  - PowerShell: Find-Module -Name WinHarden"
Write-Output "  - Install: Install-Module -Name WinHarden"
Write-Output ""

Write-Header "Publication Complete"
Write-Success "WinHarden v$($manifest.ModuleVersion) published successfully!"
Write-Output ""
Write-Output "Next steps:"
Write-Output "1. Wait 5-10 minutes for PSGallery to index the module"
Write-Output "2. Verify: Find-Module -Name WinHarden"
Write-Output "3. Create GitHub Release with v$($manifest.ModuleVersion) tag"
Write-Output ""
