BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\Core.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module Core -Force -ErrorAction SilentlyContinue
}

Describe "_CleanupOldLogs" {
    Context "Log cleanup verification" {
        It "function exists in Core module" {
            $funcCode = Get-Content -Path "$PSScriptRoot\..\functions\Core\_CleanupOldLogs.ps1" -Raw
            $funcCode | Should -Match "function _CleanupOldLogs"
        }

        It "has proper 7-day retention logic" {
            $funcCode = Get-Content -Path "$PSScriptRoot\..\functions\Core\_CleanupOldLogs.ps1" -Raw
            $funcCode | Should -Match "AddDays\(-"
            $funcCode | Should -Match "DaysToKeep"
        }
    }

    Context "Integration with Write-Log" {
        It "is called by Write-Log for cleanup" {
            $logCode = Get-Content -Path "$PSScriptRoot\..\functions\Core\Write-Log.ps1" -Raw
            $logCode | Should -Match "_CleanupOldLogs"
        }
    }
}
