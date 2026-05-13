# Telemetry Removal Options Guide

## Overview

This document explains the two approaches to telemetry removal: **Complete Removal** and **Conservative Disable**. Users choose their preferred level based on privacy concerns, system stability requirements, and technical expertise.

---

## Table of Contents

1. [Telemetry Threat Model](#telemetry-threat-model)
2. [Complete Removal Approach](#complete-removal-approach)
3. [Conservative Disable Approach](#conservative-disable-approach)
4. [Comparison Matrix](#comparison-matrix)
5. [Decision Framework](#decision-framework)
6. [Troubleshooting](#troubleshooting)

---

## Telemetry Threat Model

### What Microsoft Collects (Stock Windows)

**Telemetry Data Collected:**
- Crash dumps and error reports
- Diagnostic data (hardware info, performance metrics)
- Usage patterns (which apps used, frequency)
- Software compatibility information
- Location data (if enabled)
- Browser search history (if using Edge)
- OneDrive activity and file info
- Typing/handwriting patterns (if using input improvement)
- Audio input (if using Cortana)

**Collection Frequency:**
- Real-time: Performance counters, system events
- Hourly: Diagnostics, error logs
- Daily: Behavioral patterns, usage summaries

**Transmission:** Encrypted to Microsoft servers, typically HTTPS port 443

**Data Retention:** Microsoft policy states "up to 18 months"

### Privacy Implications

✅ **Non-Sensitive:** Crash reports, generic error codes  
⚠️ **Potentially Sensitive:** App usage patterns, hardware fingerprinting  
❌ **Sensitive:** Typing patterns, voice audio, browsing history  

---

## Complete Removal Approach

### Definition

**Complete Removal** = Disable + Block + Delete telemetry components entirely.

### Components Disabled

#### 1. Telemetry Services (Disable + Prevent Restart)

```yaml
Services to Disable:
  - DiagTrack (Diagnostic Tracking Service)
  - dmwappushservice (dmwappush service)
  - OneSyncSvc (Sync service, optional)
  - DoSvc (Delivery Optimization, optional)
  - DiagSvc (Diagnostic Policy Service, partial)
  - WerSvc (Windows Error Reporting, optional)
```

#### 2. Telemetry Binaries (Delete, when safe)

```yaml
Files to Remove:
  - C:\Windows\System32\DiagTrack.dll
  - C:\ProgramData\Microsoft\Diagnosis\
  - C:\Windows\System32\diagtrack.exe (if in System32)
  - OneDrive telemetry components (if offboarding)
```

#### 3. Scheduled Tasks (Disable)

```yaml
Task Paths to Disable:
  - \Microsoft\Windows\Application Experience\*
  - \Microsoft\Windows\Customer Experience Improvement Program\*
  - \Microsoft\Windows\Autochk\*
  - \Microsoft\Windows\UpdateOrchestrator\*
  - \Microsoft\Windows\DiskDiagnostic\*
```

#### 4. Network Blocking (Hosts File + Firewall)

```yaml
Telemetry Endpoints to Block:
  - telemetry.microsoft.com
  - *.telemetry.microsoft.com
  - watson.*.microsoft.com
  - settings-*.edge.microsoft.com
  - connectivitycheck.gstatic.com (optional)
  - telemetry.gstatic.com (optional)
```

**Method 1: Hosts File**
```
127.0.0.1 telemetry.microsoft.com
127.0.0.1 *.telemetry.microsoft.com
...
```

**Method 2: Firewall Rules**
```powershell
New-NetFirewallRule -DisplayName "Block Telemetry" `
  -Direction Outbound `
  -Program "C:\Windows\System32\svchost.exe" `
  -RemoteAddress "telemetry.microsoft.com" `
  -Action Block
```

#### 5. Group Policy (if Pro/Enterprise)

```yaml
Policies to Set:
  - Computer Configuration > Admin Templates > Windows Components > Data Collection and Preview Builds
    → Allow Diagnostic Data: Diagnostic data off (minimal)
  
  - Computer Configuration > Admin Templates > Windows Components > CEIP
    → Turn off CEIP: Enabled
  
  - Computer Configuration > Admin Templates > System > Internet Communication Management
    → Restrict Updates: Enabled
```

#### 6. Registry Tweaks (Complete Block)

```powershell
# Disable Cortana
reg add "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowCortana /t REG_DWORD /d 0 /f

# Disable Connected User Experiences
reg add "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" /v PublishUserActivities /t REG_DWORD /d 0 /f

# Disable DiagTrack service
sc config DiagTrack start= disabled
```

### Advantages of Complete Removal

✅ **Maximum privacy:** Telemetry blocked entirely  
✅ **Lower overhead:** No telemetry processes running  
✅ **Clear intent:** No hidden data collection  
✅ **Offline-capable:** System works fully disconnected  

### Disadvantages of Complete Removal

❌ **Risk of breakage:** Deleting files can cause issues  
❌ **Updates may restore:** Major Windows Update may re-enable  
❌ **Complex rollback:** Requires file restoration  
❌ **Compatibility:** Some features may not work  

### Risk Level

**Risk:** Moderate-High
- File deletion is destructive
- Service dependencies may exist
- Requires testing for side effects

### Recommendations for Complete Removal

**Who Should Use:**
- Privacy-conscious users
- Fully offline systems
- Enterprise deployments
- Systems with limited internet bandwidth

**Who Should NOT Use:**
- Users unfamiliar with Windows internals
- Laptop users (may affect battery reporting)
- Systems requiring Microsoft support
- Organizations with Group Policy requirements

---

## Conservative Disable Approach

### Definition

**Conservative Disable** = Disable services and endpoints only, no deletion.

### Components Disabled

#### 1. Telemetry Services (Disable Only)

```powershell
$services = @(
  'DiagTrack',          # Diagnostic Tracking
  'dmwappushservice',   # dmwappush
  'WerSvc',            # Windows Error Reporting (optional)
  'DoSvc'              # Delivery Optimization (optional)
)

foreach ($service in $services) {
  Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
  Set-Service -Name $service -StartupType Disabled
}
```

**Effect:** Services stop running, don't auto-start, but files remain on disk.

#### 2. Scheduled Tasks (Disable)

```powershell
$tasks = @(
  '\Microsoft\Windows\Application Experience\AitTaskheur',
  '\Microsoft\Windows\Autochk\Proxy',
  '\Microsoft\Windows\Customer Experience Improvement Program\Consolidator'
)

foreach ($task in $tasks) {
  Disable-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue
}
```

**Effect:** Tasks are disabled but can be re-enabled later.

#### 3. Network Blocking (Firewall Only)

```powershell
# Block telemetry endpoints via firewall
New-NetFirewallRule -DisplayName "Block Telemetry Outbound" `
  -Direction Outbound `
  -RemoteAddress "telemetry.microsoft.com","*.telemetry.microsoft.com" `
  -Action Block
```

**Note:** NOT modifying hosts file (reversible via firewall rules only)

#### 4. Registry Modifications (Disabling, not Deleting)

```powershell
# Set diagnostic data to off
reg add "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowDiagnosticData /t REG_DWORD /d 0 /f
```

### Advantages of Conservative Disable

✅ **Fully reversible:** Delete firewall rules, re-enable services  
✅ **No file risk:** Original files stay intact  
✅ **Windows Update safe:** Updates don't restore, services auto-disable again  
✅ **Easier rollback:** Just run rollback script  
✅ **Professional:** Suitable for enterprise deployments  

### Disadvantages of Conservative Disable

⚠️ **Not 100% private:** Files still exist on disk  
⚠️ **Slightly slower:** Services just disabled, not removed  
⚠️ **Less clear:** Ambiguous whether telemetry is truly off  

### Risk Level

**Risk:** Low
- No file system changes
- Services are just disabled (like off switch)
- Fully reversible
- Safe on all systems

### Recommendations for Conservative Disable

**Who Should Use:**
- General users wanting privacy
- Systems requiring stability/support
- Enterprise environments
- Professional deployments

**Who Should NOT Use:**
- Users with extreme privacy concerns
- Systems requiring offline-only operation
- Environments requiring forensic removal

---

## Comparison Matrix

| Feature | Complete Removal | Conservative Disable |
|---------|----------------|---------------------|
| **Privacy Level** | Maximum ✅ | Very Good ✅ |
| **Risk of Breakage** | Moderate ⚠️ | Very Low ✅ |
| **Reversibility** | Complex | Simple |
| **Rollback Time** | 15-30 min | 2-5 min |
| **Windows Update Safe** | ❌ May restore | ✅ Stays disabled |
| **File System Impact** | Destructive | None |
| **Requires Admin** | ✅ Yes | ✅ Yes |
| **Suitable for Enterprise** | ❌ No | ✅ Yes |
| **Suitable for Home Users** | ⚠️ Maybe | ✅ Yes |
| **Telemetry Binaries Remain** | ❌ No | ✅ Yes |
| **Services Running** | ❌ No | ❌ No |
| **Network Endpoints Open** | ❌ No | ❌ No (blocked) |

---

## Decision Framework

### Choose Complete Removal IF:

```
[ ] Privacy is absolute priority (not just preference)
[ ] System will be offline most of the time
[ ] You're comfortable with file system manipulation
[ ] You have full system backup available
[ ] You understand Windows service dependencies
[ ] Risk of breakage is acceptable
[ ] You need forensic-level removal
```

**→ Then use: Complete Removal**

### Choose Conservative Disable IF:

```
[ ] Privacy is important but not absolute priority
[ ] System needs to remain 100% stable
[ ] You need easy rollback capability
[ ] You want to handle future Windows Updates
[ ] System may require Microsoft support
[ ] You prefer administrative simplicity
[ ] Professional/Enterprise environment
```

**→ Then use: Conservative Disable**

### Default Recommendation

**For Most Users:** Conservative Disable

**Reasoning:**
- Provides 95% of privacy benefit
- Eliminates 100% of execution overhead
- Blocks 100% of network telemetry
- Fully reversible and safe
- Survives Windows Updates
- Works in enterprise environments

---

## Troubleshooting

### Issue: Services Re-Enable After Windows Update

**Cause:** Windows Update may restore disabled services

**Solution - Complete Removal:**
```powershell
# Re-run telemetry removal script post-update
.\Remove-Telemetry-Complete.ps1
```

**Solution - Conservative Disable:**
```powershell
# Services auto-stay disabled; just verify
Get-Service DiagTrack | Select-Object Status, StartType
```

### Issue: System Features Not Working

**Symptom:** Windows Update, Store, or Settings app not working

**Cause:** Removed telemetry services may have been required by other services

**Solution - Complete Removal:**
```powershell
# Restore from backup or rollback
.\Rollback-Registry.ps1 -SnapshotName "BeforeTelemetryRemoval"
```

**Solution - Conservative Disable:**
```powershell
# Re-enable services
Set-Service -Name DiagTrack -StartupType Automatic
Start-Service -Name DiagTrack
```

### Issue: Telemetry Connection Still Observed (Packet Sniffing)

**Cause:** Endpoint blocked at firewall, but DNS may still resolve

**Solution - Complete Removal:**
```powershell
# Verify hosts file entries
Get-Content C:\Windows\System32\drivers\etc\hosts | Select-String "telemetry"

# Verify firewall rules
Get-NetFirewallRule | Select-String "Telemetry"
```

**Solution - Conservative Disable:**
```powershell
# Verify firewall rules are active
Get-NetFirewallRule -DisplayName "*Telemetry*" | Where-Object { $_.Enabled -eq $true }
```

### Issue: Performance Not Improved After Telemetry Removal

**Cause:** Telemetry overhead is usually <1% CPU; other optimizations more important

**Solution:**
1. Verify services actually disabled: `Get-Service DiagTrack | Select Status`
2. Check for other background processes: `Get-Process | Sort WorkingSet -Desc | Head -10`
3. Apply registry optimizations for bigger gains (DPC, memory)
4. Consider debloating as priority over telemetry removal

### Issue: Cannot Remove Telemetry (Permission Denied)

**Cause:** File in use or SYSTEM process running

**Solution - Complete Removal:**
```powershell
# Run in Safe Mode with Networking
# Or stop service first
Stop-Service -Name DiagTrack -Force
# Then remove file
Remove-Item "C:\Windows\System32\DiagTrack.dll" -Force
```

**Solution - Conservative Disable:**
```powershell
# Just disable service, no file removal needed
Set-Service -Name DiagTrack -StartupType Disabled
```

---

## Summary Table

| Scenario | Recommendation | Rationale |
|----------|---|---|
| Home user, privacy-conscious | Conservative Disable | Best privacy/stability balance |
| Professional/Enterprise | Conservative Disable | Requires reversibility, compatibility |
| Fully offline system | Complete Removal | No need for reversibility |
| System admin, expert user | Complete Removal | Understands implications |
| Casual user | Conservative Disable | Simple and safe |
| Performance-focused | Either (minor difference) | Telemetry < 1% CPU impact |

---

## References

- [Microsoft Privacy Statement](https://privacy.microsoft.com/en-us/privacystatement)
- [Windows 10 Diagnostic Data](https://docs.microsoft.com/en-us/windows/privacy/windows-diagnostic-data)
- [Windows 11 Privacy](https://docs.microsoft.com/en-us/windows/privacy/windows-11-privacy)
- [Telemetry Endpoints](https://github.com/W4RH4WK/Debloat-Windows-10) (community maintained list)
