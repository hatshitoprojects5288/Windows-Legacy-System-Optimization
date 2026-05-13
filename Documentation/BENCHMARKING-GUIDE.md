# Benchmarking Guide - Verification Procedures

## Overview

This guide provides detailed procedures for measuring system performance before and after optimizations, establishing baseline metrics, and validating achievement of optimization targets.

**Key Metrics:**
- Idle RAM usage (Target: <1 GB)
- DPC/ISR latency (Target: <500 μs)
- Process count (Target: <70 processes)
- Boot time (Informational)
- System responsiveness (Qualitative)

---

## Pre-Optimization Baseline

### What to Measure BEFORE Optimization

1. **Idle RAM Usage**
   - How much RAM consumed at idle desktop
   - Measured using Task Manager

2. **DPC/ISR Latency**
   - Kernel-level interrupt handling delay
   - Measured using LatencyMon tool

3. **Process Count**
   - Number of background processes
   - Measured using Task Manager or PowerShell

4. **Boot Time**
   - Time from power-on to responsive desktop
   - Informational metric (not primary target)

5. **System Responsiveness**
   - Qualitative assessment of system feel
   - Freezes, stutters, lag, disk thrashing

### Baseline Measurement Procedure

**Time Required:** 15-20 minutes total

**Step 1: Prepare System (5 minutes)**
```
1. Boot to fresh desktop
2. Wait 2 minutes for startup tasks to complete
3. Close all user applications
4. Disable all browser plugins/extensions
5. Ensure no updates running (check Settings > Update & Security)
6. System should be at "clean idle" state
```

**Step 2: Measure Idle RAM (2 minutes)**
```
1. Right-click taskbar, select "Task Manager"
2. Click "Memory" column to sort
3. Note "In use" value at bottom
   ├─ Example: "4.8 GB / 8.0 GB"
   └─ Baseline = 4.8 GB

4. Wait 30 seconds, verify number stabilizes
5. Record baseline: ________________ GB
```

**Step 3: Count Background Processes (2 minutes)**
```powershell
# PowerShell method (accurate count)
Get-Process | Measure-Object | Select-Object -ExpandProperty Count

# Expected stock Windows:
# - Windows 10: 80-120 processes
# - Windows 11: 100-150 processes
# - Low-end target: <70 processes

Baseline process count: ________________
```

**Step 4: Measure DPC/ISR Latency (5 minutes)**

See "LatencyMon Measurement" section below.

```
Record baseline values:
- Max ISR latency: ________________ μs
- Max DPC latency: ________________ μs
- Average DPC latency: ________________ μs
```

**Step 5: Record Boot Time (Optional)**
```
1. Shut down system completely
2. Power on and record boot time
3. Boot time = power-on to first keyboard input response
4. Informational only (not primary metric)

Baseline boot time: ________________ seconds
```

---

## DPC/ISR Latency Measurement - LatencyMon

### What is LatencyMon?

**LatencyMon** measures Deferred Procedure Call (DPC) and Interrupt Service Routine (ISR) latency — the delay between when the kernel receives an interrupt and when it processes it.

**Why Measure?**
- Low latency = responsive system
- High latency = stuttering, lag, audio dropouts
- DPC latency >1000 μs causes gaming issues
- DPC latency >500 μs causes audio issues

### Installation

**Download:**
1. Navigate to: https://www.resplendence.com/latencymon
2. Download LatencyMon (free version)
3. File: LatencyMon_x64.exe
4. No installation required — portable executable

**No Dependencies:**
- Works standalone
- Requires admin privileges
- Compatible with Windows 10/11

### LatencyMon Measurement Procedure

**Time Required:** 10 minutes per measurement

**Step 1: Launch LatencyMon**
```
1. Right-click LatencyMon_x64.exe
2. Select "Run as Administrator"
3. Application window opens
4. Click "Start" button (green play icon)
5. Wait for measurement to stabilize
```

**Step 2: Let It Run (7 minutes)**
```
Allow LatencyMon to measure for 7+ minutes:
- System should be idle
- No user interaction
- Allow background tasks to complete
- Longer measurement = more accurate baseline

Watch display updates in real-time:
┌─────────────────────────────────────┐
│ Interrupt to Scheduled Latency      │
│ Max: 523.4 μs (Target: <500 μs)    │
│ Avg: 142.3 μs                       │
│                                     │
│ Deferred Procedure Call Latency     │
│ Max: 1847.2 μs (Target: <1000 μs)  │
│ Avg: 312.5 μs                       │
└─────────────────────────────────────┘
```

**Step 3: Record Measurements**
```
After 7+ minutes, record:

ISR Latency:
  Max:       ________________ μs (Target: <500)
  Avg:       ________________ μs
  Min:       ________________ μs

DPC Latency:
  Max:       ________________ μs (Target: <1000, preferred <500)
  Avg:       ________________ μs
  Min:       ________________ μs

Interrupt Count: ________________
```

**Step 4: Identify Problem Drivers (Optional)**

If latency is high (>500 μs max DPC):

```
1. Click "Drivers" tab in LatencyMon
2. Look for drivers with high latency contribution
3. Common culprits:
   - Audio drivers (Realtek, Creative, etc.)
   - Network drivers (Broadcom, Intel)
   - USB drivers (ASMedia, etc.)
   - Graphics drivers (outdated)

4. Update driver if available
5. Repeat measurement after update
```

### LatencyMon Troubleshooting

**Issue: LatencyMon shows very high latency (>2000 μs)**

**Possible Causes:**
1. System is under load (background processes)
2. Antivirus scanning in progress
3. Outdated drivers
4. Hardware issue

**Solution:**
1. Close all applications
2. Disable antivirus temporarily
3. Check Event Viewer for driver errors
4. Update all drivers
5. Consider hardware diagnostics

**Issue: "Permission Denied" error**

**Solution:**
1. Run as Administrator (right-click > Run as Administrator)
2. Disable User Account Control temporarily
3. Try on different user account

---

## Task Manager RAM Monitoring

### Detailed RAM Analysis

**Method 1: Task Manager (Visual)**
```
1. Right-click taskbar > Task Manager
2. Click "Performance" tab
3. Click "Memory" in left panel
4. View graph and "In use" value

Information provided:
┌────────────────────────┐
│ Memory                 │
├────────────────────────┤
│ In use: 2.4 GB         │ ← Idle RAM
│ Available: 5.6 GB      │
│ Committed: 3.1 GB      │
│ Cached: 0.8 GB         │
│ Paged pool: 156 MB     │
│ Non-paged pool: 89 MB  │
└────────────────────────┘
```

**Method 2: PowerShell (Accurate)**
```powershell
# Get RAM usage (in MB)
$MemoryMetrics = @{
  TotalRAM = (Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory / 1MB
  UsedRAM = (Get-WmiObject -Class Win32_OperatingSystem).TotalVisibleMemorySize - (Get-WmiObject -Class Win32_OperatingSystem).FreePhysicalMemory
  FreeRAM = (Get-WmiObject -Class Win32_OperatingSystem).FreePhysicalMemory
}

"Total: {0:N0} MB" -f $MemoryMetrics.TotalRAM
"Used:  {0:N0} MB" -f $MemoryMetrics.UsedRAM
"Free:  {0:N0} MB" -f $MemoryMetrics.FreeRAM
"Percentage: {0:N1}%" -f ($MemoryMetrics.UsedRAM / $MemoryMetrics.TotalRAM * 100)
```

**Method 3: Advanced (Detailed Breakdown)**
```powershell
# Detailed memory analysis script
$OS = Get-WmiObject -Class Win32_OperatingSystem
$Processes = Get-Process | Measure-Object WorkingSet -Sum

"=== System Memory Usage ==="
"Total Physical RAM: {0:N0} MB" -f ($OS.TotalVisibleMemorySize / 1024)
"Used (Committed):  {0:N0} MB" -f (($OS.TotalVisibleMemorySize - $OS.FreePhysicalMemory) / 1024)
"Free:              {0:N0} MB" -f ($OS.FreePhysicalMemory / 1024)
"Process Sum:       {0:N0} MB" -f ($Processes.Sum / 1MB)

"=== Top 5 Memory Consumers ==="
Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 5 @{
  Name = "Process"
  Expression = {$_.Name}
}, @{
  Name = "Memory (MB)"
  Expression = {"{0:N0}" -f ($_.WorkingSet / 1MB)}
}
```

### Target RAM Levels by System

| System | Baseline | Target |
|--------|----------|--------|
| 2 GB RAM | 800-900 MB | <500 MB |
| 4 GB RAM | 1.2-1.5 GB | <800 MB |
| 8 GB RAM | 1.5-2.0 GB | <1.0 GB |
| 16 GB+ | 2.0-3.0 GB | <1.5 GB |

---

## Process Count Analysis

### Why Process Count Matters

More processes = more:
- Memory usage
- CPU context switching
- Background activity
- Potential conflicts

**Target:** <70 processes at idle

### Measure Process Count

**Method 1: Task Manager**
```
1. Open Task Manager
2. Click "Processes" tab
3. Look at status bar (bottom)
4. "X processes" count
5. Record number
```

**Method 2: PowerShell**
```powershell
# Count all processes
$ProcessCount = @(Get-Process).Count
"Running processes: $ProcessCount"

# Show top memory consumers
Get-Process | Sort-Object WorkingSet -Descending | Select-Object Name, @{
  Name = "Memory"
  Expression = {"{0:N0} MB" -f ($_.WorkingSet / 1MB)}
} | Select-Object -First 10
```

### Identify Unnecessary Processes

If count is high (>80), investigate:

```powershell
# List all running processes
Get-Process | Select-Object Name, WorkingSet | Sort-Object WorkingSet -Descending | Format-Table -AutoSize

# Search for specific process
Get-Process | Where-Object {$_.Name -like "*searchindex*"}

# Stop process (careful!)
Stop-Process -Name "processname" -Force
```

**Common Unnecessary Processes to Remove:**
- DiagTrack (Telemetry)
- dmwappushservice (Telemetry)
- SearchIndexer (Windows Search)
- SysMain (Superfetch)
- AudioSrv (if not using audio)
- Spooler (if not printing)
- WaaSMedicSvc (Windows Update)

---

## Post-Optimization Measurement

### Measurement Timing

**When to Measure After Optimization:**
- After all optimization scripts complete
- System restarted (to clear temporary caches)
- At least 2 minutes of idle time
- No updates or scans running
- Morning after first optimization (most stable point)

### Repeat Baseline Measurements

Perform same measurements as pre-optimization:

1. **Idle RAM** (Task Manager)
2. **DPC/ISR Latency** (LatencyMon, 7+ minutes)
3. **Process Count** (PowerShell)
4. **Boot Time** (Optional)

### Record Results

Create comparison table:

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| RAM Used | 1.8 GB | 0.9 GB | **↓ 50%** |
| DPC Max | 847 μs | 298 μs | **↓ 65%** |
| DPC Avg | 412 μs | 156 μs | **↓ 62%** |
| Processes | 94 | 52 | **↓ 45%** |
| Boot Time | 45 sec | 32 sec | **↓ 29%** |

---

## Performance Charts and Reporting

### Simple Text Report

```
========================================
SYSTEM OPTIMIZATION VERIFICATION REPORT
========================================

Date: 2024-01-15
System: Windows 10 22H2
Hardware: 8GB RAM, SSD

BASELINE (Before Optimization)
------------------------------
Idle RAM Usage:        2.1 GB
DPC Latency (Max):     847 μs
DPC Latency (Avg):     412 μs
Process Count:         94
Boot Time:             45 sec

OPTIMIZED (After Optimization)
------------------------------
Idle RAM Usage:        0.9 GB (↓ 57%)
DPC Latency (Max):     298 μs (↓ 65%)
DPC Latency (Avg):     156 μs (↓ 62%)
Process Count:         52 (↓ 45%)
Boot Time:             32 sec (↓ 29%)

VERDICT: ✅ All targets achieved
```

### CSV Format (for Excel/Charts)

```csv
Metric,Before,After,Target,Status
RAM Used (GB),2.1,0.9,1.0,Pass
DPC Max (μs),847,298,500,Pass
DPC Avg (μs),412,156,300,Pass
Processes,94,52,70,Pass
Boot Time (s),45,32,N/A,Pass
```

### Automated PowerShell Report

```powershell
# Save as: Generate-OptimizationReport.ps1
param([string]$ReportPath = "$PSScriptRoot\OptimizationReport.txt")

function Get-SystemMetrics {
    $OS = Get-WmiObject -Class Win32_OperatingSystem
    $ProcessCount = @(Get-Process).Count
    $RAM = ($OS.TotalVisibleMemorySize - $OS.FreePhysicalMemory) / 1MB

    return @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        RAM_MB = [math]::Round($RAM, 2)
        ProcessCount = $ProcessCount
        WindowsVersion = $OS.Caption
        SystemUptime = (Get-Date) - [datetime]::FromFileTime((Get-WmiObject -Class Win32_OperatingSystem).LastBootUpTime)
    }
}

$Metrics = Get-SystemMetrics
$Report = @"
System Optimization Report
Generated: $($Metrics.Timestamp)

Operating System: $($Metrics.WindowsVersion)
System Uptime: $($Metrics.SystemUptime.Hours)h $($Metrics.SystemUptime.Minutes)m

Current Metrics:
- Idle RAM: $($Metrics.RAM_MB) MB
- Running Processes: $($Metrics.ProcessCount)

Target Status:
- RAM: $($Metrics.RAM_MB -lt 1000 ? "✅ Pass" : "❌ Above Target")
- Processes: $($Metrics.ProcessCount -lt 70 ? "✅ Pass" : "⚠️ Above Target")
"@

$Report | Out-File -FilePath $ReportPath -Force
Write-Host "Report saved: $ReportPath"
```

---

## Troubleshooting Performance Issues

### RAM Still High After Optimization

**Check:**
1. Run LatencyMon (might be interfering)
2. Close browser tabs (Chrome uses lots of RAM)
3. Check for active updates (`Get-WmiObject -Query "SELECT * FROM Win32_QuickFixEngineering" | Sort-Object InstalledOn -Descending`)
4. Review Task Manager for unexpected processes

### DPC Latency Increased

**Causes:**
1. Driver update broke something
2. BIOS update changed settings
3. Antivirus interfering
4. Hardware issue

**Solution:**
1. Roll back recent driver updates
2. Check BIOS settings (XMP/DOCP disabled?)
3. Disable antivirus temporarily to test
4. Update audio/network drivers specifically

### Optimization Broke System Stability

**Resolution:**
1. Run rollback: `Restore-BackupSnapshot -BackupName "Pre-Optimization"`
2. Review logs: `Get-LogPath | Get-Content`
3. Try conservative telemetry removal instead of complete removal
4. Contact support with error details

---

## Continuous Monitoring

### Set Up Periodic Monitoring

```powershell
# Create scheduled task to log metrics daily
$Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-File C:\Scripts\Log-SystemMetrics.ps1"
$Trigger = New-ScheduledTaskTrigger -Daily -At 6:00AM
Register-ScheduledTask -TaskName "Daily Metrics Log" -Action $Action -Trigger $Trigger -RunLevel Highest
```

### Long-Term Performance Tracking

Over weeks, track:
- Average DPC latency trends
- System stability (crashes/freezes)
- RAM usage stability
- Performance under load

---

## Conclusion

**Verification Checklist:**
- [ ] Baseline measurements taken before optimization
- [ ] Post-optimization measurements taken
- [ ] All target metrics achieved or documented
- [ ] LatencyMon shows <500 μs DPC latency
- [ ] RAM usage <1 GB idle
- [ ] Process count <70
- [ ] System stable and responsive
- [ ] Results documented for future reference

**Success Criteria:**
- ✅ RAM idle: <1 GB (achieved)
- ✅ DPC latency: <500 μs (achieved)
- ✅ Processes: <70 (achieved)
- ✅ System responsive and stable

If any metric not achieved, review [TROUBLESHOOTING.md](TROUBLESHOOTING.md) or rollback using [ROLLBACK-PROCEDURES.md](ROLLBACK-PROCEDURES.md).
