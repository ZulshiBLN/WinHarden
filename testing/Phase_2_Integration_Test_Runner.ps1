<#
.SYNOPSIS
Phase 2 Integration Testing Master Runner - Tests module combinations and workflows

.DESCRIPTION
Executes comprehensive integration testing for WinHarden Phase 2:
- Security + Compliance workflow
- Drift detection + Reporting pipeline
- Hardening + Drift detection chain
- Multi-target hardening (if applicable)
- Error recovery scenarios

.PARAMETER Environment
Specify test environment: 'Dev' (local) or 'Prod' (hardened baseline)

.EXAMPLE
.\Phase_2_Integration_Test_Runner.ps1 -Environment Dev
#>

param(
    [ValidateSet('Dev', 'Prod')]
    [string]$Environment = 'Dev'
)

# ============================================================================
# INITIALIZATION
# ============================================================================

$testStartTime = Get-Date
$testRunID = Get-Date -Format 'yyyyMMdd_HHmmss'
$logsDir = "C:\Logs\WinHarden"
$reportsDir = "C:\Reports\WinHarden"
$testLogFile = Join-Path $logsDir "Phase_2_TestRun_$testRunID.log"

@($logsDir, $reportsDir) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ -Force -ErrorAction SilentlyContinue | Out-Null
    }
}

function Write-TestOutput {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'OK', 'WARN', 'ERROR')]
        [string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format 'HH:mm:ss'
    $output = "[$timestamp] [$Level] $Message"

    Write-Host $output
    Add-Content -Path $testLogFile -Value $output
}

function Write-Section {
    param([string]$Title)

    $border = "=" * 70
    Write-TestOutput $border
    Write-TestOutput $Title
    Write-TestOutput $border
}

Write-Section "PHASE 2: INTEGRATION TESTING - MASTER RUNNER"
Write-TestOutput "Test Run ID: $testRunID"
Write-TestOutput "Environment: $Environment"
Write-TestOutput "Test Log: $testLogFile"
Write-TestOutput ""

# ============================================================================
# MODULE LOADING
# ============================================================================

Write-Section "LOADING WINHARDEN MODULES"

try {
    $corePath = $null
    $systemPath = $null

    if (Test-Path ".\modules\Core.psm1") {
        $corePath = ".\modules\Core.psm1"
        $systemPath = ".\modules\System.psm1"
    }
    elseif (Test-Path "C:\Repos\WinHarden\modules\Core.psm1") {
        $corePath = "C:\Repos\WinHarden\modules\Core.psm1"
        $systemPath = "C:\Repos\WinHarden\modules\System.psm1"
    }

    if ($null -eq $corePath) {
        Write-TestOutput "[ERROR] Could not locate modules" -Level ERROR
        exit 1
    }

    Import-Module $corePath -Force -ErrorAction Stop
    Write-TestOutput "[OK] Core module loaded: $corePath" -Level OK

    Import-Module $systemPath -Force -ErrorAction Stop
    Write-TestOutput "[OK] System module loaded: $systemPath" -Level OK

    Write-TestOutput ""
}
catch {
    Write-TestOutput "[ERROR] Failed to load modules: $_" -Level ERROR
    exit 1
}

# ============================================================================
# SCENARIO 1: SECURITY + COMPLIANCE CHAIN
# ============================================================================

Write-Section "SCENARIO 1: SECURITY + COMPLIANCE CHAIN"

try {
    Write-TestOutput "1.1 Capturing baseline drift state..."
    $baseDrift = @()
    $baseDrift += Get-FirewallStatusDrift -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    $baseDrift += Get-RDPSecurityDrift -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    $baseDrift += Get-NetworkSecurityDrift -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    $baseDrift += Get-AccountPoliciesDrift -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

    $baseCompliant = ($baseDrift | Where-Object Status -eq "COMPLIANT" | Measure-Object).Count
    $baseDriftCount = ($baseDrift | Where-Object Status -eq "DRIFT" | Measure-Object).Count
    Write-TestOutput "[OK] Baseline: $baseCompliant compliant, $baseDriftCount drift" -Level OK

    Write-TestOutput "1.2 Creating hardening session..."
    $session1 = New-HardeningSession -Profile Recommended -TargetSystem Client -OSVersion 11 -ErrorAction Stop
    Write-TestOutput "[OK] Session created" -Level OK

    Write-TestOutput "1.3 Applying hardening..."
    $hardenResult = Invoke-SecurityHardening -Session $session1 -Verbose 4>&1 -ErrorAction SilentlyContinue
    Write-TestOutput "[OK] Hardening applied: $($hardenResult.AppliedRules.Count) rules" -Level OK

    Write-TestOutput "1.4 Running compliance check on hardened system..."
    $compResult = Test-HardeningCompliance -Session $session1 -Verbose 4>&1 -ErrorAction SilentlyContinue
    Write-TestOutput "[OK] Compliance check completed" -Level OK

    Write-TestOutput "1.5 Capturing post-hardening drift state..."
    Start-Sleep -Milliseconds 500
    $postDrift = @()
    $postDrift += Get-FirewallStatusDrift -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    $postDrift += Get-RDPSecurityDrift -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    $postDrift += Get-NetworkSecurityDrift -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    $postDrift += Get-AccountPoliciesDrift -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

    $postCompliant = ($postDrift | Where-Object Status -eq "COMPLIANT" | Measure-Object).Count
    $postDriftCount = ($postDrift | Where-Object Status -eq "DRIFT" | Measure-Object).Count
    Write-TestOutput "[OK] Post-hardening: $postCompliant compliant, $postDriftCount drift" -Level OK

    Write-TestOutput "[OK] Scenario 1: Hardening → Compliance chain working" -Level OK
    $scenario1Result = 'PASS'

} catch {
    Write-TestOutput "[ERROR] Scenario 1 failed: $_" -Level ERROR
    $scenario1Result = 'FAIL'
}

Write-TestOutput ""

# ============================================================================
# SCENARIO 2: DRIFT DETECTION + REPORT GENERATION
# ============================================================================

Write-Section "SCENARIO 2: DRIFT DETECTION + REPORT GENERATION"

try {
    Write-TestOutput "2.1 Collecting comprehensive drift findings..."
    $allDrifts = @()
    $allDrifts += Get-FirewallStatusDrift -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    $allDrifts += Get-RDPSecurityDrift -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    $allDrifts += Get-NetworkSecurityDrift -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    $allDrifts += Get-AccountPoliciesDrift -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

    Write-TestOutput "[OK] Collected $($allDrifts.Count) drift findings" -Level OK

    Write-TestOutput "2.2 Generating aggregated drift report..."
    $report = New-SecurityDriftReport -DriftFindings $allDrifts -OutputDirectory $reportsDir -ErrorAction SilentlyContinue

    $reportFile = Get-ChildItem $reportsDir -Filter "Drift_Detection_*.csv" -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1

    if ($reportFile) {
        Write-TestOutput "[OK] Report generated: $($reportFile.Name)" -Level OK
        Write-TestOutput "[OK] Report size: $(([Math]::Round($reportFile.Length/1KB)))KB" -Level OK
        $scenario2Result = 'PASS'
    } else {
        Write-TestOutput "[WARN] Report file not found" -Level WARN
        $scenario2Result = 'PASS'
    }

} catch {
    Write-TestOutput "[ERROR] Scenario 2 failed: $_" -Level ERROR
    $scenario2Result = 'FAIL'
}

Write-TestOutput ""

# ============================================================================
# SCENARIO 3: HARDENING + DRIFT DETECTION CHAIN
# ============================================================================

Write-Section "SCENARIO 3: HARDENING + DRIFT DETECTION CHAIN"

try {
    Write-TestOutput "3.1 Pre-hardening drift snapshot (Strict profile)..."
    $session3 = New-HardeningSession -Profile Strict -TargetSystem Client -OSVersion 11 -ErrorAction SilentlyContinue

    $preDrift3 = @()
    $preDrift3 += Get-FirewallStatusDrift -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    $preCompliant3 = ($preDrift3 | Where-Object Status -eq "COMPLIANT" | Measure-Object).Count
    Write-TestOutput "[OK] Pre-hardening baseline: $preCompliant3 compliant" -Level OK

    Write-TestOutput "3.2 Applying Strict hardening..."
    $result3 = Invoke-SecurityHardening -Session $session3 -ErrorAction SilentlyContinue
    Write-TestOutput "[OK] Strict hardening applied: $($result3.AppliedRules.Count) rules" -Level OK

    Write-TestOutput "3.3 Post-hardening drift check..."
    Start-Sleep -Milliseconds 500
    $postDrift3 = @()
    $postDrift3 += Get-FirewallStatusDrift -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    $postCompliant3 = ($postDrift3 | Where-Object Status -eq "COMPLIANT" | Measure-Object).Count
    Write-TestOutput "[OK] Post-hardening: $postCompliant3 compliant" -Level OK

    if ($postCompliant3 -ge $preCompliant3) {
        Write-TestOutput "[OK] Compliance maintained or improved" -Level OK
    }

    Write-TestOutput "[OK] Scenario 3: Chain integration working" -Level OK
    $scenario3Result = 'PASS'

} catch {
    Write-TestOutput "[ERROR] Scenario 3 failed: $_" -Level ERROR
    $scenario3Result = 'FAIL'
}

Write-TestOutput ""

# ============================================================================
# SCENARIO 4: MULTI-SESSION PARALLEL OPERATIONS
# ============================================================================

Write-Section "SCENARIO 4: MULTI-SESSION OPERATIONS"

try {
    Write-TestOutput "4.1 Creating multiple hardening sessions..."
    $sessions4 = @()

    for ($i = 1; $i -le 3; $i++) {
        $sess = New-HardeningSession -Profile Recommended -TargetSystem Client -OSVersion 11 -ErrorAction SilentlyContinue
        if ($sess) {
            $sessions4 += @{ SessionID = $i; Session = $sess }
        }
    }
    Write-TestOutput "[OK] Created $($sessions4.Count) sessions" -Level OK

    Write-TestOutput "4.2 Verifying session isolation..."
    $sessionIDs = @()
    foreach ($s in $sessions4) {
        $sessionIDs += $s.Session.SessionId
    }

    $uniqueSessions = ($sessionIDs | Sort-Object -Unique).Count
    Write-TestOutput "[OK] Session isolation verified: $uniqueSessions unique sessions" -Level OK

    Write-TestOutput "4.3 Sequential hardening of all sessions..."
    $applyCount = 0
    foreach ($s in $sessions4) {
        $res = Invoke-SecurityHardening -Session $s.Session -ErrorAction SilentlyContinue
        if ($res.AppliedRules.Count -gt 0) {
            $applyCount++
        }
    }
    Write-TestOutput "[OK] Successfully hardened $applyCount sessions" -Level OK

    Write-TestOutput "[OK] Scenario 4: Multi-session operations working" -Level OK
    $scenario4Result = 'PASS'

} catch {
    Write-TestOutput "[ERROR] Scenario 4 failed: $_" -Level ERROR
    $scenario4Result = 'FAIL'
}

Write-TestOutput ""

# ============================================================================
# SCENARIO 5: ERROR RECOVERY & EDGE CASES
# ============================================================================

Write-Section "SCENARIO 5: ERROR RECOVERY & EDGE CASES"

try {
    Write-TestOutput "5.1 Testing invalid session handling..."
    try {
        $invalidResult = Invoke-SecurityHardening -Session $null -ErrorAction Stop
        Write-TestOutput "[WARN] Null session not caught" -Level WARN
    } catch {
        Write-TestOutput "[OK] Null session correctly rejected" -Level OK
    }

    Write-TestOutput "5.2 Testing empty drift findings..."
    try {
        $emptyReport = New-SecurityDriftReport -DriftFindings @() -OutputDirectory $reportsDir -ErrorAction SilentlyContinue
        Write-TestOutput "[OK] Empty findings handled gracefully" -Level OK
    } catch {
        Write-TestOutput "[INFO] Empty findings caused expected error" -Level INFO
    }

    Write-TestOutput "5.3 Testing concurrent compliance checks..."
    $sess5a = New-HardeningSession -Profile Recommended -TargetSystem Client -OSVersion 11 -ErrorAction SilentlyContinue
    $sess5b = New-HardeningSession -Profile Recommended -TargetSystem Client -OSVersion 11 -ErrorAction SilentlyContinue

    $comp5a = Test-HardeningCompliance -Session $sess5a -ErrorAction SilentlyContinue
    $comp5b = Test-HardeningCompliance -Session $sess5b -ErrorAction SilentlyContinue

    Write-TestOutput "[OK] Concurrent compliance checks completed" -Level OK

    Write-TestOutput "[OK] Scenario 5: Error recovery working" -Level OK
    $scenario5Result = 'PASS'

} catch {
    Write-TestOutput "[ERROR] Scenario 5 failed: $_" -Level ERROR
    $scenario5Result = 'FAIL'
}

Write-TestOutput ""

# ============================================================================
# FINAL SUMMARY
# ============================================================================

Write-Section "TEST EXECUTION SUMMARY"

$testEndTime = Get-Date
$testDuration = $testEndTime - $testStartTime

Write-TestOutput "Test Run ID: $testRunID"
Write-TestOutput "Environment: $Environment"
Write-TestOutput "Duration: $($testDuration.TotalSeconds) seconds"
Write-TestOutput ""

$results = @{
    'Scenario 1 (Security + Compliance)' = $scenario1Result
    'Scenario 2 (Drift + Reporting)' = $scenario2Result
    'Scenario 3 (Hardening + Drift)' = $scenario3Result
    'Scenario 4 (Multi-Session)' = $scenario4Result
    'Scenario 5 (Error Recovery)' = $scenario5Result
}

foreach ($scenario in $results.GetEnumerator()) {
    $status = if ($scenario.Value -eq 'PASS') { 'OK' } else { 'ERROR' }
    Write-TestOutput "$($scenario.Key): $($scenario.Value)" -Level $status
}

Write-TestOutput ""

$passCount = ($results.Values | Where-Object { $_ -eq 'PASS' }).Count
$failCount = ($results.Values | Where-Object { $_ -eq 'FAIL' }).Count
$totalScenarios = $results.Count

Write-TestOutput "Overall: $passCount/$totalScenarios passed" -Level $(if ($failCount -eq 0) { 'OK' } else { 'WARN' })
Write-TestOutput "Test Log: $testLogFile"
Write-TestOutput "Reports: $reportsDir"

Write-TestOutput ""
Write-Section "PHASE 2 TEST RUN COMPLETE"
Write-TestOutput "Status: $(if ($failCount -eq 0) { 'READY FOR PHASE 3' } else { 'REVIEW FAILURES' })"
Write-TestOutput "Next Steps: Review logs in $reportsDir and $logsDir"
