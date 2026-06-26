BeforeAll {
    $modulePath = (Resolve-Path "$PSScriptRoot\..\modules\Core.psm1").Path
    Import-Module $modulePath -Force
}

AfterAll {
    Remove-Module Core -Force -ErrorAction SilentlyContinue
}

Describe "Write-ErrorLog" {
    Context "Error logging" {
        It "logs message with Error level" {
            $testMessage = "Critical error occurred"

            $logDir = "$PSScriptRoot\..\logs"
            if (Test-Path $logDir) {
                Remove-Item $logDir -Recurse -Force
            }

            Write-ErrorLog -Message $testMessage

            $logFile = Get-ChildItem -Path $logDir -Filter "log_*.csv" | Select-Object -First 1
            $content = @(Get-Content -Path $logFile.FullName)
            $content[-1] | Should -Match "ERROR"
            $content[-1] | Should -Match $testMessage
        }
    }
}
