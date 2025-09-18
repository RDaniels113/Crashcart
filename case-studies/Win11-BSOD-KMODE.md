# Case Study: Windows 11 BSOD – KMODE_EXCEPTION_NOT_HANDLED

## 📝 Overview
A Windows 11 workstation experienced recurring **BSODs** with stop code:


Crashes referenced `FLTMGR.SYS` and later IRQL-related errors.  
Hardware: **Intel i9-13900K, Gigabyte B660 DS3H DDR4, 64gb DDR4 2666mhz RAM, no discrete GPU**.

This case study documents the symptoms, tools used, root causes identified, and remediation steps.

---

## ❗ Problem Symptoms
- Frequent BSODs:
  - `KMODE_EXCEPTION_NOT_HANDLED`
  - `IRQL_NOT_LESS_OR_EQUAL`
- WinDbg analysis pointed to **filter manager failures** (`FLTMGR.SYS`).
- Machine shut down within ~90 seconds due to **CPU overheating** (cooler mount failure).
- Rogue DLL (`LogiDLA.dll`) executed via `rundll32.exe` on startup.

---

## 🛠 Tools Used
- **WinDbg Preview** → Crash dump analysis (`!analyze -v`)
- **DISM / SFC** → Windows image repair
- **PowerShell** → Registry hive inspection & minifilter checks
- **DISM (offline)** → Driver removal
- **Hardware fixes** → CPU cooler reseating, thermal paste reapplication

---

## 🔍 Root Causes
1. **Cooling failure**  
   - Intel push-pin cooler didn’t seat correctly → overheating & forced shutdown.

2. **Conflicting file system minifilters**  
   - Gigabyte bundle installed **Symantec filter drivers** conflicting with Defender → `FLTMGR.SYS` crashes.

3. **Logitech Download Assistant residue**  
   - `LogiDLA.dll` persisted in public user startup → executed on boot via `rundll32.exe`.

4. **BIOS defaults instability**  
   - “Load Optimized Defaults” enabled **XMP** & **Enhanced Turbo** → unstable memory training.

---

## 🛠 Remediation Steps
- **Cooling:**  
  - Removed stock cooler, cleaned CPU/HS with 91% isopropyl alcohol.  
  - Installed **Thermaltake Contac Silent 12** with proper LGA1700 backplate.  
  - Verified CPU temps stable in BIOS.

- **Driver & Filter Cleanup:**  
  - Exported drivers offline, removed Logitech, TeamViewer, and Magic Control.  
  - Disabled Symantec minifilter drivers via SYSTEM hive edits.  
  - Verified with `fltmc filters`.

- **Windows Repairs:**  
  - Ran `DISM /RestoreHealth` and multiple `sfc /scannow`.  
  - Confirmed system file integrity.

- **Startup Cleanup:**  
  - Removed `LogiDLA.dll` entry from Public user startup.  
  - Verified removal via Task Manager and registry.

- **BIOS Stabilization:**  
  - Disabled XMP & Enhanced Turbo/MCE.  
  - Left system at JEDEC/stock for maximum stability.

---

## ✅ Outcome
- System boots reliably and remains stable under normal workloads.  
- BSODs resolved, rogue DLL removed, and CPU temps under control.  
- Verified via 30-minute idle test, Windows Update, and reboot cycles.

---

## 📚 Lessons Learned
- Stock Intel coolers are unreliable for high-wattage CPUs → always verify seating & temps first.  
- Vendor driver bundles introduce conflicts → only install chipset, GPU, NIC from OEM.  
- Minifilter conflicts (`FLTMGR.SYS`) are a common hidden BSOD cause.  
- BIOS “optimized defaults” can destabilize systems → test features like XMP one at a time.  
- Offline DISM + registry hive editing are powerful tools when online repairs fail.

---

## 📂 Key Artifacts
- [`offline-fsfilters.txt`](../artifacts/offline-fsfilters.txt) – Offline minifilter list  
- [`drivers-offline.txt`](../artifacts/drivers-offline.txt) – Exported driver inventory  
- [`windbg-analysis.txt`](../artifacts/windbg-analysis.txt) – Debugger output  

---

## 🔑 Reference Commands

```powershell
# Enumerate minifilters
fltmc filters

# List suspicious drivers
driverquery /v | findstr /i "logi|sym|team|magic"

# Windows image repairs
DISM /Online /Cleanup-Image /RestoreHealth
sfc /scannow

# Offline registry load
reg load HKLM\OfflineSYS D:\Windows\System32\config\SYSTEM
