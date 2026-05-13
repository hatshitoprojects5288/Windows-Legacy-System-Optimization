# Deployment Guide - Step-by-Step

## Overview

This guide walks you through the complete process of optimizing your Windows system from start to finish. Follow these steps in order.

---

## Table of Contents

1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Backup & Recovery Setup](#backup--recovery-setup)
3. [System Selection](#system-selection)
4. [Optimization Execution](#optimization-execution)
5. [Post-Deployment Verification](#post-deployment-verification)
6. [Monitoring & Support](#monitoring--support)

---

## Pre-Deployment Checklist

### System Requirements

Before starting optimization, verify your system meets requirements:

```
✓ Operating System:     Windows 10 22H2 or Windows 11 24H2+
✓ RAM:                  1GB minimum (but better with 2GB+)
✓ Disk Space:           500MB free minimum
✓ Administrator Access: Required (not guest account)
✓ USB/Recovery Media:   Recommended (external drive)
```

**Check Your Windows Version:**
```powershell
# Open PowerShell as Administrator and run:
[System.Environment]::OSVersion.Version
Get-WmiObject Win32_OperatingSystem | Select-Object Caption, Version, BuildNumber
```

Expected output for Windows 10:
```
Caption    : Microsoft Windows 10 Pro
Version    : 10.0.19045
BuildNumber: 19045  (or 19044 for earlier 22H2)
```

Expected output for Windows 11:
```
Caption    : Microsoft Windows 11 Pro
Version    : 10.0.22621
BuildNumber: 22621  (or 26100+ for 24H2)
```

### Pre-Deployment Steps

```
[ ] Verify Windows version is supported (Win10 22H2 or Win11 24H2+)
[ ] Ensure 500MB+ free disk space
[ ] Close all applications (especially web browsers, media players)
[ ] Disable Antivirus temporarily (will re-enable after)
[ ] Create System Restore Point (see next section)
[ ] Create Full System Backup (optional but recommended)
[ ] Have rollback scripts ready (in Scripts/Rollback/)
```

---

## Backup & Recovery Setup

### Step 1: Create System Restore Point

A **System Restore Point** allows Windows to recover if something breaks.

```powershell
# Open PowerShell as Administrator and run:
Checkpoint-Computer -Description "Before Windows Optimization" -RestorePointType "MODIFY_SETTINGS"

# Verify it was created:
Get-ComputerRestorePoint | Select-Object SequenceNumber, Description, CreationTime | Sort-Object SequenceNumber -Descending | Select-Object -First 1
```

**Output should show:**
```
SequenceNumber : 1
Description    : Before Windows Optimization
CreationTime   : [Current date/time]
```

### Step 2: Create Registry Backup

The optimization scripts create backups automatically, but manual backup is also recommended.

```powershell
# Export current registry to external drive (for safety)
$backupPath = "D:\Registry-Backup-$(Get-Date -Format 'yyyyMMdd').reg"
reg export HKLM $backupPath /y
reg export HKCU $backupPath /y

# Verify backup was created:
Get-Item $backupPath
```

### Step 3: Optional - Full System Image

For maximum safety, create a full system image to external drive:

```powershell
# Windows 10/11: Use File History + System Image
# Settings > System > Storage > Backup > Back up now

# Or use Macrium Reflect Free / EaseUS Todo Backup
# Create full disk image to external USB drive
```

---

## System Selection

### Step 1: Determine Your Risk Tolerance

Before running optimization, decide your comfort level:

**Conservative (Low Risk):**
- Safe for all users
- Disable unnecessary services
- Basic memory tuning
- Minimal risk of breakage

**Moderate (Medium Risk):**
- Includes Conservative + more optimizations
- DPC latency tuning
- Aggressive I/O optimization
- May affect specific scenarios (gaming, VoIP)

**Aggressive (High Risk):**
- All optimizations
- Complete telemetry removal
- Aggressive memory management
- Expert users only

### Step 2: Determine Your Telemetry Preference

**Conservative Disable (Recommended):**
- Disable telemetry services and block network endpoints
- No file deletion
- Fully reversible
- Safe for all systems

**Complete Removal:**
- Delete telemetry binaries entirely
- Maximum privacy
- Higher risk of breakage
- Expert users only

**See:** [TELEMETRY-OPTIONS.md](TELEMETRY-OPTIONS.md) for comparison

### Step 3: Determine Your Hardware Profile

Select profile based on your hardware:

**Ultra-Low-End (1-2GB RAM, older CPU):**
```
Risk Level:     Conservative (stability priority)
Telemetry:      Conservative Disable
Focus:          Memory optimization > DPC latency
```

**Low-End (4GB RAM, budget CPU):**
```
Risk Level:     Moderate (good balance)
Telemetry:      Conservative Disable
Focus:          Memory + DPC latency tuning
```

**Mid-Range (8GB+ RAM, mainstream CPU):**
```
Risk Level:     Moderate-Aggressive (can afford risk)
Telemetry:      Either option
Focus:          DPC latency > Memory (not constrained)
```

---

## Optimization Execution

### Step 1: Download and Extract Scripts

1. Download or clone the repository:
   ```
   https://github.com/your-org/Windows-Legacy-System-Optimization
   ```

2. Extract to a known location:
   ```
   C:\Temp\Windows-Optimization\
   ```

3. Open PowerShell as Administrator:
   ```
   Right-click PowerShell > Run as administrator
   ```

### Step 2: Navigate to Scripts Directory

```powershell
cd "C:\Temp\Windows-Optimization\Scripts\Post-Installation"

# Verify scripts exist:
Get-ChildItem *.ps1 | Select-Object Name
```

Expected output:
```
Name
----
Debloat-Windows.ps1
Remove-Telemetry-Conservative.ps1
Remove-Telemetry-Complete.ps1
Apply-Registry-Tweaks.ps1
Optimize-System.ps1
```

### Step 3: Set Execution Policy (One-Time)

```powershell
# Allow script execution for this session only
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# Verify:
Get-ExecutionPolicy
# Output should be: Bypass
```

### Step 4: Run Master Optimization Script

The master script `Optimize-System.ps1` guides you through all options:

```powershell
# Run the master script
.\Optimize-System.ps1
```

**The script will prompt you to:**

1. **Select Windows Version:**
   ```
   Windows 10 (22H2) or Windows 11 (24H2+)? [10/11]: 10
   ```

2. **Select Risk Level:**
   ```
   Risk Level [Conservative/Moderate/Aggressive]: Moderate
   ```

3. **Select Telemetry Option:**
   ```
   Telemetry Removal [Conservative/Complete/None]: Conservative
   ```

4. **Confirm Pre-Flight Checks:**
   ```
   Admin privileges: ✓ PASS
   Disk space available: ✓ PASS
   Windows version supported: ✓ PASS
   
   Continue with optimization? [Y/N]: Y
   ```

5. **Create Backup Snapshot:**
   ```
   Creating backup snapshot before optimization...
   ✓ Snapshot created: BeforeOptimization_20260513_143215
   ✓ Registry backed up: [size]
   ```

6. **Confirm Execution:**
   ```
   Ready to apply optimizations:
   - Debloat Windows (remove unnecessary apps/services)
   - Remove telemetry (Conservative disable)
   - Apply registry tweaks (category: All)
   
   IMPORTANT: This process takes 5-15 minutes.
   Your system may become unresponsive briefly.
   
   Continue? [Y/N]: Y
   ```

### Step 5: Monitor Execution

The script will display progress:

```
[14:32:15] Starting Windows optimization (Risk: Moderate, Telemetry: Conservative)

[14:32:20] Phase 1: Debloating Windows
  ✓ Removed OneDrive shortcut
  ✓ Disabled Cortana service
  ✓ Removed 3D Objects folder
  ⊘ AppX packages already minimal
  [Progress: 25%]

[14:33:10] Phase 2: Removing Telemetry (Conservative)
  ✓ Disabled DiagTrack service
  ✓ Disabled dmwappushservice
  ✓ Added firewall rules (5 endpoints blocked)
  [Progress: 50%]

[14:34:00] Phase 3: Applying Registry Tweaks
  ✓ Timer resolution set to 1ms
  ✓ IRQ balancing disabled
  ✓ Memory pool tuned
  ✓ Cache limits set
  [Progress: 75%]

[14:34:30] Phase 4: Cleanup
  ✓ Validated all changes
  ✓ Generated completion report
  [Progress: 100%]

═══════════════════════════════════════════════════════════════
OPTIMIZATION COMPLETE ✓
═══════════════════════════════════════════════════════════════

Backup Snapshot: BeforeOptimization_20260513_143215
Rollback Command: .\Rollback-Registry.ps1 -SnapshotName "BeforeOptimization_20260513_143215"

Changes Made:
  - 24 registry values modified
  - 5 services disabled
  - 8 scheduled tasks disabled
  - 5 firewall rules added

Next Steps:
  1. Restart your system to apply all changes
  2. Monitor performance improvement
  3. Run Benchmark-System.ps1 to measure before/after
  
Log File: C:\Logs\Windows-Optimization_20260513_143215.log
```

### Step 6: Restart System

After optimization completes, restart your system to apply all changes:

```powershell
# Restart immediately:
Restart-Computer

# Or schedule restart for later:
Shutdown -r -t 300 -c "Optimization complete, restarting in 5 minutes"
```

**What happens during restart:**
- New registry settings are loaded
- Disabled services don't start
- Firewall rules are active
- Memory tuning is applied

---

## Post-Deployment Verification

### Step 1: Verify System Starts

After restart:

```
[ ] System boots successfully (no errors/loops)
[ ] Desktop loads normally
[ ] Taskbar is responsive
[ ] Mouse/keyboard work
```

### Step 2: Verify Services Are Disabled

```powershell
# Open PowerShell as Administrator
Get-Service DiagTrack, dmwappushservice | Select-Object Name, Status, StartType

# Expected output:
Name                 Status  StartType
----                 ------  ---------
DiagTrack          Stopped  Disabled
dmwappushservice   Stopped  Disabled
```

### Step 3: Verify Registry Changes

```powershell
# Check timer resolution
Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\TimerResolution" -Name Current

# Expected output:
Current : 1
```

### Step 4: Verify Network Blocking

```powershell
# Check firewall rules
Get-NetFirewallRule -DisplayName "*Telemetry*" | Where-Object { $_.Enabled -eq $true }

# Expected output:
DisplayName                       : Block Telemetry Outbound
Enabled                          : True
Direction                        : Outbound
Action                           : Block
```

### Step 5: Quick Performance Check

**Measure Current RAM Usage:**
```powershell
$totalRAM = (Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1GB
$freeRAM = (Get-WmiObject Win32_OperatingSystem).FreePhysicalMemory / 1MB
$usedRAM = $totalRAM - ($freeRAM / 1024)

Write-Host "Total RAM: $([Math]::Round($totalRAM, 2)) GB"
Write-Host "Used RAM: $([Math]::Round($usedRAM, 2)) GB"
Write-Host "Free RAM: $([Math]::Round($freeRAM / 1024, 2)) GB"
```

**Compare to baseline:**
- Before optimization: `1.2 GB used`
- After optimization: `0.8 GB used`
- **Improvement: +400 MB free**

---

## Monitoring & Support

### Step 1: Enable Performance Monitoring

```powershell
# Run benchmark tool to measure before/after
cd "Scripts\Verification"
.\Benchmark-System.ps1
```

**Output will show:**
- Current RAM usage
- DPC latency (requires LatencyMon)
- Process count
- Hard fault rate

### Step 2: Run LatencyMon (Optional but Recommended)

For DPC latency measurement:

1. Download: https://www.resplendence.com/latencymon
2. Install and launch
3. Click "Start" to begin monitoring
4. Run your typical workload for 10+ minutes
5. Check if DPC latency is < 500 μs

### Step 3: Monitor for Issues

**First 24 hours:** Watch for any problems:
- System crashes or hangs
- Broken functionality (audio, networking, display)
- Unexpected errors
- Unusual slowness

**If problems occur:**
- Check log file: `C:\Logs\Windows-Optimization_[timestamp].log`
- Run rollback script: `.\Rollback-Registry.ps1`
- Restore system restore point if needed

### Step 4: Document Results

Create a benchmark report:

```
System: Dell Inspiron 15 (i3-2130 + 4GB + HDD)
Optimization Date: May 13, 2026
Risk Level: Moderate
Telemetry: Conservative Disable

Before Optimization:
  Idle RAM:           1.3 GB
  Available RAM:      2.7 GB
  DPC Latency (avg):  847 μs
  Processes:          52

After Optimization:
  Idle RAM:           0.9 GB
  Available RAM:      3.1 GB
  DPC Latency (avg):  156 μs
  Processes:          21

Improvement:
  RAM Freed:          +400 MB
  DPC Latency:        -82%
  Processes:          -40%

Overall Assessment: ✓ Optimization Successful
System feels noticeably more responsive.
```

---

## Troubleshooting

### Issue: Script Won't Run (Execution Policy Error)

**Error:**
```
File cannot be loaded because running scripts is disabled on this system.
```

**Solution:**
```powershell
# Run PowerShell as Administrator and execute:
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
# Then run script again
```

### Issue: System Won't Start After Optimization

**Symptom:** Black screen, boot loop, or system freeze

**Solution:**
1. Boot into Safe Mode:
   - **Windows 10:** Hold Shift, click Restart, select Troubleshoot > Advanced > Safe Mode
   - **Windows 11:** Same process
2. Run rollback script:
   ```powershell
   .\Rollback-Registry.ps1 -SnapshotName "BeforeOptimization_[timestamp]"
   ```
3. Restart normally

### Issue: Internet Not Working After Optimization

**Symptom:** Network disconnected or very slow

**Cause:** Likely firewall rule is too aggressive

**Solution:**
```powershell
# Remove firewall rules blocking telemetry
Remove-NetFirewallRule -DisplayName "*Telemetry*"

# Or restore from System Restore Point
rstrui.exe
```

### Issue: Performance Not Improved

**Cause:** Telemetry overhead is usually <1% CPU

**Solution:**
1. Verify optimizations were applied: `.\Benchmark-System.ps1`
2. Check if other bloatware is running: `Get-Process | Sort WorkingSet -Desc`
3. Consider additional optimizations:
   - Disable unused startup programs
   - Update chipset drivers
   - Check for malware
   - Perform disk cleanup

---

## Next Steps After Deployment

### Recommended Follow-Ups

1. **Update Drivers** (especially chipset/SATA):
   - Use manufacturer's website
   - Not Windows Update (usually older versions)

2. **Install Essential Software:**
   - Lightweight web browser (Firefox, Chrome)
   - Office suite (LibreOffice for low-end)
   - Your required applications

3. **Periodic Maintenance:**
   - Run disk cleanup monthly
   - Monitor event logs for errors
   - Update Windows security patches
   - Re-run `Benchmark-System.ps1` quarterly

4. **Create Recovery Media:**
   - Create bootable Windows USB
   - Store system image on external drive
   - Document rollback procedures

---

## Support & Documentation

For detailed information, see:
- [ARCHITECTURE.md](ARCHITECTURE.md) — Design decisions
- [PERFORMANCE-TARGETS.md](PERFORMANCE-TARGETS.md) — Metrics and baselines
- [REGISTRY-REFERENCE.md](REGISTRY-REFERENCE.md) — Details on each tweak
- [TELEMETRY-OPTIONS.md](TELEMETRY-OPTIONS.md) — Telemetry comparison
- [ROLLBACK-PROCEDURES.md](ROLLBACK-PROCEDURES.md) — Full recovery guide
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) — Common issues

---

## Conclusion

Your Windows system is now optimized for maximum performance and privacy. Remember:

✅ Monitor your system for the first 24 hours  
✅ Keep backups of critical data  
✅ Document your optimization settings  
✅ Contact support if issues arise  

**Enjoy your faster, leaner Windows system!**
