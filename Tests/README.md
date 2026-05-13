# Testing Framework Documentation

## Overview

The Windows-Legacy-System-Optimization project uses **Pester 5.0+** for comprehensive testing. This framework ensures production-ready code quality through:

- **Unit Tests**: Test individual utility modules in isolation
- **Integration Tests**: Test end-to-end workflows
- **Regression Tests**: Verify rollback procedures work correctly

---

## Directory Structure

```
Tests/
├── Unit-Tests/                  # Unit test files (.Tests.ps1)
│   ├── Logging.Tests.ps1
│   ├── Registry-Operations.Tests.ps1
│   ├── Validation.Tests.ps1
│   └── Backup-Management.Tests.ps1
├── Integration-Tests/           # Integration test files
│   └── Integration.Tests.ps1
├── Regression-Tests/            # Regression test files
│   └── Regression.Tests.ps1
├── Run-Tests.ps1                # Master test runner script
└── README.md                    # This file
```

---

## Quick Start

### Prerequisites

```powershell
# Install Pester (if not already installed)
Install-Module -Name Pester -Force -SkipPublisherCheck

# Verify installation
Get-Module -Name Pester -ListAvailable
```

### Running Tests

**Run all tests:**
```powershell
cd Tests
.\Run-Tests.ps1
```

**Run specific test type:**
```powershell
.\Run-Tests.ps1 -TestType Unit        # Unit tests only
.\Run-Tests.ps1 -TestType Integration # Integration tests only
.\Run-Tests.ps1 -TestType Regression  # Regression tests only
```

**Run with verbose output:**
```powershell
.\Run-Tests.ps1 -Verbose
```

**Run and exit with error code if tests fail:**
```powershell
.\Run-Tests.ps1 -ExitOnFailure
```

### Individual Test Files

**Run a specific test file:**
```powershell
Invoke-Pester -Path "Unit-Tests\Logging.Tests.ps1"
```

**Run tests matching a pattern:**
```powershell
Invoke-Pester -Path "Unit-Tests\*.Tests.ps1" -Filter "*Logging*"
```

---

## Test Categories

### Unit Tests

Test individual functions in isolation with mocked dependencies.

**Files:**
- `Logging.Tests.ps1` — Tests centralized logging framework
- `Registry-Operations.Tests.ps1` — Tests safe registry editing
- `Validation.Tests.ps1` — Tests system validation functions
- `Backup-Management.Tests.ps1` — Tests backup/restore functionality

**Running:**
```powershell
.\Run-Tests.ps1 -TestType Unit
```

**Expected Coverage:**
- ✅ Function initialization
- ✅ Parameter validation
- ✅ Error handling
- ✅ Return value correctness
- ✅ Edge cases

### Integration Tests

Test complete workflows end-to-end on actual systems.

**Files:**
- `Integration.Tests.ps1` — Full optimization workflow testing

**Running:**
```powershell
.\Run-Tests.ps1 -TestType Integration
```

**Expected Coverage:**
- ✅ Module loading
- ✅ System validation flow
- ✅ Logging + backup coordination
- ✅ Registry operations sequence
- ✅ Complete optimization cycle

**Prerequisites:**
- Administrator privileges recommended
- Sufficient disk space (500MB+)
- 5-10 minutes execution time

### Regression Tests

Ensure rollback procedures work correctly.

**Files:**
- `Regression.Tests.ps1` — Rollback verification

**Running:**
```powershell
.\Run-Tests.ps1 -TestType Regression
```

**Expected Coverage:**
- ✅ Snapshot creation/restoration
- ✅ Backup file integrity
- ✅ Metadata consistency
- ✅ State management
- ✅ Full cycle: apply → rollback → verify

---

## Test Results Interpretation

### Success Output

```
╔════════════════════════════════════════════════════════════════╗
║ TEST EXECUTION SUMMARY                                         ║
╚════════════════════════════════════════════════════════════════╝

By Test Suite:
───────────────────────────────────────────────────────────────
Unit            | ✓ 45 | ✗ 0 | ⊘ 0
Integration     | ✓ 12 | ✗ 0 | ⊘ 0
Regression      | ✓ 8  | ✗ 0 | ⊘ 0

Total Results:
───────────────────────────────────────────────────────────────
Passed:  65
Failed:  0
Skipped: 0

Overall Status: ✓ PASSED
```

### Failure Output

```
✗ FAILED
Failed test: Logging.Tests.ps1 - Initialize-Logging creates log file
Error: Expected $true, but got $false

Details:
  Context: "Initialization with Default Path"
  It: "Creates log file in temp directory"
  Expected: Test-Path should return $true
  Actual: Test-Path returned $false
```

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| `Module not found` | Incorrect import path | Verify module file exists in Utils/ |
| `Access Denied` | Registry access restrictions | Run as Administrator |
| `Timeout` | Long-running operations | Increase Pester timeout or run manually |
| `Skipped tests` | Missing dependencies | Install required modules |

---

## Writing New Tests

### Test File Structure

```powershell
# Tests/{Category}/{TestName}.Tests.ps1

BeforeAll {
    # Import modules needed for tests
    $ModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) "..\Scripts\Utils\MyModule.ps1"
    Import-Module $ModulePath -Force
}

AfterAll {
    # Cleanup
    Remove-Module MyModule -ErrorAction SilentlyContinue
}

Describe "Module Name - Function Name" {
    BeforeEach {
        # Setup before each test
        Initialize-Logging -LogPath (Join-Path $TestDrive "test.log")
    }
    
    AfterEach {
        # Cleanup after each test
        Close-Logging
    }
    
    Context "Test Category" {
        It "Tests specific behavior" {
            # Arrange
            $input = "test"
            
            # Act
            $result = Invoke-Function -Parameter $input
            
            # Assert
            $result | Should -Be "expected"
        }
    }
}
```

### Test Naming Conventions

- **Describe block**: `"Module Name - Function Name"`
- **Context block**: Logical grouping (e.g., "Error Handling", "Valid Input")
- **It block**: Clear description of what is tested

```powershell
Describe "Logging Module - Write-LogMessage" {
    Context "Valid Parameters" {
        It "Writes message to log file with correct format"
        It "Returns success status"
    }
    
    Context "Invalid Parameters" {
        It "Throws error for invalid log level"
        It "Handles null message gracefully"
    }
}
```

### Assertions

Common Pester assertions:

```powershell
# Equality
$result | Should -Be $expected
$result | Should -Not -Be $expected

# Type checking
$result | Should -BeOfType [string]
$result | Should -BeNull
$result | Should -Not -BeNullOrEmpty

# String matching
$result | Should -Match "pattern"
$result | Should -MatchExactly "exact string"
$result | Should -Like "wild*card"

# Collections
$result | Should -Contain "item"
$result.Count | Should -BeGreaterThan 0
$result | Should -HaveCount 5

# Exceptions
{ Function-That-Throws } | Should -Throw
{ Function-That-Throws } | Should -Throw -ExceptionType [System.Exception]
```

---

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run Tests
        run: |
          cd Tests
          .\Run-Tests.ps1 -TestType All -ExitOnFailure
```

### Local Pre-Commit Hook

```bash
#!/bin/bash
# .git/hooks/pre-commit

cd Tests
powershell -ExecutionPolicy Bypass -File ".\Run-Tests.ps1" -TestType Unit -ExitOnFailure

if [ $? -ne 0 ]; then
    echo "Unit tests failed. Commit aborted."
    exit 1
fi
```

---

## Best Practices

### Writing Effective Tests

1. **One assertion per test** (when possible)
   ```powershell
   # ✅ Good: Clear, focused
   It "Returns success status" {
       $result | Should -Be $true
   }
   
   # ❌ Avoid: Multiple assertions
   It "Returns correct data" {
       $result | Should -Not -BeNull
       $result.Count | Should -Be 5
       $result[0] | Should -Be "item"
   }
   ```

2. **Use descriptive test names**
   ```powershell
   # ✅ Good: Clear intent
   It "Throws error when path is null"
   
   # ❌ Vague: Unclear
   It "Tests null handling"
   ```

3. **Organize with Describe/Context/It**
   ```powershell
   Describe "Function" {          # What is being tested
       Context "Scenario" {        # Under what conditions
           It "Expected result" {  # What should happen
   ```

4. **Use TestDrive for file operations**
   ```powershell
   It "Creates log file" {
       $logPath = Join-Path $TestDrive "test.log"
       Initialize-Logging -LogPath $logPath
       
       Test-Path $logPath | Should -Be $true
   }
   ```

### Test Data

- Use `$TestDrive` for temporary files (automatic cleanup)
- Avoid external dependencies (mock when possible)
- Don't assume file system state

---

## Troubleshooting

### Module Import Errors

**Problem:** `Cannot find a matching module entry for 'Logging'`

**Solution:** Ensure module path is correct:
```powershell
$ModulePath = Join-Path (Split-Path -Parent $PSScriptRoot) "..\Scripts\Utils\Logging.ps1"
Import-Module $ModulePath -Force
```

### Registry Access Issues

**Problem:** Registry operations fail with "Access Denied"

**Solution:** Run PowerShell as Administrator:
```powershell
Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass" -Verb RunAs
```

### Timeout Issues

**Problem:** Tests timeout before completion

**Solution:** Increase Pester timeout:
```powershell
Invoke-Pester -Path "Integration.Tests.ps1" -Timeout 600  # 10 minutes
```

---

## Performance Expectations

| Test Type | Expected Duration | Notes |
|-----------|------------------|-------|
| Unit Tests | < 30 seconds | Fast, isolated tests |
| Integration Tests | 5-10 minutes | May require system I/O |
| Regression Tests | 3-5 minutes | Backup/restore operations |
| Full Suite | 15-20 minutes | All tests combined |

---

## References

- [Pester Documentation](https://pester.dev/)
- [Pester Best Practices](https://github.com/pester/Pester/wiki/Best-Practices)
- [PowerShell Testing](https://docs.microsoft.com/en-us/powershell/scripting/learn/ps101/10-script-blocks)

---

## Contributing Tests

When adding new scripts, include corresponding tests:

1. Create `{ScriptName}.Tests.ps1` in appropriate test directory
2. Follow established patterns and naming conventions
3. Aim for >80% code coverage
4. Run full test suite before submitting PR
5. Document any special test requirements

**Checklist:**
- [ ] Test file follows naming convention
- [ ] Proper BeforeAll/AfterAll setup
- [ ] Tests use $TestDrive for file I/O
- [ ] Clear, descriptive test names
- [ ] All assertions are meaningful
- [ ] No external dependencies
- [ ] Run-Tests.ps1 reports success
