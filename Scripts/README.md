# PowerShell Standards & Guidelines

## Overview

This document defines the coding standards, error handling patterns, and best practices for all PowerShell scripts in the Windows-Legacy-System-Optimization project. These standards ensure **production-ready**, **maintainable**, and **reliable** code.

---

## Table of Contents

1. [Script Structure](#script-structure)
2. [Error Handling](#error-handling)
3. [Logging](#logging)
4. [Function Design](#function-design)
5. [Registry Operations](#registry-operations)
6. [Code Style](#code-style)
7. [Documentation](#documentation)
8. [Testing Requirements](#testing-requirements)

---

## Script Structure

### Header Template

Every script must start with a comprehensive comment-based help block:

```powershell
<#
.SYNOPSIS
    Brief one-line description of what the script does.

.DESCRIPTION
    Detailed description of functionality, use cases, and behavior.
    Explain what problems it solves and when to use it.

.PARAMETER ParameterName
    Description of the parameter, including valid values and defaults.

.EXAMPLE
    Example of how to use the script or function.

.NOTES
    Author: Windows-Legacy-System-Optimization Team
    Version: 1.0
    Production-Ready: Yes
    Requires: PowerShell 5.1+, Administrator privileges
    Dependencies: Logging.ps1, Validation.ps1
    Last Modified: [DATE]

.LINK
    https://github.com/your-repo/path

#>
```

### Script Initialization

```powershell
# =============================================================================
# SCRIPT INITIALIZATION
# =============================================================================

# Enable strict mode for early error detection
Set-StrictMode -Version Latest

# Set error action preference
$ErrorActionPreference = "Stop"

# Define script variables
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$ScriptName = Split-Path -Leaf $MyInvocation.MyCommand.Path

# Import required modules
try {
    Import-Module (Join-Path $ScriptPath "Utils\Logging.ps1") -ErrorAction Stop
    Import-Module (Join-Path $ScriptPath "Utils\Validation.ps1") -ErrorAction Stop
}
catch {
    Write-Error "Failed to import required modules: $_"
    exit 1
}
```

---

## Error Handling

### Try-Catch Blocks

All operations that can fail must use try-catch:

```powershell
try {
    # Operation that might fail
    $result = Get-Item -Path $path -ErrorAction Stop
    
    # Validate result
    if (-not $result) {
        throw "Item not found: $path"
    }
    
    return $result
}
catch [System.IO.FileNotFoundException] {
    # Handle specific exception
    Write-LogError "File not found: $path"
    return $null
}
catch {
    # Generic exception handler
    Write-LogError "Unexpected error" -Exception $_
    throw  # Re-throw if critical
}
```

### ErrorAction Preferences

```powershell
# For non-critical operations, use SilentlyContinue
$value = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue

# For critical operations, use Stop
Remove-Item -Path $path -Force -ErrorAction Stop

# For user-initiated operations, use Inquire
Get-Process | Stop-Process -ErrorAction Inquire
```

### Exit Codes

Use standardized exit codes:

```powershell
0   # Success
1   # General error
2   # Misuse of command (invalid parameters)
3   # Permission denied
4   # Resource not available
5   # Prerequisite check failed
```

---

## Logging

### Logging Initialization

Every script must initialize logging:

```powershell
# Initialize logging
Initialize-Logging -LogPath "C:\Logs\script-name.log"

# Log messages throughout execution
Write-LogInfo "Starting optimization process"
Write-LogDebug "Loading registry tweaks from: $tweakPath"
Write-LogWarning "Potential compatibility issue detected"
Write-LogError "Critical error occurred" -Exception $_.Exception

# Always close logging before exit
Close-Logging
```

### Log Levels

| Level | Usage | Visibility |
|-------|-------|-----------|
| **DEBUG** | Detailed diagnostic information | File only |
| **INFO** | General informational messages | Console + File |
| **WARN** | Warning conditions (non-fatal) | Console + File |
| **ERROR** | Error conditions (operation failed) | Console + File |
| **CRITICAL** | Critical errors (system impact) | Console + File |

### Log Message Guidelines

```powershell
# ✅ Good: Specific, actionable
Write-LogInfo "Registry value set: HKLM:\SYSTEM\...\TimerResolution = 1"

# ✅ Good: Clear error context
Write-LogError "Failed to disable service 'DiagTrack': Access Denied"

# ❌ Bad: Vague
Write-LogInfo "Operation completed"

# ❌ Bad: Too much detail
Write-LogDebug "Starting loop with counter i=0, max=100, step=1..."
```

---

## Function Design

### Function Header Template

```powershell
<#
.SYNOPSIS
    One-line description.

.DESCRIPTION
    Detailed description explaining behavior and use cases.

.PARAMETER ParamName
    Description including type, valid values, and defaults.

.PARAMETER Recurse
    If $true, operates recursively. Default: $false

.OUTPUTS
    Description of return value (type and meaning).

.EXAMPLE
    PS> Get-OptimizationStatus -Verbose
    Description of what this does.

.NOTES
    Function-specific notes, edge cases, or caveats.
#>
```

### Function Signature

```powershell
function Invoke-Optimization {
    param(
        # Required parameters first
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        # Optional parameters with defaults
        [Parameter(Mandatory=$false)]
        [int]$Timeout = 30,
        
        # Switch parameters for boolean flags
        [Parameter(Mandatory=$false)]
        [switch]$Force,
        
        # Array parameters for multiple values
        [Parameter(Mandatory=$false)]
        [string[]]$Exclude = @()
    )
    
    # Parameter validation
    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw "Path parameter cannot be empty"
    }
    
    if ($Timeout -le 0) {
        throw "Timeout must be greater than 0"
    }
    
    # Function body...
}
```

### Parameter Validation

```powershell
# Type validation
[Parameter(Mandatory=$true)]
[ValidateSet('Conservative', 'Moderate', 'Aggressive')]
[string]$RiskLevel

# Range validation
[Parameter(Mandatory=$false)]
[ValidateRange(1, 100)]
[int]$Percentage = 50

# Not null or empty
[Parameter(Mandatory=$true)]
[ValidateNotNullOrEmpty()]
[string]$ConfigPath

# Custom validation
[Parameter(Mandatory=$true)]
[ValidateScript({ Test-Path $_ })]
[string]$FilePath
```

### Return Values

```powershell
# For success/failure operations
function Set-OptimizationValue {
    try {
        # ... operation ...
        
        # Validate success
        if ($result -eq $expected) {
            Write-LogInfo "Operation successful"
            return $true
        }
        else {
            Write-LogError "Operation validation failed"
            return $false
        }
    }
    catch {
        Write-LogError "Operation failed" -Exception $_
        return $false
    }
}

# For data retrieval operations
function Get-SystemMetrics {
    try {
        $metrics = @{
            'CPUUsage' = Get-CpuUsage
            'RAMUsage' = Get-RamUsage
            'DiskUsage' = Get-DiskUsage
        }
        return $metrics
    }
    catch {
        Write-LogError "Failed to retrieve metrics" -Exception $_
        return $null
    }
}
```

---

## Registry Operations

### Registry Path Handling

Always use full registry paths:

```powershell
# ✅ Good: Complete path
$path = "HKLM:\SYSTEM\CurrentControlSet\Services\TimerResolution"

# ✅ Good: Variable for clarity
$regRoot = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion"
$regPath = Join-Path $regRoot "Policies"
```

### Safe Registry Modification

All registry modifications **MUST** include backup:

```powershell
function Update-RegistryOptimization {
    try {
        # Create backup first
        $backupName = Backup-RegistryPath -RegistryPath $regPath
        
        if (-not $backupName) {
            Write-LogError "Failed to create backup, aborting modification"
            return $false
        }
        
        # Attempt modification
        $success = Set-RegistryValue -Path $regPath -Name $valueName -Value $newValue
        
        if (-not $success) {
            # Rollback on failure
            Restore-RegistryFromBackup -BackupName $backupName
            return $false
        }
        
        return $true
    }
    catch {
        Write-LogError "Registry operation failed" -Exception $_
        return $false
    }
}
```

### Registry Import Safety

```powershell
# For .reg files, validate before import
function Import-RegistryTweaks {
    param(
        [Parameter(Mandatory=$true)]
        [string]$RegFile
    )
    
    try {
        # Validate file
        if (-not (Test-Path $RegFile)) {
            throw "Registry file not found: $RegFile"
        }
        
        # Create snapshot backup
        $snapshot = New-BackupSnapshot -SnapshotName "BeforeTweakImport" `
                                       -RegistryPaths @("HKLM:\SYSTEM", "HKLM:\SOFTWARE")
        
        if (-not $snapshot) {
            throw "Failed to create backup snapshot"
        }
        
        # Import registry
        $result = Import-RegistryFile -RegFilePath $RegFile
        
        if (-not $result) {
            # Attempt rollback
            Restore-BackupSnapshot -SnapshotName "BeforeTweakImport"
            throw "Registry import failed and rollback attempted"
        }
        
        return $true
    }
    catch {
        Write-LogError "Registry import operation failed" -Exception $_
        return $false
    }
}
```

---

## Code Style

### Naming Conventions

```powershell
# Functions: Verb-Noun in PascalCase
function Get-SystemMetrics { }
function Set-RegistryValue { }
function Test-AdminPrivileges { }
function Invoke-Optimization { }

# Variables: camelCase for local, $script: prefix for module scope
$systemPath = "C:\Windows"
$script:BackupDirectory = $null
$global:LogLevel = "INFO"

# Constants: UPPER_CASE with $script: prefix
$script:MAX_RETRIES = 3
$script:TIMEOUT_SECONDS = 60

# Private functions: prefix with underscore or use double underscore convention
function _ValidateInput { }
function __InternalHelper { }
```

### Indentation and Spacing

```powershell
# Use 4 spaces (not tabs)
function Test-Example {
    if ($condition) {
        # Code indented 4 spaces
        $value = Get-Item
    }
}

# Line breaks around major sections
# ========================================
# SECTION: Loading Configuration
# ========================================
$config = Load-Config

# Spacing in control structures
if ($test -eq $true) {
    Write-Host "Value"
}

# NOT: if($test -eq $true){Write-Host "Value"}
```

### Comments and Documentation

```powershell
# Use comment-based help for functions
<#
.SYNOPSIS
    Description
#>

# Use inline comments for complex logic
# Check if the backup was successful before proceeding
if (-not (Test-Path $backupFile)) {
    throw "Backup verification failed"
}

# Avoid obvious comments
# ❌ Bad: $count = $count + 1  # Increment count
# ✅ Good: $retryCount++  # Retry if transient failure
```

---

## Documentation

### In-Code Documentation

Every non-trivial section must be documented:

```powershell
<#
.SYNOPSIS
    Apply critical registry optimizations for DPC latency reduction.

.DESCRIPTION
    This function modifies kernel-level registry settings to minimize
    DPC (Deferred Procedure Call) latency. Changes include:
    - Timer resolution adjustment
    - Thread priority optimization
    - Interrupt coalescing tuning

    All changes are backed up and can be rolled back individually.

.PARAMETER RegistryTweaks
    Array of registry tweak definitions (see Registry-Tweaks/METADATA.json)

.PARAMETER RiskLevel
    Only apply tweaks at or below this risk level:
    - Conservative: Minimal, widely-tested tweaks
    - Moderate: Standard optimizations, low compatibility risk
    - Aggressive: Aggressive tuning, may affect some applications

.EXAMPLE
    PS> $tweaks = Get-RegistryTweaks -Component "DPC"
    PS> Apply-RegistryOptimizations -RegistryTweaks $tweaks -RiskLevel "Moderate"

.NOTES
    Requires Administrator privileges.
    Changes take effect immediately (no reboot required).
#>
```

---

## Testing Requirements

### Unit Test Standards

Every utility module must have corresponding unit tests:

```powershell
# Tests/Unit-Tests/Logging.Tests.ps1
Describe "Logging Module" {
    Context "Initialize-Logging" {
        It "Creates log file in specified directory" {
            Initialize-Logging -LogPath "TestDrive:\test.log"
            Test-Path "TestDrive:\test.log" | Should -Be $true
            Close-Logging
        }
        
        It "Returns correct log path" {
            Initialize-Logging -LogPath "TestDrive:\test.log"
            Get-LogPath | Should -Be "TestDrive:\test.log"
            Close-Logging
        }
    }
    
    Context "Write-LogMessage" {
        It "Writes message to log file" {
            Initialize-Logging -LogPath "TestDrive:\test.log"
            Write-LogInfo "Test message"
            Get-Content "TestDrive:\test.log" | Should -Match "Test message"
            Close-Logging
        }
    }
}
```

### Execution Requirements

Every script must:

1. ✅ Run without errors on target Windows versions (10 22H2, 11 24H2)
2. ✅ Pass all unit tests (if applicable)
3. ✅ Generate comprehensive logs for troubleshooting
4. ✅ Validate all prerequisites before executing
5. ✅ Include rollback procedures for destructive operations
6. ✅ Handle interrupts gracefully (Ctrl+C cleanup)

### Pre-Commit Validation

Before committing, ensure:

```powershell
# Lint check (PSScriptAnalyzer)
Invoke-ScriptAnalyzer -Path "Scripts\" -Recurse

# Run all unit tests
Invoke-Pester -Path "Tests\Unit-Tests\" -Recurse

# Verify no hardcoded credentials
Get-Content "Scripts\*.ps1" | Select-String -Pattern "password|secret|key" | Should -BeNullOrEmpty
```

---

## Example: Production-Ready Script

```powershell
<#
.SYNOPSIS
    Apply DPC latency optimizations to Windows registry.

.DESCRIPTION
    Configures kernel-level registry settings to minimize DPC latency
    for improved system responsiveness on low-end PCs.

.NOTES
    Author: Windows-Legacy-System-Optimization Team
    Version: 1.0
    Requires: Administrator, Logging.ps1, Registry-Operations.ps1
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('Conservative', 'Moderate', 'Aggressive')]
    [string]$RiskLevel = 'Moderate'
)

# =============================================================================
# INITIALIZATION
# =============================================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Initialize-Logging -LogPath "C:\Logs\DPC-Optimization.log"

try {
    Import-Module (Join-Path $ScriptPath "Utils\Logging.ps1") -ErrorAction Stop
    Import-Module (Join-Path $ScriptPath "Utils\Registry-Operations.ps1") -ErrorAction Stop
    Import-Module (Join-Path $ScriptPath "Utils\Validation.ps1") -ErrorAction Stop
}
catch {
    Write-LogCritical "Failed to import modules" -Exception $_
    exit 1
}

# =============================================================================
# MAIN LOGIC
# =============================================================================

try {
    Write-LogInfo "Starting DPC latency optimization (Risk Level: $RiskLevel)"
    
    # Validate prerequisites
    if (-not (Test-AdminPrivileges)) {
        throw "Administrator privileges required"
    }
    
    # Load registry tweaks
    $tweaksPath = Join-Path $ScriptPath "..\Registry-Tweaks\Windows-10\Components\DPC-Interrupt-Handling.reg"
    
    if (-not (Test-Path $tweaksPath)) {
        throw "Registry tweaks file not found: $tweaksPath"
    }
    
    # Create backup
    $backupName = Backup-RegistryPath -RegistryPath "HKLM:\SYSTEM"
    if (-not $backupName) {
        throw "Failed to create registry backup"
    }
    
    # Apply tweaks
    $result = Import-RegistryFile -RegFilePath $tweaksPath
    if (-not $result) {
        Restore-RegistryFromBackup -BackupName $backupName
        throw "Failed to apply registry tweaks"
    }
    
    Write-LogInfo "DPC optimization completed successfully"
    Write-LogInfo "Backup created: $backupName (for rollback if needed)"
    
    exit 0
}
catch {
    Write-LogCritical "Optimization failed" -Exception $_
    exit 1
}
finally {
    Close-Logging
}
```

---

## Checklist for Code Review

- [ ] Script follows header template format
- [ ] All parameters documented in help block
- [ ] Error handling with try-catch blocks
- [ ] Logging initialized and used throughout
- [ ] Registry operations include backups
- [ ] Validation performed on all inputs
- [ ] Exit codes documented and appropriate
- [ ] No hardcoded credentials or secrets
- [ ] Compatible with PowerShell 5.1+
- [ ] Tested on target Windows versions
- [ ] Passes PSScriptAnalyzer linting

---

## References

- [PowerShell Best Practices](https://docs.microsoft.com/en-us/powershell/scripting/developer/cmdlet/cmdlet-development-guidelines)
- [PSScriptAnalyzer Rules](https://github.com/PowerShell/PSScriptAnalyzer/wiki/Rules)
- [Comment-Based Help](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comment_based_help)
- [Error Handling](https://docs.microsoft.com/en-us/powershell/scripting/developer/cmdlet/error-handling-best-practices)
