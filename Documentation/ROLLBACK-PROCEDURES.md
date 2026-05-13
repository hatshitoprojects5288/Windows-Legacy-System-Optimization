# Rollback Procedures - Disaster Recovery Guide

## Overview

This guide provides step-by-step procedures for rolling back optimizations, recovering from system issues, and restoring from backup snapshots created before and during optimization.

**Key Principles:**
- All optimization changes are **fully reversible**
- Automatic backups created before each modification
- Point-in-time recovery from any checkpoint
- Safe Mode recovery capability
- Comprehensive verification procedures

---

## Quick Rollback (Standard Cases)

### For Recent Optimization Issues

**Time:** 5-10 minutes  
**Requirements:** Admin access, stable Windows boot  
**Difficulty:** Simple

**Step 1: Open PowerShell as Administrator**
```powershell
# Windows 10/11
Win + X, then select "Windows PowerShell (Admin)"
  or
Win + X, then select "Terminal (Admin)"
```

**Step 2: Navigate to Scripts Directory**
```powershell
cd "C:\Users\YourUsername\Documents\GitHub\Windows-Legacy-System-Optimization\Scripts"
```

**Step 3: List Available Backups**
```powershell
# Import backup management utility
. .\Utils\Backup-Management.ps1

# List all snapshots
Get-AllBackupSnapshots | Format-Table -AutoSize

# Output example:
# BackupName                           Timestamp           RegistryBackups    Description
# ─────────────────────────────────    ────────────────    ─────────────────  ──────────────────────
# Pre-Optimization-2024-01-15          2024-01-15 14:32    4                  Before all tweaks
# AfterDPC-Fix-2024-01-15              2024-01-15 14:45    5                  DPC tweaks applied
# AfterMemory-Opt-2024-01-15           2024-01-15 15:02    6                  Memory tweaks applied
```

**Step 4: Choose Restoration Point**
```powershell
# Restore to most recent pre-optimization backup
$BackupName = "Pre-Optimization-2024-01-15"

# OR restore to specific checkpoint
$BackupName = "AfterDPC-Fix-2024-01-15"
```

**Step 5: Perform Rollback**
```powershell
# Restore from snapshot
Restore-BackupSnapshot -BackupName $BackupName -Verbose

# Verification: Script confirms each registry key restored
# Output:
# [INFO] Restoring backup snapshot: Pre-Optimization-2024-01-15
# [INFO] Restored 127 registry keys from backup
# [INFO] Snapshot restored successfully
# [SUCCESS] System rollback completed
```

**Step 6: Verify System**
```powershell
# Verify critical services running
$Services = @("LanmanWorkstation", "LanmanServer", "WinRM", "Audiosrv")
foreach ($Service in $Services) {
    $Status = (Get-Service $Service -ErrorAction SilentlyContinue).Status
    "[CHECK] $Service : $Status"
}

# Check registry keys restored
Test-RegistryPathAccess -RegistryPath "HKLM:\System\CurrentControlSet\Services\DPC"
```

**Step 7: Restart System**
```powershell
# Graceful restart
Restart-Computer -Force

# Wait for system to boot
# Allow 2-3 minutes for all services to start
```

**Step 8: Verify After Restart**
```powershell
# Run system check
. .\Utils\Validation.ps1
Test-PreFlightValidation -Verbose

# Measure performance
# Use LatencyMon to verify DPC latency returned to baseline
# Check RAM usage in Task Manager
```

---

## Complete Registry Rollback

### For Comprehensive System Recovery

**Time:** 10-15 minutes  
**Requirements:** Admin access, PowerShell access  
**Difficulty:** Moderate  
**Use When:** Multiple optimization issues or total system corruption

**Warning:** This restores ALL registry changes. Use only if selective rollback fails.

**Step 1: Boot into Safe Mode (if needed)**

If system won't boot normally:

```
Windows 10:
1. Shut down completely
2. Press power button
3. When starting up, press F8 repeatedly (or Shift + F8)
4. Select "Safe Mode with Networking"

Windows 11:
1. Shut down and restart
2. At boot screen, press F8 repeatedly
3. Advanced startup options appear
4. Select "Troubleshoot" > "Advanced Options" > "Startup Settings" > "Safe Mode with Networking"
```

**Step 2: Open PowerShell (Admin)**
```powershell
# In Safe Mode, open PowerShell with full admin rights
# Click Start, type "powershell", right-click > "Run as Administrator"
```

**Step 3: Load Backup Management Utilities**
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force
. C:\Scripts\Utils\Backup-Management.ps1
. C:\Scripts\Utils\Logging.ps1
```

**Step 4: Initialize Logging**
```powershell
# Set up logging for audit trail
Initialize-Logging -LogPath "C:\Logs\Rollback-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
```

**Step 5: List All Available Backups**
```powershell
# Get complete list with metadata
$Backups = Get-AllBackupSnapshots
$Backups | Format-Table -Property @(
    'BackupName',
    'Timestamp',
    'RegistryBackups',
    'SizeGB'
) -AutoSize

# Show oldest backup (most likely clean state)
$Backups | Sort-Object Timestamp | Select-Object -First 1
```

**Step 6: Choose Target Restoration State**

**Option A: Restore to Pre-Optimization State**
```powershell
# Safest: Return to state before ANY optimizations applied
$BackupName = "Pre-Optimization-2024-01-15"
Write-LogMessage "Restoring to PRE-OPTIMIZATION state: $BackupName" -Severity "WARNING"
```

**Option B: Restore to Specific Successful Checkpoint**
```powershell
# Restore to point AFTER successful DPC optimization, but BEFORE memory optimization that caused issues
$BackupName = "AfterDPC-Fix-2024-01-15"
Write-LogMessage "Restoring to checkpoint: $BackupName" -Severity "WARNING"
```

**Step 7: Execute Full Rollback**
```powershell
Write-LogMessage "=== COMPLETE REGISTRY ROLLBACK ===" -Severity "INFO"
Write-LogMessage "Target: $BackupName" -Severity "INFO"
Write-LogMessage "Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Severity "INFO"

# Perform restoration with detailed logging
try {
    Restore-BackupSnapshot -BackupName $BackupName -Verbose
    Write-LogMessage "Registry rollback completed successfully" -Severity "SUCCESS"
}
catch {
    Write-LogMessage "ROLLBACK FAILED: $_" -Severity "CRITICAL"
    return
}
```

**Step 8: Verify Registry Integrity**
```powershell
Write-LogMessage "Verifying registry integrity..." -Severity "INFO"

# Check critical registry paths exist
$CriticalPaths = @(
    "HKLM:\System\CurrentControlSet\Services",
    "HKLM:\Software\Microsoft\Windows",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion"
)

foreach ($Path in $CriticalPaths) {
    if (Test-Path $Path) {
        Write-LogMessage "✓ Registry path valid: $Path" -Severity "INFO"
    }
    else {
        Write-LogMessage "✗ CRITICAL: Registry path missing: $Path" -Severity "CRITICAL"
    }
}
```

**Step 9: System Services Check**
```powershell
Write-LogMessage "Checking system services..." -Severity "INFO"

# List critical services that should be running
$CriticalServices = @(
    "Audiosrv",           # Audio
    "Dhcp",               # DHCP
    "dnscache",           # DNS
    "LanmanWorkstation",  # SMB client
    "LanmanServer",       # SMB server
    "WinRM",              # Remote management
    "WinHttpAutoProxySvc" # Web proxy
)

foreach ($Service in $CriticalServices) {
    try {
        $Status = (Get-Service $Service -ErrorAction Stop).Status
        $Startup = (Get-Service $Service).StartType
        Write-LogMessage "Service $Service : $Status (Startup: $Startup)" -Severity "INFO"
    }
    catch {
        Write-LogMessage "Could not verify service $Service" -Severity "WARNING"
    }
}
```

**Step 10: Perform Forced Restart**
```powershell
Write-LogMessage "Initiating system restart..." -Severity "INFO"
Close-Logging

# Allow 10 seconds for log to flush
Start-Sleep -Seconds 10

# Restart with force flag
Restart-Computer -Force
```

**Step 11: Post-Restart Verification**

After system boots:

```powershell
# Boot delay (allow 3-5 minutes for all services)
Start-Sleep -Seconds 300

# Run full pre-flight validation
. C:\Scripts\Utils\Validation.ps1
Test-PreFlightValidation -Verbose

# Generate system compatibility report
Generate-SystemCompatibilityReport
```

---

## Safe Mode Recovery

### For Unbootable Systems

**Time:** 15-30 minutes  
**Requirements:** Safe Mode access, external drive optional  
**Difficulty:** Advanced  
**Use When:** System won't boot normally

**Step 1: Boot into Safe Mode with Networking**

**Windows 10:**
```
1. Shut down completely
2. Power on and immediately hold F8 key
3. If F8 doesn't work:
   - Hold Shift while clicking "Restart" from Settings
   - Select "Troubleshoot" > "Advanced Options" > "Startup Settings"
   - Press 5 for "Safe Mode with Networking"
```

**Windows 11:**
```
1. Shut down and restart
2. At BIOS/Boot screen, hold F8 or Shift+F8
3. Navigate to "Troubleshoot" > "Advanced Options" > "Startup Settings"
4. Select "Safe Mode with Networking" (F6 or number)
```

**Step 2: Log In with Local Account**
```
- Use local administrator account (not Microsoft account)
- If using Microsoft account, ensure password is remembered offline
- Safe Mode only allows local account login
```

**Step 3: Connect to Network (if needed)**
```
- Safe Mode with Networking provides internet access
- Right-click network icon > "Open Settings"
- Connect to WiFi or Ethernet
```

**Step 4: Enable Script Execution**
```powershell
# Open PowerShell as Administrator (might require admin password)
# Right-click PowerShell > "Run as Administrator"

# Enable script execution
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force
```

**Step 5: Load Utilities and Execute Rollback**
```powershell
# Navigate to backup utilities
$UtilsPath = "C:\Scripts\Utils"
if (-not (Test-Path $UtilsPath)) {
    # Locate utilities on external drive or recovery media if needed
    $UtilsPath = Read-Host "Enter path to Scripts\Utils directory"
}

# Load backup management
. "$UtilsPath\Backup-Management.ps1"
. "$UtilsPath\Logging.ps1"

# Initialize logging to external drive (safer)
Initialize-Logging -LogPath "C:\Recovery\SafeModeRollback-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
```

**Step 6: Perform Rollback in Safe Mode**
```powershell
# Execute complete rollback to pre-optimization state
Write-LogMessage "Safe Mode Rollback Initiated" -Severity "INFO"
Restore-BackupSnapshot -BackupName "Pre-Optimization-2024-01-15" -Verbose

# This may take 5-10 minutes
# Log all operations for verification
```

**Step 7: Exit Safe Mode and Boot Normally**
```powershell
# Close all programs
# Click Start > Power > Restart
# System boots normally (not in Safe Mode)
# Wait for all services to start (3-5 minutes)
```

**Step 8: Verify System Boot**
```powershell
# After normal boot, verify functionality
# Test:
#   - Internet connectivity
#   - Audio (if needed)
#   - Essential services running
#   - No error messages in Event Viewer
```

---

## Emergency Recovery

### System Completely Unresponsive

**Time:** 30+ minutes  
**Requirements:** External recovery media, another computer  
**Difficulty:** Advanced

**If Safe Mode boot fails:**

**Option 1: Windows Recovery Partition**

Windows 10/11 include built-in recovery partition:

```
1. Shut down completely
2. Power on and hold F11 (or Shift+F11)
3. Navigate to "Reset this PC"
4. Choose "Keep my files" or "Remove everything"
5. Windows will reinstall from recovery partition
```

**Option 2: Windows Installation Media Recovery**

```
1. Create Windows USB installation media on another computer
2. Boot from USB on affected system
3. On setup screen, press Shift+F10 (opens Command Prompt)
4. Navigate to System Restore:
   cd X:\sources\recovery\tools
   recenv.exe
5. Choose "System Restore" from earlier checkpoint
```

**Option 3: Complete Registry Backup Restoration**

If you have external backup:

```
1. Boot from Windows USB recovery media
2. Open Command Prompt (Shift+F10)
3. Connect external drive with backup files
4. Navigate to backup location and copy registry hives
5. Replace corrupted registry hives:
   cd X:\Windows\System32\config
   copy D:\backup\SYSTEM SYSTEM
   copy D:\backup\SOFTWARE SOFTWARE
   copy D:\backup\SAM SAM
6. Reboot and Windows should start with recovered registry
```

---

## Targeted Rollback

### For Specific Optimization Issues

**Use When:** Only certain optimizations caused problems, not the entire system

**Time:** 5-10 minutes  
**Difficulty:** Moderate

**Step 1: Identify Problem Optimization**

```powershell
# Example: "System unstable after DPC latency optimization"
# Review changelog to find which registry changes were made
. C:\Scripts\Utils\Registry-Operations.ps1
Get-RegistryChangeLog | Where-Object {$_.Timestamp -gt (Get-Date).AddMinutes(-30)}

# Output example:
# Timestamp              Path                                    Value        OldValue  NewValue
# ─────────────────     ─────────────────────────────────────  ─────────────────────────────────
# 2024-01-15 14:47      HKLM:\System\CurrentControlSet\S...    DPC          1         0
# 2024-01-15 14:48      HKLM:\System\CurrentControlSet\S...    Interrupt    1         0
```

**Step 2: Find Related Backup Snapshot**
```powershell
# List backups to find ones BEFORE the problem optimization
Get-AllBackupSnapshots | Sort-Object Timestamp

# Identify: Which backup was BEFORE DPC optimization?
# Example: "Pre-Optimization-2024-01-15" or "AfterMemory-Opt-2024-01-15"
```

**Step 3: Targeted Restoration**
```powershell
# Restore ONLY registry keys from DPC optimization
# (This is different from full snapshot restore)

# Find backup that has the state BEFORE DPC changes
$GoodBackup = "AfterMemory-Opt-2024-01-15"
Restore-BackupSnapshot -BackupName $GoodBackup -Verbose
```

**Step 4: Test System Stability**
```powershell
# Verify system now stable after targeted rollback
# Test:
#   - Essential services running
#   - No error messages
#   - System responsive
#   - Device Manager clean (no yellow exclamation marks)
```

---

## Verification After Rollback

### Comprehensive Verification Checklist

After any rollback, verify system health:

```powershell
# Load utilities
. C:\Scripts\Utils\Validation.ps1
. C:\Scripts\Utils\Logging.ps1

# Run comprehensive validation
Write-LogMessage "=== POST-ROLLBACK VERIFICATION ===" -Severity "INFO"

# Check 1: System boots and runs
[✓] System boots normally
[✓] Desktop responsive
[✓] File Explorer works

# Check 2: Critical services running
$Services = @(
    "Audiosrv",
    "Dhcp",
    "dnscache",
    "LanmanWorkstation"
)
foreach ($Service in $Services) {
    $Status = (Get-Service $Service).Status
    if ($Status -eq "Running") { "[$Service: PASS]" } 
    else { "[$Service: FAIL]" }
}

# Check 3: No critical errors
$Errors = Get-WinEvent -LogName System -MaxEvents 100 | Where-Object {$_.Level -eq 1} # 1 = Critical
if ($Errors.Count -eq 0) { "[Errors: PASS]" }
else { "[Errors: $($Errors.Count) CRITICAL ERRORS FOUND]" }

# Check 4: Network connectivity
Test-Connection 8.8.8.8 -Count 1 | Select-Object -ExpandProperty StatusCode
if ($? -eq $true) { "[Network: PASS]" }

# Check 5: Registry integrity
Test-RegistryPathAccess -RegistryPath "HKLM:\System\CurrentControlSet\Services"
```

---

## Backup and Restore Log Location

All backup/restore operations logged to:

```
C:\Logs\Rollback-YYYYMMDD-HHMMSS.log
```

**Logs contain:**
- Backup/restore timestamp
- Each registry key modified
- Success/failure status
- Performance metrics
- Any errors encountered

**Review logs for:**
```powershell
# Find all rollback operations
Get-ChildItem C:\Logs\Rollback-*.log | Sort-Object LastWriteTime -Descending

# View most recent rollback
$LatestLog = Get-ChildItem C:\Logs\Rollback-*.log | Sort-Object LastWriteTime -Descending | Select-Object -First 1
Get-Content $LatestLog
```

---

## Prevention: Regular Backups

### Best Practices for System Safety

**Create Backups:**
1. Before any major optimization
2. After each successful component optimization
3. After major Windows updates
4. Before trying new drivers

**Backup Naming Convention:**
```
Pre-[Optimization Name]-[Date]
After-[Optimization Name]-[Date]

Examples:
- Pre-Optimization-2024-01-15
- AfterDPC-Fix-2024-01-15
- AfterMemory-Opt-2024-01-15
- AfterTelemetry-Removal-2024-01-15
```

**Script:**
```powershell
# Automated daily backup
$BackupName = "Daily-Backup-$(Get-Date -Format 'yyyyMMdd')"
. C:\Scripts\Utils\Backup-Management.ps1
New-BackupSnapshot -BackupName $BackupName
```

---

## Troubleshooting Rollback Issues

### Issue: Rollback Fails with "Backup Not Found"

**Cause:** Backup was deleted or never created

**Solution:**
1. Verify backup exists: `Get-AllBackupSnapshots`
2. Check backup location: `C:\Users\USERNAME\Documents\GitHub\...` 
3. If missing, use Windows System Restore instead: `rstrui.exe`

### Issue: System Still Unstable After Rollback

**Cause:** Another optimization also problematic, or hardware issue

**Solution:**
1. Roll back further (earlier checkpoint)
2. Check Event Viewer for driver/service errors
3. Consider factory reset if unresolvable

### Issue: Rollback Takes Too Long (>30 minutes)

**Cause:** Very large number of registry changes, slow disk

**Solution:**
1. Let it complete (may take 30-60 minutes)
2. Use external USB 3.0 drive if available (faster)
3. Defragment drive if on HDD: `Optimize-Volume -DriveLetter C -Defrag`

---

## Conclusion

**Rollback Safety Summary:**
- ✅ All optimizations fully reversible
- ✅ Automatic backups before each change
- ✅ Point-in-time recovery capability
- ✅ Safe Mode recovery available
- ✅ Emergency recovery procedures documented

**Remember:**
- Never panic if optimization causes issues
- Backups exist and are readily available
- System recovery is straightforward
- Worst case: Reinstall Windows (everything recoverable)

For issues not covered here, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md) or consult logs for specific error details.
