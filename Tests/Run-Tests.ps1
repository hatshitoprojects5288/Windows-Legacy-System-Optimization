# Test Runner Configuration
# Tests/Run-Tests.ps1
#
# This script runs all tests (unit, integration, regression) and generates a report.

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('All', 'Unit', 'Integration', 'Regression')]
    [string]$TestType = 'All',
    
    [Parameter(Mandatory=$false)]
    [switch]$Verbose,
    
    [Parameter(Mandatory=$false)]
    [switch]$ExitOnFailure
)

# =============================================================================
# CONFIGURATION
# =============================================================================

$TestsRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $TestsRoot

$TestDirectories = @{
    'Unit'        = Join-Path $TestsRoot "Unit-Tests"
    'Integration' = Join-Path $TestsRoot "Integration-Tests"
    'Regression'  = Join-Path $TestsRoot "Regression-Tests"
}

# =============================================================================
# FUNCTIONS
# =============================================================================

function Initialize-TestEnvironment {
    Write-Host "Initializing test environment..." -ForegroundColor Cyan
    
    # Check if Pester is installed
    if (-not (Get-Module -Name Pester -ListAvailable)) {
        Write-Host "Installing Pester module..." -ForegroundColor Yellow
        Install-Module -Name Pester -Force -SkipPublisherCheck
    }
    
    # Import Pester
    Import-Module -Name Pester -RequiredVersion 5.0 -ErrorAction SilentlyContinue
    
    Write-Host "Test environment initialized" -ForegroundColor Green
}

function Run-TestSuite {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TestName,
        
        [Parameter(Mandatory=$true)]
        [string]$TestDirectory
    )
    
    Write-Host "`n" -ForegroundColor Cyan
    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║ Running $TestName Tests" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    
    if (-not (Test-Path $TestDirectory)) {
        Write-Host "Test directory not found: $TestDirectory" -ForegroundColor Yellow
        return @{ 'Failed' = 0; 'Passed' = 0; 'Skipped' = 0 }
    }
    
    $testFiles = Get-ChildItem -Path $TestDirectory -Filter "*.Tests.ps1" -Recurse
    
    if ($testFiles.Count -eq 0) {
        Write-Host "No test files found in $TestDirectory" -ForegroundColor Yellow
        return @{ 'Failed' = 0; 'Passed' = 0; 'Skipped' = 0 }
    }
    
    $results = @{
        'Failed'  = 0
        'Passed'  = 0
        'Skipped' = 0
        'Errors'  = @()
    }
    
    foreach ($testFile in $testFiles) {
        Write-Host "`nRunning: $($testFile.Name)" -ForegroundColor Yellow
        
        try {
            $pesterParams = @{
                'Path'       = $testFile.FullName
                'PassThru'   = $true
                'ErrorAction' = 'Continue'
            }
            
            if ($Verbose) {
                $pesterParams['Verbose'] = $true
            }
            
            $testResult = Invoke-Pester @pesterParams
            
            $results['Passed']  += $testResult.PassedCount
            $results['Failed']  += $testResult.FailedCount
            $results['Skipped'] += $testResult.SkippedCount
            
            if ($testResult.FailedCount -gt 0) {
                $results['Errors'] += $testResult.FailedBlocksFailed
            }
        }
        catch {
            Write-Host "Error running test file: $_" -ForegroundColor Red
            $results['Errors'] += $_
            $results['Failed']++
        }
    }
    
    return $results
}

function Print-TestReport {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$AllResults
    )
    
    Write-Host "`n" -ForegroundColor Cyan
    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║ TEST EXECUTION SUMMARY" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    
    $totalPassed = ($AllResults.Values | Measure-Object -Property 'Passed' -Sum).Sum
    $totalFailed = ($AllResults.Values | Measure-Object -Property 'Failed' -Sum).Sum
    $totalSkipped = ($AllResults.Values | Measure-Object -Property 'Skipped' -Sum).Sum
    
    Write-Host "`nBy Test Suite:"
    Write-Host "─────────────────────────────────────────────────────────────────"
    
    foreach ($suiteName in $AllResults.Keys | Sort-Object) {
        $suite = $AllResults[$suiteName]
        
        $passColor = if ($suite['Passed'] -gt 0) { 'Green' } else { 'Yellow' }
        $failColor = if ($suite['Failed'] -gt 0) { 'Red' } else { 'Green' }
        
        Write-Host "$($suiteName -ljust 15) | " -NoNewline
        Write-Host "✓ $($suite['Passed'])" -ForegroundColor $passColor -NoNewline
        Write-Host " | " -NoNewline
        Write-Host "✗ $($suite['Failed'])" -ForegroundColor $failColor -NoNewline
        Write-Host " | " -NoNewline
        Write-Host "⊘ $($suite['Skipped'])" -ForegroundColor Yellow
    }
    
    Write-Host "`nTotal Results:"
    Write-Host "─────────────────────────────────────────────────────────────────"
    Write-Host "Passed:  " -NoNewline
    Write-Host $totalPassed -ForegroundColor Green
    Write-Host "Failed:  " -NoNewline
    Write-Host $totalFailed -ForegroundColor $(if ($totalFailed -gt 0) { 'Red' } else { 'Green' })
    Write-Host "Skipped: " -NoNewline
    Write-Host $totalSkipped -ForegroundColor Yellow
    
    Write-Host "`nOverall Status: " -NoNewline
    if ($totalFailed -eq 0) {
        Write-Host "✓ PASSED" -ForegroundColor Green
    }
    else {
        Write-Host "✗ FAILED" -ForegroundColor Red
    }
    
    Write-Host "`n"
    
    return ($totalFailed -eq 0)
}

# =============================================================================
# MAIN
# =============================================================================

Write-Host "Windows Optimization - Test Runner" -ForegroundColor Cyan
Write-Host "Test Type: $TestType`n" -ForegroundColor Yellow

# Initialize environment
Initialize-TestEnvironment

# Run tests based on selection
$allResults = @{}

if ($TestType -in 'All', 'Unit') {
    $allResults['Unit'] = Run-TestSuite -TestName "Unit" -TestDirectory $TestDirectories['Unit']
}

if ($TestType -in 'All', 'Integration') {
    $allResults['Integration'] = Run-TestSuite -TestName "Integration" -TestDirectory $TestDirectories['Integration']
}

if ($TestType -in 'All', 'Regression') {
    $allResults['Regression'] = Run-TestSuite -TestName "Regression" -TestDirectory $TestDirectories['Regression']
}

# Generate report
$allTestsPassed = Print-TestReport -AllResults $allResults

# Exit with appropriate code
if ($ExitOnFailure -and -not $allTestsPassed) {
    exit 1
}

exit 0
