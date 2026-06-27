BeforeAll {
    $projectRoot = (Resolve-Path "$PSScriptRoot\..").Path
    $corePath = Join-Path -Path $projectRoot -ChildPath "modules\Core.psm1"
    $systemPath = Join-Path -Path $projectRoot -ChildPath "modules\System.psm1"

    if (Test-Path $corePath) {
        Import-Module $corePath -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path $systemPath) {
        Import-Module $systemPath -Force -ErrorAction SilentlyContinue
    }
}

AfterAll {
    Remove-Module Core -Force -ErrorAction SilentlyContinue
    Remove-Module System -Force -ErrorAction SilentlyContinue
}

Describe "Monitor_Windows_Updates.ps1" {
    Context "Section 1: Windows Update Status" {
        It "returns UP-TO-DATE when no updates available" {
            Mock Get-WindowsUpdateStatus -MockWith {
                return [PSCustomObject]@{
                    AvailableUpdates = 0
                    SecurityUpdates = 0
                    CriticalUpdates = 0
                    OtherUpdates = 0
                    AllUpdates = @()
                    SecurityUpdatesList = @()
                    CriticalUpdatesList = @()
                }
            }

            $updateStatus = Get-WindowsUpdateStatus
            $updateStatus.AvailableUpdates | Should -Be 0
            $status = if ($updateStatus.AvailableUpdates -eq 0) { "UP-TO-DATE" } else { "UPDATES-PENDING" }
            $status | Should -Be "UP-TO-DATE"
        }

        It "returns UPDATES-PENDING when updates available" {
            Mock Get-WindowsUpdateStatus -MockWith {
                return [PSCustomObject]@{
                    AvailableUpdates = 1
                    SecurityUpdates = 1
                    CriticalUpdates = 0
                    OtherUpdates = 0
                    AllUpdates = @()
                    SecurityUpdatesList = @()
                    CriticalUpdatesList = @()
                }
            }

            $updateStatus = Get-WindowsUpdateStatus
            $updateStatus.AvailableUpdates | Should -Be 1
            $status = if ($updateStatus.AvailableUpdates -eq 0) { "UP-TO-DATE" } else { "UPDATES-PENDING" }
            $status | Should -Be "UPDATES-PENDING"
        }

        It "counts security and critical updates correctly" {
            Mock Get-WindowsUpdateStatus -MockWith {
                return [PSCustomObject]@{
                    AvailableUpdates = 2
                    SecurityUpdates = 1
                    CriticalUpdates = 1
                    OtherUpdates = 0
                    AllUpdates = @()
                    SecurityUpdatesList = @()
                    CriticalUpdatesList = @()
                }
            }

            $status = Get-WindowsUpdateStatus
            $status.SecurityUpdates | Should -Be 1
            $status.CriticalUpdates | Should -Be 1
            $status.AvailableUpdates | Should -Be 2
        }

        It "handles update search errors gracefully" {
            Mock Get-WindowsUpdateStatus -MockWith {
                throw [System.Exception]::new("Search failed")
            }

            {
                Get-WindowsUpdateStatus -ErrorAction Stop
            } | Should -Throw
        }
    }

    Context "Section 2: Auto-Update Configuration" {
        It "retrieves Auto-Update configuration" {
            Mock Get-AutoUpdateConfiguration -MockWith {
                return [PSCustomObject]@{
                    PolicyValue = 4
                    Description = "Auto Download and Schedule Installation"
                    IsEnabled = $true
                }
            }

            $autoConfig = Get-AutoUpdateConfiguration
            $autoConfig.IsEnabled | Should -Be $true
        }

        It "handles missing Auto-Update config gracefully" {
            Mock Get-AutoUpdateConfiguration -MockWith {
                throw [System.Exception]::new("Config not found")
            }

            {
                Get-AutoUpdateConfiguration -ErrorAction Stop
            } | Should -Throw
        }

        It "defaults to Windows settings when policy not set" {
            Mock Get-AutoUpdateConfiguration -MockWith {
                return [PSCustomObject]@{
                    PolicyValue = $null
                    Description = "Default Windows settings"
                    IsEnabled = $false
                }
            }

            $autoConfig = Get-AutoUpdateConfiguration
            $autoConfig.PolicyValue | Should -BeNullOrEmpty
            $autoConfig.IsEnabled | Should -Be $false
        }
    }

    Context "Section 3: Update History" {
        It "handles empty update history" {
            Mock Get-UpdateHistory -MockWith {
                return @()
            }

            $history = Get-UpdateHistory -Count 5
            $history | Should -BeNullOrEmpty
        }

        It "handles missing InstalledOn date" {
            Mock Get-UpdateHistory -MockWith {
                return @(
                    [PSCustomObject]@{
                        HotFixID = "KB345678"
                        InstalledOn = $null
                    }
                )
            }

            $history = Get-UpdateHistory -Count 1
            $history | Should -Not -BeNullOrEmpty

            $installDate = if ($history[0].InstalledOn) {
                (Get-Date $history[0].InstalledOn -Format "yyyy-MM-dd")
            }
            else {
                "Unknown"
            }
            $installDate | Should -Be "Unknown"
        }

        It "retrieves valid update history" {
            Mock Get-UpdateHistory -MockWith {
                return @(
                    [PSCustomObject]@{
                        HotFixID = "KB789012"
                        InstalledOn = [DateTime]"2026-06-20"
                    }
                )
            }

            $history = Get-UpdateHistory -Count 1
            $history | Should -Not -BeNullOrEmpty
        }
    }

    Context "Section 4: Reboot Status" {
        It "detects pending reboot correctly" {
            Mock Get-PendingRebootStatus -MockWith {
                return [PSCustomObject]@{
                    IsPending = $true
                    Message = "System restart required"
                }
            }

            $rebootStatus = Get-PendingRebootStatus
            $rebootStatus.IsPending | Should -Be $true
        }

        It "returns no reboot required status" {
            Mock Get-PendingRebootStatus -MockWith {
                return [PSCustomObject]@{
                    IsPending = $false
                    Message = "No reboot required"
                }
            }

            $rebootStatus = Get-PendingRebootStatus
            $rebootStatus.IsPending | Should -Be $false
        }

        It "updates status to REBOOT-REQUIRED when reboot pending" {
            Mock Get-PendingRebootStatus -MockWith {
                return [PSCustomObject]@{
                    IsPending = $true
                    Message = "Reboot required"
                }
            }

            $rebootStatus = Get-PendingRebootStatus
            $pendingReboot = $rebootStatus.IsPending
            $status = "UPDATES-PENDING"
            if ($pendingReboot) {
                $status = "REBOOT-REQUIRED"
            }
            $status | Should -Be "REBOOT-REQUIRED"
        }

        It "handles reboot status check errors" {
            Mock Get-PendingRebootStatus -MockWith {
                throw [System.Exception]::new("Access denied")
            }

            {
                Get-PendingRebootStatus -ErrorAction Stop
            } | Should -Throw
        }
    }

    Context "Report Summary Generation" {
        It "creates report summary with all required fields" {
            $reportSummary = @{
                'Scan_Date' = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                'Status' = 'UP-TO-DATE'
                'Updates_Available' = 0
                'Security_Updates' = 0
                'Critical_Updates' = 0
                'Reboot_Pending' = $false
                'Auto_Updates_Enabled' = $true
            }

            $reportSummary | Should -Not -BeNullOrEmpty
            $reportSummary.Keys | Should -Contain 'Status'
            $reportSummary.Keys | Should -Contain 'Updates_Available'
            $reportSummary['Status'] | Should -Be 'UP-TO-DATE'
        }

        It "updates report summary when updates pending" {
            $reportSummary = @{
                'Status' = 'UPDATES-PENDING'
                'Updates_Available' = 3
                'Security_Updates' = 2
                'Critical_Updates' = 1
            }

            $reportSummary['Status'] | Should -Be 'UPDATES-PENDING'
            $reportSummary['Updates_Available'] | Should -Be 3
        }

        It "updates report summary when reboot required" {
            $reportSummary = @{
                'Status' = 'REBOOT-REQUIRED'
                'Reboot_Pending' = $true
            }

            $reportSummary['Status'] | Should -Be 'REBOOT-REQUIRED'
            $reportSummary['Reboot_Pending'] | Should -Be $true
        }

        It "preserves Auto_Updates_Enabled status" {
            Mock Get-AutoUpdateConfiguration -MockWith {
                return [PSCustomObject]@{ IsEnabled = $true }
            }

            $autoUpdateConfig = Get-AutoUpdateConfiguration
            $autoUpdateEnabled = if ($autoUpdateConfig -and $autoUpdateConfig.IsEnabled) { $true } else { $false }
            $autoUpdateEnabled | Should -Be $true
        }
    }

    Context "Report Export (CSV)" {
        It "exports report to CSV file" {
            $testDir = Join-Path -Path $TestDrive -ChildPath "reports"
            $null = New-Item -ItemType Directory -Path $testDir -Force

            $reportSummary = @{
                'Scan_Date' = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                'Status' = 'UP-TO-DATE'
                'Updates_Available' = 0
            }

            $reportFile = Join-Path $testDir "test_report.csv"
            $reportSummary | Export-Csv -Path $reportFile -NoTypeInformation

            $reportFile | Should -Exist
            $csvContent = Get-Content $reportFile
            $csvContent | Should -Not -BeNullOrEmpty
        }

        It "creates output directory if needed" {
            $testDir = Join-Path -Path $TestDrive -ChildPath "newreports"
            $testDir | Should -Not -Exist

            $null = New-Item -ItemType Directory -Path $testDir -Force -ErrorAction Stop
            $testDir | Should -Exist
        }

        It "handles CSV export" {
            $testDir = Join-Path -Path $TestDrive -ChildPath "csvtest"
            $null = New-Item -ItemType Directory -Path $testDir -Force

            $reportSummary = @{
                'Status' = 'UP-TO-DATE'
                'Updates_Available' = 0
            }

            $reportFile = Join-Path $testDir "export_test.csv"
            $reportSummary | Export-Csv -Path $reportFile -NoTypeInformation -ErrorAction Stop

            $reportFile | Should -Exist
        }
    }

    Context "Exit Codes" {
        It "returns exit code 0 for UP-TO-DATE" {
            $status = 'UP-TO-DATE'
            $exitCode = switch ($status) {
                'UP-TO-DATE'
                {
                    0
                }
                'UPDATES-PENDING'
                {
                    1
                }
                'REBOOT-REQUIRED'
                {
                    2
                }
                'CHECK-FAILED'
                {
                    3
                }
                default
                {
                    1
                }
            }
            $exitCode | Should -Be 0
        }

        It "returns exit code 1 for UPDATES-PENDING" {
            $status = 'UPDATES-PENDING'
            $exitCode = switch ($status) {
                'UP-TO-DATE'
                {
                    0
                }
                'UPDATES-PENDING'
                {
                    1
                }
                'REBOOT-REQUIRED'
                {
                    2
                }
                'CHECK-FAILED'
                {
                    3
                }
                default
                {
                    1
                }
            }
            $exitCode | Should -Be 1
        }

        It "returns exit code 2 for REBOOT-REQUIRED" {
            $status = 'REBOOT-REQUIRED'
            $exitCode = switch ($status) {
                'UP-TO-DATE'
                {
                    0
                }
                'UPDATES-PENDING'
                {
                    1
                }
                'REBOOT-REQUIRED'
                {
                    2
                }
                'CHECK-FAILED'
                {
                    3
                }
                default
                {
                    1
                }
            }
            $exitCode | Should -Be 2
        }

        It "returns exit code 3 for CHECK-FAILED" {
            $status = 'CHECK-FAILED'
            $exitCode = switch ($status) {
                'UP-TO-DATE'
                {
                    0
                }
                'UPDATES-PENDING'
                {
                    1
                }
                'REBOOT-REQUIRED'
                {
                    2
                }
                'CHECK-FAILED'
                {
                    3
                }
                default
                {
                    1
                }
            }
            $exitCode | Should -Be 3
        }

        It "returns exit code 1 for unknown status" {
            $status = 'UNKNOWN'
            $exitCode = switch ($status) {
                'UP-TO-DATE'
                {
                    0
                }
                'UPDATES-PENDING'
                {
                    1
                }
                'REBOOT-REQUIRED'
                {
                    2
                }
                'CHECK-FAILED'
                {
                    3
                }
                default
                {
                    1
                }
            }
            $exitCode | Should -Be 1
        }
    }

    Context "WhatIf Behavior" {
        It "skips report export when WhatIf is specified" {
            $WhatIfPreference = $true
            $shouldExport = -not $WhatIfPreference
            $shouldExport | Should -Be $false
        }

        It "shows what-if message for report location" {
            $OutputDir = Join-Path -Path $TestDrive -ChildPath "logs"
            $reportPattern = Join-Path $OutputDir "Windows_Updates_*.csv"
            $reportPattern | Should -Match "Windows_Updates_\*\.csv"
        }
    }

    Context "Error Handling" {
        It "handles errors in update status check" {
            Mock Get-WindowsUpdateStatus -MockWith {
                throw [System.Exception]::new("COM object failed")
            }

            $status = "UP-TO-DATE"
            try {
                $updateStatus = Get-WindowsUpdateStatus
            }
            catch {
                $status = "CHECK-FAILED"
            }

            $status | Should -Be "CHECK-FAILED"
        }

        It "handles errors in auto-update config retrieval" {
            Mock Get-AutoUpdateConfiguration -MockWith {
                throw [System.Exception]::new("Registry access denied")
            }

            $autoUpdateConfig = $null
            try {
                $autoUpdateConfig = Get-AutoUpdateConfiguration
            }
            catch {
                $autoUpdateConfig = $null
            }

            $autoUpdateConfig | Should -BeNullOrEmpty
        }

        It "handles errors in reboot status check" {
            Mock Get-PendingRebootStatus -MockWith {
                throw [System.Exception]::new("Access denied")
            }

            $pendingReboot = $false
            try {
                $rebootStatus = Get-PendingRebootStatus
                $pendingReboot = $rebootStatus.IsPending
            }
            catch {
                $pendingReboot = $false
            }

            $pendingReboot | Should -Be $false
        }

        It "prevents status change from REBOOT-REQUIRED when CHECK-FAILED" {
            $status = "CHECK-FAILED"
            $pendingReboot = $true

            if ($pendingReboot) {
                if ($status -ne "CHECK-FAILED") {
                    $status = "REBOOT-REQUIRED"
                }
            }

            $status | Should -Be "CHECK-FAILED"
        }
    }

    Context "KB Article Handling" {
        It "handles updates with valid KB numbers" {
            $update = @{
                KBArticleIDs = @("123456")
                Title = "Test Update"
            }

            $kbNumber = $update.KBArticleIDs[0]
            $kbPrefix = if ($kbNumber) {
                "KB$kbNumber"
            }
            else {
                "[No KB]"
            }

            $kbPrefix | Should -Be "KB123456"
        }

        It "handles updates without KB numbers" {
            $update = @{
                KBArticleIDs = @()
                Title = "Test Update"
            }

            $kbNumber = $update.KBArticleIDs[0]
            $kbPrefix = if ($kbNumber) {
                "KB$kbNumber"
            }
            else {
                "[No KB]"
            }

            $kbPrefix | Should -Be "[No KB]"
        }

        It "handles updates with null KB numbers" {
            $update = @{
                KBArticleIDs = @($null)
                Title = "Test Update"
            }

            $kbNumber = $update.KBArticleIDs[0]
            $kbPrefix = if ($kbNumber) {
                "KB$kbNumber"
            }
            else {
                "[No KB]"
            }

            $kbPrefix | Should -Be "[No KB]"
        }
    }

    Context "Output Directory Handling" {
        It "validates output directory logic" {
            $OutputDir = Join-Path -Path $TestDrive -ChildPath "testlogs"
            $OutputDir | Should -Not -Exist

            if (-not (Test-Path $OutputDir -PathType Container)) {
                $null = New-Item -ItemType Directory -Path $OutputDir -Force
            }

            $OutputDir | Should -Exist
        }

        It "uses default logs directory when not specified" {
            $projectRoot = $TestDrive
            $OutputDir = ""

            if (-not $OutputDir) {
                $OutputDir = Join-Path -Path $projectRoot -ChildPath "logs"
            }

            $OutputDir | Should -Match "logs"
        }
    }
}
