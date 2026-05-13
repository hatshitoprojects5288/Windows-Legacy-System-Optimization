# Performance Targets & Metrics

## Overview

This document defines the specific performance targets, measurement methodologies, and success criteria for the Windows-Legacy-System-Optimization project. All optimizations are evaluated against these objectives.

---

## Table of Contents

1. [Primary Targets](#primary-targets)
2. [Metric Definitions](#metric-definitions)
3. [Measurement Tools](#measurement-tools)
4. [Baseline Measurements](#baseline-measurements)
5. [Success Criteria](#success-criteria)
6. [Realistic Expectations](#realistic-expectations)
7. [Measurement Best Practices](#measurement-best-practices)

---

## Primary Targets

### Target 1: Ultra-Low Idle RAM Usage

**Objective:** Achieve <1GB idle RAM consumption on Windows 10 and Windows 11.

#### Windows 10 22H2 Baseline
- Stock installation: **1.2 - 1.5 GB**
- Target after optimization: **< 1.0 GB**
- Improvement: **200-500 MB** (15-30% reduction)

#### Windows 11 24H2 Baseline
- Stock installation: **0.9 - 1.2 GB**
- Target after optimization: **< 0.9 GB**
- Improvement: **100-300 MB** (10-25% reduction)

**Measurement Method:**
```powershell
# Measure idle RAM (top-level metric)
$totalRAM = (Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory / 1GB
$freeRAM = (Get-WmiObject Win32_OperatingSystem).FreePhysicalMemory / 1MB
$usedRAM = $totalRAM - ($freeRAM / 1024)

Write-Host "Total RAM: $([Math]::Round($totalRAM, 2)) GB"
Write-Host "Free RAM: $([Math]::Round($freeRAM / 1024, 2)) GB"
Write-Host "Used RAM: $([Math]::Round($usedRAM, 2)) GB"
```

**Measurement Conditions:**
- 30 minutes after boot (services settled)
- No user applications running
- Network disconnected (no cloud sync)
- Taskbar/system tray minimized
- No external devices connected

---

### Target 2: Sub-500μs DPC Latency

**Objective:** Achieve <500 microseconds (μs) sustained DPC latency under typical workload.

#### Baseline DPC Latency
- Stock Windows 10: **800-1200 μs** (problematic for real-time)
- Stock Windows 11: **600-900 μs** (better, but still marginal)
- Target: **< 500 μs** (suitable for gaming, DAW, VoIP)

#### DPC Latency Classification

| Latency Range | Suitability | Notes |
|--------------|-------------|-------|
| < 200 μs | Excellent | Professional audio/video, real-time trading |
| 200-500 μs | Good | Gaming, VoIP, casual content creation |
| 500-1000 μs | Acceptable | General computing, web browsing |
| 1000-2000 μs | Poor | Noticeable stuttering in audio/video |
| > 2000 μs | Unacceptable | Severe audio clicks, mouse lag |

**Measurement Method (LatencyMon):**
```
LatencyMon is the industry-standard tool for DPC latency measurement.
Download: https://www.resplendence.com/latencymon

Measurements:
- DPC Latency (average) — target: < 200 μs
- DPC Latency (maximum) — target: < 500 μs
- ISR (Interrupt Service Routine) latency — target: < 100 μs
- Hard fault rate — target: < 10/sec
```

**Measurement Conditions:**
- 10-minute continuous measurement
- System idle, no user input
- No background audio/video
- Drivers fully loaded and settled
- Network disabled (no background sync)

**Alternative Measurement (Windows Performance Toolkit):**
```powershell
# For users without LatencyMon license
xperf -on PROC_THREAD+INTERRUPT+DPC -f trace.etl
# [Run workload for 60 seconds]
xperf -d trace.etl
# Analyze with Windows Performance Analyzer (WPA)
```

---

### Target 3: Minimal Process Count

**Objective:** Minimize background process count to reduce context switching overhead.

#### Baseline Process Count
- Stock Windows 10: **40-60 processes**
- Stock Windows 11: **50-80 processes**
- Target: **20-30 processes** (after optimization)

**Measurement Method:**
```powershell
# Count running processes
$processCount = (Get-Process).Count
Write-Host "Running processes: $processCount"

# List top memory consumers
Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 10 | `
  Format-Table Name, @{L="RAM (MB)"; E={[Math]::Round($_.WorkingSet / 1MB, 2)}}
```

**Target Processes (Essential):**
- System processes (3-5)
- Session/User session manager (2-3)
- Display driver (1-2)
- Audio (1-2)
- Network (1-2)
- Security/Antivirus (1-2)
- User applications (varies)

**Success:** Keeping essential processes while removing bloatware.

---

### Target 4: Reduced Hard Fault Rate

**Objective:** Achieve < 10 hard faults/sec to minimize disk paging.

#### Hard Fault Rate Explanation

A **hard fault** occurs when a program accesses memory that must be retrieved from disk. This is extremely slow compared to RAM access.

**Impact:**
- Each hard fault = 10-100ms disk latency
- Hard faults cause audio clicks, stutters, mouse lag
- Correlation: High hard fault rate = poor user experience

#### Baseline Hard Fault Rate
- Stock system with full workload: **50-200 faults/sec**
- Idle stock system: **5-20 faults/sec**
- Target after optimization: **< 10 faults/sec** even under workload

**Measurement Method (LatencyMon):**
```
LatencyMon displays "Hard Pagefaults" count.
Monitor during:
1. Idle state (should be < 5/sec)
2. Light workload — video playback (should be < 20/sec)
3. Heavy workload — VM, rendering (should be < 30/sec)
```

**Measurement with Performance Monitor:**
```powershell
# Get hard page fault rate
$perfmon = Get-Counter -Counter "\Memory\Pages/sec" -Continuous -SampleInterval 1
# Watch for spikes; target is < 100 Pages/sec during typical usage
```

---

## Metric Definitions

### DPC Latency
**Definition:** Time between when an interrupt occurs and when the DPC handler can begin execution.

**Impact:** Direct correlation with audio artifacts, mouse responsiveness, video smoothness.

**Measurement Points:**
- Average DPC latency (mathematical mean)
- Maximum DPC latency (worst case)
- DPC latency variance (consistency)
- Percentile latency (e.g., 95th percentile)

### ISR Latency
**Definition:** Interrupt Service Routine latency — time from interrupt to ISR execution.

**Impact:** Lower-level than DPC; affects scheduling of higher-priority interrupts.

**Measurement Points:**
- ISR latency (average)
- ISR latency (maximum)
- ISR latency (count > threshold)

### Context Switch Rate
**Definition:** Number of times the CPU switches from one thread to another per second.

**Impact:** High context switch rate = CPU waste on switching, not actual work.

**Target:**
- Idle: < 500 switches/sec
- Single heavy load: < 5000 switches/sec
- System saturation: < 10,000 switches/sec

### Process Working Set
**Definition:** Physical RAM allocated to a single process at a given moment.

**Impact:** Affects memory fragmentation, cache efficiency, page fault rate.

**Measurement Method:**
```powershell
Get-Process | Select-Object Name, @{L="WS (MB)"; E={[Math]::Round($_.WorkingSet / 1MB, 2)}} | Sort-Object "WS (MB)" -Descending
```

### Idle vs. Loaded State
| State | RAM Usage | DPC Latency | Context Switches |
|-------|-----------|------------|-----------------|
| **Idle** | Minimal | Stable, low | Very low |
| **Loaded** | Higher | May spike | Elevated |
| **Target** | < 1GB | < 500 μs | Predictable |

---

## Measurement Tools

### Primary Tools

#### 1. LatencyMon (Industry Standard)
**Purpose:** Measure DPC and ISR latency in real-time

**Download:** https://www.resplendence.com/latencymon  
**License:** Free evaluation (fully functional)  
**Metrics Provided:**
- DPC latency (average, max)
- ISR latency
- Hard page fault rate
- Interrupt storm detection

**Usage:**
```
1. Launch LatencyMon
2. Click "Start" to begin monitoring
3. Run your workload for 10+ minutes
4. LatencyMon will highlight problematic drivers
5. Export results to CSV for before/after comparison
```

#### 2. Performance Monitor (Built-in)
**Purpose:** Monitor system metrics over time

**Access:** `perfmon.msc`

**Key Counters:**
```
Memory:
  - Available MBytes
  - Pages/sec (hard faults)
  - Cache Bytes
  
Processor:
  - % Processor Time
  - Context Switches/sec
  - Interrupts/sec
  
PhysicalDisk:
  - % Disk Time
  - Disk Queue Length
```

#### 3. Windows Performance Toolkit (WPT)
**Purpose:** Deep kernel-level performance analysis

**Components:**
- Windows Performance Recorder (WPR) — capture events
- Windows Performance Analyzer (WPA) — analyze trace files

**Usage:**
```powershell
# Start recording
xperf -on PROC_THREAD+INTERRUPT+DPC

# [Run workload]
Start-Sleep -Seconds 60

# Stop and save
xperf -d trace.etl

# Analyze
wpa trace.etl
```

#### 4. Task Manager & Resource Monitor
**Purpose:** Quick system monitoring

**Access:** `taskmgr.exe` (Task Manager), `resmon.exe` (Resource Monitor)

**Metrics:**
- Current RAM usage
- Running processes
- Disk I/O
- Network usage
- CPU thread count

### Secondary Tools

#### 5. MemTest86
**Purpose:** Test memory integrity after optimization

**Download:** https://www.memtest86.com/

**Usage:** Boot from USB to verify no memory errors were introduced by registry tweaks

#### 6. CPU-Z & GPU-Z
**Purpose:** Monitor real-time CPU/GPU state and clock speeds

**Purpose:** Verify no throttling issues after optimization

---

## Baseline Measurements

### Recommended Baseline Collection

**Before running optimizations, collect baseline metrics:**

#### Step 1: Fresh Windows Installation
```
1. Install Windows 10 22H2 or Windows 11 24H2 (clean)
2. Install chipset drivers
3. Update Windows to latest patch level
4. Restart and wait 30 minutes for first-run tasks
```

#### Step 2: Disable Cloud Sync (for fair comparison)
```powershell
# Disconnect OneDrive
Get-Process OneDrive -ErrorAction SilentlyContinue | Stop-Process -Force

# Disconnect Microsoft Account
Settings > Accounts > Your info > Sign in with local account instead
```

#### Step 3: Collect Baseline Metrics
```powershell
# Measure baseline RAM usage
[System.Diagnostics.Performance.PerformanceCounter]::new("Memory", "Available MBytes")

# Measure baseline DPC latency
# (Use LatencyMon for 10+ minutes)

# Measure baseline process count
(Get-Process).Count

# Measure baseline hard fault rate
# (Use Performance Monitor or LatencyMon)
```

#### Step 4: Document Everything
```yaml
Baseline Snapshot:
  Date: [Measurement date]
  OS: [Windows 10 22H2 or Windows 11 24H2]
  Build: [Exact build number]
  RAM: [Total installed]
  
Metrics:
  Idle RAM Used: XX.XX GB
  DPC Latency (avg): XXX μs
  DPC Latency (max): XXX μs
  Process Count: XX
  Hard Faults/sec: X
  
Notes:
  [Any relevant system configuration]
```

---

## Success Criteria

### Optimization Success = Meeting Target Metrics

| Metric | Baseline | Target | Success |
|--------|----------|--------|---------|
| **Idle RAM (Win10)** | 1.2-1.5 GB | < 1.0 GB | -200 MB or more |
| **Idle RAM (Win11)** | 0.9-1.2 GB | < 0.9 GB | -100 MB or more |
| **DPC Latency Avg** | 800-1200 μs | < 200 μs | -50% or more |
| **DPC Latency Max** | 2000+ μs | < 500 μs | -50% or more |
| **Process Count** | 40-80 | 20-30 | -30+ fewer |
| **Hard Fault Rate** | 50-200/sec | < 10/sec | -80% or more |

### Failure Scenarios

**Optimization failed if:**
- ❌ No measurable improvement in any metric
- ❌ System stability degraded (crashes, hangs)
- ❌ Internet connectivity broken
- ❌ Core services non-functional (audio, display)
- ❌ Antivirus disabled or non-functional

**In case of failure:** Run rollback procedures immediately.

---

## Realistic Expectations

### Factors Affecting Results

#### Hardware Dependent
- **SSD vs HDD:** HDD systems see 20-30% more improvement
- **RAM Capacity:** 1-2GB systems see biggest % improvement
- **CPU Type:** Older CPUs benefit more from DPC optimization
- **Chipset:** Older chipsets have more latency optimization potential

#### Workload Dependent
- **Idle optimizations:** 100% achievable
- **Light workload:** 80-90% achievable
- **Heavy workload:** 50-70% achievable
- **Real-time workload:** 70-100% achievable (DAW, gaming)

#### Diminishing Returns
```
Optimization 1 (Disable Cortana):      -50 MB
Optimization 2 (Disable OneDrive):     -40 MB
Optimization 3 (Registry tuning):      -80 MB
Optimization 4 (Service removal):      -60 MB
Optimization 5 (Memory optimization):  -30 MB
...
Optimization 20+ (Additional tweaks):  -5 MB per optimization
```

### What NOT To Expect

| Expectation | Reality |
|-------------|---------|
| 4GB → 8GB RAM performance | Impossible (hardware limitation) |
| Slow HDD becomes fast | ~20-30% faster, but still slow |
| Pentium 4 → Modern performance | No (architecture limitation) |
| 100% RAM available | No (system needs working set) |
| Zero DPC latency | Impossible (hardware physics) |

---

## Measurement Best Practices

### Before Measurement

✅ **Do:**
- Close all user applications
- Disable antivirus monitoring (temporarily)
- Disable network sync (OneDrive, etc.)
- Disconnect network if possible
- Wait 30+ minutes after boot

❌ **Don't:**
- Measure during Windows Update
- Include background services in metrics
- Run multiple measurements back-to-back (system state changes)
- Compare different hardware configurations
- Measure with full workload running

### During Measurement

✅ **Do:**
- Use consistent workload (same applications, same duration)
- Record environmental conditions (temperature, power state)
- Take multiple measurements (minimum 3)
- Average results across runs
- Document any anomalies

❌ **Don't:**
- Move mouse or interact with system
- Change power settings between measurements
- Measure for less than 5 minutes
- Compare different OS versions
- Measure during driver installation

### After Measurement

✅ **Do:**
- Save baseline data for comparison
- Document methodology
- Calculate statistical mean and variance
- Compare identical conditions (before/after)
- Share methodology, not just results

❌ **Don't:**
- Cherry-pick best results
- Ignore outliers without reason
- Compare against different baseline
- Over-claim improvements
- Measure without proper controls

---

## Sample Before/After Report

```
╔════════════════════════════════════════════════════════════════╗
║         PERFORMANCE OPTIMIZATION RESULTS                       ║
║         Windows 10 22H2 on Intel i3-2130 / 4GB RAM             ║
╚════════════════════════════════════════════════════════════════╝

Test Date:      May 13, 2026
Test Duration:  10 minutes per measurement
Measurement Tool: LatencyMon 11.2
Samples Taken:  3 (averaging results)

─────────────────────────────────────────────────────────────────
                          BEFORE           AFTER         IMPROVEMENT
─────────────────────────────────────────────────────────────────

MEMORY USAGE:
  Idle RAM:        1.35 GB        0.82 GB      -393 MB (-29.1%)
  Available RAM:   2.65 GB        3.18 GB      +530 MB (+20.0%)

DPC LATENCY:
  Average:          1047 μs         187 μs      -860 μs (-82.1%)
  Maximum:         3401 μs         412 μs      -2989 μs (-87.9%)
  Std Dev:         602 μs          58 μs       -544 μs (-90.4%)

ISR LATENCY:
  Average:          89 μs           42 μs       -47 μs (-52.8%)
  Maximum:         254 μs          98 μs       -156 μs (-61.4%)

SYSTEM HEALTH:
  Hard Faults/sec:  28              3           -25 (-89.3%)
  Process Count:    54              21          -33 (-61.1%)
  Context Sw/sec:   2100            890         -1210 (-57.6%)

─────────────────────────────────────────────────────────────────

SUBJECTIVE ASSESSMENT:
  ✓ System feels noticeably more responsive
  ✓ Audio playback is smooth (no clicks/pops)
  ✓ Mouse movement is fluid
  ✓ Applications launch faster
  ✓ Gaming experience improved (no stutters)

CONCLUSION: ✅ OPTIMIZATION SUCCESSFUL
All metrics exceed targets. System ready for production use.

ROLLBACK INFO: Available via snapshot "BeforeOptimization"
Created: May 13, 2026 14:32:15 UTC
Size: 156 MB (compressed registry backup)
```

---

## References

- [DPC Latency Analysis](https://docs.microsoft.com/en-us/windows-hardware/drivers/devtest/dpc-latency-analysis)
- [Performance Monitoring](https://docs.microsoft.com/en-us/windows/win32/perfctrs/about-performance-counters)
- [LatencyMon Documentation](https://www.resplendence.com/latencymon)
- [Windows Performance Toolkit](https://docs.microsoft.com/en-us/windows-hardware/test/wpt/)
