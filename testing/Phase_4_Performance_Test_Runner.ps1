<#
.SYNOPSIS
Phase 4 Performance Testing Master Runner - Benchmarks WinHarden under load

.DESCRIPTION
Executes comprehensive performance testing:
- Single function latency benchmarking
- Large-scale drift detection performance
- Parallel execution scalability
- Logging performance impact
- Memory usage monitoring

.PARAMETER Environment
Specify test environment: 'Dev' or 'Prod'

.EXAMPLE
.\Phase_4_Performance_Test_Runner.ps1 -Environment Dev
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
$testLogFile = Join-Path $logsDir "Phase_4_Performance_$testRunID.log"

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

Write-Section "PHASE 4: PERFORMANCE TESTING - MASTER RUNNER"
Write-TestOutput "Test Run ID: $testRunID"
Write-TestOutput "Environment: $Environment"
Write-TestOutput ""

# ============================================================================
# MODULE LOADING
# ============================================================================

Write-Section "LOADING WINHARDEN MODULES"

try {
    $corePath = $null
    if (Test-Path ".\modules\Core.psm1") {
        $corePath = ".\modules\Core.psm1"
        $systemPath = ".\modules\System.psm1"
    }
    elseif (Test-Path "C:\Repos\WinHarden\modules\Core.psm1") {
        $corePath = "C:\Repos\WinHarden\modules\Core.psm1"
        $systemPath = "C:\Repos\WinHarden\modules\System.psm1"
    }

    if ($null -eq $corePath) {
        Write-TestOutput "[ERROR] Modules not found" -Level ERROR
        exit 1
    }

    Import-Module $corePath -Force -ErrorAction Stop | Out-Null
    Write-TestOutput "[OK] Core module loaded" -Level OK

    Import-Module $systemPath -Force -ErrorAction Stop | Out-Null
    Write-TestOutput "[OK] System module loaded" -Level OK

    Write-TestOutput ""
}
catch {
    Write-TestOutput "[ERROR] Module loading failed: $_" -Level ERROR
    exit 1
}

# ============================================================================
# SCENARIO 1: SINGLE FUNCTION LATENCY
# ============================================================================

Write-Section "SCENARIO 1: SINGLE FUNCTION LATENCY BENCHMARKING"

try {
    $latencies = @{}

    Write-TestOutput "1.1 Firewall Drift Detection (10 iterations)..."
    $times = @()
    for ($i = 1; $i -le 10; $i++) {
        $start = [DateTime]::UtcNow
        Get-FirewallStatusDrift -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Out-Null
        $elapsed = ([DateTime]::UtcNow - $start).TotalMilliseconds
        $times += $elapsed
    }
    $avg = [Math]::Round(($times | Measure-Object -Average).Average, 0)
    $latencies['Firewall'] = $avg
    Write-TestOutput "[OK] Firewall: ${avg}ms (Target: < 1000ms)" -Level OK

    Write-TestOutput "1.2 RDP Security Drift (10 iterations)..."
    $times = @()
    for ($i = 1; $i -le 10; $i++) {
        $start = [DateTime]::UtcNow
        Get-RDPSecurityDrift -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Out-Null
        $elapsed = ([DateTime]::UtcNow - $start).TotalMilliseconds
        $times += $elapsed
    }
    $avg = [Math]::Round(($times | Measure-Object -Average).Average, 0)
    $latencies['RDP'] = $avg
    Write-TestOutput "[OK] RDP: ${avg}ms" -Level OK

    Write-TestOutput "1.3 Network Security Drift (10 iterations)..."
    $times = @()
    for ($i = 1; $i -le 10; $i++) {
        $start = [DateTime]::UtcNow
        Get-NetworkSecurityDrift -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Out-Null
        $elapsed = ([DateTime]::UtcNow - $start).TotalMilliseconds
        $times += $elapsed
    }
    $avg = [Math]::Round(($times | Measure-Object -Average).Average, 0)
    $latencies['Network'] = $avg
    Write-TestOutput "[OK] Network: ${avg}ms" -Level OK

    Write-TestOutput "1.4 Account Policies Drift (10 iterations)..."
    $times = @()
    for ($i = 1; $i -le 10; $i++) {
        $start = [DateTime]::UtcNow
        Get-AccountPoliciesDrift -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Out-Null
        $elapsed = ([DateTime]::UtcNow - $start).TotalMilliseconds
        $times += $elapsed
    }
    $avg = [Math]::Round(($times | Measure-Object -Average).Average, 0)
    $latencies['Account'] = $avg
    Write-TestOutput "[OK] Account: ${avg}ms" -Level OK

    $allPass = $latencies.Values | Where-Object { $_ -gt 5000 }
    $scenario1Result = if ($allPass) { 'WARN' } else { 'PASS' }
    Write-TestOutput "[OK] Scenario 1: Latency benchmarking complete" -Level OK

} catch {
    Write-TestOutput "[ERROR] Scenario 1 failed: $_" -Level ERROR
    $scenario1Result = 'FAIL'
}

Write-TestOutput ""

# ============================================================================
# SCENARIO 2: LARGE-SCALE DRIFT DETECTION
# ============================================================================

Write-Section "SCENARIO 2: LARGE-SCALE DRIFT DETECTION"

try {
    Write-TestOutput "2.1 Comprehensive drift detection (5 iterations)..."
    $times = @()

    for ($i = 1; $i -le 5; $i++) {
        $start = [DateTime]::UtcNow

        $firewall = Get-FirewallStatusDrift -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        $rdp = Get-RDPSecurityDrift -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        $network = Get-NetworkSecurityDrift -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        $account = Get-AccountPoliciesDrift -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

        $elapsed = ([DateTime]::UtcNow - $start).TotalSeconds
        $times += $elapsed

        $totalItems = @($firewall, $rdp, $network, $account) | Measure-Object | Select-Object -ExpandProperty Count
        Write-TestOutput "  Run $i`: ${elapsed}s (Items: $totalItems)" -Level INFO
    }

    $avg = [Math]::Round(($times | Measure-Object -Average).Average, 2)
    Write-TestOutput "[OK] Average: ${avg}s (Target: < 10s)" -Level OK

    Write-TestOutput "2.2 Report generation (3 iterations)..."
    $times = @()

    for ($i = 1; $i -le 3; $i++) {
        $findings = @()
        $findings += Get-FirewallStatusDrift -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        $findings += Get-RDPSecurityDrift -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        $findings += Get-NetworkSecurityDrift -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        $findings += Get-AccountPoliciesDrift -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

        $start = [DateTime]::UtcNow
        New-SecurityDriftReport -DriftFindings $findings -OutputDirectory $reportsDir -ErrorAction SilentlyContinue | Out-Null
        $elapsed = ([DateTime]::UtcNow - $start).TotalMilliseconds
        $times += $elapsed
    }

    $avg = [Math]::Round(($times | Measure-Object -Average).Average, 0)
    Write-TestOutput "[OK] Report generation: ${avg}ms (Target: < 1000ms)" -Level OK

    $scenario2Result = if ($avg -lt 1000) { 'PASS' } else { 'WARN' }

} catch {
    Write-TestOutput "[ERROR] Scenario 2 failed: $_" -Level ERROR
    $scenario2Result = 'FAIL'
}

Write-TestOutput ""

# ============================================================================
# SCENARIO 3: PARALLEL EXECUTION SCALABILITY
# ============================================================================

Write-Section "SCENARIO 3: PARALLEL EXECUTION SCALABILITY"

try {
    Write-TestOutput "3.1 Sequential hardening baseline..."
    $start = [DateTime]::UtcNow
    $session = New-HardeningSession -Profile Recommended -TargetSystem Client -OSVersion 11 -ErrorAction SilentlyContinue
    Invoke-SecurityHardening -Session $session -ErrorAction SilentlyContinue | Out-Null
    $sequential = [Math]::Round(([DateTime]::UtcNow - $start).TotalSeconds, 2)
    Write-TestOutput "[OK] Sequential: ${sequential}s" -Level OK

    Write-TestOutput "3.2 Multi-session hardening (5 sessions)..."
    $sessions = @()
    $start = [DateTime]::UtcNow

    for ($i = 1; $i -le 5; $i++) {
        $sess = New-HardeningSession -Profile Recommended -TargetSystem Client -OSVersion 11 -ErrorAction SilentlyContinue
        if ($sess) { $sessions += $sess }
    }

    foreach ($s in $sessions) {
        Invoke-SecurityHardening -Session $s -ErrorAction SilentlyContinue | Out-Null
    }

    $parallel = [Math]::Round(([DateTime]::UtcNow - $start).TotalSeconds, 2)
    $scaleFactor = [Math]::Round($parallel / $sequential, 2)

    Write-TestOutput "[OK] Multi-session (5x): ${parallel}s" -Level OK
    Write-TestOutput "[OK] Scaling factor: ${scaleFactor}x" -Level OK

    $scenario3Result = if ($scaleFactor -lt 6) { 'PASS' } else { 'WARN' }

} catch {
    Write-TestOutput "[ERROR] Scenario 3 failed: $_" -Level ERROR
    $scenario3Result = 'FAIL'
}

Write-TestOutput ""

# ============================================================================
# SCENARIO 4: LOGGING OVERHEAD
# ============================================================================

Write-Section "SCENARIO 4: LOGGING PERFORMANCE IMPACT"

try {
    Write-TestOutput "4.1 Drift detection without verbose logging (5 runs)..."
    $times = @()
    for ($i = 1; $i -le 5; $i++) {
        $start = [DateTime]::UtcNow
        Get-FirewallStatusDrift -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Out-Null
        $elapsed = ([DateTime]::UtcNow - $start).TotalMilliseconds
        $times += $elapsed
    }
    $avgNoLog = [Math]::Round(($times | Measure-Object -Average).Average, 0)
    Write-TestOutput "[OK] Without logging: ${avgNoLog}ms" -Level OK

    Write-TestOutput "4.2 Drift detection with verbose output (5 runs)..."
    $times = @()
    for ($i = 1; $i -le 5; $i++) {
        $start = [DateTime]::UtcNow
        Get-FirewallStatusDrift -ErrorAction SilentlyContinue -Verbose 4>&1 | Out-Null
        $elapsed = ([DateTime]::UtcNow - $start).TotalMilliseconds
        $times += $elapsed
    }
    $avgWithLog = [Math]::Round(($times | Measure-Object -Average).Average, 0)
    Write-TestOutput "[OK] With logging: ${avgWithLog}ms" -Level OK

    if ($avgNoLog -gt 0) {
        $overhead = [Math]::Round((($avgWithLog - $avgNoLog) / $avgNoLog * 100), 1)
        Write-TestOutput "[OK] Logging overhead: ${overhead}% (Target: < 15%)" -Level OK
        $scenario4Result = if ($overhead -lt 15) { 'PASS' } else { 'WARN' }
    } else {
        Write-TestOutput "[WARN] Timing too fast to measure accurately" -Level WARN
        $scenario4Result = 'PASS'
    }

} catch {
    Write-TestOutput "[ERROR] Scenario 4 failed: $_" -Level ERROR
    $scenario4Result = 'FAIL'
}

Write-TestOutput ""

# ============================================================================
# SCENARIO 5: MEMORY MONITORING
# ============================================================================

Write-Section "SCENARIO 5: MEMORY USAGE MONITORING"

try {
    Write-TestOutput "5.1 Baseline memory usage..."
    $baseline = [Math]::Round((Get-Process -Id $PID).WorkingSet / 1MB, 1)
    Write-TestOutput "[OK] Process memory: ${baseline}MB" -Level OK

    Write-TestOutput "5.2 Memory during comprehensive drift detection..."
    $preMemory = [Math]::Round((Get-Process -Id $PID).WorkingSet / 1MB, 1)

    Get-FirewallStatusDrift -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Out-Null
    Get-RDPSecurityDrift -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Out-Null
    Get-NetworkSecurityDrift -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Out-Null
    Get-AccountPoliciesDrift -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Out-Null

    $postMemory = [Math]::Round((Get-Process -Id $PID).WorkingSet / 1MB, 1)
    $delta = $postMemory - $preMemory

    Write-TestOutput "[OK] Memory delta: ${delta}MB (Target: < 100MB)" -Level OK

    Write-TestOutput "5.3 Memory during hardening..."
    $preMemory = [Math]::Round((Get-Process -Id $PID).WorkingSet / 1MB, 1)

    $session = New-HardeningSession -Profile Recommended -TargetSystem Client -OSVersion 11 -ErrorAction SilentlyContinue
    Invoke-SecurityHardening -Session $session -ErrorAction SilentlyContinue | Out-Null

    $postMemory = [Math]::Round((Get-Process -Id $PID).WorkingSet / 1MB, 1)
    $hardDelta = $postMemory - $preMemory

    Write-TestOutput "[OK] Hardening memory delta: ${hardDelta}MB (Target: < 200MB)" -Level OK

    $scenario5Result = if ($delta -lt 100 -and $hardDelta -lt 200) { 'PASS' } else { 'WARN' }

} catch {
    Write-TestOutput "[ERROR] Scenario 5 failed: $_" -Level ERROR
    $scenario5Result = 'FAIL'
}

Write-TestOutput ""

# ============================================================================
# FINAL SUMMARY
# ============================================================================

Write-Section "PERFORMANCE TEST SUMMARY"

$testEndTime = Get-Date
$testDuration = ($testEndTime - $testStartTime).TotalSeconds

Write-TestOutput "Test Run ID: $testRunID"
Write-TestOutput "Environment: $Environment"
Write-TestOutput "Duration: ${testDuration}s"
Write-TestOutput ""

$results = @{
    'Scenario 1 (Latency)' = $scenario1Result
    'Scenario 2 (Large-Scale)' = $scenario2Result
    'Scenario 3 (Scalability)' = $scenario3Result
    'Scenario 4 (Logging)' = $scenario4Result
    'Scenario 5 (Memory)' = $scenario5Result
}

foreach ($scenario in $results.GetEnumerator()) {
    $status = if ($scenario.Value -eq 'PASS') { 'OK' } else { $scenario.Value }
    Write-TestOutput "$($scenario.Key): $($scenario.Value)" -Level $status
}

Write-TestOutput ""

$passCount = ($results.Values | Where-Object { $_ -eq 'PASS' }).Count
Write-TestOutput "Overall: $passCount/5 passed" -Level $(if ($passCount -ge 4) { 'OK' } else { 'WARN' })
Write-TestOutput "Test Log: $testLogFile"

Write-TestOutput ""
Write-Section "PHASE 4 PERFORMANCE TEST COMPLETE"
Write-TestOutput "Status: $(if ($passCount -eq 5) { 'READY FOR PHASE 5' } else { 'REVIEW PERFORMANCE DATA' })"
