# ISO Build Guide - Custom Windows Images

## Overview

This guide provides reference information for creating custom Windows ISO images with reduced bloatware and optimized configurations. This is **optional** — you can also optimize stock Windows using post-installation scripts.

---

## Approaches to Custom ISO

### Approach 1: Post-Installation Optimization (Recommended for Most Users)

**What:** Install stock Windows, then run debloat/optimization scripts  
**Pros:** Simple, reversible, no special tools needed  
**Cons:** Requires cleanup after installation  
**Timeline:** 30-60 minutes  
**Recommended for:** Most users, first-time users

**Steps:**
1. Install Windows from official media
2. Boot and reach desktop
3. Run `Optimize-System.ps1` script
4. Restart and done

### Approach 2: NTLite Customization (For Advanced Users)

**What:** Remove components from ISO before installation  
**Pros:** Cleaner install, fewer things to disable  
**Cons:** Requires special tool, more technical  
**Timeline:** 1-2 hours  
**Recommended for:** Advanced users, mass deployment

**Steps:**
1. Download Windows ISO
2. Use NTLite to remove components
3. Create customized ISO
4. Deploy to systems

### Approach 3: Windows PE / WinPE (Expert Only)

**What:** Create minimal Windows PE environment with only necessary components  
**Pros:** Maximum control, minimal footprint  
**Cons:** Highly technical, error-prone  
**Timeline:** 2-4 hours  
**Recommended for:** IT professionals only

---

## Approach 1: Post-Installation (Easiest)

**Recommended.** Follow [DEPLOYMENT-GUIDE.md](DEPLOYMENT-GUIDE.md).

---

## Approach 2: NTLite Customization

### Prerequisites

1. **NTLite Tool:**
   - Download: https://www.ntlite.com/
   - Free evaluation version available
   - Licensed version recommended (supports scripting)

2. **Windows ISO:**
   - Windows 10 22H2: https://www.microsoft.com/software-download/windows10
   - Windows 11 24H2: https://www.microsoft.com/software-download/windows11
   - File size: 5-7 GB

3. **System Requirements:**
   - Processor: Any modern CPU
   - RAM: 4GB minimum (8GB recommended)
   - Disk: 20GB free space
   - OS: Windows or Linux

### Step 1: Download Windows ISO

**Windows 10 22H2:**
```
1. Visit: https://www.microsoft.com/software-download/windows10
2. Click "Download tool now"
3. Run Media Creation Tool
4. Select "Create installation media"
5. Choose USB drive or ISO file
6. File saved as: Windows.iso (~5.5 GB)
```

**Windows 11 24H2:**
```
1. Visit: https://www.microsoft.com/software-download/windows11
2. Scroll to "Download Windows 11 Disk Image"
3. Select Windows 11 version
4. Select language (English)
5. File saved as: Win11_24H2.iso (~6.5 GB)
```

### Step 2: Launch NTLite

```
1. Install NTLite
2. Launch application
3. Click "Browse" and select Windows ISO
4. NTLite will extract and analyze (takes 1-2 minutes)
```

### Step 3: Select Components to Remove

**Safe to Remove (Conservative):**
- OneDrive
- Cortana
- Xbox components (XboxApp, Xbox DVR, etc.)
- Optional Features:
  - Fax and Scan
  - Math Recognizer
  - Media Feature Pack
  - Windows Sandbox

**Potentially Risky (Moderate):**
- 3D Objects folder
- Telemetry services (DiagTrack, dmwappushservice)
- Indexing service (Windows Search)
- Superfetch (SysMain)

**Very Risky (Aggressive - Not Recommended via ISO):**
- Cortana Search
- Defender components
- Core system services
- Display drivers

### Step 4: Remove Components in NTLite

```
1. Left panel: Select "Windows 10" or "Windows 11"
2. Right panel shows components
3. Right-click components and select "Remove"
4. Green checkmark = will be removed

Components to Remove:
  [ ] OneDrive
  [ ] Cortana
  [ ] Xbox
  [ ] 3D Objects
  [ ] Mail/Calendar apps
  [ ] Photos app
  [ ] Groove Music
  [ ] Movies & TV
  [ ] Photos
  [ ] Alarms
  [ ] Calculator
```

### Step 5: Create Custom ISO

```
1. Click "Integrate" menu
2. Ensure "Windows" is selected
3. Click "Export" button
4. Select export destination (local drive, external USB)
5. Choose "Create ISO"
6. NTLite will repackage (takes 10-20 minutes)
7. Output: CustomWindows.iso (~4-5 GB)
```

### Step 6: Create Installation Media

**Option A: USB Drive**
```powershell
# Use Rufus tool: https://rufus.ie/
1. Insert USB drive (8GB+)
2. Launch Rufus
3. Select device: [Your USB drive]
4. Boot selection: CustomWindows.iso
5. Click "START"
6. Wait for completion (5-15 minutes)
```

**Option B: DVD Disc**
```
1. Insert blank DVD
2. Right-click CustomWindows.iso
3. Select "Burn disc image"
4. Confirm and burn
```

### Step 7: Deploy and Test

```
1. Boot system from USB/DVD
2. Install as normal Windows
3. System will have fewer pre-installed bloatware
4. Run post-installation optimization scripts
5. Verify system works correctly
```

### Step 8: Validation Checklist

After installation from custom ISO:

```
[ ] System boots successfully
[ ] Windows Update works
[ ] Internet connectivity functional
[ ] Audio and display drivers loaded
[ ] Core system services running
[ ] No error messages in Event Viewer
[ ] Uninstalled components actually removed
```

---

## Approach 3: Windows PE (Advanced)

**This approach is highly technical and not recommended for most users.**

### Minimal Overview

**Purpose:** Create minimal bootable Windows environment with only necessary drivers/services

**Tools Required:**
- Windows ADK (Assessment and Deployment Kit)
- WinPE add-on
- PowerShell scripting knowledge

**Basic Steps:**
1. Install Windows ADK
2. Create WinPE image
3. Add necessary drivers manually
4. Remove telemetry components from image
5. Create bootable media
6. Deploy and verify

**Not Covered:** Full WinPE implementation is beyond this document scope. See:
- Microsoft: [Windows PE Overview](https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/windows-pe-intro)
- IT professional forums and documentation

---

## Recommendations

### For Typical Users

✅ **Use Approach 1 (Post-Installation):**
- Install Windows normally
- Run optimization scripts
- Simpler, reversible, no special tools

### For IT Professionals / Mass Deployment

✅ **Use Approach 2 (NTLite):**
- Create custom ISO once
- Deploy to multiple systems
- Faster deployment than post-installation
- Reduces initial bloatware

### For Minimal / Embedded Systems

⚠️ **Consider Approach 3 (WinPE):**
- Requires significant expertise
- Only for very specific use cases
- Not recommended for general users

---

## Comparison Table

| Feature | Post-Install | NTLite | WinPE |
|---------|-----------|--------|-------|
| **Complexity** | Simple | Medium | Complex |
| **Time Investment** | 30 min | 1-2 hours | 2-4 hours |
| **Special Tools** | None | NTLite | ADK + scripting |
| **Reversibility** | Yes | Partial | No |
| **Mass Deployment** | Scripted | Yes | Yes |
| **Learning Curve** | Minimal | Medium | High |
| **Recommended** | ✅ Most Users | ⚠️ IT Pro | ❌ Expert Only |

---

## Troubleshooting Custom ISO

### Issue: Custom ISO Won't Boot

**Cause:** Media not created properly or incompatible boot mode

**Solution:**
1. Recreate USB/DVD media
2. Use Rufus for USB creation
3. Verify BIOS settings (UEFI vs Legacy)
4. Try different USB port

### Issue: Missing Drivers After Installation

**Cause:** Removed drivers that were essential

**Solution:**
1. Don't remove storage drivers (SATA, NVMe, RAID)
2. Don't remove display drivers
3. Download chipset drivers from manufacturer
4. Use Device Manager to update drivers

### Issue: System Won't Start After Removing Components

**Cause:** Removed required system component

**Solution:**
1. Boot from recovery media
2. Run Windows Repair
3. Or reinstall using stock ISO instead

### Issue: Windows Activation Failed

**Cause:** Custom ISO may have licensing issues

**Solution:**
1. Use standard ISO from Microsoft (not modified)
2. Modify only non-critical components
3. Keep Windows core files intact
4. Run activation after installation

---

## Best Practices

✅ **Do:**
- Start with conservative removals
- Test custom ISO on virtual machine first
- Keep standard ISO as backup
- Document all changes made
- Use reputable tools (NTLite from trusted source)

❌ **Don't:**
- Remove system-critical components
- Modify without understanding impact
- Use cracked or pirated tools
- Skip testing on test system first
- Remove drivers without replacement

---

## Conclusion

For most users, **post-installation optimization** (Approach 1) is recommended:
- Simple and straightforward
- No special tools needed
- Fully reversible
- Achieves 95% of custom ISO benefits

Advanced users interested in mass deployment should explore **NTLite** (Approach 2):
- Professional tool
- Supports automation
- Significantly faster deployment

WinPE (Approach 3) is for specialized enterprise scenarios only.

---

## References

- [NTLite Documentation](https://www.ntlite.com/documentation/)
- [Windows ISO Downloads](https://www.microsoft.com/software-download/)
- [Windows ADK](https://docs.microsoft.com/en-us/windows-hardware/get-started/adk-install)
- [Rufus USB Creator](https://rufus.ie/)
